#!/bin/ksh
# -------------------------------------------------------------------------------------
#	$Id: $
# -------------------------------------------------------------------------------------
#	Trivadis AG, Infrastructure Managed Services
#	Europa-Strasse 5, 8152 Glattbrugg, Switzerland
# -------------------------------------------------------------------------------------
#	File-Name........:	mk_packages.ksh
#	Author...........:	Stefan Oehrli (soe) stefan.oehrli@trivadis.com
#	Editor...........:	soe
#	Date.............:	24.02.2011
#	Revision.........:	$LastChangedRevision: $
#	Version..........:	1.0
#	Purpose..........:	Script to create a tar package from a toolbox. 
#	Usage............:	mk_packages.ksh
#	Reference........:	--
#	Group/Privileges.:	--
#	File formats.....:	use temporary file to configure targets
#	Output.......... :	--
#	Called by........:	--
#	Libraries........:	--
#	Error handling...:	simple checks
#	Restrictions.....:	directories are hardcoded....
#	Notes............:	--
# -------------------------------------------------------------------------------------
#	Revision history.:  
#   21.05.2008    soe   first initial draft version.
# -------------------------------------------------------------------------------------
# 	TODO List:
# -------------------------------------------------------------------------------------

TOOLBOX="oradba"
TODAY=$(date "+%Y-%m-%d")

#cd /u00/app/oracle/local/${TOOLBOX}/install || exit

rm -rf ${TOOLBOX}
rm -f  ${TOOLBOX}${TODAY}.tgz

mkdir ${TOOLBOX}
cd ${TOOLBOX}
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
export COPYFILE_DISABLE=true
cp -pr ../../bin .
cp -pr ../../etc .
cp -pr ../../rcv .
cp -pr ../../rsp .
cp -pr ../../sql .

#mkdir reports log

#rm -rf packages/ install/ development/ log/

find . -name ".svn" -depth -exec rm -rf {} \; 2>/dev/null
find . -name ".DS_Store" -depth -exec rm -rf {} \; 2>/dev/null
find . -name "._*" -depth -exec rm -rf {} \; 2>/dev/null

cd ..
tar czvf ${TOOLBOX}${TODAY}.tgz ${TOOLBOX}
cp ${TOOLBOX}${TODAY}.tgz ${TOOLBOX}.tgz
rm -rf ${TOOLBOX}

