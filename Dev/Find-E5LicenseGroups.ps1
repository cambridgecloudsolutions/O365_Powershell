Connect-AzureAD

$AllAzureADUsers = Get-AzureADUser -All $true

$AssignAADPremiumP2LicenseGroup = Get-AzureADGroup -SearchString "Assign AAD Premium P2 license"
$AssignAADPremiumP2LicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignAADPremiumP2LicenseGroup.ObjectID -All $true
$AssignE5AudioConferencingGroup = Get-AzureADGroup -SearchString "Assign E5 Audio-Conferencing"
$AssignE5AudioConferencingGroupMembers = Get-AzureADGroupMember -ObjectID $AssignE5AudioConferencingGroup.ObjectID -All $true
$AssignPbiProLicenseGroup = Get-AzureADGroup -SearchString "Assign E5 Power BI Pro"
$AssignPbiProLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignPbiProLicenseGroup.ObjectID -All $true
$AssignM365BusinessVoiceTrialLicenseGroup = Get-AzureADGroup -SearchString "Assign M365 Business Voice Trial License"
$AssignM365BusinessVoiceTrialLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignM365BusinessVoiceTrialLicenseGroup.ObjectID -All $true
$AssignM365MyAnalyticsLicenseGroup = Get-AzureADGroup -SearchString "Assign M365 My Analytics (Full)"
$AssignM365MyAnalyticsLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignM365MyAnalyticsLicenseGroup.ObjectID -All $true
$AssignMSToDoLicenseGroup = Get-AzureADGroup -SearchString "Assign MS To DO"
$AssignMSToDoLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignMSToDoLicenseGroup.ObjectID -All $true
$AssignO365E5LicenseGroup = Get-AzureADGroup -SearchString "Assign O365 E5 License"
$AssignO365E5LicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignO365E5LicenseGroup.ObjectID -All $true
$AssignO365FlowLicenseGroup = Get-AzureADGroup -SearchString "Assign O365 Flow License"
$AssignO365FlowLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignO365FlowLicenseGroup.ObjectID -All $true
$AssignO365PlannerLicenseGroup = Get-AzureADGroup -SearchString "Assign O365 Planner License"
$AssignO365PlannerLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignO365PlannerLicenseGroup.ObjectID -All $true
$AssignO365PowerAppsLicenseGroup = Get-AzureADGroup -SearchString "Assign O365 Power Apps License"
$AssignO365PowerAppsLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignO365PowerAppsLicenseGroup.ObjectID -All $true
$AssignO365TeamsLicenseGroup = Get-AzureADGroup -SearchString "Assign O365 Teams License"
$AssignO365TeamsLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignO365TeamsLicenseGroup.ObjectID -All $true
$AssignIRMFeatureTestLicenseGroup = Get-AzureADGroup -SearchString "IRM Feature-Test"
$AssignIRMFeatureTestLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignIRMFeatureTestLicenseGroup.ObjectID -All $true
$AssignMDMTestingLicenseGroup = Get-AzureADGroup -SearchString "MDM Testing"
$AssignMDMTestingLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignMDMTestingLicenseGroup.ObjectID -All $true
$AssignRetireIntuneLicenseGroup = Get-AzureADGroup -SearchString "RetireIntune_App_TermUser"
$AssignRetireIntuneLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignRetireIntuneLicenseGroup.ObjectID -All $true
$AssignTeamsVoiceCommonAreaPhonesLicenseGroup = Get-AzureADGroup -SearchString "Teams Voice Common Area Phones"
$AssignTeamsVoiceCommonAreaPhonesLicenseGroupMembers = Get-AzureADGroupMember -ObjectID $AssignTeamsVoiceCommonAreaPhonesLicenseGroup.ObjectID -All $true

$outputString = "User, AADPremiumP2, E5 Audio Conferencing, PBI Pro, M365 Business Voice Trial, M365 My Analytics, MS To Do, O365 E5, O365 Flow, O365 Planner, O365 Power Apps, O365 Teams, IRM Feature, MDM Testing, Retire InTune, Teams Voice Common Area`n"

foreach($user in $AllAzureADUsers){

    $foundE5License = $false

    $licenses = Get-AzureADUserLicenseDetail -ObjectID $user.ObjectID
    foreach($license in $licenses){
        switch ($license.SkuPartNumber){
            "SPE_E5" {$foundE5License = $true}
        } 
    }

    if($foundE5License){

        $tempOutputString = $user.UserPrincipalName + ","

        $isAADPremiumP2LicenseMember = $false
        $isE5AudioConferencingMember = $false
        $isPbiProLicenseMember = $false
        $isM365BusinessVoiceTrialMember = $false
        $isM365MyAnalyticsMember = $false
        $isMSToDOMember = $false
        $isO365E5Member = $false
        $isO365FlowMember = $false
        $isO365PlannerMember = $false
        $isO365PowerAppsMember = $false
        $isO365TeamsMember = $false
        $isIRMFeatureMember = $false
        $isMDMTestingMember = $false
        $isRetireInTuneMember = $false
        $isTeamsVoiceCommonAreaPhonesMember = $false

        $isAADPremiumP2LicenseMember = $AssignAADPremiumP2LicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isE5AudioConferencingMember = $AssignE5AudioConferencingGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isPbiProLicenseMember = $AssignPbiProLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isM365BusinessVoiceTrialMember = $AssignM365BusinessVoiceTrialLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isM365MyAnalyticsMember = $AssignM365MyAnalyticsLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isMSToDOMember = $AssignMSToDoLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isO365E5Member = $AssignO365E5LicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isO365FlowMember = $AssignO365FlowLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isO365PlannerMember = $AssignO365PlannerLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isO365PowerAppsMember = $AssignO365PowerAppsLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isO365TeamsMember = $AssignO365TeamsLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isIRMFeatureMember = $AssignIRMFeatureTestLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isMDMTestingMember = $AssignMDMTestingLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isRetireInTuneMember = $AssignRetireIntuneLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isTeamsVoiceCommonAreaPhonesMember = $AssignTeamsVoiceCommonAreaPhonesLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}

        if( $isAADPremiumP2LicenseMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isE5AudioConferencingMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isPbiProLicenseMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isM365BusinessVoiceTrialMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isM365MyAnalyticsMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isMSToDOMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isO365E5Member){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isO365FlowMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isO365PlannerMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isO365PowerAppsMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isO365TeamsMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isIRMFeatureMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isMDMTestingMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isRetireInTuneMember){$tempOutputString += "1,"}else{$tempOutputString += "0,"}
        if( $isTeamsVoiceCommonAreaPhonesMember){$tempOutputString += "1,"}else{$tempOutputString += "0`n"}

        Write-Host $tempOutputString

        $outputString += $tempOutputString
    }
}

$outputString | Out-File -FilePath ".\E5GroupAnalysis.csv" -Encoding utf8