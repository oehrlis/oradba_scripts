# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: create_krb5_spn.ps1
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.11.08
# Version....: --
# Usage......: create_krb5_spn.ps1 -ServiceName "db23"
# Parameters.: ServiceName     The name of the service or host. Default is 'db23'.
# Purpose....: Automates the creation of a service account for Oracle Database Kerberos Authentication.
# Notes......: This script facilitates the setup of a service account in Active
#              Directory for Oracle Database Kerberos Authentication. It generates
#              a secure password (if not provided), creates an AD user with the
#              specified service name, and configures the necessary
#              Service Principal Name (SPN).
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------
param (
    $ServiceName    ='db23',        # Service / Host Name as script parameter
    )         

$UserDN             = "cn=Users"    # Container for Service Name 
# - End of Customization -------------------------------------------------------

# - Default Values -------------------------------------------------------------
$UserBaseDN = "$UserDN," + (Get-ADDomain).DistinguishedName # define User base DN 
$DNSRoot    = (Get-ADDomain).DNSRoot                        # define DNS root
# - EOF Default Values ---------------------------------------------------------

# - Main -----------------------------------------------------------------------
Write-Host '= Setup KRB Service Name ==========================================='
Write-Host "INFO : Service Name        : $ServiceName"
Write-Host "INFO : DNS Root            : $DNSRoot"
Write-Host "INFO : User base DN        : $UserBaseDN"

# check if service name already exists
if (!(Get-ADUser -Filter "sAMAccountName -eq '$ServiceName'")) {
    Write-Host "INFO : Service Account ($ServiceName) does not exist."
} else  {
    Write-Host "INFO : Remove existing Service Account ($ServiceName)."
    Remove-ADUser -Identity $ServiceName -Confirm:$False
} 

Write-Host "INFO : Get credentials for $ServiceName."
$credential = Get-Credential -message 'Kerberos Service Account' -UserName $ServiceName
Write-Host "INFO : Create service account for DB server $ServiceName."
$ServiceUserParams = @{
    Name                    =   $credential.UserName
    DisplayName             =   $ServiceName
    SamAccountName          =   $ServiceName
    UserPrincipalName       =   "oracle/$ServiceName.$DNSRoot"
    Description             =   "Kerberos Service User for $ServiceName"
    Path                    =   $UserBaseDN
    AccountPassword         =   credential.Password
    PasswordNeverExpires    =   $true
    Enabled                 =   $true
    KerberosEncryptionType  =   "AES256"
}

# create kerberos service account
New-ADUser @ServiceUserParams
    
Write-Host "INFO : Create Service Principal Name (SPN) DB server $ServiceName."
setspn $ServiceName -s oracle/$ServiceName.$DNSRoot

Write-Host '= Finished Setup KRB Service Name =================================='
# - EOF ------------------------------------------------------------------------
