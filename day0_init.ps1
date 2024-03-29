# MFT Download
$mft = 'C:\$MFT'
$work_path = "C:\MFT"
$out_name = $env:COMPUTERNAME + "_day0.csv"
$password = "KHt3qbz]cC@Y/PG~L~]L"

cmd /c net user administrator $password

Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/MFT.zip -OutFile MFT.zip
# unzip 
Expand-Archive -LiteralPath .\MFT.zip -DestinationPath $work_path
# Install DotNet
C:\MFT\dotnet-runtime-6.0.15-win-x64.exe /install /passive /norestart
# Get MFT raw file
C:\MFT\forecopy.exe -f $mft $work_path
# Parsing MFT to csv
C:\MFT\MFTECmd\MFTECmd.exe -f 'C:\MFT\$MFT' --csv $work_path --csvf $out_name

# Start ssh install
Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/OpenSSH-Win64.zip -OutFile OpenSSH-Win64.zip

Expand-Archive OpenSSH-Win64.zip -DestinationPath .\ -Force

if ((Get-Service -Name sshd -ErrorAction SilentlyContinue).Length -gt 0) {
    Write-Output "OpenSSH is already installed, uninstall sshd."
    & 'C:\Program Files\OpenSSH-Win64\uninstall-sshd.ps1'
    Stop-Process -Name sshd -Force
    
    Write-Output "Overwrite our files"
    Copy-Item .\OpenSSH-Win64\* -Destination "C:\Program Files\OpenSSH-Win64" -Force

    Write-Output "Add our key to the authorized_keys file"
    echo '' | Add-Content -Encoding UTF8 C:\Users\Administrator\.ssh\authorized_keys
    echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBl52LXRyBSrSPNJbN+M5M2bZyPoXffiDerLATHMezC4' | Add-Content -Encoding UTF8 C:\Users\Administrator\.ssh\authorized_keys
    & 'C:\Program Files\OpenSSH-Win64\install-sshd.ps1'
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
} 
else {
    mkdir C:\Windows\System32\OpenSSH -Force
    Copy-Item .\OpenSSH-Win64\* -Destination C:\Windows\System32\OpenSSH
    cd C:\Windows\System32\OpenSSH
    icacls libcrypto.dll /grant Everyone:RX
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force


    mkdir C:\ProgramData\ssh -Force
    echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBl52LXRyBSrSPNJbN+M5M2bZyPoXffiDerLATHMezC4' | Set-Content -Encoding UTF8 C:\ProgramData\ssh\administrators_authorized_keys

    $acl = Get-Acl C:\ProgramData\ssh\administrators_authorized_keys
    $acl.SetAccessRuleProtection($true, $false)
    $administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("$env:UserName","FullControl","Allow")
    $systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
    $acl.SetAccessRule($administratorsRule)
    $acl.SetAccessRule($systemRule)
    $acl | Set-Acl

    ((Get-Content -Path C:\Windows\System32\OpenSSH\sshd_config_default -Raw) -replace '#PubkeyAuthentication yes','PubkeyAuthentication yes' -replace '#PasswordAuthentication yes','PasswordAuthentication no') | Set-Content -Path C:\Windows\System32\OpenSSH\sshd_config_default

    icacls C:\ProgramData\ssh\administrators_authorized_keys /remove:g Administrator
    icacls C:\ProgramData\ssh\administrators_authorized_keys /remove:g Everyone
    icacls C:\ProgramData\ssh\administrators_authorized_keys /grant Administrator:RX
    icacls C:\ProgramData\ssh\administrators_authorized_keys /grant Everyone:RX

    .\install-sshd.ps1
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'

    if (!(Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
        New-NetFirewallRule -Name 'sshd' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 42847
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    }

}
 

# get file list
cd $home\Desktop
cmd /c Dir /s/a-d/ogn-s c:\ > out1.txt

#########################################################
# START syscheck.ps1
#########################################################


# add the "EnableSensitiveInfoSearch" flag to search for sensitive data
param ([Switch]$EnableSensitiveInfoSearch = $false)

# used for logging purposes
$Version = "1.16" 

#########################################################
# START_OF_SCRIPT, PartOfDomain 
#########################################################

$startTime = Get-Date
write-host Hello dear user! -ForegroundColor Green
Write-Host This script will output the results to a folder or a zip file with the computer name. -ForegroundColor Green
#check if running as an elevated admin
$runningAsAdmin = (whoami /groups | select-string S-1-16-12288) -ne $null
if (!$runningAsAdmin)
    {Write-host "Please run the script as an elevated admin, or else some output will be missing! :-(" -ForegroundColor Red}

# get hostname to use as the folder name and file names
$hostname = hostname
# get the windows version for later use
$winVersion = [System.Environment]::OSVersion.Version

# remove old folder and create new one
Remove-Item $hostname -Recurse -ErrorAction SilentlyContinue
New-Item $hostname -type directory -ErrorAction SilentlyContinue | Out-Null

# output log
# JJ:logfile name: e.g., Log_DESKTOP_VK38dKG.txt
$outputFileName = "$hostname\Log_$hostname.txt"
"Computer Name: $hostname" | Out-File $outputFileName -Append
"Windows Version: " + (Get-WmiObject -class Win32_OperatingSystem).Caption | Out-File $outputFileName -Append

# JJ: here checks "PartOfDomain". If True, the computer is part of a domain. If the value is NULL, the computer is not in a domain or the status is unknown. If you remove the computer from a domain, the value becomes false.
$partOfDomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
"Part of Domain: $partOfDomain" | Out-File $outputFileName -Append 
if ($partOfDomain)
{
    "Domain Name: " + (Get-WmiObject -class Win32_ComputerSystem).Domain | Out-File $outputFileName -Append
    if ((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 2)
        {"Domain Controller: True" | Out-File $outputFileName -Append}
    else
        {"Domain Controller: False" | Out-File $outputFileName -Append}    
}
$user = whoami
"`nRunning User: $user" | Out-File $outputFileName -Append
"Running As Admin: $runningAsAdmin" | Out-File $outputFileName -Append
$uptimeDate = [Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem).LastBootUpTime)
"System Uptime: Since " + $uptimeDate.ToString("dd/MM/yyyy HH:mm:ss") | Out-File $outputFileName -Append
"Script Version: $Version" | Out-File $outputFileName -Append
"Script Start Time: " + $startTime.ToString("dd/MM/yyyy HH:mm:ss") | Out-File $outputFileName -Append


#########################################################
# ?
#########################################################

# get current user privileges
write-host Running whoami... -ForegroundColor Yellow
$outputFileName = "$hostname\Whoami_$hostname.txt"
"`nOutput of `"whoami /all`" command:`n" | Out-File $outputFileName -Append
# when running whoami /all and not connected to the domain, claims information cannot be fetched and an error occurs. Temporarily silencing errors to avoid this.
#$PrevErrorActionPreference = $ErrorActionPreference
#$ErrorActionPreference = "SilentlyContinue"
if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain -and (!(Test-ComputerSecureChannel)))
    {whoami /user /groups /priv | Out-File $outputFileName -Append}
else
    {whoami /all | Out-File $outputFileName -Append}
