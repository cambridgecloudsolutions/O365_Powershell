param(
    [string]$inputManagerName
    
)

Import-Module ActiveDirectory
function Get-AllReports {
    
    param(
    [string]$inputManagerName
    )
         #Check for apostrophes in the Manager Name
        if ($inputManagerName.contains("'")){
            $inputManagerName = $inputManagerName.Replace("'","''")
        }   
    
        $sanityCheck = Get-ADUser -Filter "Name -eq '$inputManagerName'" -Properties *
    
        if ($sanityCheck -ne $null){
            #Write-Host "User Exists"
        }
        else {
            Write-Host "`nThat manager name does not exist. Please check and try again`n"
            
            $script:sanityCheckReturn = 1
            return
        }
        
    if ($depth -eq 0){
        Write-Host "Running report for " $inputManagerName "`n`n"
    }
    try{
        $managerDN = Get-ADUser -Filter "Name -eq '$inputManagerName'" -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
        if ($managerDN.contains("'")){
            $managerDN = $managerDN.Replace("'","''")
        }
        $reports = Get-ADUser -Filter "Manager -eq '$managerDN'" -Properties DisplayName | Select-Object -ExpandProperty DisplayName
        $reports = Get-ADUser -Filter {Name -eq $inputManagerName} -Properties Company, DirectReports, DisplayName | Select-Object -ExpandProperty DirectReports
        
        if ($reports.length -gt 0){
            $depth++
        }
        else{
            $depth--
        }
        
        foreach ($report in $reports){        
            $userName = ($report -split ',')[0].Substring(3)
            $userEmail = Get-ADUser -Filter {Name -eq $userName } -Properties EmailAddress | Select-Object -Property EmailAddress
            $userEmail = $userEmail -Split "="
            $userEmail = $userEmail[1] -replace ".$"
            if ($userName -eq "Martha Wofford"){
                #Skip this as she reports to herself
            }
            else{ 
                    if ($userName.contains("L2")){
                        #Ignore this - service account
                    }
                    else{   
                        $userCompany = Get-ADUser -Filter "Name -eq '$userName'" -Properties company | Select-Object -ExpandProperty company
                        $businessCategory = Get-ADUser -Filter "Name -eq '$userName'" -Properties businessCategory | Select-Object -ExpandProperty businessCategory
                        if($userCompany -eq $null -or $businessCategory -eq $null -or $businessCategory -eq "Service Account" -or $businessCategory -eq "O365-Sync" ){
                            #ignore it
                        }
                        else{
                            if ($userEmail -eq ""){
                                Write-Host "skipping " $userName
                                #Skip it - not a person
                            }
                            else{
                            Write-Host $userName "," $userEmail ","$businessCategory
                            $script:userNames += $userName + "," + $userEmail + "," + $businessCategory + "`n"
                            $inputManagerName = $userName
                            Get-AllReports $inputManagerName
                            }
                        }
                    }
                
                }           
        }       
    }
    
    catch{
        $errorLog += "Error occurred processing " + $user + "`n"
        $errorLogCount++
    }
}

$depth = 0
$errorLog = ""
$errorLogCount = 0
$script:sanityCheckReturn = 0
$script:userNames  = ""
$userNameFilePath = ".\" +$inputManagerName +"_all_usernames.csv"

try{
    Get-AllReports $inputManagerName
}
catch{
    Write-Host "Usage: Get-AllReports -inputManagerName ""Manager Name"""
}

$script:userNames | Out-File -FilePath $userNameFilePath -Encoding utf8


