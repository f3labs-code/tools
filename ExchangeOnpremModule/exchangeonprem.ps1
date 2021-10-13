

# Create object to export
$global:export_object = @()

function export-result {
    param (
        $result, $label
    )
    if ($null -eq $result) {
        $result = "None"
    }

    if ($result -is [System.Object]) {
        $result = $result | Out-String
    }

    $global:export_object += [pscustomobject]@{label=$label;content=$result}
}

# Get Exchange Servers
$exchange_servers = Get-ExchangeServer | select Name
$exchange_servercount = ($exchange_servers).count

export-result $exchange_servers "Exchange Servers"


#Get Exchange Server Versions
$exchange_serverversion = Get-ExchangeServer | select Name, AdminDisplayVersion
export-result $exchange_serverversion "Exchange Server Versions"


# Get Exchange Server Operating Systems
$exchange_serveros = Get-ExchangeServer | select Name 
$server_oses = @()
foreach ($exserver in $exchange_serveros) {
    $servername = $exserver.Name 
    $add_server = get-adcomputer -Filter "Name -eq '$servername'" -Properties * | select DNSHostname, OperatingSystem
    $server_oses += $add_server
}
export-result $server_oses "Exchange Server OS Versions"


# Get Total Number of Exchange Servers
export-result $exchange_servercount "Exchange Server Count"


# Get Exchange Server Roles
$exchange_serverroles = Get-ExchangeServer | select Name,ServerRole
export-result $exchange_serverroles "Exchange Server Roles"


# Get Exchange Server Enterprise Edition
$exchange_enterprise = Get-ExchangeServer | select Name,Edition | where {$_.Edition -eq "Enterprise"}
export-result $exchange_enterprise "Exchange Server Enterprise"


# Get Exchange Server Standard Edition
$exchange_standard = Get-ExchangeServer | select Name,Edition | where {$_.Edition -eq "Standard"}
export-result $exchange_standard "Exchange Server Standard"


# Get DAG List
$dag_list = Get-DatabaseAvailabilityGroup
export-result $dag_list "Database Availability Groups"


# Get DAG Witness
$dag_witness = Get-DatabaseAvailabilityGroup | select Name, WitnessServer
export-result $dag_witness "Database Availability Group Witness Servers"


# Get DAG IP Addresses
$dag_ips = Get-DatabaseAvailabilityGroup | select Name, DatabaseAvailabilityGroupIpv4Addresses
export-result $dag_ips "Database Availability Group IPs"


# Get users in admin roles
set-adserversettings -ViewEntireForest $true
$admin_roles = Get-RoleGroupMember "Organization Management"
export-result $admin_roles "Administrators"


# Get Journal Rules
$journal_rules = Get-JournalRule
export-result $journal_rules "Journal Rules"


# Get Federation Trusts
$fed_trusts = Get-FederationTrust
export-result $fed_trusts "Federation Trusts"


# Get Org Relationships
$org_relationship = Get-OrganizationRelationship
export-result $org_relationship "Org Relationships"


# Outlook Anywhere General
$outlook_anywhere = Get-OutlookAnywhere
$oa_enabled = $outlook_anywhere | where {$_.IsValid -eq "True"} | select Servername
$oa_external = $outlook_anywhere | select-object Servername,ExternalHostname
$oa_internal = $outlook_anywhere | select-object Servername,InternalHostname
$oa_auth = $outlook_anywhere | select-object Servername,IISAuthenticationMethods
export-result $oa_enabled "Outlook Anywhere Enabled Servers"
export-result $oa_external "Outlook Anywhere External URL"
export-result $oa_internal "Outlook Anywhere Internal URL"
export-result $oa_auth "Outlook Anywhere Auth Methods"


# Get Mailbox Databases
$mailbox_db = Get-MailboxDatabase | select Name,Server
export-result $mailbox_db "Mailbox DBs"


# Get Public Folder Databases
$pf_db = Get-PublicFolderDatabase | Select Name,Server
export-result $pf_db "Public Folder DBs"


# Get Public Folder Root
if ($null -ne $pf_db) {
    $pf_root = get-publicfolder
} else {
    $pf_root = $null
}

export-result $pf_root "Public Folder Root"

# Get Archiving Enabled
$archiving = Get-Mailbox -Filter "ArchiveGuid -ne `$null"
if (($archiving).count -eq 0) {
    export-result "Yes" "Archiving Enabled"
} else {
    export-result "No" "Archiving Enabled"
}

# Get Journaling Enabled
$journaling = Get-MailboxDatabase | select Name,JournalRecipient
export-result $journaling "Journaling Enabled"


