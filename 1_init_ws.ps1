
# set ssh key
Add-Content -Path C:\Users\Administrator\.ssh\authorized_keys -Value "`r`nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGlz+ylWm+INl2uRj61fovI8ihshgnqhlqkvzGI37ns BEG13_BLUE@LS24"

Stop-Service sshd
Start-Service sshd

# set ret ssh default terminal
$keyPath = "HKLM:\SOFTWARE\OpenSSH"
$valueName = "defaultshell"
$newValue = "C:\windows\system32\cmd.exe"
New-ItemProperty -Path $keyPath -Name $valueName -Value $newValue -PropertyType String -Force | Out-Null


# Download anslible tools
Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/ansible_tools.zip.0.part -OutFile ansible_tools.zip.0.part
Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/ansible_tools.zip.1.part -OutFile ansible_tools.zip.1.part
Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/ansible_tools.zip.2.part -OutFile ansible_tools.zip.2.part

& cmd.exe /c copy /b .\ansible_tools.zip.* .\ansible_tools.zip

Expand-Archive ansible_tools.zip -DestinationPath c:\Users\Administrator\ansible_tools\ -Force

Remove-Item ansible_tools.zip.0.part
Remove-Item ansible_tools.zip.1.part
Remove-Item ansible_tools.zip.2.part
Remove-Item ansible_tools.zip


# reset LGPO
& secedit /configure /cfg c:\Windows\inf\defltbase.inf /db defltbase.sdb /verbose

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