#$ErrorActionPreference = $PrevErrorActionPreference
"`n========================================================================================================" | Out-File $outputFileName -Append
"`nSome rights allow for local privilege escalation to SYSTEM and shouldn't be granted to non-admin users:" | Out-File $outputFileName -Append
"`nSeImpersonatePrivilege`nSeAssignPrimaryPrivilege`nSeTcbPrivilege`nSeBackupPrivilege`nSeRestorePrivilege`nSeCreateTokenPrivilege`nSeLoadDriverPrivilege`nSeTakeOwnershipPrivilege`nSeDebugPrivilege " | Out-File $outputFileName -Append
"`nSee the following guide for more info:`nhttps://book.hacktricks.xyz/windows/windows-local-privilege-escalation/privilege-escalation-abusing-tokens" | Out-File $outputFileName -Append


#########################################################
# IPCONFIG
#########################################################

# get IP settings
write-host Running ipconfig... -ForegroundColor Yellow
$outputFileName = "$hostname\ipconfig_$hostname.txt"
"`nOutput of `"ipconfig /all`" command:`n" | Out-File $outputFileName -Append
ipconfig /all | Out-File $outputFileName -Append

# test for internet connectivity
write-host Trying to ping the internet... -ForegroundColor Yellow
$outputFileName = "$hostname\Internet-Connectivity_$hostname.txt"
"============= ping -n 2 8.8.8.8 =============" | Out-File $outputFileName -Append
ping -n 2 8.8.8.8 | Out-File $outputFileName -Append
# more detailed test for newer PowerShell versions - takes a lot of time and not very important

# get network connections (run-as admin is required for -b associated application switch)
$outputFileName = "$hostname\Netstat_$hostname.txt"
$csvFilename = "$hostname\Netstat_$hostname.csv"
write-host Running netstat... -ForegroundColor Yellow
"`n============= netstat -nao =============" | Out-File $outputFileName -Append
netstat -nao | findstr LIST | Out-File $outputFileName -Append
"`n============= netstat -naob (includes process name, elevated admin permission is required =============" | Out-File $outputFileName -Append
netstat -naob | findstr LIST | Out-File $outputFileName -Append

netstat -an | findstr LISTEN | Out-File $csvFilename -Append


#########################################################
# If machine is in Domain, Resultant Set of Policy (RSoP)
#  - from Group Policy settings 
#########################################################