# Get Outlook Web Access Mailbox Policies
$owa_mailboxpolicies = Get-OwaMailboxPolicy | select Name
export-result $owa_mailboxpolicies "OWA Mailbox Policies"


# Get Edge Subscriptions
$edge_subscriptions = Get-EdgeSubscription
export-result $edge_subscriptions "Edge Subscriptions"


# Get Unified Messaging
$um = Get-UMMailbox
export-result $um "Unified Messaging"


# Get Exchange Certificates
$exch_certs = Get-ExchangeCertificate | select CertificateDomains, Services, NotAfter
export-result $exch_certs "Exchange Certs"


# Get Receive Connectors
$rec_connector = Get-Receiveconnector | select Server,Name
export-result $rec_connector "Receive Connectors"


# Get Total Mailboxes
$user_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "UserMailbox"
$shared_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "SharedMailbox"
$room_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "RoomMailbox"
$equip_mailboxes = Get-Mailbox -Resultsize Unlimited -RecipientTypeDetails "EquipmentMailbox"
$content = "User Mailboxes: " + $user_mailboxes.count + "`nShared Mailboxes: " + $shared_mailboxes.count + "`nRoom Mailboxes: " + $room_mailboxes.count + "`nEquipment Mailboxes: " + $equip_mailboxes.count

export-result $content "Mailbox Count"

# Check for Archive Mailboxes
$archive_mailboxes = Get-Mailbox -ResultSize Unlimited | where {$_.ArchiveStatus -eq "Active"}
export-result $archive_mailboxes "Archive Mailboxes"


# Check for Sharing Policy
$sharing_policy = Get-sharingpolicy
export-result $sharing_policy "Sharing Policies"


# Get Address Lists
$address_lists = Get-AddressList
export-result $address_lists "Address Lists"


# Get Retention Policies
$retention_policies = Get-RetentionPolicy
export-result $retention_policies "Retention Policies"


# Get Retention Policy Tags
$retention_tags = Get-RetentionPolicyTag
export-result $retention_tags "Retention Tags"

# Get offline address books
$offline_addressbooks = Get-OfflineAddressBook 
export-result $offline_addressbooks "Offline Address Books"


# Get oab policies
$oab_policies = Get-AddressBookPolicy
export-result $oab_policies "OAB Policies"


# Get ActiveSync Policies
$activesync_policies = Get-ActiveSyncMailboxPolicy
export-result $activesync_policies "Activesync Policies"


# Get Remote Domains
$remote_domains = Get-RemoteDomain 
export-result $remote_domains "Remote Domains"


# Get Accepted Domains
$accepted_domains = Get-AcceptedDomain
export-result $accepted_domains "Accepted Domains"


# Get MX Records
$mxrecords = @()
foreach($domain in $accepted_domains) {
        $thisrecord = resolve-dnsname $domain.domainname -type MX | where {$_.Section -eq "Answer"} | select Name,NameExchange,Preference,TTL
        $mxrecords += $thisrecord
}

export-result $mxrecords "MX Records"

# Get TXT Records for DMARC and SPF
$spfrecords = @()
$dmarcrecords = @()
foreach($domain in $accepted_domains) {
 
        $spfrecords += resolve-dnsname -name $domain.domainname -type TXT | where {$_.Strings -like "*spf*"} | select Name,Type,TTL,Strings
        $dmarcrecords += resolve-dnsname -name $domain.domainname -type TXT | where {$_.Strings -like "*dmarc*"} | select Name,Type,TTL,Strings
}

export-result $spfrecords "SPF Records"
export-result $dmarcrecords "DMARC Records"


# Get Email Address Policies
$email_address_policies = Get-EmailAddressPolicy
export-result $email_address_policies "Email Address Policies"

# Get Transport Rules
$transport_rules = Get-TransportRule 
export-result $transport_rules "Transport Rules"


# Get Send Connectors
$send_connectors = Get-SendConnector
export-result $send_connectors "Send Connectors"


# Get Transport Settings
$transport_config = Get-transportconfig 
$max_receivesize = $transport_config.MaxReceiveSize 
$max_sendsize = $transport_config.MaxSendSize
$max_recipientenvelopelimit = $transport_config.MaxRecipientEnvelopeLimit 
$max_dumpster = $transport_config.MaxDumpsterSizePerDatabase
$max_dumpstertime = $transport_config.MaxDumpsterTime 

$content = "Max Receive Size: $max_receivesize `nMax Send Size: $max_sendsize `nMax Recipient Envelope Limit: $max_recipientenvelopelimit `nMax Dumpster Size: $max_dumpster `nMax Dumpster Time: $max_dumpstertime"
export-result $content "Transport Settings"


# Create Object to send to Export-CSV
$global:export_object | export-csv ".\onpremexchange_settings.csv" -NoTypeInformation
