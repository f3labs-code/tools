# Create object to export
$export_object = @()

# Get AD Forest
$ad_forest = Get-ADForest | select Name
$export_object += [pscustomobject]@{label="AD Forest";content=$ad_forest.Name}

# Get AD Domain
$ad_domain = Get-ADDomain | select Name
$export_object += [pscustomobject]@{label="AD Domain";content=$ad_domain.Name}

# Get AD Forest Schema Level
$forest_schema = Get-ADObject (Get-ADRootDSE).schemaNamingContext -property objectVersion | select objectVersion
$export_object += [pscustomobject]@{label="Forest Schema Level";content=$forest_schema.objectVersion}

# Get Domain Functional Level
$domain_level = Get-addomain | select DomainMode
$export_object += [pscustomobject]@{label="Domain Functional Level";content=$domain_level.DomainMode}

# Get Forest Functional Level
$forest_level = Get-AdForest | select ForestMode
$export_object += [pscustomobject]@{label="Forest Functional Level";content=$forest_level.ForestMode}

# Get Domain Controller OS Level
$dcs = Get-ADDomainController -Filter * | Select Hostname,OperatingSystem,OperatingSystemVersion
$dcs = $dcs | out-string
$export_object += [pscustomobject]@{label="Domain Controllers OS Version";content=$dcs}


# Get FSMO Role Holders
$schema_master = (Get-ADForest | Select schemamaster).schemamaster
$domainnamingmaster = (Get-ADForest | Select domainnamingmaster).domainnamingmaster
$domain = get-addomain
$pdc_emulator = $domain.PDCEmulator 
$rid_master = $domain.RidMaster 
$inf_master = $domain.InfrastructureMaster
$content = "Schema Master: $schema_master `nDomain Naming Master: $domainnamingmaster `nPDC Emulator: $pdc_emulator `nRID Master: $rid_master `nInf Master: $inf_master"
$export_object += [pscustomobject]@{label="FSMO Roles";content=$content}

# Get Global Catalog Servers
$gc_dcs = Get-ADDomainController -Filter {IsGlobalCatalog -eq $true} | select Hostname
$gc_dcs = $gc_dcs | out-string
$export_object += [pscustomobject]@{label="GC Servers";content=$gc_dcs}

# Get Domain Controller List
$dcs = Get-ADDomainController -Filter * | Select Hostname
$dcs = $dcs | out-string
$export_object += [pscustomobject]@{label="Domain Controllers";content=$dcs}

# Get number of AD Users
$ad_users = (Get-ADUser -filter *).count
$export_object += [pscustomobject]@{label="User Count";content=$ad_users}

# Get AD Users not logged in 90 days
$ninetydays = (Get-Date).AddDays(-90)
$valid_users = (Get-ADUser -filter {lastLogonDate -lt $ninetydays} -Property Name,lastLogonDate).count
$export_object += [pscustomobject]@{label="Users Logged in Last 90 Days";content=$valid_users}

# Create Object to send to Export-CSV
$export_object | export-csv ".\ad_settings.csv" -NoTypeInformation
