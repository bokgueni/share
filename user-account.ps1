$pth=$env:USERDNSDOMAIN.Replace(".",",DC=")
$pth="CN=Users,DC="+$pth
echo $pth
Import-module ActiveDirectory 

echo "Changing Passwords"
Get-ADUser -Filter * `
|? -Property samaccountname -ne "administrator" `
|? -Property samaccountname -ne "scoringbot" `
|? -Property samaccountname -ne "gt" `
|% {
    Add-ADGroupMember -Identity 'Protected Users' -Members $_.SamAccountName
    Set-ADAccountPassword -Reset -Identity $_.SamAccountName -NewPassword (ConvertTo-SecureString -AsPlainText 'Tkdydwkvotmdnjem123!@#' -Force) `
    }

