Set-ExecutionPolicy Bypass -Force

# set ssh key
$ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGlz+ylWm+INl2uRj61fovI8ihshgnqhlqkvzGI37ns BEG13_BLUE@LS24"

# Download ssh install file
Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/OpenSSH-Win64.zip -OutFile OpenSSH-Win64.zip
Expand-Archive OpenSSH-Win64.zip -DestinationPath .\ -Force

# Start ssh install
if ((Get-Service -Name sshd -ErrorAction SilentlyContinue).Length -gt 0) {
    Write-Output "OpenSSH is already installed, uninstall sshd."
    & 'C:\Program Files\OpenSSH-Win64\uninstall-sshd.ps1'
    Stop-Process -Name sshd -Force
    
    Write-Output "Overwrite our files"
    Copy-Item .\OpenSSH-Win64\* -Destination "C:\Program Files\OpenSSH-Win64" -Force

    Write-Output "Add our key to the authorized_keys file"
    echo '' | Add-Content -Encoding UTF8 C:\Users\Administrator\.ssh\authorized_keys
    echo "$ssh_key" | Add-Content -Encoding UTF8 C:\Users\Administrator\.ssh\authorized_keys
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
    echo "$ssh_key" | Set-Content -Encoding UTF8 C:\ProgramData\ssh\administrators_authorized_keys

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
        New-NetFirewallRule -Name 'sshd' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    }

}


# set ret ssh default terminal
$keyPath = "HKLM:\SOFTWARE\OpenSSH"
$valueName = "defaultshell"
$newValue = "C:\windows\system32\cmd.exe"
New-ItemProperty -Path $keyPath -Name $valueName -Value $newValue -PropertyType String -Force | Out-Null

# Remove WDAC
$efi_path = 'S:\EFI\Microsoft\Boot'
if (Test-Path $efi_path) {
    Remove-Item -path C:\Windows\System32\CodeIntegrity\SiPolicy.p7b -Force
    Remove-Item -path C:\Windows\System32\CodeIntegrity\CiPolicies -recurse -Force
    Remove-Item -path C:\Windows\System32\CodeIntegrity\Tokens -recurse -Force
    Remove-Item -path S:\EFI\Microsoft\Boot -recurse -Force
    Write-Output "WDAC configuration file delete complete. Reobot..."
    Restart-Computer
}
else {
    Write-Output "WDAC configuration file does not exist."
}

