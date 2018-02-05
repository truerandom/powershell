param([switch] $Configure)

$DC1="ps"
$DC2="local"
$User="administrator"
$DN="CN=$env:USERNAME,CN=Users,DC=$DC1,DC=$DC2"
$infoPC=Get-WmiObject Win32_ComputerSystem
$pcName = $infoPC.Name

    if($Configure)
    {
        $ScriptBlockContent = { 
            param ($DN)        
            dsget user $DN -memberof | Select-String "LE? Web Dav"
        }
        $variable=Invoke-Command -ComputerName DC -ScriptBlock $ScriptBlockContent -ArgumentList $DN                      
        if($variable.Count -eq 0 -or $variable.Count -eq 2)
        {
            echo "Error no se puede crear la carpeta compartida"
            exit
        }
        else
        {
            $directorio = $variable.Matches.Value
            $path=pwd
            $direccioncompleta=$path.Path + "\" + $directorio
            if((Test-Path $direccioncompleta) -eq $true){
                echo "El directorio $direccioncompleta ya existe"
            }
            else{
                "No existe"
                New-Item -ItemType Directory -Path $path.Path -Name $directorio
                net share $directorio=$direccioncompleta /GRANT:Everyone,READ
            }
        }
    }
    else{
        $ScriptBlockContent = { 
            param ($pcName)        
            Get-ADComputer -Filter {name -eq $pcName}
        }
                              
        $variable=Invoke-Command -ComputerName DC -ScriptBlock $ScriptBlockContent -ArgumentList $pcName          

        #$pcName
        $credenciales="$DC1\$User"

        if($pcName -eq $variable.Name){
        
            echo "cambiar el nombre del equipo? Y/N"
            #$opcion
            $opcion=Read-Host         
            switch -Regex ($opcion){
                'Y|y' {
                     echo  "nuevo nombre:"
                     $nuevoNombre=Read-Host 
                     $infoPC.Rename($nuevoNombre)
                     echo  "reiniciando el equipo"
                      }
                'N|n' { continue }
            }
        }
        else{
            $dominio = "$DC1.$DC2"
            add-computer `
            -domainname $dominio `
            -Credential $credenciales
        }
    }



