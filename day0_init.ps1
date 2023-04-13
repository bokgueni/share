$mft = 'C:\$MFT'
$work_path = "C:\MFT"
$out_name = $env:COMPUTERNAME + "_day0.csv"

Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/MFT.zip -OutFile MFT.zip

Expand-Archive -LiteralPath .\MFT.zip -DestinationPath $work_path

C:\MFT\dotnet-runtime-6.0.15-win-x64.exe /install /passive /norestart
C:\MFT\forecopy.exe -f $mft $work_path
C:\MFT\MFTECmd\MFTECmd.exe -f 'C:\MFT\$MFT' --csv $work_path --csvf $out_name


Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/OpenSSH-Win64.zip -OutFile OpenSSH-Win64.zip

Expand-Archive OpenSSH-Win64.zip -DestinationPath .\ -Force

if ((Get-Service -Name sshd -ErrorAction SilentlyContinue).Length -gt 0) {
    Write-Output "OpenSSH is already installed, uninstall sshd."
    & 'C:\Program Files\OpenSSH-Win64\uninstall-sshd.ps1'
    
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