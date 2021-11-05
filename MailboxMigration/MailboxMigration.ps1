#1. Combine finalize script with move to group script
#2. Add in the credential prompts, Connect-ExchangeOnline and Connect-AzureAD
#3. Add in a check if licensed, exchange online enabled, don't migrate that user and report at end that not licensed
#4. Add in a check if SendAs permissions exist on the mailbox being migrated and from who has it, export that data to a file but migrate the mailbox.
#5. Add in a check to see if mailbox has forwarding enabled, export that data to a file.
#6. Possible to create mobileiron script

Start-Transcript

Write-Host "Enter Exchange Online Credentials:" -ForegroundColor Green
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline 

Write-Host "Enter Azure Credentials:" -ForegroundColor Green
Import-Module AzureAD
Connect-AzureAD 

Write-Host "Enter credentials for MobileIron:" -ForegroundColor Green
$cred = Get-Credential

###################################################################################################
#######       CHANGE THESE PATHS TO THE ACTUAL FILES BEING USED FOR THE MIGRATION USERS     #######
###################################################################################################

$inputCSV = Import-CSV -Path ".\25crossroads.csv"           # Path to CSV file containing the users being migrated.
$mobileUserCSV = Import-CSV -Path ".\mobileusers.csv"       # Path to CSV file containing the users that are approved for Mobile devices
$groupName = "Intune Users Group Default Apps Mobile"       # Name of Intune Group to add users to

###################################################################################################
#######                                     END CHANGES                                     #######
###################################################################################################

# Licenses to search users for
$searchLicenses = @{}
$searchLicenses.Add("efb87545-963c-4e0d-99df-69c6916d9eb0","Exchange Enterprise")
$searchLicenses.Add("9aaf7827-d63c-4b61-89c3-182f06f82e5c","Exchange Standard")
$searchLicenses.Add("4a82b400-a79f-41a4-b4e2-e94f5787b113","Exchange Kiosk")

$moveReport = @()                                           # Initialize report variables. 
                                        
# Get PartitionId for MobileIron
$dmPartitionId = (Invoke-RestMethod -Method 'Get' -Uri https://na1.mobileiron.com/api/v1/metadata/tenant -Credential $cred -Authentication Basic).result.defaultDmPartitionId
write-host "DEBUG: dmPartitionId: $dmPartitionId"

foreach ($line in $inputCSV) {

    # Initialize variables from primary smtp address
    $smtp = $line.PrimarySmtpAddress
    $user = get-azureaduser -Filter "mail eq '$smtp'"
    $group = get-azureadgroup -All $true | where-object {$_.DisplayName -eq "$groupName"}
    $userLicenses = $user.AssignedPlans
    #$userMailbox = get-mailbox -Identity "$smtp"
    $licensed = $false
    $mobile = $false

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

    if ($licensed -eq $true) {
        # User is licensed so continue the move.
        ##################################################
        Write-Host "Finalizing move request for $smtp" -ForegroundColor cyan
        Resume-MoveRequest $smtp

        # Check if the user smtp address is in the list of users approved for mobile
        ##################################################
        if ($mobileUserCSV.PrimarySmtpAddress -contains "$smtp") {

            # User is approved for mobile use so add them to the InTune group.
            Add-AzureAdGroupMember -objectId $group.ObjectId -RefObjectId $user.ObjectId
            Write-Host "Added $($user.DisplayName) to $groupName" -ForegroundColor cyan
            $mobile = $true

            # Now check the user for MobileIron device registrations.
            write-host "Checking $smtp for MobileIron Devices..." -ForegroundColor Blue

            # Get list of devices assigned to the user.
            $devices = (Invoke-RestMethod -Method 'Get' -Uri "https://na1.mobileiron.com/api/v1/device?q=&dmPartitionId=$dmPartitionId&fq=EMAILADDRESS+EQ+$smtp" -Credential $cred -Authentication Basic).result.searchResults
            if ($devices -eq $null) {
                write-host "User $smtp did not have any devices!" -ForegroundColor Yellow
                $deviceCount = 0
            } else {
                
                # If the user has devices, then loop through them and retire them one at a time.
                foreach ($device in $devices) {
                    write-host "Checking $smtp device $($device.prettyModel)"

                    # If the device is not already retired or pending retirement, then retire it.
                    if ($device.registrationState -ne "RETIRED" -and $device.registrationState -ne "RETIRE PENDING") {
                        $deviceId = $device.id
                        $deviceModel = $device.prettyModel
                        $body = @{ids="$deviceId"}

                        # Retire the device
                        $result = (Invoke-RestMethod -Method ‘Put’ -Uri 'https://na1.mobileiron.com/api/v1/device/retire' -Form $body -Credential $cred -Authentication Basic)
                        if ($result.error -eq $null) {
                            write-host "Successfully retired device $deviceModel for user $smtp" -ForegroundColor Green
                        }
                    } else {
                        # If the device is already retired, notify the user of this and move on.
                        write-host "Device $($device.prettyModel) already retired. Skipping..."
                    }
                    # Sleep for 2 seconds to ease API restrictions.
                    start-sleep -s 2
                }
                $deviceCount = $devices.count
            }
        }

    } else {
        # User is not licensed. Report this and abort the move.
        Write-Host "$smtp is not licensed in 365. Aborting move!" -ForegroundColor red
    }

    # Update move report
    $moveReport += [pscustomobject]@{
        "PrimarySMTPAddress" = $smtp
        "Migrated" = $licensed
        "Added to Mobile Group" = $mobile
        "Mobile Devices Retired" = $deviceCount
    }

}

# Output all CSV Files:
$moveReport | export-csv "$((Get-Date).ToString("yyyyMMdd_HHmmss"))_moveReport.csv" -NoTypeInformation

Stop-Transcript