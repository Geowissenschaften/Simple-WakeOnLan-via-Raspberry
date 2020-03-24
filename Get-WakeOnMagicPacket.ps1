$UseIPFilter = $False
$IPFilter = "192.168.*"
$ForcePhysicalMediaType = $False
$PhysicalMediaType = "802.3" # Ethernet
# $PhysicalMediaType = "Native 802.11" # Wi-Fi


If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "-noprofile -executionpolicy bypass & '" + $MyInvocation.MyCommand.Definition + "'"
    #Start-Process powershell -Verb runAs -noprofile -executionpolicy bypass -ArgumentList $arguments
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

$InterfaceIndex = (Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"}).InterfaceIndex

if ($UseIPFilter) {
    $InterfaceIndex = foreach ($Index in $InterfaceIndex) {
        (Get-NetIPAddress | Where-Object {$_.IPAddress -like $IPFilter -and $_.InterfaceIndex -eq $Index}).InterfaceIndex}
}

if ($ForcePhysicalMediaType -or ($InterfaceIndex | Measure-Object).Count -ne 1) {
    $NetAdapter = Get-NetAdapter | Where-Object {$_.InterfaceIndex -eq  $InterfaceIndex -and $_.PhysicalMediaType -eq $PhysicalMediaType}
} else {
    $NetAdapter = Get-NetAdapter | Where-Object {$_.InterfaceIndex -eq  $InterfaceIndex}
}

if (($NetAdapter | Measure-Object).Count -ne 1) {
  if ($UseIPFilter) {
      Write-Host "Could not finde a unique adapter with IP-Filter: $IPFilter and PhysicalMediaType: $PhysicalMediaType"
    } else {
      Write-Host "Could not finde a unique adapter with PhysicalMediaType: $PhysicalMediaType"
    }
  Write-Host ""
  pause
  exit
}

$IPAddress = (Get-NetIPAddress | Where-Object {$_.InterfaceIndex -eq  $InterfaceIndex}).IPAddress

$NetAdapter | Select-Object Name, @{name='MacAddress'; expression={$_.MacAddress.replace('-',':')}}, @{name='WakeOnMagicPacket'; expression={(Get-NetAdapterPowerManagement -Name $_.Name).WakeOnMagicPacket}}, @{name='IPAddress'; expression={$IPAddress}} | Format-List

pause
