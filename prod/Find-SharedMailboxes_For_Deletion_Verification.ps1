<#
Script Name: Find-SharedMailboxes_For_Deletion_Verification.ps1
Script Author: Chris Cook chris.cook@bcbsri.org
Script Purpose: This script will iterate through all Shared Mailboxes within the Exchange Online environment, and check for the 
last usage dates on Inbox Folders, Sent Items and Calendar Folders. It excludes standard calendars such as birthdays and US Holidays.

The output of the script is a CSV file which lists shared mailboxes which have shown no activity for at least 365 days or have 'test' in 
their name. It will also output a list of users who have access to the shared mailbox. 

TO DO 10/16/24:

    Need to update to place the output files in a centrally accessible location
    Need to update to automatically send emails to Shared Mailbox owners using a standard template advising them that the mailbox
    should be reviewed for need and directing them to the correct SR to decommission
    Script needs to be moved to a server where a scheduled job can be run monthly to update the data for tracking purposes. 
    
#>


Import-Module ActiveDirectory
Connect-ExchangeOnline

$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox
$sharedMailboxAddress = $sharedMailboxes.PrimarySmtpAddress

$todayDate = Get-Date
$outputString = ",Created,Inbox,, Sent Items,, Calendar`n"
$appendDeletedMailboxesString = ""
$count = $SharedMailboxes.length
if($count -eq 0){
    Write-Host "Error retrieving Shared Mailbox information"
}

