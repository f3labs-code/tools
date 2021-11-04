Write-Host "Enter credentials for MobileIron:" -ForegroundColor Blue
$cred = Get-Credential

$csvfile = '.\devices_to_retire.csv'

$emails = import-Csv $csvfile

# Get dmPartition Id
$dmPartitionId = (Invoke-RestMethod -Method 'Get' -Uri https://na1.mobileiron.com/api/v1/metadata/tenant -Credential $cred -Authentication Basic).result.defaultDmPartitionId
write-host "dmPartitionId: $dmPartitionId"

foreach ($email in $emails) {
    $smtp = $email.primarySmtpAddress
    write-host "Checking $smtp for MobileIron Devices"

    $devices = (Invoke-RestMethod -Method 'Get' -Uri "https://na1.mobileiron.com/api/v1/device?q=&dmPartitionId=$dmPartitionId&fq=EMAILADDRESS+EQ+$smtp" -Credential $cred -Authentication Basic).result.searchResults
    if ($devices -eq $null) {
        write-host "User $smtp did not have any devices!" -ForegroundColor Yellow
        continue
    }
    foreach ($device in $devices) {
        write-host "Checking $smtp device $($device.prettyModel)"
        if ($device.registrationState -ne "RETIRED" -and $device.registrationState -ne "PENDING RETIREMENT") {
            $deviceId = $device.id
            $deviceModel = $device.prettyModel
            $body = @{ids="$deviceId"}
            $result = (Invoke-RestMethod -Method ‘Put’ -Uri 'https://na1.mobileiron.com/api/v1/device/retire' -Form $body -Credential $cred -Authentication Basic)
            if ($result.error -eq $null) {
                write-host "Successfully retired device $deviceModel for user $smtp" -ForegroundColor Green
            }
        } else {
            write-host "Device $($device.prettyModel) already retired. Skipping..."
        }
    }

}
