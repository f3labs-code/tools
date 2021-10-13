# Initialize results array
$export_object = @()

# Get all teams info
$teams = Get-Team
$users = $teams | get-teamuser

#Get number of teams:
$num_teams = ($teams).count
$export_object += [pscustomobject]@{label="Number of Teams";content=$num_teams}

#Get number of guests:
$guests = $users.Role | where {$_ -eq "guest"}
$num_guests = ($guests).count
$export_object += [pscustomobject]@{label="Number of Guests";content=$num_guests}

# Get Teams Update policy
$teams_update = Get-CSTeamsUpdateManagementPolicy | where {$_.Identity -eq "Global"}
$teams_update = $teams_update | Out-String 
$export_object += [pscustomobject]@{label="Teams Update Policy";content=$teams_update}

# Anonymous Meeting Settings
$anon_settings = Get-CsTeamsMeetingConfiguration

$anon_join = $anon_settings.disableanonymousjoin
$anon_interactapps = $anon_settings.disableappinteractionforanonymoususers

if ($anon_join -eq $true) {$anon_join = $false} else {$anon_join = $true}
if ($anon_interactapps -eq $true) {$anon_interactapps = $false} else {$anon_interactapps = $true}

$export_object += [pscustomobject]@{label="Anonymous Users can join a meeting";content=$anon_join}
$export_object += [pscustomobject]@{label="Anonymous Users can interact with apps in meetings";content=$anon_interactapps}

# Skype interop setting
$client_config = get-csteamsclientconfiguration
$allow_interop = $client_config.AllowSkypeBusinessInterop

$export_object += [pscustomobject]@{label="Users can communicate with other Skype for Business and Teams Users";content=$allow_interop}

# Allow Guest Settings
$allow_guestaccess = $client_config.AllowGuestUser
$export_object += [pscustomobject]@{label="Allow Guest Users";content=$allow_guestaccess}

# File Sharing Settings
$dropbox = $client_config.AllowDropBox
$box = $client_config.AllowBox 
$googledrive = $client_config.AllowGoogleDrive
$sharefile = $client_config.AllowSharefile
$egnyte = $client_config.AllowEgnyte

$content = "DropBox: $dropbox `nBox: $box `nGoogle Drive: $googledrive `nSharefile: $sharefile `nEgnyte: $egnyte"
$export_object += [pscustomobject]@{label="File Sharing Options";content=$content}

#Get Coexsitence Mode:
$coexist = Get-CSTeamsUpgradePolicy | where {$_.Identity -eq "Global"}
$export_object += [pscustomobject]@{label="Coexistence Mode";content=$coexist.Mode}

#Get Global Settings:
$globalsettings = Get-CsTeamsMeetingPolicy | where {$_.Identity -eq "Global"}
$preferred_app = $globalsettings.PreferredMeetingProviderForIslandsMode
$automatic_download = (Get-CsTeamsUpgradepolicy | where {$_.Identity -eq "Global"}).NotifySfbUsers

$export_object += [pscustomobject]@{label="Notify Upgrade Available";content=$automatic_download}
$export_object += [pscustomobject]@{label="Preferred App for users to join SFB meetings";content=$preferred_app}
$export_object += [pscustomobject]@{label="Download Teams in Background for SFB Users";content=$automatic_download}


# Create Object to send to Export-CSV
$export_object | export-csv ".\teams_settings.csv" -NoTypeInformation




