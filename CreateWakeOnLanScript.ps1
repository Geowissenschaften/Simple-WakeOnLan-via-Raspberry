$WOLServer = "WOLServer DNS-Name or IP"
$WOLServerPort = "55555"
$UseIPFilter = $False
$IPFilter = "192.168.*"
$ForcePhysicalMediaType = $False
$PhysicalMediaType = "802.3" # Ethernet
# $PhysicalMediaType = "Native 802.11" # Wi-Fi


$Parent = (Get-Item $PSCommandPath).DirectoryName

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
      Write-Host "Cannot create WOL-Script"
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

$NetAdapter | Select-Object Name, @{name='MacAddress'; expression={$_.MacAddress.replace('-',':')}}, @{name='IPAddress'; expression={$IPAddress}} | Format-List

$Hostname = Hostname

$MacAddress = $NetAdapter.MacAddress

$SendTCPMessageFunction=@'
Function Send-TCPMessage {
    Param (
            [Parameter(Mandatory=$true, Position=0)]
            [ValidateNotNullOrEmpty()]
            [string]
            $EndPoint
        ,
            [Parameter(Mandatory=$true, Position=1)]
            [int]
            $WOLServerPort
        ,
            [Parameter(Mandatory=$true, Position=2)]
            [string]
            $Message
    )
    Process {
        # Setup connection
        $IP = [System.Net.Dns]::GetHostAddresses($EndPoint)
        $Address = [System.Net.IPAddress]::Parse($IP)
        $Socket = New-Object System.Net.Sockets.TCPClient($Address,$WOLServerPort)

        # Setup stream wrtier
        $Stream = $Socket.GetStream()
        $Writer = New-Object System.IO.StreamWriter($Stream)

        # Write message to stream
        $Message | % {
            $Writer.WriteLine($_)
            $Writer.Flush()
        }

        # Close connection and stream
        $Stream.Close()
        $Socket.Close()
    }
}
'@

$SendTCPMessageCall="Send-TCPMessage -Port $WOLServerPort -Endpoint $WOLServer -Message $MacAddress # $hostname"

$ScriptOut="$Parent\Wake_[$Hostname]_via_$WOLServer.ps1"

$SendTCPMessageFunction | Out-File -LiteralPath $ScriptOut
$SendTCPMessageCall | Out-File -LiteralPath $ScriptOut -Append


Write-Host "Created: $ScriptOut"  
Write-Host "Copy script to the computer from where you want to wake this computer"
Write-Host ""

pause
