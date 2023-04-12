# download init scripts and programes
Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/Day2.zip -OutFile Day2.zip

$7zipPath = "C:\PROGRA~1\7-Zip\7z.exe"
iex "$7zipPath x .\Day2.zip -oDay2"


$ScriptBlock =  {

Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/uninstall {361FB9AD-9238-4E87-8CFB-4126752A79F8} /qn" -Wait
Start-Process "C:\PROGRA~1\CCleaner\uninst.exe" -ArgumentList "/S" -Wait
Start-Process "C:\PROGRA~2\Dropbox\Client\DropboxUninstaller.exe" -Wait


Remove-Item "C:\Windows\Provisioning\Autopilot\DiagonsticAnalysis.pif" -Force
Remove-Item "C:\Windows\SYSTEM32\KerbClientFun.dll" -Force
Remove-Item "C:\Windows\SYSTEM32\CHKNTFS.EXE" -Force
Remove-Item "C:\Windows\System32\tlsssp.dll" -Force 
Remove-Item "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchIndexer.exe" -Force 
Remove-Item "C:\PROGRA~1\windows photo viewer\photodevices.exe" -Force
Remove-Item "C:\Windows\System32\RpcSsm.dll" -Force
Remove-Item "C:\Program Files (x86)\Compare It!\Slovak.dic" -Force
Remove-Item "C:\windows\system32\migration\UsbPortMig.exe" -Force
Remove-Item "C:\windows\system32\kerberos2.dll" -Force


Start-Process 'cmd' -ArgumentList '/c reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks /t REG_DWORD /d 0'
Start-Process 'cmd' -ArgumentList '/c net user Administrator eogksalsrnr3!'

Start-Process 'cmd' -ArgumentList '/c netsh advfirewall firewall add rule name="AppComm Helper" program="%WINDIR%\System32\migration\UsbPortMig.exe" protocol=tcp dir=out enable=yes action=block profile=any'
Start-Process 'cmd' -ArgumentList '/c netsh advfirewall firewall add rule name="AppComm Helper" program="%WINDIR%\System32\migration\UsbPortMig.exe" protocol=tcp dir=in enable=yes action=block profile=any'

Start-Process 'cmd' -ArgumentList '/c netsh advfirewall firewall add rule name="Malware Block" protocol=tcp localport=8008 dir=in enable=yes action=block profile=any'
Start-Process 'cmd' -ArgumentList '/c netsh advfirewall firewall add rule name="Malware Block" protocol=tcp localport=8008 dir=out enable=yes action=block profile=any'


cd C:\Users\Administrator\Desktop\Day2
#.\remove_malware.bat
.\7_change_files.cmd
cd 2_Windows-10-v21H1\Scripts
.\Baseline-LocalInstall.ps1



pause
 }


function Run-Elevated ($scriptblock)
{
  $sh = new-object -com 'Shell.Application'
  $sh.ShellExecute('powershell', "-NoExit -Command $scriptblock", '', 'runas')
}

Run-Elevated $ScriptBlock


