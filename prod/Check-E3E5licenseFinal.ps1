<#
Script Name: Check-E3E5LicenseFinal.ps1
Script Author: Chris Cook chris.cook@bcbsri.org
Script Purpose: This script will iterate through all user accounts in the Azure AD and query their Microsoft license entitlement. 
If the user has an E3 or E5 license assigned the script will:

    1. Check to see if the user has both and E3 and and E5 license assigned
    2. If the user has an E5 license assigned then a check is made to see if the user has either been assigned a Power BI Pro license or
       has a Teams Phone number assigned to them. The Power BI Pro check is a query to the Assign E5 Power Bi Pro Security Group and the Teams
       phone check is a lookup to a CSV file which is used as an input. 
    3. If a user has an E5 license and does not have Power BI Pro or a Teams Phone Number then they are flagged for downgrade to an E3 

The output of the script is a number of CSV files listing user accounts which should be assigned E3 or E5 licenses and those where both 
an E3 and E5 license have been assigned to a user 

TO DO 10/16/24:

    Need to update to place the output files in a centrally accessible location
    Script needs to be moved to a server where a scheduled job can be run monthly to update the data for tracking purposes. 

    
#>

Connect-AzureAD

Write-Host "Filtering AD users and writing group membership in to memory. This may take a few minutes. "
$AllAzureADUsers = Get-AzureADUser -All $true

$AvdUsersGroup = Get-AzureADGroup -SearchString "AVD-AZ-Netskope-Users"
$AssignPbiProLicenseGroup = Get-AzureADGroup -SearchString "Assign E5 Power BI Pro"
$AvdGroupMembers = Get-AzureADGroupMember -ObjectID $AvdUsersGroup.ObjectID -All $true
$PbiProGroupMembers = Get-AzureADGroupMember -ObjectID $AssignPbiProLicenseGroup.ObjectID -All $true
$E3LicenseGroup = Get-AzureADGroup -SearchString "Assign O365 E3 License"
$E3LicenseGroupMembers = Get-AzureADGroupMember -ObjectID $E3LicenseGroup.ObjectID -All $true
$E5LicenseGroup = Get-AzureADGroup -SearchString "Assign O365 E5 License"
$E5LicenseGroupMembers = Get-AzureADGroupMember -ObjectID $E5LicenseGroup.ObjectID -All $true
$E5AudioConferencingGroup = Get-AzureADGroup -SearchString "Assign E5 Audio-Conferencing"
$E5AudioConferencingGroupMembers = Get-AzureADGroupMember -ObjectID $E5AudioConferencingGroup.ObjectID -All $true
$E5FlowLicenseGroup = Get-AzureADGroup -SearchString "Assign O365 Flow License"
$E5FlowLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $E5FlowLicenseGroup.ObjectID -All $true
$E5PlannerLicenseGroup = Get-AzureADGroup -SearchString "Assign O365 Planner License"
$E5PlannerLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $E5PlannerLicenseGroup.ObjectID -All $true 
$E5PowerAppsLicenseGroup = Get-AzureADGroup -SearchString "Assign O365 Power Apps License"
$E5PowerAppsLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $E5PowerAppsLicenseGroup.ObjectID -All $true
$E5TeamsVoiceCommonAreaPhonesGroup = Get-AzureADGroup -SearchString "Teams Voice Common Area Phones"
$E5TeamsVoiceCommonAreaPhonesGroupMembers = Get-AzureADGroupMember -ObjectID $E5TeamsVoiceCommonAreaPhonesGroup.ObjectID -All $true

$teamsPhoneUserPath = ".\input\teamsPhoneWithNumber.csv"
$teamsPhoneUserArray = Import-Csv -Path $teamsPhoneUserPath

Write-Host "Script preparation complete"

