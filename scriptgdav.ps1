param(
	   [string]$user,
       [switch] $W,
       [switch] $F2,
       [switch] $Out
)

function existeGrupo($nombregrupo){
    $grupos = Get-ADGroup -Filter * 
    foreach($grupo in $grupos){
        if($grupo.Name -eq $nombregrupo){
            return $true
        }
    }
    return $false

}

function creaGrupo($nombregrupo){
	if(-Not (existeGrupo $nombregrupo)){
		NEW-ADGroup –name $nombregrupo –groupscope Global
	}
}

function existeUser($user){
	$Name = $user
	$Usuario = Get-ADUser -LDAPFilter "(sAMAccountName=$Name)"
	If ($User -eq $Null) {
		return $false
	}
	Else {
		return $true
	}
}

function createUser($user){
	Import-Module ActiveDirectory
	New-ADUser `
	 -Name $user `
	 -SamAccountName  $user `
	 -DisplayName $user `
	 -AccountPassword (ConvertTo-SecureString "hola123," -AsPlainText -Force) `
	 -Enabled $true
}

function agregaUserGrupo($user,$grupo){
	ADD-ADGroupMember $grupo –members $user
}

function eliminaUserGrupo($user,$grupo){
	Remove-ADGroupMember -Identity $grupo -Members $user
}

if($user){
    if($F2){
        echo "Buscar en core.local"
    }
    if($W){
        #echo "w activo"
        if($Out){
            echo "Eliminar user de le"
            eliminaUserGrupo $user "LE Web Dav"
        }else{
            echo "Agregar user a le"
            agregaUserGrupo $user "LE Web Dav"
        }
    }
    #no w
    else{
        if($Out){
            echo "Eliminar user de LE"
            eliminaUserGrupo $user "LE Web Dav"
        }else{
            echo "Agregar user a L"
            agregaUserGrupo $user "L Web Dav"
        }
    }
}
