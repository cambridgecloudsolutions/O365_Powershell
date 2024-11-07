$outputString = ""

$flows = Get-AdminFlow
$flows | ForEach-Object {
    $flow = $_
    if ($flow.enabled) {
        Write-Host $flow.DisplayName
        $user = Get-UsersOrGroupsFromGraph -ObjectId $flow.CreatedBy.userId
        $FlowName = $flow.DisplayName 
        $OwnerName = $user.DisplayName
        $OwnerEmail = $user.UserPrincipalName
        $lastModified = $flow.LastModifiedTime
        $created = $flow.CreatedTime
        $outputString += $FlowName + "," + $OwnerName + "," + $OwnerEmail + "," + $lastModified + "," + $created + "`n"
    }

}
$outputString | Out-File -FilePath ".\output\NewenabledFlows.csv" -Encoding utf8



