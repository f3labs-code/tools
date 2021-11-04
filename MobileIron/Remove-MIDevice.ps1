Write-Host "Enter credentials for MobileIron:" -ForegroundColor Blue
$creds = Get-Credential

$csvfile = '.\devices_to_retire.csv'

$emails = import-Csv $csvfile

foreach ($email in $emails) {
    $smtp = $email.primarySmtpAddress

    $devices = (Invoke-RestMethod -Method 'Get' -Uri "https://na1.mobileiron.com/api/v1/device?q=&dmPartitionId=26653&fq=EMAILADDRESS+EQ+$smtp" -Credential $cred -Authentication Basic).result.searchResults
    if ($devices -eq $null) {
        write-host "User $smtp did not have any devices!" -ForegroundColor Yellow
        break
    }
    foreach ($device in $devices) {
        if ($device.registrationState -ne "RETIRED" -and $device.registrationState -ne "PENDING RETIREMENT") {
            $deviceId = $device.id
            $deviceModel = $device.prettyModel
            $body = @{ids="$deviceId"}
            $result = (Invoke-RestMethod -Method ‘Put’ -Uri 'https://na1.mobileiron.com/api/v1/device/retire' -Form $body -Credential $cred -Authentication Basic)
            if ($result.error -eq $null) {
                write-host "Successfully retired device $deviceModel for user $smtp" -ForegroundColor Green
            }
        }
    }

}
