Import-Module ActiveDirectory
Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell 
#Import-Module -Name PnP.PowerShell -UseWindowsPowerShell


$username = "ENTER EMAIL HERE"
$password = ConvertTo-SecureString "ENTER PASSWORD HERE" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)


# Connect to SharePoint Online
Connect-SPOService -Url https://bcbsri-admin.sharepoint.com -Credential $credential
$outputString = ""

$Sites = Get-SPOSite -Limit 500
$counter = $Sites.length

foreach($site in $sites){
    $counter--
    write-Host $counter $site.url
    try{
        Connect-PnPOnline -Url $site.Url -Credentials $credential

        $pages = Get-PnPListItem -List "Site Pages"
    
    
        foreach ($page in $pages) {
            try{
            
                $fullPageUrl = $page.FieldValues["FileRef"]
                $pageUrl = $page.FieldValues["FileLeafRef"]
                
                if(($pageUrl -eq "KWizCom") -or ($pageUrl -eq "form.aspx") -or ($pageUrl -eq "settings.aspx") -or ($pageUrl -eq "datasheet.aspx") -or ($pageUrl -eq "redirect.aspx")){
                    #ignore it - they throw a 404
                }
                else{
                    try{
                        $pageContent = Get-PnPClientSidePage -Identity $pageUrl
                        $peopleWebPart = $pageContent.Controls | Where-Object { $_.Title -eq "People" }

                        if ($peopleWebPart) {
                            $jsonData = $peopleWebPart.PropertiesJson
                            $jsonObject = $jsonData | ConvertFrom-Json 
                            foreach ($entry in $jsonObject) {
                                foreach ($person in $entry.persons) {
                                    $email = $person.id
                                    if($email.contains("|")){
                                        $email = $email -Split "\|"
                                        $email = $email[2]
                                    }
                                    $user = Get-ADUser -Filter { EmailAddress -eq $email }
                                    if ($user -ne $Null) {
                                        #Write-Host "User " $email " is still in AD."
                                    } 
                                    else {
                                        Write-Host "User " $email " in site " $fullPageUrl " is not in AD."
                                        $outputString += $email + "," + $fullPageUrl + "`n"
                                    }
                                }
                            }
                    
                        }
                        else {
                        #Write-Output "No contact card found on the page."
                        } 
                    }
                    catch{
                        #Error on page - will deal with it later
                    }  
                } 
            }
            catch{
                Write-Host "error with " $fullPageUrl
                #Write-Host "Error Message: $($_.Exception.Message)"
            }
        }
    }
    catch{
        #Write-Host "Error processing " $Site.Url
    }
}
$outputString | Out-File -FilePath ".\ContactCardNotInAd.csv" -Encoding utf8
