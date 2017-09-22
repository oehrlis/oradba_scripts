# -------------------------------------------------------------------------------------
#    $Id: $
# -------------------------------------------------------------------------------------
#    Trivadis AG, Infrastructure Managed Services
#    Europa-Strasse 5, 8152 Glattbrugg, Switzerland
# -------------------------------------------------------------------------------------
#    File-Name........:  mos_download_url.sh
#    Author...........:  Stefan Oehrli (oes) stefan.oehrli@trivadis.com
#    Editor...........:  $LastChangedBy: $
#    Date.............:  22. April 2011
#    Revision.........:  1.0
#    Purpose..........:  Download Patch's from MOS (My Oracle Support)
#    Usage............:  mos_download_url.sh -u <USER> -p <PASSWORD> -f <download_url_file.txt>
#    File formats.....:  dont use files
#    Restrictions.....:  unknown
#    Notes............:  --
# -------------------------------------------------------------------------------------
#    Revision history.:  
#    22.04.2011    soe   initial release
# -------------------------------------------------------------------------------------
# GLOBAL VARS #############################################################
## MOS Account
MOS_USER=ACCOUNT
MOS_PASSWORD=PASSWORD

# ---- You should not have to change anything below this line -------------
WGET=/usr/bin/wget                               # path to wget
LOGDIR=$(pwd -P $(dirname $0))
MyName="`basename $0`"                           # script name
DOWNLOAD_FILE=${MyName}.txt
LOGFILE=${LOGDIR}/${MyName}-$(date +%m-%d-%y-%H%M).log
# END OF GLOBAL VARS ######################################################
# FUNCTIONS
#---------------------------------------------------------------------
Usage()
#
# PURPOSE: Usage
#---------------------------------------------------------------------
{
    echo "INFO : Usage, ${MyName}  [-hv]"
    echo "INFO :        -h             Usage (this message)"
    echo "INFO :        -u <USER>      MOS user account"
    echo "INFO :        -p <PASSWORD>  MOS password"
    echo "INFO :        -f <FILE>      Text file with download url"
    echo "INFO :                       Logfile : ${LOGFILE}"
}
# END OF FUNCTIONS ########################################################


# MAIN ####################################################################
if [ $# -lt 1 ]; then                         				# Exit if no. of command line args is 0
	Usage
	exit 1
fi

# processing commandline parameter"
while getopts hu:p:f: arg 
do
    case $arg in
        h)  Usage                                           # print Usage
            exit 0;;
        u)  MOS_USER="${OPTARG}";;                          # set the MOS user account
        p)  MOS_PASSWORD="${OPTARG}";;                      # set the MOS password
        f)  DOWNLOAD_FILE="${OPTARG}";;                     # set download file with the url
		?)  Usage                                           # print Usage
            exit 1;;                                        # exit with error code 1
    esac
done

test -f $DOWNLOAD_FILE|| (echo "Can not access download file ${DOWNLOAD_FILE}" && exit 1)
for i in $(cat $DOWNLOAD_FILE|grep -v ^#)
do
OUTPUT_FILE=$(echo "$i"|cut -d= -f3)
echo "download $OUTPUT_FILE from '$i'" >> $LOGFILE 2>&1
${WGET} --http-user=$MOS_USER --http-password=$MOS_PASSWORD --no-check-certificate -O $OUTPUT_FILE "$i" >> $LOGFILE 2>&1
done
# END OF MAIN #############################################################
# EOF #####################################################################