# get GPOs
# check if the computer is in a domain
$outputFileName = "$hostname\gpresult_$hostname.html"
if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain)
{
    # check if we have connectivity to the domain, or if is a DC
    if (((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 2) -or (Test-ComputerSecureChannel))
    {
        write-host Running GPResult to get GPOs... -ForegroundColor Yellow
        gpresult /f /h $outputFileName
        # /h doesn't exists on Windows 2003, so we run without /h into txt file
        if (!(Test-Path $outputFileName)) {gpresult $hostname\gpresult_$hostname.txt}
    }
    else
    {
        write-host Unable to get GPO configuration... the computer is not connected to the domain -ForegroundColor Red
    }
}


#########################################################
# Export security settings 
#########################################################

# get security policy settings (secpol.msc), run as admin is required
# to open the *.inf output file, open MMC, add snap-in "Security Templates", right click and choose new path, choose the *.inf file path, and open it
$outputFileName = "$hostname\Security-Policy_$hostname.inf"
if ($runningAsAdmin)
{
    write-host Getting security policy settings... -ForegroundColor Yellow
    secedit /export /CFG $outputFileName | Out-Null
}
else
{
    write-host Unable to get security policy settings... elevated admin permissions are required -ForegroundColor Red
}

#########################################################
# Get audit policy settings
#########################################################

# get audit policy (Windows vista/2008 & run-as admin are required)
$outputFileName = "$hostname\Audit-Policy_$hostname.txt"
if ($winVersion.Major -ge 6)
{
    if ($runningAsAdmin)
    {
        write-host Getting audit policy settings... -ForegroundColor Yellow
        "`nOutput of `"auditpol /get /category:*`" command:`n" | Out-File $outputFileName -Append
        auditpol /get /category:* | Out-File $outputFileName -Append
    }
    else
    {
        write-host Unable to get audit policy... elevated admin permissions are required -ForegroundColor Red
        "Unable to get audit policy without running as admin. Consider running again with elevated admin permissions." | Out-File $outputFileName -Append
    }
}

#########################################################
# Get Windows features
#########################################################

# get windows features (Windows vista/2008 or above is required)
$outputFileName = "$hostname\Windows-Features_$hostname.txt"
if ($winVersion.Major -ge 6)
{    
    # first check if we can fetch Windows features in any way - Windows workstation without RunAsAdmin cannot fetch features (also Win2008 but it's rare...)
    if ((!$runningAsAdmin) -and ((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 1))
    {
        write-host Unable to get Windows features... elevated admin permissions are required -ForegroundColor Red
    }
    else
    {
        write-host Getting Windows features... -ForegroundColor Yellow
    }

    "There are several ways of getting the Windows features. Some require elevation. See the following for details: https://hahndorf.eu/blog/WindowsFeatureViaCmd" | Out-File $outputFileName -Append
    # get features with Get-WindowsFeature. Requires Windows SERVER 2008R2 or above
    if (($winVersion.Major -ge 7) -or ($winVersion.Minor -ge 1)) # version should be 7+ or 6.1+
    {
        if (((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 2) -or ((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 3))
        {
            "`n============= Output of: Get-WindowsFeature =============" | Out-File $outputFileName -Append
            Get-WindowsFeature | ft -AutoSize | Out-File $outputFileName -Append
        }
    }
    # get features with Get-WindowsOptionalFeature. Requires Windows 8/2012 or above and run-as-admin
    if (($winVersion.Major -ge 7) -or ($winVersion.Minor -ge 2)) # version should be 7+ or 6.2+
    {
        "`n============= Output of: Get-WindowsOptionalFeature -Online =============" | Out-File $outputFileName -Append
        if ($runningAsAdmin)
            {Get-WindowsOptionalFeature -Online | sort FeatureName | ft | Out-File $outputFileName -Append}
        else
            {"Unable to run Get-WindowsOptionalFeature without running as admin. Consider running again with elevated admin permissions." | Out-File $outputFileName -Append}
    }
    # get features with dism. Requires run-as-admin
    "`n============= Output of: dism /online /get-features /format:table | ft =============" | Out-File $outputFileName -Append
    if ($runningAsAdmin)
    {
        dism /online /get-features /format:table | Out-File $outputFileName -Append
    }
    else
        {"Unable to run dism without running as admin. Consider running again with elevated admin permissions." | Out-File $outputFileName -Append}
}

#########################################################
# Get installed hotfixes
#########################################################

# get installed hotfixes (/format:htable doesn't always work)
$outputFileName = "$hostname\Hotfixes_$hostname.txt"
write-host Getting installed hotfixes... -ForegroundColor Yellow
"`nThe OS version is: " + [System.Environment]::OSVersion + ". See if this version is supported according to the following pages:" | Out-File $outputFileName -Append
"https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions" | Out-File $outputFileName -Append
"https://en.wikipedia.org/wiki/Windows_10_version_history" | Out-File $outputFileName -Append
"https://support.microsoft.com/he-il/help/13853/windows-lifecycle-fact-sheet" | Out-File $outputFileName -Append
"`nOutput of `"Get-HotFix`" PowerShell command, sorted by installation date:`n" | Out-File $outputFileName -Append
Get-HotFix | sort InstalledOn -Descending -ErrorAction SilentlyContinue | Out-File $outputFileName -Append


#########################################################
# Process List
#########################################################

# get processes (new powershell version and run-as admin are required for IncludeUserName)
write-host Getting processes... -ForegroundColor Yellow
$outputFileName = "$hostname\Process-list_$hostname.txt"
$csvFilename = "$hostname\Process-list_$hostname.csv"

"`nOutput of `"Get-Process`" PowerShell command:`n" | Out-File $outputFileName -Append
try {
Get-Process -IncludeUserName | ft -AutoSize ProcessName, id, company, ProductVersion, username, cpu, WorkingSet | Out-String -Width 180 | Out-File $outputFileName -Append
Get-Process -IncludeUserName | select processname, company, productversion, username | ConvertTo-Csv | Out-File $csvFilename -Append
}
# run without IncludeUserName if the script doesn't have elevated permissions or for old powershell versions
catch {Get-Process | ft -AutoSize ProcessName, id, company, ProductVersion, cpu, WorkingSet | Out-String -Width 180 | Out-File $outputFileName -Append}

# get services
write-host Getting services... -ForegroundColor Yellow
$outputFileName = "$hostname\Services_$hostname.txt"
"`nOutput of `"Get-WmiObject win32_service`" PowerShell command:`n" | Out-File $outputFileName -Append
Get-WmiObject win32_service  | Sort displayname | ft -AutoSize DisplayName, Name, State, StartMode, StartName | Out-String -Width 180 | Out-File $outputFileName -Append

# get installed software
write-host Getting installed software... -ForegroundColor Yellow
$outputFileName = "$hostname\Software_$hostname.txt"
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | sort DisplayName | Out-String -Width 180 | Out-File $outputFileName

#########################################################
# Shared Directory
#########################################################

# get shared folders (Share permissions are missing for older PowerShell versions)
write-host Getting shared folders... -ForegroundColor Yellow
$outputFileName = "$hostname\Shares_$hostname.txt"
"============= Shared Folders =============" | Out-File $outputFileName -Append
$shares = Get-WmiObject -Class Win32_Share
$shares | Out-File $outputFileName -Append
# get shared folders + share permissions + NTFS permissions with SmbShare module (exists only in Windows 8 or 2012 and above)
foreach ($share in $shares)
{
    $sharePath = $share.Path
    $shareName = $share.Name
    "`n============= Share Name: $shareName | Share Path: $sharePath =============" | Out-File $outputFileName -Append
    "Share Permissions:" | Out-File $outputFileName -Append
    # Get share permissions with SmbShare module (exists only in Windows 8 or 2012 and above)
    try
    {
        import-module smbshare -ErrorAction SilentlyContinue
        $share | Get-SmbShareAccess | Out-String -Width 180 | Out-File $outputFileName -Append
    }
    catch
    {
        $shareSecSettings = Get-WmiObject -Class Win32_LogicalShareSecuritySetting -Filter "Name='$shareName'"
        if ($shareSecSettings -eq $null)
            {
            # Unfortunately, some of the shares security settings are missing from the WMI. Complicated stuff. Google "Count of shares != Count of share security"
            "Couldn't find share permissions, doesn't exist in WMI Win32_LogicalShareSecuritySetting.`n" | Out-File $outputFileName -Append}
        else
        {
            $DACLs = (Get-WmiObject -Class Win32_LogicalShareSecuritySetting -Filter "Name='$shareName'" -ErrorAction SilentlyContinue).GetSecurityDescriptor().Descriptor.DACL
            foreach ($DACL in $DACLs)
            {
                if ($DACL.Trustee.Domain) {$Trustee = $DACL.Trustee.Domain + "\" + $DACL.Trustee.Name}
                else {$Trustee = $DACL.Trustee.Name}
                $AccessType = [Security.AccessControl.AceType]$DACL.AceType
                $FileSystemRights = $DACL.AccessMask -as [Security.AccessControl.FileSystemRights]
                "Trustee: $Trustee | Type: $AccessType | Permission: $FileSystemRights" | Out-File $outputFileName -Append
            }
        }    
    }
    "NTFS Permissions:" | Out-File $outputFileName -Append
    try {(Get-Acl $sharePath).Access | ft | Out-File $outputFileName -Append}
    catch {"No NTFS permissions were found." | Out-File $outputFileName -Append}
}

#########################################################
# Local and domain account policy
#########################################################

# get local+domain account policy
write-host Getting local and domain account policy... -ForegroundColor Yellow
$outputFileName = "$hostname\AccountPolicy_$hostname.txt"
"============= Local Account Policy =============" | Out-File $outputFileName -Append
"`nOutput of `"NET ACCOUNTS`" command:`n" | Out-File $outputFileName -Append
NET ACCOUNTS | Out-File $outputFileName -Append
# check if the computer is in a domain
"`n============= Domain Account Policy =============" | Out-File $outputFileName -Append
if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain)
{
    if (((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 2) -or (Test-ComputerSecureChannel))
    {
        "`nOutput of `"NET ACCOUNTS /domain`" command:`n" | Out-File $outputFileName -Append
        NET ACCOUNTS /domain | Out-File $outputFileName -Append
    }    
    else
        {"Error: No connection to the domain." | Out-File $outputFileName -Append}
}
else
    {"Error: The computer is not part of a domain." | Out-File $outputFileName -Append}


#########################################################
# List of local users
#########################################################

# get local users + admins
# only run if no running on a domain controller
$outputFileName = "$hostname\Local-Users_$hostname.txt"
if ((Get-WmiObject -Class Win32_OperatingSystem).ProductType -ne 2)
{
    write-host Getting local users + administrators... -ForegroundColor Yellow
    "============= Local Administrators =============" | Out-File $outputFileName -Append
    "`nOutput of `"NET LOCALGROUP administrators`" command:`n" | Out-File $outputFileName -Append
    NET LOCALGROUP administrators | Out-File $outputFileName -Append
    "`n============= Local Users =============" | Out-File $outputFileName -Append
    # Get-LocalUser exists only in Windows 10 / 2016
    try
    {
        "`nOutput of `"Get-LocalUser`" PowerShell command:`n" | Out-File $outputFileName -Append
        Get-LocalUser | ft name, enabled, AccountExpires, PasswordExpires, PasswordRequired, PasswordLastSet, LastLogon, description, SID | Out-String -Width 180 | Out-File $outputFileName -Append
    }
    catch
    {
        "`nGetting information regarding local users from WMI.`n" | Out-File $outputFileName -Append
        "Output of `"Get-CimInstance win32_useraccount -Namespace `"root\cimv2`" -Filter `"LocalAccount=`'$True`'`"`" PowerShell command:`n" | Out-File $outputFileName -Append
        Get-CimInstance win32_useraccount -Namespace "root\cimv2" -Filter "LocalAccount='$True'" | Select Caption,Disabled,Lockout,PasswordExpires,PasswordRequired,Description,SID | format-table -autosize | Out-String -Width 180 | Out-File $outputFileName -Append
    }
}

#########################################################
# SMB configuration
#########################################################
	
# check SMB protocol hardening
Write-Host Getting SMB hardening configuration... -ForegroundColor Yellow
$outputFileName = "$hostname\SMB_$hostname.txt"
"`n============= SMB versions Support (Server Settings) =============" | Out-File $outputFileName -Append
# Check if Windows Vista/2008 or above
if ($winVersion.Major -ge 6)
{
    $SMB1 = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters SMB1 -ErrorAction SilentlyContinue
    $SMB2 = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters SMB2 -ErrorAction SilentlyContinue
    $smbServerConfig = Get-SmbServerConfiguration
    $smbClientConfig = Get-SmbClientConfiguration
    if ($SMB1.SMB1 -eq 0)
        {"SMB1 Server is not supported (based on registry values). Which is nice." | Out-File $outputFileName -Append}
    else
        {"SMB1 Server is supported (based on registry values). Which is pretty bad and a finding." | Out-File $outputFileName -Append}
    if (!$smbConfig.EnableSMB1Protocol)
        {"SMB1 Server is not supported (based on Get-SmbServerConfiguration). Which is nice." | Out-File $outputFileName -Append}
    else
        {"SMB1 Server is supported (based on Get-SmbServerConfiguration). Which is pretty bad and a finding." | Out-File $outputFileName -Append}
    "---------------------------------------" | Out-File $outputFileName -Append
    if ($SMB2.SMB2 -eq 0)
        {"SMB2 and SMB3 Server are not supported (based on registry values). Which is weird, but not a finding." | Out-File $outputFileName -Append}
    else
        {"SMB2 and SMB3 Server are supported (based on registry values). Which is OK." | Out-File $outputFileName -Append}
    if (!$smbServerConfig.EnableSMB2Protocol)
        {"SMB2 Server is not supported (based on Get-SmbServerConfiguration). Which is weird, but not a finding." | Out-File $outputFileName -Append}
    else
        {"SMB2 Server is supported (based on Get-SmbServerConfiguration). Which is OK." | Out-File $outputFileName -Append}
}
else
{
    "Old Windows versions (XP or 2003) support only SMB1." | Out-File $outputFileName -Append
}
"`n============= SMB versions Support (Client Settings) =============" | Out-File $outputFileName -Append
# Check if Windows Vista/2008 or above
if ($winVersion.Major -ge 6)
{
    $SMB1Client = (sc.exe qc lanmanworkstation | ? {$_ -like "*START_TYPE*"}).split(":")[1][1]
    Switch ($SMB1Client)
    {
        "0" {"SMB1 Client is set to 'Boot'. Which is weird. Disabled is better." | Out-File $outputFileName -Append}
        "1" {"SMB1 Client is set to 'System'. Which is not weird. although disabled is better." | Out-File $outputFileName -Append}
        "2" {"SMB1 Client is set to 'Automatic' (Enabled). Which is not very good, a possible finding, but not a must." | Out-File $outputFileName -Append}
        "3" {"SMB1 Client is set to 'Manual' (Turned off, but can be started). Which is pretty good, although disabled is better." | Out-File $outputFileName -Append}
        "4" {"SMB1 Client is set to 'Disabled'. Which is nice." | Out-File $outputFileName -Append}
    }
}
else
{
    "Old Windows versions (XP or 2003) support only SMB1." | Out-File $outputFileName -Append
}
"`n============= SMB Signing (Server Settings) =============" | Out-File $outputFileName -Append
$SmbServerRequireSigning = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters RequireSecuritySignature
$SmbServerSupportSigning = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters EnableSecuritySignature
if ($SmbServerRequireSigning.RequireSecuritySignature -eq 1)
{
    "Microsoft network server: Digitally sign communications (always) = Enabled" | Out-File $outputFileName -Append
    "SMB signing is required by the server, Which is good." | Out-File $outputFileName -Append
}
else
{
    if ($SmbServerSupportSigning.EnableSecuritySignature -eq 1)
    {
        "Microsoft network server: Digitally sign communications (always) = Disabled" | Out-File $outputFileName -Append
        "Microsoft network server: Digitally sign communications (if client agrees) = Enabled" | Out-File $outputFileName -Append
        "SMB signing is enabled by the server, but not required. Clients of this server are susceptible to man-in-the-middle attacks, if they don't require signing. A possible finding." | Out-File $outputFileName -Append
    }
    else
    {
        "Microsoft network server: Digitally sign communications (always) = Disabled." | Out-File $outputFileName -Append
        "Microsoft network server: Digitally sign communications (if client agrees) = Disabled." | Out-File $outputFileName -Append
        "SMB signing is disabled by the server. Clients of this server are susceptible to man-in-the-middle attacks. A finding." | Out-File $outputFileName -Append
    }
}
# potentially, we can also check SMB signing configuration using PowerShell:
<#if ($smbServerConfig -ne $null)
{
    "---------------------------------------" | Out-File $outputFileName -Append
    "Get-SmbServerConfiguration SMB server-side signing details:" | Out-File $outputFileName -Append
    $smbServerConfig | fl *sign* | Out-File $outputFileName -Append
}#>
"`n============= SMB Signing (Client Settings) =============" | Out-File $outputFileName -Append
$SmbClientRequireSigning = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters RequireSecuritySignature
$SmbClientSupportSigning = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters EnableSecuritySignature
if ($SmbClientRequireSigning.RequireSecuritySignature -eq 1)
{
    "Microsoft network client: Digitally sign communications (always) = Enabled" | Out-File $outputFileName -Append
    "SMB signing is required by the client, Which is good." | Out-File $outputFileName -Append
}
else
{
    if ($SmbClientSupportSigning.EnableSecuritySignature -eq 1)
    {
        "Microsoft network client: Digitally sign communications (always) = Disabled" | Out-File $outputFileName -Append
        "Microsoft network client: Digitally sign communications (if client agrees) = Enabled" | Out-File $outputFileName -Append
        "SMB signing is enabled by the client, but not required. This computer is susceptible to man-in-the-middle attacks against servers that don't require signing. A possible finding." | Out-File $outputFileName -Append
    }
    else
    {
        "Microsoft network client: Digitally sign communications (always) = Disabled." | Out-File $outputFileName -Append
        "Microsoft network client: Digitally sign communications (if client agrees) = Disabled." | Out-File $outputFileName -Append
        "SMB signing is disabled by the client. This computer is susceptible to man-in-the-middle attacks. A finding." | Out-File $outputFileName -Append
    }
}
if (($smbServerConfig -ne $null) -and ($smbClientConfig -ne $null)) {
    # potentially, we can also check SMB signing configuration using PowerShell:
    <#"---------------------------------------" | Out-File $outputFileName -Append
    "Get-SmbClientConfiguration SMB client-side signing details:" | Out-File $outputFileName -Append
    $smbClientConfig | fl *sign* | Out-File $outputFileName -Append #>
    "`n============= Raw Data - Get-SmbServerConfiguration =============" | Out-File $outputFileName -Append
    $smbServerConfig | Out-File $outputFileName -Append
    "`n============= Raw Data - Get-SmbClientConfiguration =============" | Out-File $outputFileName -Append
    $smbClientConfig | Out-File $outputFileName -Append
}

#########################################################
# RDP settings
#########################################################


# Getting RDP security settings
Write-Host Getting RDP security settings... -ForegroundColor Yellow
$outputFileName = "$hostname\RDP_$hostname.txt"
"============= Raw RDP Settings (from WMI) =============" | Out-File $outputFileName -Append
$WMIFilter = "TerminalName='RDP-tcp'" # there might be issues with the quotation marks - to debug
$RDP = Get-WmiObject -class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -Filter $WMIFilter
$RDP | fl Terminal*,*Encrypt*, Policy*,Security*,SSL*,*Auth* | Out-File $outputFileName -Append
"`n============= NLA (Network Level Authentication) =============" | Out-File $outputFileName -Append
if ($RDP.UserAuthenticationRequired -eq 1)
    {"NLA is required, which is fine." | Out-File $outputFileName -Append}
if ($RDP.UserAuthenticationRequired -eq 0)
    {"NLA is not required, which is bad. A possible finding." | Out-File $outputFileName -Append}
"`n============= Security Layer (SSL/TLS) =============" | Out-File $outputFileName -Append
if ($RDP.SecurityLayer -eq 0)
    {"Native RDP encryption is used instead of SSL/TLS, which is bad. A possible finding." | Out-File $outputFileName -Append}
if ($RDP.SecurityLayer -eq 1)
    {"SSL/TLS is supported, but not required ('Negotiate' setting). Which is not recommended, but not necessary a finding." | Out-File $outputFileName -Append}
if ($RDP.SecurityLayer -eq 2)
    {"SSL/TLS is required for connecting. Which is good." | Out-File $outputFileName -Append}
"`n============= Raw RDP Timeout Settings (from Registry) =============" | Out-File $outputFileName -Append
$RDPTimeout = Get-Item "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services" 
if ($RDPTimeout.ValueCount -eq 0)
    {"RDP timeout is not configured. A possible finding." | Out-File $outputFileName -Append}
else
{
    "The following RDP timeout properties were configured:" | Out-File $outputFileName -Append
    $RDPTimeout | Out-File $outputFileName -Append
    "`nMaxConnectionTime = Time limit for active RDP sessions" | Out-File $outputFileName -Append
    "MaxIdleTime = Time limit for active but idle RDP sessions" | Out-File $outputFileName -Append
    "MaxDisconnectionTime = Time limit for disconnected RDP sessions" | Out-File $outputFileName -Append
    "fResetBroken = Log off session (instead of disconnect) when time limits are reached" | Out-File $outputFileName -Append
    "60000 = 1 minute, 3600000 = 1 hour, etc." | Out-File $outputFileName -Append
    "`nFor further information, see the GPO settings at: Computer Configuration\Administrative Templates\Windows Components\Remote Desktop Services\Remote Desktop Session\Session Time Limits" | Out-File $outputFileName -Append
}


#########################################################
# Local Security Authority (LSA) protection
# https://docs.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection
#########################################################

# getting LSA protection configuration (for Windows 8.1 and above only)
$outputFileName = "$hostname\LSA-Protection_$hostname.txt"
if (($winVersion.Major -ge 10) -or (($winVersion.Major -eq 6) -and ($winVersion.Minor -eq 3)))
{
    Write-Host Getting LSA protection settings... -ForegroundColor Yellow
    $RunAsPPL = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" RunAsPPL -ErrorAction SilentlyContinue
    if ($RunAsPPL -eq $null)
        {"RunAsPPL registry value does not exists. LSA protection is off . Which is bad and a possible finding." | Out-File $outputFileName -Append}
    else
    {
        "RunAsPPL registry value is: " +$RunAsPPL.RunAsPPL | Out-File $outputFileName -Append
        if ($RunAsPPL.RunAsPPL -eq 1)
            {"LSA protection is on. Which is good." | Out-File $outputFileName -Append}
        else
            {"LSA protection is off. Which is bad and a possible finding." | Out-File $outputFileName -Append}
    }
}

#########################################################
# Check sensitive information (e.g., plain text PW)
#########################################################

# search for sensitive information (i.e. cleartext passwords) if the flag exists
$outputFileName = "$hostname\Sensitive-Info_$hostname.txt"
if ($EnableSensitiveInfoSearch)
{
    write-host Searching for sensitive information... -ForegroundColor Yellow
    "============= Looking for clear-text passwords =============" | Out-File $outputFileName -Append
    # recursive searches in c:\temp, current user desktop, default IIS website root folder
    # add any other directory that you want. searching in C:\ may take a while.
    $paths = "C:\Temp",[Environment]::GetFolderPath("Desktop"),"c:\Inetpub\wwwroot"
    foreach ($path in $paths)
    {
        "`n============= recursive search in $path =============" | Out-File $outputFileName -Append
        # find txt\ini\config\xml\vnc files with the word password in it, and dump the line
        # ignore the files outputted during the assessment...
        $includeFileTypes = @("*.txt","*.ini","*.config","*.xml","*vnc*")
        Get-ChildItem -Path $path -Include $includeFileTypes -Attributes !System -File -Recurse -ErrorAction SilentlyContinue | ? {$_.Name -notlike "*_$hostname.txt"} | Select-String -Pattern password | Out-File $outputFileName -Append
        # find files with the name pass\cred\config\vnc\p12\pfx and dump the whole file, unless it is too big
        # ignore the files outputted during the assessment...
        $includeFilePatterns = @("*pass*","*cred*","*config","*vnc*","*p12","*pfx")
        $files = Get-ChildItem -Path $path -Include $includeFilePatterns -Attributes !System -File -Recurse -ErrorAction SilentlyContinue | ? {$_.Name -notlike "*_$hostname.txt"}
        foreach ($file in $files)
        {
            "------------- $file -------------" | Out-File $outputFileName -Append
            $fileSize = (Get-Item $file.FullName).Length
            if ($fileSize -gt 300kb) {"The file is too large to copy (" + [math]::Round($filesize/(1mb),2) + " MB)." | Out-File $outputFileName -Append}
            else {cat $file.FullName | Out-File $outputFileName -Append}
        }
    }
}

#########################################################
# AV info
#########################################################

# get anti-virus status
# works only on Windows Clients, Not on Servers (2008, 2012, etc.). Maybe the "Get-MpPreference" could work on servers - wasn't tested.
$outputFileName = "$hostname\Antivirus_$hostname.txt"
if ((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 1)
{
    write-host Getting Anti-Virus status... -ForegroundColor Yellow
    if ($winVersion.Major -ge 6)
    {
        $AntiVirusProducts = Get-WmiObject -Namespace root\SecurityCenter2 -Class AntiVirusProduct
        $FirewallProducts = Get-WmiObject -Namespace root\SecurityCenter2 -Class FirewallProduct
        $AntiSpywareProducts = Get-WmiObject -Namespace root\SecurityCenter2 -Class AntiSpywareProduct
        "`nSecurity products status was taken from WMI values on WMI namespace `"root\SecurityCenter2`".`n" | Out-File $outputFileName -Append
    }
    else
    {
        $AntiVirusProducts = Get-WmiObject -Namespace root\SecurityCenter -Class AntiVirusProduct
        $FirewallProducts = Get-WmiObject -Namespace root\SecurityCenter -Class FirewallProduct
        $AntiSpywareProducts = Get-WmiObject -Namespace root\SecurityCenter -Class AntiSpywareProduct
        "`nSecurity products status was taken from WMI values on WMI namespace `"root\SecurityCenter`".`n" | Out-File $outputFileName -Append
    }
    if ($AntiVirusProducts -eq $null)
        {"No Anti Virus products were found." | Out-File $outputFileName -Append}
    "`n============= Anti-Virus Products Status =============" | Out-File $outputFileName -Append
    foreach ($av in $AntiVirusProducts)
    {    
        "`nProduct Display name: " + $av.displayname | Out-File $outputFileName -Append
        "Product Executable: " + $av.pathToSignedProductExe | Out-File $outputFileName -Append
        "Time Stamp: " + $av.timestamp | Out-File $outputFileName -Append
        "Product (raw) state: " + $av.productState | Out-File $outputFileName -Append
        # check the product state
        $hx = '0x{0:x}' -f $av.productState
        if ($hx.Substring(3,2) -match "00|01")
            {"AntiVirus is NOT enabled" | Out-File $outputFileName -Append}
        else
            {"AntiVirus is enabled" | Out-File $outputFileName -Append}
        if ($hx.Substring(5) -eq "00")
            {"Virus definitions are up to date" | Out-File $outputFileName -Append}
        else
            {"Virus definitions are NOT up to date" | Out-File $outputFileName -Append}
    }
    "`n============= Anti-Virus Products Status (Raw Data) =============" | Out-File $outputFileName -Append
    $AntiVirusProducts | Out-File $outputFileName -Append
    "`n============= Firewall Products Status (Raw Data) =============" | Out-File $outputFileName -Append
    $FirewallProducts | Out-File $outputFileName -Append
    "`n============= Anti-Spyware Products Status (Raw Data) =============" | Out-File $outputFileName -Append
    $AntiSpywareProducts | Out-File $outputFileName -Append
    # check Windows Defender settings
    "`n============= Windows Defender Settings Status =============`n" | Out-File $outputFileName -Append
    $WinDefenderSettings = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager"
    switch ($WinDefenderSettings.AllowRealtimeMonitoring)
    {
        $null {"AllowRealtimeMonitoring registry value was not found." | Out-File $outputFileName -Append}
        0 {"Windows Defender Real Time Monitoring is off." | Out-File $outputFileName -Append}
        1 {"Windows Defender Real Time Monitoring is on." | Out-File $outputFileName -Append}
    }
    switch ($WinDefenderSettings.EnableNetworkProtection)
    {
        $null {"EnableNetworkProtection registry value was not found." | Out-File $outputFileName -Append}
        0 {"Windows Defender Network Protection is off." | Out-File $outputFileName -Append}
        1 {"Windows Defender Network Protection is on." | Out-File $outputFileName -Append}
        2 {"Windows Defender Network Protection is set to audit mode." | Out-File $outputFileName -Append}
    }
    "`n---------------------------------" | Out-File $outputFileName -Append
    "`nValues under HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager:" | Out-File $outputFileName -Append
     $WinDefenderSettings | Out-File $outputFileName -Append
     "`n---------------------------------" | Out-File $outputFileName -Append
     "`nRaw output of Get-MpPreference (Defender settings):" | Out-File $outputFileName -Append
     $MpPreference = Get-MpPreference
     $MpPreference | Out-File $outputFileName -Append
     "`n---------------------------------" | Out-File $outputFileName -Append
     $MpComputerStatus = Get-MpComputerStatus
     "`nEnabled Defender features:" | Out-File $outputFileName -Append
     $MpComputerStatus | fl *enabled* | Out-File $outputFileName -Append
     "`nDefender Tamper Protection:" | Out-File $outputFileName -Append
     $MpComputerStatus | fl *tamper* | Out-File $outputFileName -Append
     "`nRaw output of Get-MpComputerStatus:" | Out-File $outputFileName -Append
     $MpComputerStatus | Out-File $outputFileName -Append
     "`n---------------------------------" | Out-File $outputFileName -Append
     "`nAttack Surface Reduction Rules Ids:" | Out-File $outputFileName -Append
     $MpPreference.AttackSurfaceReductionRules_Ids | Out-File $outputFileName -Append
     "`nAttack Surface Reduction Rules Actions:" | Out-File $outputFileName -Append
     $MpPreference.AttackSurfaceReductionRules_Actions | Out-File $outputFileName -Append
     "`nAttack Surface Reduction Only Exclusions:" | Out-File $outputFileName -Append
     $MpPreference.AttackSurfaceReductionOnlyExclusions | Out-File $outputFileName -Append
}


#########################################################
# FW info
#########################################################

# get Windows Firewall configuration
Write-Host Getting Windows Firewall configuration... -ForegroundColor Yellow
$outputFileName = "$hostname\Windows-Firewall_$hostname.txt"
if ((Get-Service mpssvc).status -eq "Running")
{
    "The Windows Firewall service is running." | Out-File $outputFileName -Append
    # The NetFirewall commands are supported from Windows 8/2012 (version 6.2)
    if (($winVersion.Major -gt 6) -or (($winVersion.Major -eq 6) -and ($winVersion.Minor -ge 2))) # version should be 6.2+
    { 
        "`n----------------------------------`n" | Out-File $outputFileName -Append
        "The output of Get-NetFirewallProfile is:`n" | Out-File $outputFileName -Append
        Get-NetFirewallProfile -PolicyStore ActiveStore | Out-File $outputFileName -Append    
        "`n----------------------------------`n" | Out-File $outputFileName -Append
        "The output of Get-NetFirewallRule can be found in the Windows-Firewall-Rules CSV file. No port and IP information there." | Out-File $outputFileName -Append
        Get-NetFirewallRule -PolicyStore ActiveStore | Export-Csv $hostname\Windows-Firewall-Rules_$hostname.csv -NoTypeInformation
    }
    if ($runningAsAdmin)
    {
        "`n----------------------------------`n" | Out-File $outputFileName -Append
        netsh advfirewall export "$hostname\Windows_Firewall_Rules_$hostname.wfw" | Out-Null
        "Firewall rules exported into Windows_Firewall_Rules_$hostname.wfw" | Out-File $outputFileName -Append
        "To view it, open gpmc.msc in a test environment, create a temporary GPO, get to Computer=>Policies=>Windows Settings=>Security Settings=>Windows Firewall=>Right click on Firewall icon=>Import Policy" | Out-File $outputFileName -Append
    }
}
else
{
    "The Windows Firewall service is not running." | Out-File $outputFileName -Append
}


#########################################################
# 1) check Link-Local Multicast Name Resolution (LLMNR)
# 2) check NETBIOS-NS 
# * Both are insecure
#########################################################

# check if LLMNR and NETBIOS-NS are enabled
# LLMNR and NETBIOS-NS are insecure legacy protocols for local multicast DNS queries that can be abused by Responder/Inveigh
Write-Host Getting LLMNR and NETBIOS-NS configuration... -ForegroundColor Yellow
$outputFileName = "$hostname\LLMNR_and_NETBIOS_$hostname.txt"
"============= LLMNR Configuration =============" | Out-File $outputFileName -Append
"`nGPO Setting: Computer Configuration -> Administrative Templates -> Network -> DNS Client -> Enable Turn Off Multicast Name Resolution" | Out-File $outputFileName -Append
$LLMNR = Get-ItemProperty "HKLM:\Software\policies\Microsoft\Windows NT\DNSClient" EnableMulticast -ErrorAction SilentlyContinue
$LLMNR_Enabled = $LLMNR.EnableMulticast
"`nRegistry Setting: `"HKLM:\Software\policies\Microsoft\Windows NT\DNSClient`" -> EnableMulticast = $LLMNR_Enabled" | Out-File $outputFileName -Append
if ($LLMNR_Enabled -eq 0)
    {"`nLLMNR is disabled, which is secure." | Out-File $outputFileName -Append}
else
    {"`nLLMNR is enabled, which is a finding, especially for workstations." | Out-File $outputFileName -Append}
"`n============= NETBIOS Name Service Configuration =============" | Out-File $outputFileName -Append
"`nChecking the NETBIOS Node Type configuration - see 'https://getadmx.com/?Category=KB160177#' for details...`n" | Out-File $outputFileName -Append
$NodeType = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters" NodeType -ErrorAction SilentlyContinue).NodeType
if ($NodeType -eq 2)
    {"NetBIOS Node Type is set to P-node (only point-to-point name queries to a WINS name server), which is secure." | Out-File $outputFileName -Append}
else
{
    switch ($NodeType)
    {
        $null {"NetBIOS Node Type is set to the default setting (broadcast queries), which is not secure and a finding." | Out-File $outputFileName -Append}
        1 {"NetBIOS Node Type is set to B-node (broadcast queries), which is not secure and a finding." | Out-File $outputFileName -Append}
        4 {"NetBIOS Node Type is set to M-node (broadcasts first, then queries the WINS name server), which is not secure and a finding." | Out-File $outputFileName -Append}
        8 {"NetBIOS Node Type is set to H-node (queries the WINS name server first, then broadcasts), which is not secure and a finding." | Out-File $outputFileName -Append}        
    }

    "`nChecking the NETBIOS over TCP/IP configuration for each network interface." | Out-File $outputFileName -Append
    "`nNetwork interface properties -> IPv4 properties -> Advanced -> WINS -> NetBIOS setting" | Out-File $outputFileName -Append
    "`nNetbiosOptions=0 is default, and usually means enabled, which is not secure and a possible finding." | Out-File $outputFileName -Append
    "NetbiosOptions=1 is enabled, which is not secure and a possible finding." | Out-File $outputFileName -Append
    "NetbiosOptions=2 is disabled, which is secure." | Out-File $outputFileName -Append
    "If NetbiosOptions is set to 2 for the main interface, NetBIOS Name Service is protected against poisoning attacks even though the NodeType is not set to P-node, and this is not a finding." | Out-File $outputFileName -Append
    $interfaces = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_*" NetbiosOptions -ErrorAction SilentlyContinue
    $interfaces | select PSChildName,NetbiosOptions | Out-File $outputFileName -Append
}


#########################################################
# lsass memory check: cleartext PW
#########################################################

# check if cleartext credentials are saved in lsass memory for WDigest
# turned on by default for Win7/2008/8/2012, to fix it you must install kb2871997 and than fix the registry value below
# turned off by default for Win8.1/2012R2 and above
write-host Getting WDigest credentials configuration... -ForegroundColor Yellow
$outputFileName = "$hostname\WDigest_$hostname.txt"
"============= WDigest Configuration =============" | Out-File $outputFileName -Append
$WDigest = Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\SecurityProviders\WDigest" UseLogonCredential -ErrorAction SilentlyContinue
if ($WDigest -eq $null)
{
    "`nWDigest UseLogonCredential registry value wasn't found." | Out-File $outputFileName -Append
    # check if running on Windows 6.3 or above
    if (($winVersion.Major -ge 10) -or (($winVersion.Major -eq 6) -and ($winVersion.Minor -eq 3)))
        {"`nThe WDigest protocol is turned off by default for Win8.1/2012R2 and above. So it is OK, but still recommended to set the UseLogonCredential registry value to 0, to revert malicious attempts of enabling WDigest." | Out-File $outputFileName -Append}
    else
    {
        # check if running on Windows 6.1/6.2, which can be hardened, or on older version
        if (($winVersion.Major -eq 6) -and ($winVersion.Minor -ge 1))    
            {"`nWDigest stores cleartext user credentials in memory by default in Win7/2008/8/2012. A possible finding." | Out-File $outputFileName -Append}
        else
            {"`nThe operating system version is not supported. You have worse problems than WDigest configuration." | Out-File $outputFileName -Append}
            {"`nWDigest stores cleartext user credentials in memory by default, but this configuration cannot be hardened since it is a legacy OS." | Out-File $outputFileName -Append}
    }
}
else
{    
    if ($WDigest.UseLogonCredential -eq 0)
    {
        "`nWDigest UseLogonCredential registry key set to 0." | Out-File $outputFileName -Append
        "`nWDigest doesn't store cleartext user credentials in memory, which is good. The setting was intentionally hardened." | Out-File $outputFileName -Append
    }
    if ($WDigest.UseLogonCredential -eq 1)
    {
        "`nWDigest UseLogonCredential registry key set to 1." | Out-File $outputFileName -Append
        "`nWDigest stores cleartext user credentials in memory, which is bad and a finding. The configuration was either intentionally configured by an admin for some reason, or was set by a threat actor to fetch clear-text credentials." | Out-File $outputFileName -Append
    }
}


#########################################################
# Net Session enumeration permissions
#########################################################

# check for Net Session enumeration permissions
write-host Getting NetSession configuration... -ForegroundColor Yellow
$outputFileName = "$hostname\NetSession_$hostname.txt"
"============= NetSession Configuration =============" | Out-File $outputFileName -Append
"By default, on Windows 2016 (and below) and old builds of Windows 10, any authenticated user can enumerate the SMB sessions on a computer, which is a major vulnerability mainly on Domain Controllers, enabling valuable reconnaissance, as leveraged by BloodHound." | Out-File $outputFileName -Append
"`nSee more details here:" | Out-File $outputFileName -Append
"https://gallery.technet.microsoft.com/Net-Cease-Blocking-Net-1e8dcb5b" | Out-File $outputFileName -Append
"https://www.powershellgallery.com/packages/NetCease/1.0.3" | Out-File $outputFileName -Append
"`n--------- Security Descriptor Check ---------" | Out-File $outputFileName -Append
# copied from Get-NetSessionEnumPermission
"Below are the permissions granted to enumerate net sessions." | Out-File $outputFileName -Append
"If the Authenticated Users group has permissions, this is a finding.`n" | Out-File $outputFileName -Append
$SessionRegValue = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity SrvsvcSessionInfo).SrvsvcSessionInfo
$SecurityDesc = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList ($true,$false,$SessionRegValue,0)
$SecurityDesc.DiscretionaryAcl | ForEach-Object {$_ | Add-Member -MemberType ScriptProperty -Name TranslatedSID -Value ({$this.SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value}) -PassThru} | Out-File $outputFileName -Append
"`n--------- Raw Registry Value Check ---------" | Out-File $outputFileName -Append
"For comparison, below are the beggining of example values of the SrvsvcSessionInfo registry key, which holds the ACL for NetSessionEnum:" | Out-File $outputFileName -Append
"Default value for Windows 2019 and newer builds of Windows 10 (hardened): 1,0,4,128,160,0,0,0,172" | Out-File $outputFileName -Append
"Default value for Windows 2016, older builds of Windows 10 and older OS versions (not secure - finding): 1,0,4,128,120,0,0,0,132" | Out-File $outputFileName -Append
"Value after running NetCease (hardened): 1,0,4,128,20,0,0,0,32" | Out-File $outputFileName -Append
"`nThe SrvsvcSessionInfo registry value under HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity is set to:" | Out-File $outputFileName -Append
$SessionRegValue | Out-File $outputFileName -Append


#########################################################
# SAM enumeration permissions
#########################################################

# check for SAM enumeration permissions
write-host Getting SAM enumeration configuration... -ForegroundColor Yellow
$outputFileName = "$hostname\SAM-Enumeration_$hostname.txt"
"============= Remote SAM (SAMR) Configuration =============" | Out-File $outputFileName -Append
"`nBy default, in Windows 2016 (and above) and Windows 10 build 1607 (and above), only Administrators are allowed to make remote calls to SAM with the SAMRPC protocols, and (among other things) enumerate the members of the local groups." | Out-File $outputFileName -Append
"However, in older OS versions, low privileged domain users can also query the SAM with SAMRPC, which is a major vulnerability mainly on non-Domain Contollers, enabling valuable reconnaissance, as leveraged by BloodHound." | Out-File $outputFileName -Append
"These old OS versions (Windows 7/2008R2 and above) can be hardened by installing a KB and configuring only the Local Administrators group in the following GPO policy: 'Network access: Restrict clients allowed to make remote calls to SAM'." | Out-File $outputFileName -Append
"The newer OS versions are also recommended to be configured with the policy, though it is not essential." | Out-File $outputFileName -Append
"`nSee more details here:" | Out-File $outputFileName -Append
"https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-access-restrict-clients-allowed-to-make-remote-sam-calls" | Out-File $outputFileName -Append
"https://blog.stealthbits.com/making-internal-reconnaissance-harder-using-netcease-and-samri1o" | Out-File $outputFileName -Append
"`n----------------------------------------------------" | Out-File $outputFileName -Append

$RestrictRemoteSAM = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Lsa RestrictRemoteSAM -ErrorAction SilentlyContinue
if ($RestrictRemoteSAM -eq $null)
{
    "`nThe 'RestrictRemoteSAM' registry value was not found. SAM enumeration permissions are configured as the default for the OS version, which is $winVersion." | Out-File $outputFileName -Append
    if (($winVersion.Major -ge 10) -and ($winVersion.Build -ge 14393))
        {"This OS version is hardened by default." | Out-File $outputFileName -Append}
    else
        {"This OS version is not hardened by default and this issue can be seen as a finding." | Out-File $outputFileName -Append}
}
else
{
    $RestrictRemoteSAMValue = $RestrictRemoteSAM.RestrictRemoteSAM
    "`nThe 'RestrictRemoteSAM' registry value is set to: $RestrictRemoteSAMValue" | Out-File $outputFileName -Append
    $RestrictRemoteSAMPermissions = ConvertFrom-SDDLString -Sddl $RestrictRemoteSAMValue
    "`nBelow are the permissions for SAM enumeration. Make sure that only Administrators are granted Read permissions." | Out-File $outputFileName -Append
    $RestrictRemoteSAMPermissions | Out-File $outputFileName -Append
}


#########################################################
# (insecure) PowerShell v2 installation
#########################################################

# check for PowerShell v2 installation, which lacks security features (logging, AMSI)
write-host Getting PowerShell versions... -ForegroundColor Yellow
$outputFileName = "$hostname\PowerShell-Versions_$hostname.txt"
"PowerShell 1/2 are legacy versions which don't support logging and AMSI." | Out-File $outputFileName -Append
"It's recommended to uninstall legacy PowerShell versions and make sure that only PowerShell 5+ is installed." | Out-File $outputFileName -Append
"See the following article for details on PowerShell downgrade attacks: https://www.leeholmes.com/blog/2017/03/17/detecting-and-preventing-powershell-downgrade-attacks" | Out-File $outputFileName -Append
"`nThis script is running on PowerShell version " + $PSVersionTable.PSVersion.ToString() | Out-File $outputFileName -Append
# Checking if PowerShell Version 2/5 are installed, by trying to run command (Get-Host) with PowerShellv2 and v5 Engine.
"`n============= Running Test Commands =============" | Out-File $outputFileName -Append
try
{
    $temp = Start-Job {Get-Host} -PSVersion 2.0 -Name "PSv2Check"
    "PowerShell version 2 is installed and was able to run commands. This is a finding!" | Out-File $outputFileName -Append
}
catch
{
    "PowerShell version 2 was not able to run. This is secure." | Out-File $outputFileName -Append
}
finally
{
    Get-Job | Remove-Job -Force
}
# same as above, for PSv5
try
{
    $temp = Start-Job {Get-Host} -PSVersion 5.0 -Name "PSv5Check"
    "PowerShell version 5 is installed and was able to run commands." | Out-File $outputFileName -Append
}
catch
{
    "PowerShell version 5 was not able to run." | Out-File $outputFileName -Append
}
finally
{
    Get-Job | Remove-Job -Force
}
# use Get-WindowsFeature if running on Windows SERVER 2008R2 or above
if (($winVersion.Major -ge 7) -or (($winVersion.Major -ge 6) -and ($winVersion.Minor -ge 1))) # version should be 7+ or 6.1+
{
    if (((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 2) -or ((Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq 3)) # type should be server or DC
    {
        "`n============= Checking if PowerShell 2 Windows Feature is enabled with Get-WindowsFeature =============" | Out-File $outputFileName -Append
        Get-WindowsFeature -Name PowerShell-V2 | Out-File $outputFileName -Append
    }    
}
# use Get-WindowsOptionalFeature if running on Windows 8/2012 or above, and running as admin
if (($winVersion.Major -gt 6) -or (($winVersion.Major -eq 6) -and ($winVersion.Minor -ge 2))) # version should be 6.2+
{    
    "`n============= Checking if PowerShell 2 Windows Feature is enabled with Get-WindowsOptionalFeature =============" | Out-File $outputFileName -Append
    if ($runningAsAdmin)
    {
        Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShell* | ft DisplayName, State -AutoSize | Out-File $outputFileName -Append
    }
    else
    {
        "Cannot run Get-WindowsOptionalFeature when non running as admin." | Out-File $outputFileName -Append
    }
}
# run registry check
"`n============= Registry Check =============" | Out-File $outputFileName -Append
"Based on the registry value described in the following article:" | Out-File $outputFileName -Append
"https://devblogs.microsoft.com/powershell/detection-logic-for-powershell-installation" | Out-File $outputFileName -Append
$LegacyPowerShell = Get-ItemProperty "HKLM:\Software\Microsoft\PowerShell\1\PowerShellEngine" PowerShellVersion -ErrorAction SilentlyContinue
if (($LegacyPowerShell.PowerShellVersion -eq "2.0") -or ($LegacyPowerShell.PowerShellVersion -eq "1.0"))
{
    "PowerShell version " + $LegacyPowerShell.PowerShellVersion + " is installed, based on the registry value mentioned above." | Out-File $outputFileName -Append
}
else
{
    "PowerShell version 1/2 is not installed." | Out-File $outputFileName -Append
}




#########################################################
# Finishing up the script
#########################################################

$currTime = Get-Date
$outputFileName = "$hostname\Log_$hostname.txt"
"Script End Time (before zipping): " + $currTime.ToString("dd/MM/yyyy HH:mm:ss")  | Out-File $outputFileName -Append
"Total Running Time (before zipping): " + [int]($currTime - $startTime).TotalSeconds + " seconds"  | Out-File $outputFileName -Append

# compress the files to a zip. works for PowerShell 5.0 (Windows 10/2016) only. sometimes the compress fails because the file is still in use.
try
{
    Compress-Archive -Path $hostname\* -DestinationPath $hostname -Force -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force -Path $hostname -ErrorAction SilentlyContinue
    Write-Host All Done! Please send the output ZIP file. -ForegroundColor Green
}
catch
{
    Write-Host All Done! Please ZIP all the files and send it back. -ForegroundColor Green
}

$endTime = Get-Date
$elapsed = $endTime - $startTime
Write-Host The script took ([int]$elapsed.TotalSeconds) seconds. Thank you. -ForegroundColor Green
Start-Sleep -Seconds 2
