# Install the Microsoft Graph PowerShell SDK
Install-Module Microsoft.Graph -Scope CurrentUser

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Reports.Read.All"

# Get Copilot usage report
$report = Get-MgReportUserActivityUserDetail -Period "D7"

# Filter for Copilot usage
$copilotUsage = $report | Where-Object { $_.ProductName -eq "Copilot" }

# Find the last usage date
$lastUsage = $copilotUsage | Sort-Object LastActivityDate -Descending | Select-Object -First 1

# Output the last usage date
$lastUsage.LastActivityDate
