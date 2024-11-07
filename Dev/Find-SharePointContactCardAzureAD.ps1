Import-Module AzureAD
# Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell 
# Import-Module -Name PnP.PowerShell -UseWindowsPowerShell

function Get-Credentials {
    param (
        [string]$username,
        [string]$password
    )
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential($username, $securePassword)
}

function Connect-ToSharePoint {
    param (
        [string]$url,
        [PSCredential]$credential
    )
    Connect-SPOService -Url $url -Credential $credential
}

function Process-SitePages {
    param (
        [string]$siteUrl,
        [PSCredential]$credential
    )
    try {
        Connect-PnPOnline -Url $siteUrl -Credentials $credential
        $pages = Get-PnPListItem -List "Site Pages"
        foreach ($page in $pages) {
            Process-Page $page $siteUrl
        }
    } catch {
        Write-Verbose "Error processing $siteUrl : $($_.Exception.Message)"
    }
}

function Process-Page {
    param (
        [PSObject]$page,
        [string]$siteUrl
    )
    $fullPageUrl = $page.FieldValues["FileRef"]
    $pageUrl = $page.FieldValues["FileLeafRef"]
    if ($pageUrl -notin @("KWizCom", "form.aspx", "settings.aspx", "datasheet.aspx", "redirect.aspx")) {
        try {
            $pageContent = Get-PnPClientSidePage -Identity $pageUrl
            $peopleWebPart = $pageContent.Controls | Where-Object { $_.Title -eq "People" }
            if ($peopleWebPart) {
                Process-PeopleWebPart $peopleWebPart $fullPageUrl
            }
        } catch {
            Write-Verbose "Error on page $fullPageUrl : $($_.Exception.Message)"
        }
    }
}

function Process-PeopleWebPart {
    param (
        [PSObject]$peopleWebPart,
        [string]$fullPageUrl
    )
    $jsonData = $peopleWebPart.PropertiesJson
    $jsonObject = $jsonData | ConvertFrom-Json 
    foreach ($entry in $jsonObject) {
        foreach ($person in $entry.persons) {
            $email = $person.id
            if ($email.contains("|")) {
                $email = $email -Split "\|"
                $email = $email
            }
            $user = Get-AzureADUser -Filter "UserPrincipalName eq '$email'"
            if ($user -eq $null) {
                Write-Output "User $email in site $fullPageUrl is not in AAD."
                $outputString += "$email,$fullPageUrl`n"
            }
        }
    }
}

$username = ""
$password = ""
$credential = Get-Credentials -username $username -password $password

Connect-ToSharePoint -url "https://bcbsri-admin.sharepoint.com" #-credential $credential

$outputString = ""
$Sites = Get-SPOSite -Limit 500
$counter = $Sites.length

foreach ($site in $Sites) {
    $counter--
    Write-Verbose "$counter $site.url"
    Process-SitePages -siteUrl $site.Url -credential $credential
}

$outputString | Out-File -FilePath ".\ContactCardNotInAd.csv" -Encoding utf8