foreach($mailbox in $sharedMailboxAddress){
    try{
        $mailboxADCheck = Get-ADUser -Filter {EmailAddress -eq $mailbox}
        if($mailboxADCheck -like "*OU=Termeduser*"){
            $appendDeletedMailboxesString += $mailbox + "," + "Awaiting AD removal`n"
        }
        else{
            if($mailbox -eq "Security.Administration@bcbsri.org"){
                #ignore it - it kills the script for some reason
            }
            else{
                $countToDisplay = $count--
                Write-Host "Processing " $mailbox $countToDisplay
                $createdDate = Get-Mailbox -Identity $mailbox | Select-Object WhenMailboxCreated
                $createdDate = (($createdDate -split "=")[1] -split " ")[0]
                $createdDate = [datetime]::ParseExact($createdDate, "MM/dd/yyyy", $null)
                $createdDateTimespan = New-TimeSpan -Start $createdDate -End $todayDate
                $localOutputString = ""
                $localOutputString += $mailbox + "," + $createdDate + ","
                
                $InboxResult = Get-MailboxFolderStatistics -Identity $mailbox -IncludeOldestAndNewestItems -FolderScope Inbox | Select-Object -Property Name, NewestItemReceivedDate
                if($InboxResult.length -gt 2){
                    $newestInboxDates = @()
                    foreach($inbox in $inboxResult){
                        $folderStats = Get-MailboxFolderStatistics -Identity $mailbox -FolderScope $folder.FolderPath -IncludeOldestAndNewestItems | Select-Object -ExpandProperty NewestItemReceivedDate
                        $newestInboxDates += $folderStats    
                    }
                    $mostRecentInboxDate = (($newestInboxDates | Sort-Object -Descending | Select-Object -First 1) -split " ")[0].trim()
                }
                else{
                    $mostRecentInboxDate = (($InboxResult -split "=")[2] -split " ")[0].trim()
                }

                if(($mostRecentInboxDate -eq "}") -or ($Null -eq $mostRecentInboxDate)){
                    $localOutputString += "Null,1000,"
                    $InboxTimespan = New-TimeSpan -Start '01/01/2000' -End $todayDate
                }
                else{
                    $lastUsedDate = [datetime]::ParseExact($mostRecentInboxDate, "MM/dd/yyyy", $null)
                    $InboxTimespan = New-TimeSpan -Start $lastUsedDate -End $todayDate
                    $localOutputString += $lastUsedDate.ToString("MM/dd/yyyy") + "," + $InboxTimespan.Days + ","
                } 
                
                $SentItemsResult  = Get-MailboxFolderStatistics -Identity $mailbox -IncludeOldestAndNewestItems -FolderScope SentItems | Select-Object -Property Name, NewestItemReceivedDate
                if($SentItemsResult.length -gt 2){
                    $newestSentDates = @()
                    foreach($sentItem in $SentItemsResult){
                        $folderStats = Get-MailboxFolderStatistics -Identity $mailbox -FolderScope $folder.FolderPath -IncludeOldestAndNewestItems | Select-Object -ExpandProperty NewestItemReceivedDate
                        $newestSentDates += $folderStats    
                    }
                    $mostRecentSentDate = (($newestSentDates | Sort-Object -Descending | Select-Object -First 1) -split " ")[0].trim()
                }
                else{
                    $mostRecentSentDate = (($SentItemsResult -split "=")[2] -split " ")[0].trim()
                }

                if(($mostRecentSentDate -eq "}") -or ($Null -eq $mostRecentSentDate)){
                    $localOutputString += "Null,1000,"
                    $SentItemsTimespan = New-TimeSpan -Start '01/01/2000' -End $todayDate
                }
                else{
                    $lastUsedDate = [datetime]::ParseExact($mostRecentSentDate, "MM/dd/yyyy", $null)
                    $SentItemsTimespan = New-TimeSpan -Start $lastUsedDate -End $todayDate
                    $localOutputString += $lastUsedDate.ToString("MM/dd/yyyy") + "," + $SentItemsTimespan.Days + ","
                } 

                $CalendarResult  = Get-MailboxFolderStatistics -Identity $mailbox -IncludeOldestAndNewestItems -FolderScope Calendar | Select-Object -Property Name, NewestItemReceivedDate
                if($CalendarResult.length -gt 2){
                    $newestCalendarDates = @()
                    foreach($calendar in $CalendarResult){
                        if(($calendar.Name -eq "Birthdays") -or ($calendar.Name -eq "United States holidays")){
                            #ignore it
                        }
                        else{
                            $folderStats = Get-MailboxFolderStatistics -Identity $mailbox -FolderScope $folder.FolderPath -IncludeOldestAndNewestItems | Select-Object -ExpandProperty NewestItemReceivedDate
                            $newestCalendarDates += $folderStats    
                        }
                    }
                    $mostRecentCalendarDate = (($newestCalendarDates | Sort-Object -Descending | Select-Object -First 1) -split " ")[0].trim()
                }
                else{
                    $mostRecentCalendarDate = (($CalendarResult -split "=")[2] -split " ")[0].trim()
                }

                if(($mostRecentCalendarDate -eq "}") -or ($Null -eq $mostRecentCalendarDate)){
                    $localOutputString += "Null,1000,"
                    $CalendarTimespan = New-TimeSpan -Start '01/01/2000' -End $todayDate
                }
                else{
                    $lastUsedDate = [datetime]::ParseExact($mostRecentCalendarDate, "MM/dd/yyyy", $null)
                    $CalendarTimespan = New-TimeSpan -Start $lastUsedDate -End $todayDate
                    $localOutputString += $lastUsedDate.ToString("MM/dd/yyyy") + "," + $CalendarTimespan.Days + ","
                } 
                #only write to the log if we think this is one to be deleted
                if(((($createdDateTimespan.Days -ge 365) -and ($InboxTimespan.Days -ge 365) -and ($SentItemsTimespan.Days -ge 365) -and ($CalendarTimespan.Days -ge 365))) -or ($mailbox -like "*test*")){
                    $usersWithAccess = Get-MailboxPermission -Identity $mailbox | Where-Object { $_.User -like '*@*' } | Select-Object -ExpandProperty User
                    $userNames = $usersWithAccess -join ";"
                    $outputString += $localOutputString + "," + $userNames + "`n"
                }
                
            }
        }
    }
    catch{
        Write-Host "Error processing " $mailbox
    }
}
$outputString += $appendDeletedMailboxesString
$outputString | Out-File -FilePath ".\output\SharedMailboxOutput.csv" -Encoding utf8
