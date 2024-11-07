param(
    [string]$managerEmail,
    [string]$licenseName,
    [switch]$showUserNames,
    [switch]$showBCBSRIOnly
)

Connect-AzureAD

function Get-LicenseCount {
    
    param(
    [string]$managerEmail
    
    )
            
    if($depth -eq 0){
        $sanityCheck = Get-AzureADUser -Filter "Mail eq '$managerEmail'"
        if ($sanityCheck -ne $null){
            Write-Host "`nRunning license usage report for " $sanityCheck.DisplayName "`n`n"
        }
        else {
            if($depth -eq 0){
                Write-Host "`nThat manager name" $managerEmail " does not exist. Please check and try again`n"
                Write-Host "`n`nUsage:`n`n   To get count of users only: Get-LicenseDistribution -managerEmail ""manager name"" -licenseName ""license name"" `n`n   To get count of users and list license user names: Get-LicenseDistribution -inputManagerName ""manager name"" -licenseName ""license name"" -showUserNames`n`n"
                $script:sanityCheckReturn = 1
                return
            }
        }
    }

    try{
        $manager = Get-AzureADUser -Filter "Mail eq '$managerEmail'"
        $reports = Get-AzureADUserDirectReport -ObjectId $manager.ObjectId | Select-Object -ExpandProperty ObjectId
                
        if ($reports.length -gt 0){
            $depth++
        }
        else{
            $depth--
        }
            
        foreach ($report in $reports){
            try{   
                $user = Get-AzureADUser -ObjectId $report
                $userEmail = $user.Mail
                $DNExtension = (Get-AzureADUserExtension -ObjectId $user.ObjectId).get_item("onPremisesDistinguishedName")              
                if(($DNExtension -match "OU=BCBSRI") -or ($DNExtension -match "OU=STD") -or (($DNExtension -match "OU=CONSULTANTS") -or ($DNExtension -match "OU=ITSERVICEPROVIDERS") -and (-not $showBCBSRIOnly))) {
                #if($user.JobTitle -ne $Null){                               
                    if ($user.Mail -eq "martha.wofford@bcbsri.org"){
                        #Skip this as she reports to herself
                    }
                    else{ 
                        if ($depth -eq 1){
                            $cleanName = $user.DisplayName -replace '\s', '_' -replace '[^a-zA-Z0-9]', '_'
                            $varName = "${cleanName}_Associate_Count"
                            $varName2 = "${cleanName}_License_Count"
                            $outputTableName = "${cleanName}"
                            New-Variable -Name $varName -Value 0
                            New-Variable -Name $varName2 -Value 0
                            $script:count = 1 #Include the manager themselves
                            $script:licenseCount = 0
                            Write-Host $user.DisplayName ":`n"
                        }
                        #Check the user against the license array to see if they are in there
                        
                        if ($userEmail -in $script:licenseUserList){
                            if ($showUserNames.IsPresent){
                                Write-Host "     " $licenseName " used by " $userEmail.tolower()
                            }
                            $script:licenseCount++
                            $script:totalLicenseCount++
                            $script:licenseUserNames += $userEmail.tolower() + "`n"
                            $script:licenseUserCheckArray += $userEmail
                        }
                            
                        $script:totalReportCount++

                        if ($depth -gt 1){
                            $script:count++
                        } 

                        Set-Variable -Name $varName -Value $script:count

                        Get-LicenseCount $userEmail

                        if ($depth -eq 1){
                            if($showUserNames.IsPresent){
                                write-host "`n"
                            } #This is just to put a space between users list and the next bit
                            Write-Host "  "$varName ":"$script:count
                            Write-Host "  "$varName2 ":"$script:licenseCount
                            Write-Host "`n"
                            $associatesNotLicensed = $script:count - $script:licenseCount
                            $script:tableOutput += $outputTableName + "," + $script:count + "," + $associatesNotLicensed + "," + $script:licenseCount + "`n"
                        }
                    }           
                }
                else{
                    #Write-Host "skipping " $user.DisplayName
                }  
            }
            catch{
                Write-Host "Error Message: $($_.Exception.Message)"
            } 
        }
    }
    catch{
        
    
    $errorLog += "Error occurred processing " + $user + "`n"
    $errorLogCount++
    }
}       
    