$outputString = "UPN, AVD User, E3, E5, PBI Pro, Teams Phone, Downgrade, Month to Month, Validate`n"
$E3UserList = ""
$E5UserList = ""
$E3MonthToMonthUserList = ""
$E5MonthToMonthUserList = ""
$directlyAssignedLicenseLog = ""
$totalE3Today = 0
$totalE5Today = 0
$totalE3Tomorrow = 0
$totalE3MonthtoMonthTomorrow = 0
$totalE5Tomorrow = 0
$totalE5MonthtoMonthTomorrow = 0
$masterList = ""

foreach($user in $AllAzureAdUsers){
    try{
        $foundE3License = $false
        $foundE5License = $false
        $foundTeamsPhone = $false
        $MonthToMonthUser = $false
        $DowngradeLicense = $false
        $doNotAddToE3List = $false
        $isAvdUser = $false
        $isDirectlyAssignedLicense = $false
        $isAVDUserString = ""
        $isPBIPROMember = ""
        $isTeamsPhoneUser = ""

        $licenses = Get-AzureADUserLicenseDetail -ObjectID $user.ObjectID

        foreach($license in $licenses){
            switch ($license.SkuPartNumber){
                "SPE_E3" {$foundE3License = $true}
                "SPE_E5" {$foundE5License = $true}
                #"POWER_BI_STANDARD" {$foundPBILicense = $true}
            } 
        }

        if($foundE3License -or $foundE5License){
            $masterList += $user.userPrincipalName + "," + $user.CompanyName + ","
            if($user.CompanyName -like "*NTT*"){
                $MonthToMonthUser = $true
            }
    
            if($teamsPhoneUserArray.phoneUser -contains $user.userPrincipalName){
                $foundTeamsPhone = $true
            }

            if($foundTeamsPhone){
                $isTeamsPhoneUser = "TRUE"
            }
            else{
                $isTeamsPhoneUser = "FALSE"
            }
                
            $isAvdUser = $AvdGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
            if($isAvdUser){
                $isAVDUserString = "TRUE"
            }
            else{
                $isAVDUserString = "FALSE"
            }
            $isPBIGroupMember = $PbiProGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
            if($isPBIGroupMember){
                $isPBIPROMember = "TRUE"
            }
            else{
                $isPBIPROMember = "FALSE"
            }
            $isE5AudioConferencingGroupMember = $E5AudioConferencingGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
            if($isE5AudioConferencingGroupMember){
                $isAudioUser = "TRUE"
            }
            else{
                $isAudioUser = "FALSE"
            }
            $isE5FlowLicenseGroupMember = $E5FlowLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
            $isE5PlannerLicenseGroupMember = $E5PlannerLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
            $isE5PowerAppsLicenseGroupMember = $E5PowerAppsLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
            $isE5TeamsVoiceCommonAreaPhonesMember = $E5TeamsVoiceCommonAreaPhonesGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        
            if($foundE5License){
                $totalE5Today++
                $masterList += "Has E5,"
                if(($foundTeamsPhone) -or ($isPBIGroupMember) -or ($isE5AudioConferencingGroupMember) -or ($isE5FlowLicenseGroupMember) -or ($isE5PlannerLicenseGroupMember) -or ($isE5PowerAppsLicenseGroupMember) -or ($isE5TeamsVoiceCommonAreaPhonesMember)){
                    if($foundE3License){ #The user should have an E5 license so don't add them to the E3 list later
                        $totalE3Today++
                        $doNotAddToE3List = $true
                    }
                    if($MonthToMonthUser){
                        $E5MonthToMonthUserList += $user.userPrincipalName + "," + $user.CompanyName + "," + $isPBIPROMember + "," + $isTeamsPhoneUser + $isAudioUser + "`n"
                        $totalE5MonthtoMonthTomorrow++
                        $masterList += "E5 Monthly,"
                    }
                    else{
                        $E5UserList += $user.userPrincipalName + "," + $user.CompanyName + "," + $isPBIPROMember + "," + $isTeamsPhoneUser + $isAudioUser + "`n"
                        $totalE5Tomorrow++
                        $masterList += "E5 Yearly,"
                    }
                }
                else{
                    $DowngradeLicense = $true 
                    if($MonthToMonthUser){
                        $moveFromE5toE3MonthToMonthUserList += $user.userPrincipalName + "," + $user.CompanyName + "`n"
                        $totalE3MonthtoMonthTomorrow++
                        $masterList += "E3 Monthly,"
                    }
                    else{
                        $moveFromE5toE3UserList += $user.userPrincipalName + "," + $user.CompanyName + "`n"
                        $totalE3Tomorrow++
                        $masterList += "E3 Yearly,"
                    }
                }
            }

            if($foundE3License -and !$doNotAddToE3List){
                $totalE3Today++
                $masterList += "Has E3,"
                if($MonthToMonthUser){
                    $E3MonthToMonthUserList += $user.userPrincipalName + "," + $user.CompanyName + "`n"
                    $totalE3Tomorrow++
                    $masterList += "E3 Monthly"
                }
                else{
                    $E3UserList += $user.userPrincipalName + "," + $user.CompanyName + "`n"
                    $totalE3Tomorrow++
                    $masterList += "E3 Yearly"
                }
            }
            $masterList += "`n"

            <#if($foundE3License){
                $isE3GroupMember = $E3LicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
                if(!$isE3GroupMember){
                    $isDirectlyAssignedLicense = $true
                    Write-host $user.mail " has a directly assigned E3 license"
                }
            }
            if($foundE5License){
                $isE5GroupMember = $E5LicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
                if(!$isE5GroupMember -and !$isPBIGroupMember){
                    $isDirectlyAssignedLicense = $true
                    Write-Host $user.mail " has a directly assigned E5 license" $isPBIGroupMember
                }
            }
            if($isDirectlyAssignedLicense){
                $directlyAssignedLicenseLog += $user.mail + "`n"
            }

            if($foundE3License -and $foundE5License){
                if($foundE5License -and !$foundTeamsPhone -and !$isPBIGroupMember){
                    #Write-Host $user.userPrincipalName, "Remove E5"
                }
                else{
                    #Write-Host $user.userPrincipalName, "Remove E3"
                }
            }
            #>
            $outputString += $user.mail + "," + $isAvdUserString + "," + $foundE3License + "," + $foundE5License + "," + $isPBIProMember + "," + $foundTeamsPhone + "," + $DowngradeLicense + "," + $MonthToMonthUser + "`n"
        }
        
    }
    catch{
        $errorMessage = $_.Exception.Message
        $errorOutputString += $user.userPrincipalName + "," + $errorMessage + "," + $user.CompanyName + "`n"
    }
}

