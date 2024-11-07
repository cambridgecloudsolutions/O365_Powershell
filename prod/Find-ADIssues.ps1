$onPremUsers = Import-Csv -Path ".\OnPremUsers.csv"
$azureADUsers = Import-Csv -Path ".\AzureADUsers.csv"

$missingInAzureAD = $onPremUsers | Where-Object { $_.UserPrincipalName -notin $azureADUsers.UserPrincipalName }
$missingInOnPrem = $azureADUsers | Where-Object { $_.UserPrincipalName -notin $onPremUsers.UserPrincipalName }

$missingInAzureAD | Export-Csv -Path ".\MissingInAzureAD.csv" -NoTypeInformation
$missingInOnPrem | Export-Csv -Path ".\MissingInOnPrem.csv" -NoTypeInformation