function GetLicenseInformation {
    param (
        [string]$licenseName
    )
    #Create an array of Copilot users from MSOnline
    Connect-MsolService
    $licenseNameSearchString = "*" + $licenseName + "*"
    
    try{
        $users = Get-MsolUser -All | Where-Object { $_.Licenses.AccountSkuId -like $licenseNameSearchString }
    }
    catch{
        Write-Host "Error getting license information"
    }
    
    # Create an array to store the UserPrincipalName
    $script:licenseUserList = @()
    # Loop through the users and add their UserPrincipalName to the array
    foreach ($user in $users) {
        $script:licenseUserList += $user.UserPrincipalName
    }
}

### START ###

$script:totalReportCount = 0
$script:totalLicenseCount = 0
$depth = 0
$errorLog = ""
$errorLogCount = 0
$script:licenseUserNames = ""
$script:licenseNotBCBSRI = ""
$script:NoEmployeeID = ""
$script:licenseUserCheckArray = @()
$script:sanityCheckReturn = 0
$script:tableOutput = ""


try{
    GetLicenseInformation $licenseName
}
catch{
    Write-Host "Error getting license information"
}
try{
    Get-LicenseCount $managerEmail -$showUserNames
}
catch{
    Write-Host "`n`nUsage:`n`n   To get count of users only: Get-LicenseDistribution.ps1 -managerEmail ""manager email address"" -licenseName ""license name""`n`n   To get count of users and list user names: Get-LicenseDistibution.ps1 -managerEmail ""manager email address"" -licenseName ""license name"" -showUserNames`n`nTo get a list of the whole company use a Manager Name of 'Martha Wofford'`n`n"
    exit 
}
#Check to see if the manager has Copilot
if ($managerEmail -in $script:licenseUserList){
    $script:totalLicenseCount++
    if($showUserNames.IsPresent){Write-Host "     " $licenseName " used by " $managerEmail.tolower() "`n" }
    $script:licenseUserNames += $managerEmail + "`n"
}
#Increment total report count by 1 to take account of the input manager
$script:totalReportCount++
if ($script:sanityCheckReturn -eq 0){
    Write-Host $inputManagerName "Total Associates in group:" $script:totalReportCount 
    Write-Host $inputManagerName "Total Associates in group with " $licenseName ":" $script:totalCopilotCount
    $totalAssociatesNotLicensed = $script:totalReportCount - $script:totalLicenseCount
    
    if($script:licenseNotBCBSRI.length -gt 0){Write-Host "`n" $script:licenseNotBCBSRI}
    if($errorLogCount -gt 0){
        Write-Host "`n" $errorLogCount "errors were encountered"
        Write-Host $errorLog
    }
    $finalTableOutput = "Name,Total Associates, Not licensed," + $licenseName + " Licenses`n" + $inputManagerName + "_overall," + $script:totalReportCount + "," + $totalAssociatesNotLicensed + "," + $script:totalLicenseCount + "`n" + $script:tableOutput
    $todayDate = Get-Date -Format "yyyy-MM-dd"
    $outputFilePath = ".\" +$inputManagerName +"_" + $licenseName + "licensereport_" + $todayDate + ".csv"
    $userNameFilePath = ".\" +$inputManagerName +"_" + $licenseName + "licensereport_usernames_" + $todayDate + ".csv"
    $finalTableOutput | Out-File -FilePath $outputFilePath -Encoding utf8
    $script:licenseUserNames | Out-File -FilePath $userNameFilePath -Encoding utf8
}

if($managerEmail -like "martha.wofford@bcbsri.org"){ #This only works if you are at the top of the tree as otherwise will find people not in the manager scope
    Write-Host "The following details are only shown when the whole company is reported on:`n"
    try{    
        foreach($email in $script:licenseUserList){
            #write-Host "here"
            if ($script:licenseUserCheckArray -contains $email){
                #write-Host "Do nothing for now"
            }
            else{
                try{
                    $user = Get-AzureADUser -Filter "Mail eq '$email'"
                    $userCompany = $user.CompanyName
                    $userManager = ($user.Manager -split "=")[1] -replace ".{3}$"
                    $DNExtension = ((Get-AzureADUserExtension -ObjectId $user.ObjectId).get_item("onPremisesDistinguishedName") -split '=')[2] -replace ".{3}$"
                    
                    if($email -eq "martha.wofford@bcbsri.org"){
                        #Ignore as she will not be in a reporting line seeing as is CEO
                    }
                    else{
                        Write-Host $email.tolower() "has " $licenseName " but is not found in reporting line. Member of " $userCompany.toupper() ". Manager Name: " $userManager ". User OU is: " $DNExtension
                    }
                }
                catch{
                    Write-Host "error with "$email
                }
            }
        }
    }
    catch{
        Write-Host "Error Message: $($_.Exception.Message)"
    }
}

