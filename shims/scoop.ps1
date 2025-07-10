# C:\Users\daver\Desktop\PCIe\apps\scoop\current\bin\scoop.ps1
$path = Join-Path $PSScriptRoot "..\apps\scoop\current\bin\scoop.ps1"
if ($MyInvocation.ExpectingInput) { $input | & $path  @args } else { & $path  @args }
exit $LASTEXITCODE
