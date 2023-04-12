Invoke-WebRequest -Uri https://github.com/bokgueni/share/raw/main/MFT.zip -OutFile MFT.zip

Expand-Archive -LiteralPath .\MFT.zip -DestinationPath .\MFT

cd MFT

.\dotnet-runtime-6.0.15-win-x64.exe /install /passive /norestart

.\forecopy.exe -f 'C:\$MFT' .

MFTECmd\MFTECmd.exe -f '$MFT' --csv . --csvf $env:COMPUTERNAME"_before.csv"