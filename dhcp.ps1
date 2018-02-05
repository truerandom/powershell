#DHCP Script
param(
	   [string]$MAC
)

function getDominio(){
	$Domain=[System.Net.Dns]::GetHostByName($VM).Hostname.split('.')
	$Domain=$Domain[1]+'.'+$Domain[2]
	return $Domain	
}

function getHostname(){
	return "$env:computername"
}

function verificarEquipoDominio(){
	$dominio = getDominio
	$cname = getHostname
	if ($dominio -ne "ps.local" -Or $cname -ne "Dav"){
		echo "ERROR: el script no se esta ejecutando en Dav o en dominio"
		exit
	}
}

function verificaMAC(){
    $patron = "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
	if (-Not $MAC){
		return $false
	}
	if ($MAC | Select-String -Pattern $patron) {
		return $true
	}
	return $false
}

function getFabricante(){
	$content = Get-Content "./listamacs.txt"
    $MAC
	$macf=$MAC -replace "-",""
    $macfb = $macf.Substring(0,6)
	$content | Select-String -AllMatches $macfb
    
}

function getLease(){
	$nombre = getHostname
	$Scope = "10.1.2.0"
	Get-DhcpServerv4Lease -ComputerName $nombre -ScopeId $Scope -ClientId $MAC
}

function installDHCP(){
	
	Install-WindowsFeature -Name 'DHCP' -IncludeManagementTools
}

function configuraScope(){
    $Inicio = "10.1.2.4"
	$Fin = "10.1.2.20"
	$Mascara = "255.255.255.224"
    $Desc = "Dav"
	$Scope = "10.1.2.0"
	$equipo = getHostname
	$ipdns1 = "10.1.2.1"
	$ipif = (Get-NetAdapter).ifIndex
    Add-DhcpServerV4Scope -Name "DHCP Scope" -StartRange $Inicio -EndRange $Fin -SubnetMask $Mascara
    $iplibre = Get-DhcpServerv4FreeIPAddress -ComputerName $equipo -Scopeid $Scope
	Add-DhcpServerv4Reservation -ComputerName $equipo -ScopeId $Scope -IPAddress $iplibre -ClientId $MAC
}

function instaladoDHCP(){
    $arr = gsv -Name ".*DHCP.*"
	    if($arr | Select-String -Pattern ".*DHCPServer.*"){
		    #echo "DHCP SERVER INSTALADO"
		    return $true
	    }else{
		    #echo "DHCP NO ESTA INSTALADO"
		    return $false
	    }
	return $false
    
}

function setDNS(){
	$ipdns1 = "10.1.2.1"
	$ipif = (Get-NetAdapter).ifIndex
	Set-DnsClientServerAddress -InterfaceIndex $ipif  -ServerAddresses ($ipdns1)
}

function desinstalarDHCP(){
	Uninstall-WindowsFeature -Name 'DHCP' -IncludeManagementTools
}

function configuraScopeX(){
    $Inicio = "10.1.2.4"
	$Fin = "10.1.2.20"
	$Mascara = "255.255.255.224"
    $Desc = "Dav"
	$Scope = "10.1.2.0"
	$equipo = getHostname
	$ipdns1 = "10.1.2.1"
	$ipif = (Get-NetAdapter).ifIndex
    Add-DhcpServerV4Scope -Name "DHCP Scope" -StartRange $Inicio -EndRange $Fin -SubnetMask $Mascara
    return
}

function setReservation(){
    $Scope = "10.1.2.0"
	$equipo = getHostname
    $iplibre = Get-DhcpServerv4FreeIPAddress -ComputerName $equipo -Scopeid $Scope
	Add-DhcpServerv4Reservation -ComputerName $equipo -ScopeId $Scope -IPAddress $iplibre -ClientId $MAC
    return
}

verificarEquipoDominio
if($MAC){
	if( verificaMAC $MAC ){
        $vardhcp = instaladoDHCP
        #pruebas
        $lel=$true
        echo $lel
        echo "suxcexfulleando [$vardhcp]"
		if ( $vardhcp -eq $true){
			#Hacer la reservacion de la MAC
            setReservation
			#Informar quien es el fabricante
			getFabricante
			#Ver ultimo lease
			getLease
		}
		else{
			#Instalar DHCP y Configurar scope
            echo "Instalo DHCP"
			installDHCP
            #configuro scope
            configuraScopeX
            #hago reservacion
            setReservation
			#Dns a DC ps.local
			setDNS

		}
	}
	else{
		#Mac erronea
		echo "MAC no valida"
		exit
	}
}	
else{
	if($desinstalar){
		#desinstalar dhcp
		desinstalarDHCP
	}
}