Write-Host "Total E3 Today: " $totalE3Today
Write-Host "Total E5 Today: " $totalE5Today
Write-Host "Total E3 Month to Month Tomorrow: " $totalE3MonthtoMonthTomorrow
Write-Host "Total E3 Tomorrow: " $totalE3Tomorrow
Write-Host "Total E5 Tomorrow: " $totalE5Tomorrow
Write-Host "Total E5 Month to Month Tomorrow: " $totalE5MonthtoMonthTomorrow

$outputString | Out-File -FilePath ".\output\NewOutput.csv" -Encoding utf8
$E3MonthToMonthUserList | Out-File -FilePath ".\output\E3MonthtoMonthUserList.csv" -Encoding utf8
$E3UserList | Out-File -FilePath ".\output\E3UserList.csv" -Encoding utf8
$E5MonthToMonthUserList | Out-File -FilePath ".\output\E5MonthtoMonthUserList.csv" -Encoding utf8
$E5UserList | Out-File -FilePath ".\output\E5UserList.csv" -Encoding utf8
$moveFromE5toE3MonthToMonthUserList | Out-File -FilePath ".\output\moveE5toE3MonthlyUserList.csv" -Encoding utf8
$moveFromE5toE3UserList | Out-File -FilePath ".\output\moveE5toE3UserList.csv" -Encoding utf8
$masterList | Out-File -FilePath ".\output\masterList.csv" -Encoding utf8
#$directlyAssignedLicenseLog | Out-File -FilePath ".\output\DirectlyAssignedLicenses.csv" -Encoding utf8


