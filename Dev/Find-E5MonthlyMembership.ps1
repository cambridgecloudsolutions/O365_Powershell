Connect-AzureAD

<#$userList = @(

    "Akila.Alexander@BCBSRI.ORG",
    "ANITHA.GOPI@BCBSRI.ORG",
    "ansuman.barik@BCBSRI.ORG",
    "arunkumar.chandrasekaran@BCBSRI.ORG",
    "ashly.thomas@BCBSRI.ORG",
    "ASHWINI.ARABINAWAD@BCBSRI.ORG",
    "avinash.reddy@BCBSRI.ORG",
    "BHARATHI.KRISHNAMOORTHY@BCBSRI.ORG",
    "gabriel.kirubakaran@BCBSRI.ORG",
    "haritha.konda@BCBSRI.ORG",
    "hemanta.choudhury@BCBSRI.ORG",
    "JAMES.FEDERICO@BCBSRI.ORG",
    "jasneet.kaur@BCBSRI.ORG",
    "JENNIFER.BROOKS@BCBSRI.ORG",
    "JOANNE.HERNANDEZ@BCBSRI.ORG",
    "Jyoti.Babali@BCBSRI.ORG",
    "KALAIVANI.E@BCBSRI.ORG",
    "kavya.vasudeva@BCBSRI.ORG",
    "KAYLA.PEIXOTO@BCBSRI.ORG",
    "keerthika.sundaramoorthy@BCBSRI.ORG",
    "KUMAR.BRAJESH@BCBSRI.ORG",
    "kunditipadugu.vineetha@BCBSRI.ORG",
    "leo.ambrose@BCBSRI.ORG",
    "LISA.SOUSA@BCBSRI.ORG",
    "malini.somaiah@BCBSRI.ORG",
    "Manoj.Metukuru@BCBSRI.ORG",
    "MARYELLEN.CHAMBERLAIN@BCBSRI.ORG",
    "NaveenKumar.Balasubramani@BCBSRI.ORG",
    "PATTI.PATTERSON@BCBSRI.ORG",
    "pooja.arya@BCBSRI.ORG",
    "Pratik.Ray@BCBSRI.ORG",
    "priyanka.karmeham@BCBSRI.ORG",
    "RAKESH.HAMSABALAN@BCBSRI.ORG",
    "Ranjitha.Devarajan@BCBSRI.ORG",
    "RENJITH.KUMAR@BCBSRI.ORG",
    "ROBERT.SEGAMA@BCBSRI.ORG",
    "roja.ulligadde@BCBSRI.ORG",
    "RYALA.MANOJ@BCBSRI.ORG",
    "SABIR.ALI@BCBSRI.ORG",
    "saran.raghavan@BCBSRI.ORG",
    "Seenivasan.Karuthapandian@BCBSRI.ORG",
    "sharath.srirangam@bcbsri.org",
    "Sheril.Yadav@BCBSRI.ORG",
    "SHIKHA.SAXENA@BCBSRI.ORG",
    "shivashankar.paspunoori@BCBSRI.ORG",
    "smita.srivastava@BCBSRI.ORG",
    "SRINIVASAN.ANBU@BCBSRI.ORG",
    "Sudhanshu.kushwaha@BCBSRI.ORG",
    "SUNIL.RANGINENI@BCBSRI.ORG",
    "Vaishali.Shembekar@BCBSRI.ORG",
    "VARUN.DEVRANI@BCBSRI.ORG",
    "vidyavati.km@BCBSRI.ORG",
    "VISHAL.GOYAL@BCBSRI.ORG"

)#>

$AllAzureADUsers = Get-AzureADUser -All $true


$AssignPbiProLicenseGroup = Get-AzureADGroup -SearchString "Assign E5 Power BI Pro"
$PbiProGroupMembers = Get-AzureADGroupMember -ObjectID $AssignPbiProLicenseGroup.ObjectID -All $true
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

$outputString = "UPN, PBI Pro, Teams Phone, Audio Conf, Flow, Planner, Power Apps, Teams Voice`n"

foreach($user in $AllAzureADUsers){
    #$user = Get-AzureADUser -ObjectID $E5User

    $licenses = Get-AzureADUserLicenseDetail -ObjectID $user.ObjectID

        foreach($license in $licenses){
            switch ($license.SkuPartNumber){
                "SPE_E5" {$foundE5License = $true}
            } 
        }

    if($foundE5License){   

    $outputString += $user.userPrincipalName + ","

        if($teamsPhoneUserArray.phoneUser -contains $user.userPrincipalName){$foundTeamsPhone = $true }
        $isPBIGroupMember = $PbiProGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isE5AudioConferencingGroupMember = $E5AudioConferencingGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isE5FlowLicenseGroupMember = $E5FlowLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isE5PlannerLicenseGroupMember = $E5PlannerLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isE5PowerAppsLicenseGroupMember = $E5PowerAppsLicenseGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}
        $isE5TeamsVoiceCommonAreaPhonesMember = $E5TeamsVoiceCommonAreaPhonesGroupMembers | Where-Object {$_.ObjectID -eq $user.ObjectID}

        if($isPBIGroupMember){$outputString += "YES,"}else{$outputString += "NO,"}
        if($foundTeamsPhone){$outputString += "YES,"}else{$outputString += "NO,"}
        if($isE5AudioConferencingGroupMember){$outputString += "YES,"}else{$outputString += "NO,"}
        if($isE5FlowLicenseGroupMember){$outputString += "YES,"}else{$outputString += "NO,"}
        if($isE5PlannerLicenseGroupMember){$outputString += "YES,"}else{$outputString += "NO,"}
        if($isE5PowerAppsLicenseGroupMember){$outputString += "YES,"}else{$outputString += "NO,"}
        if($isE5TeamsVoiceCommonAreaPhonesMember){$outputString += "YES,"}else{$outputString += "NO,"}

        $outputString += "`n"
    }
}

$outputString | Out-File -FilePath ".\output\E5GroupCheck.csv" -Encoding utf8
