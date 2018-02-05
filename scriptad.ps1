param(
	   [string]$tipo
)

function getdominio(){
	$Domain=[System.Net.Dns]::GetHostByName($VM).Hostname.split('.')
	$Domain=$Domain[1]+'.'+$Domain[2]
	return $Domain	
}

function agregarDominio(){
	#Variables
    $nombrePC=Get-WmiObject Win32_ComputerSystem
    $nuevoNombre="Dav"
    $dominio="ps.local"
    $credenciales="ps\Administrator"

    #Cambiar nombre al equipo
    $nombrePC.Rename($nuevoNombre)

    #Unir al dominio
    add-computer `
    -domainname $dominio `
    -Credential $credenciales
	
	#verifico si pudo agregarse
	if($?){
	   echo "Se agrego al dominio"
	   restart-computer
	}
	else{
	   echo "No fue posible agregar al dominio"
	   exit
	}

}

function setIP($ip){
	#Establecer IP Estatica
	$ipaddress = $ip
	$ipprefix = "27"
	$ipif = (Get-NetAdapter).ifIndex
	
	New-NetIPAddress -IPAddress $ipaddress -PrefixLength $ipprefix -InterfaceIndex $ipif
}

function creaDominio(){
	# Variables para crear el dominio
    $dominio="ps.local"
    $netbios="ps"
    $nivelFuncional="Win2012R2"

    #Instalacion de ADDS 
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    #Configurfacion del dominio
    Import-Module ADDSDeployment

    install-ADDSForest `
    -DomainName $dominio `
    -DomainNetbiosName $netbios `
    -DomainMode $nivelFuncional `
    -ForestMode $nivelFuncional `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -NoRebootOnCompletion `
    -Force 

}

if (-Not $tipo){
	echo "Necesitas definir forest o servicios"
	exit
}
	
if ($tipo -match "^forest$"){ 
    #Establecer IP Estatica
	setIP "10.1.2.1"
	creaDominio 
    #Reiniciar para aplicar todos los cambios
    restart-computer
    return
} 

if ($tipo  -match "^servicios$") {    
	<#
	- Verifique que el equipo pertenece al dominio ps.local
	en caso de no pertenecer, le cambie el nombre al equipo por Dav, lo agregue al dominio y reinicie el equipo                                                                                              
	Si  no existe el dominio, debe notificar el error.
	#>
	$dominio = getdominio
	if ($dominio -ne "ps.local"){
		echo "el equipo no pertenece a ps.local"
		echo "agregandolo"
		$resultado = agregarDominio	
		return
	}
}

else{
	echo "Necesitas definir forest o servicios"
	exit
}
