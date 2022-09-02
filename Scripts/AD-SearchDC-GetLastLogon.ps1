<#
.SYNOPSIS
    Checks the LastLogon for On-Premises AD Users against each Windows Active Directory Domain Controller

.DESCRIPTION
    This script searches AD for AD User Objects that matches sAMAccountName and logs the lastLogon to a .csv file.
    Goes through each Domain Controller for the value, lastLogon is a value that's specific to each Domain Controller.

    Written by: Timothy Duong
    ChangeLog:
    1.0 - Created Script and tested in Test Environment (30th of August)
    1.1 - Updated the PS Array to System.Collections and changed the Get-ADUser to be outside the loop instead

.INPUTS
    sAMAccountName of Users in a .CSV file and set in variable $CSVImport, use 'sAMAccountName' as the header.
    Place the .CSV File in required folder accordingly

.OUTPUTS
    .CSV located at $OutputFile
#>

# Variables
$CSVUserList = 'C:\Scripts\ADUserList.csv'
$OutputFile = 'C:\Scripts\SearchDC-GetlastLogon.csv'
$LogonHistory = [System.Collections.Generic.List[psobject]]::new()

#########################

Import-Module ActiveDirectory

$DCs = (Get-ADDomainController -Filter *).Name

ForEach ($DC in $DCs) {
    Try {
        $Users = Import-CSV -Path $CSVUserList
        $DCUsers = Get-ADUSer -Filter * -Server $DC -Property lastLogon | Select-Object -Property sAMAccountName, lastLogon
        ForEach ($User in $Users) {
            $ADUser = $DCUsers | Where-Object { $_.sAMAccountName -eq $User.sAMAccountName }
            $LogonHistoryobject = New-Object -TypeName PSObject -Property ([ordered]@{
                    'LogonName'  = $($user.sAMAccountName)
                    'DomainCont' = $DC
                    'lastLogon'  = [datetime]::FromFileTime($ADUser.lastLogon)
                })
            $LogonHistory.Add($LogonHistoryobject)
        }
    }

    Catch {
        Write-Host "Cannot connect DC $($dc)!"
    }
}

$LogonHistory | Export-CSV -Path $OutputFile -NoTypeInformation -Delimiter ',' -Encoding UTF8

#########################
