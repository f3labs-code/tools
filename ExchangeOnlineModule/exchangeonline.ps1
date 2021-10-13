# Create object to export
$export_object = @()

# Get users in admin roles
$admin_roles = Get-RoleGroupMember "Organization Management"
$admin_roles = $admin_roles | out-string
$export_object += [pscustomobject]@{label="Administrators";content=$admin_roles}

# Get Journal Rules
$journal_rules = Get-JournalRule
$export_object += [pscustomobject]@{label="Journal Rules";content=$journal_rules}

# Get Total Mailboxes
$user_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "UserMailbox"
$shared_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "SharedMailbox"
$room_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "RoomMailbox"
$equip_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "EquipmentMailbox"
$content = "User Mailboxes: " + $user_mailboxes.count + "`nShared Mailboxes: " + $shared_mailboxes.count + "`nRoom Mailboxes: " + $room_mailboxes.count + "`nEquipment Mailboxes: " + $equip_mailboxes.count

$export_object += [pscustomobject]@{label="Mailbox Count";content=$content}

# Check for Archive Mailboxes
$archive_mailboxes = Get-Mailbox -ResultSize Unlimited | where {$_.ArchiveStatus -eq "Active"}
$export_object += [pscustomobject]@{label="Archive Mailboxes";content=$archive_mailboxes}

# Check for Sharing Policy
$sharing_policy = Get-sharingpolicy
$export_object += [pscustomobject]@{label="Sharing Policies";content=$sharing_policy}

# Get Address Lists
$address_lists = Get-AddressList
$address_lists = $address_lists | out-string
$export_object += [pscustomobject]@{label="Address Lists";content=$address_lists}

# Get Retention Policies
$retention_policies = Get-RetentionPolicy
$retention_policies = $retention_policies | out-string
$export_object += [pscustomobject]@{label="Retention Policies";content=$retention_policies}

# Get offline address books
$offline_addressbooks = Get-OfflineAddressBook 
$export_object += [pscustomobject]@{label="Offline Address Books";content=$offline_addressbooks}

# Get oab policies
$oab_policies = Get-AddressBookPolicy
$export_object += [pscustomobject]@{label="OAB Policies";content=$oab_policies}

# Get ActiveSync Policies
$activesync_policies = Get-ActiveSyncMailboxPolicy
$export_object += [pscustomobject]@{label="Activesync Policies";content=$activesync_policies}

# Get Remote Domains
$remote_domains = Get-RemoteDomain 
$remote_domains = $remote_domains | out-string
$export_object += [pscustomobject]@{label="Remote Domains";content=$remote_domains}

# Get Accepted Domains
$accepted_domains = Get-AcceptedDomain
$accepted_domains = $accepted_domains | out-string
$export_object += [pscustomobject]@{label="Accepted Domains";content=$accepted_domains}

# Get Email Address Policies
$email_address_policies = Get-EmailAddressPolicy
$export_object += [pscustomobject]@{label="Email Address Policies";content=$email_address_policies}

# Get Transport Rules
$transport_rules = Get-TransportRule 
$transport_rules = $transport_rules | out-string
$export_object += [pscustomobject]@{label="Transport Rules";content=$transport_rules}

# Get Send Connectors
$send_connectors = Get-SendConnector
$send_connectors = $send_connectors | out-string
$export_object += [pscustomobject]@{label="Send Connectors";content=$send_connectors}

# Get Transport Settings
$transport_config = Get-transportconfig 
$max_receivesize = $transport_config.MaxReceiveSize 
$max_sendsize = $transport_config.MaxSendSize
$max_recipientenvelopelimit = $transport_config.MaxRecipientEnvelopeLimit 
$max_dumpster = $transport_config.MaxDumpsterSizePerDatabase
$max_dumpstertime = $transport_config.MaxDumpsterTime 

$content = "Max Receive Size: $max_receivesize `nMax Send Size: $max_sendsize `nMax Recipient Envelope Limit: $max_recipientenvelopelimit `nMax Dumpster Size: $max_dumpster `nMax Dumpster Time: $max_dumpstertime"
$export_object += [pscustomobject]@{label="Transport Settings";content=$content}

# Get MX Records
# Create Object to send to Export-CSV
$export_object | export-csv ".\exchange_settings.csv" -NoTypeInformation

