# Simple-WakeOnLan-via-Raspberry

I wanted a simple solution to wake computers in a network reachable through a VPN connection.  

I use systemd service listening at port 55555 for a MAC addresss.  
You can change it, just replace the 55555 everywhere in the scripts.

## Requierments
### WakeOnLAN enabled on destination computers
#### UEFI / BIOS
Your Motherboard needs to support WakeOnLAN and it needs to be enabled. As far as I know this cannot be achived via remote.  
This is needed to turn on your computer if it is completely powered off.  

#### Operating system
If your computer is in "Sleep Mode" the OS will have to wake it.
Therefore WakeOnLAN needs to be enabled in the OS as well.  
##### Windows: Get WakeOnLAN state via PowerShell
To check the state you can use the `Get-WakeOnMagicPacket.ps1` PowerShell script. (right click on the script, execute with powershell)  
If you want to Enable the WakeOnMagicPacket you can use the `Set-WakeOnMagicPacket.ps1` PowerShell script.

Both scripts do need admin rights to execute.  
It will only output/change network adapters that are connected.   
You can also change the follwoing variables at the top of the script.

    $UseIPFilter = $False  
    $IPFilter = "192.168.*"  
    $ForcePhysicalMediaType = $False  
    $PhysicalMediaType = "802.3" # Ethernet  
    # $PhysicalMediaType = "Native 802.11" # Wi-Fi  
If you set `$UseIPFilter = $True` only network adapters that match the `$IPFilter` will be used.  
If you set `$ForcePhysicalMediaType = $True` only network adapters that match the `$PhysicalMediaType` will be used,  
otherwise `$PhysicalMediaType` is the preffered network adatper type.  
Change it to `$PhysicalMediaType = "Native 802.11"` if you want Wi-Fi insted of ethernet adapters. 

These scripts uses: 

    Get-NetAdapterPowerManagement | Select-Object Name, WakeOnMagicPacket 

set to enabled (replace [Name] with Adapter-Name):
  
    Set-NetAdapterPowerManagement -Name [Name] -WakeOnMagicPacket Enabled

### computer/raspberry running the SendMagicPacket (WOL-Server)
I will call this the "WOL-Sever". It needs to be in the same network as the machines you want to wake.
I use a Raspberry 1.

#### sudo is expected
(Raspian should come with sudo installed)

#### allow port in firewall 
(Raspian does not come with a pre-configured Firewall)

    firewall-cmd --add-port=55555/tcp --permanent
#### SendMagicPacket service needs to be installed
You can do this by running the `Install_SendMagicPacket_service.sh` script as root.
You can also copy and paste the commands one by one if you want more control over the process.

Change the port at the top of the script if you want a different one.  
I will not explain the script in detail.  
It uses systemd to open a socket on the specified port. It will use the input to that socket and execute etherwake with it.

### MAC adress of computers you want to wake
#### Linux: Scan MAC addresses in the network:
You might have to install arp-scan first:

	apt-get --assume-yes install nmap arp-scan  

To scan your local network:

    arp-scan --ignoredups --interface=eth0 --localnet --quiet
#### Windows: get MAC address via PowerShell
If you use the `Create-WakeOnLanScript.ps1` script, your MAC address will be added in there automatically added in there.

Alternative:

    Get-NetAdapter -Physical | Select-Object Name, @{name='MacAddress'; expression={$_.MacAddress.replace('-',':')}} | Format-List

## Wake your Computer
[host/IP] - the DNS name or IP of the computer/raspberry running the SendMagicPacket systemd service

### Linux:

    echo xx:xx:xx:xx:xx:xx | netcat [host/IP] 55555  

### Windows (Powershell):
You can use the `Create-WakeOnLanScript.ps1` PowerShell script to create a script that will wake the computer.  
You will have to change the `$WOLServer` value. Also change the `$WOLServerPort` if you changed it in the server configuration.  
The rest of the variables can be changed as explained above. 

    $WOLServer = "WOLServer DNS-Name or IP"  
    $WOLServerPort = "55555"  

Execeute it on the compter you want to wake, then copy the script it creates to the computer from which you want to wake it.

Alternative:  
Change the variables at the top of the `Wake-Host.ps1` PowerShell Script

    $MacAddress = "xx:xx:xx:xx:xx:xx"
    $WOLServer = "WOLServer DNS-Name or IP"
    $WOLServerPort = "55555"



it uses:

Send-TCPMessage function can be found here: [Function Send-TCPMessage](https://www.programming-books.io/essential/powershell/tcp-sender-6fa1df87741041cb89d7e2c1fecc95b2)

    Send-TCPMessage -Port 55555 -Endpoint [host/ip] -Message xx:xx:xx:xx:xx:xx

Alternative:  
ncat can be found here.: [nmap.org - ncat](https://nmap.org/ncat/)

    echo xx:xx:xx:xx:xx:xx | ncat [host/IP] 55555  
