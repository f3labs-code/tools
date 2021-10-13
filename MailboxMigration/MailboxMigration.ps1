#1. Combine finalize script with move to group script
#2. Add in the credential prompts, Connect-ExchangeOnline and Connect-AzureAD
#3. Add in a check if licensed, exchange online enabled, don't migrate that user and report at end that not licensed
#4. Add in a check if SendAs permissions exist on the mailbox being migrated and from who has it, export that data to a file but migrate the mailbox.
#5. Add in a check to see if mailbox has forwarding enabled, export that data to a file.
#6. Possible to create mobileiron script

Start-Transcript

Write-Host "Enter Exchange Online Credentials:" -ForegroundColor Green
#$azure_creds = Get-Credential
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline 

Write-Host "Enter Azure Credentials:" -ForegroundColor Green
#$exo_creds = Get-Credential
Import-Module AzureADPreview -UseWindowsPowershell
Connect-AzureAD 

$inputCSV = Import-CSV -Path ".\25crossroads.csv"     # Path to CSV file for import
$groupName = "Intune Users Group Default Apps Mobile"       # Name of Intune Group to add users to
$searchLicenses = @{}
$searchLicenses.Add("efb87545-963c-4e0d-99df-69c6916d9eb0","Exchange Enterprise")
$searchLicenses.Add("9aaf7827-d63c-4b61-89c3-182f06f82e5c","Exchange Standard")
$searchLicenses.Add("4a82b400-a79f-41a4-b4e2-e94f5787b113","Exchange Kiosk")                       # Licenses to search users for

$moveReport = @()                                           # Initialize report variables. 
$sendAsReport = @()                                         # This will be used to output the 
$sendOnBehalfReport = @()                                   # results of the move to the CSV files
$mailboxForwardingReport = @()                              




foreach ($line in $inputCSV) {

    # Initialize variables from primary smtp address
    $smtp = $line.PrimarySmtpAddress
    $user = get-azureaduser -Filter "mail eq '$smtp'"
    $group = get-azureadgroup -All $true | where-object {$_.DisplayName -eq "$groupName"}
    $userLicenses = $user.AssignedPlans
    #$userMailbox = get-mailbox -Identity "$smtp"
    $licensed = $false

    # Check to see if user is licensed.
    foreach ($license in $userLicenses) {
        foreach ($searchLicense in $searchLicenses.keys) {
            # write-host "Checking license $searchLicense against $license)" -ForegroundColor Yellow
            if ($license -like "*$searchLicense*" -and $license -like "*Enabled*") {
                write-host "Found $($searchLicenses[$searchLicense]) license for user $smtp" -ForegroundColor Green
                $licensed = $true
            }
        }
    }

    # The below items need to be checked on-prem and exported separately because the org is in hybrid mode.

    # Check if sendas rights on this mailbox
    #$sendAsRights = $userMailbox| get-adpermission | where-object {$_.ExtendedRights -like "*send*" -and -not ($_.User -match "NT AUTHORITY")} | select-object User

    # Check send on behalf rights on this mailbox
    #$sendOnBehalfRights = $userMailbox | where-object {$_.GrantSendOnBehalfTo -ne $null} | select-object GrantSendOnBehalfTo

    # Check if mailbox forwarding is enabled
    #$mailboxForwarding = $userMailbox | where-object {$_.ForwardingSmtpAddress -ne $null} | select-object ForwardingSmtpAddress

    if ($licensed -eq $true) {
        # User is licensed so continue the move.
        Write-Host "Finalizing move request for $smtp" -ForegroundColor cyan
        Resume-MoveRequest $smtp
        Add-AzureAdGroupMember -objectId $group.ObjectId -RefObjectId $user.ObjectId
        Write-Host "Added $($user.DisplayName) to $groupName" -ForegroundColor cyan

        # Update reports
        $sendAsReport += [pscustomobject]@{"PrimarySMTPAddress" = $smtp; "SendAs" = $sendAsRights}
        $sendOnBehalfReport += [pscustomobject]@{"PrimarySMTPAddress" = $smtp; "SendOnBehalfOf" = $sendOnBehalfRights}
        $mailboxForwardingReport += [pscustomobject]@{"PrimarySMTPAddress" = $smtp; "MailboxForwarding" = $mailboxForwarding}

    } else {
        # User is not licensed. Report this and abort the move.
        Write-Host "$smtp is not licensed in 365. Aborting move!" -ForegroundColor red
    }

    # Update move report
    $moveReport += [pscustomobject]@{
        "PrimarySMTPAddress" = $smtp
        "Migrated" = $licensed
        "sendAsRights" = $sendAsRights
        "sendOnBehalfRights" = $sendOnBehalfRights
        "mailboxForwarding" = $mailboxForwarding
    }

}

# Output all CSV Files:
$sendAsReport | export-csv "$((Get-Date).ToString("yyyyMMdd_HHmmss"))_sendAsReport.csv" -NoTypeInformation
$sendOnBehalReport | export-csv "$((Get-Date).ToString("yyyyMMdd_HHmmss"))_sendOnBehalfReport.csv" -NoTypeInformation
$mailboxForwardingReport | export-csv "$((Get-Date).ToString("yyyyMMdd_HHmmss"))_mailboxForwardingReport.csv" -NoTypeInformation
$moveReport | export-csv "$((Get-Date).ToString("yyyyMMdd_HHmmss"))_moveReport.csv" -NoTypeInformation

Stop-Transcript