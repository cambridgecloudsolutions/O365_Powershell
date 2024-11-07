Install-Module -Name MicrosoftPowerBIMgmt
Connect-PowerBIServiceAccount

    $userEmails = @(
        "Abhijit.Adak@BCBSRI.ORG", 
        "abodh.gawande@BCBSRI.ORG", 
        "Adam.Barkley@bcbsri.org",
        "Adam.Costa@bcbsri.org",
        "adam.stacey@BCBSRI.ORG",
        "Aditi.Jain@bcbsri.org",
        "Zinda.Mason@bcbsri.org",
        "Adrianne.Ramos@bcbsri.org",
        "Adrienne.Camara@bcbsri.org",
        "chris.cook@bcbsri.org"
    )

    foreach($user in $userEmails){
        $startDate = [datetime]::Parse('2024-08-01')
        
        for ($i = 0; $i -lt 30; $i++) {
            $activityDate = $startDate.AddDays($i).ToString('yyyy-MM-dd')
            $activityEvents = Get-PowerBiActivityEvent -StartDateTime ($activityDate + 'T00:00:00.000') -EndDateTime ($activityDate + 'T23:59:59.999') -User $user
        
            if ($activityEvents.Count -eq 0) {
                Write-Output "$user $activityDate : No activity"
            } else {
                foreach ($event in $activityEvents) {
                    Write-Output "$user $activityDate : Activity detected - Type: $($event.ActivityType)"
                }
            }
        }
    }