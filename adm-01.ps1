# Установка временной зоны - Москва\С. Петербург
Set-TimeZone -Id 'Russian Standard Time'

$PlaceNumber = read-host "Введите номер площадки"

    $vmmName = "m$($placeNumber)-adm-01"
    $domain = "m$($placeNumber).dzm"
    $password = "Qwerty123!" | ConvertTo-SecureString -asPlainText -Force
    $username = "$domain\Administrator" 
    $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    $distrPath = "\\10.1$placeNumber.3.201\temp\distr"
    $statePath = "C:\temp\vmmState.txt"

#  create state file
if (!(Test-Path $statePath)){
	if (!(Test-Path C:\temp\)) { New-Item C:\temp\ -ItemType Directory | Out-Null }
	New-Item $statePath -ItemType File | Out-Null
}

$state = Get-Content $statePath
$state = 0 + $state

if($state -lt 1){
    
   $IP = "10.1$placeNumber.3.46"
	$Mask = "255.255.255.0"
	$GW = "10.1$placeNumber.3.1"
    	$DNSServers = "10.1$placeNumber.3.10,10.1$placeNumber.3.11"
	
	Write-Host "Установка параметров сети..." -ForegroundColor Yellow
	netsh interface ip set address (Get-NetAdapter).Name static $IP $Mask $GW

	Write-Host "Установка параметров DNS клиента..." -ForegroundColor Yellow
	Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).ifIndex -ServerAddresses $DNSServers

    # Установка состояния установки
    Write-Host "Сетевые настройки, готовы!" -ForegroundColor Yellow
    1 | Out-File -FilePath $statePath
}

if($state -lt 2){
            sleep 2

            Write-Host "Переименовываем компьютер" -ForegroundColor Green	
                             Rename-Computer -newName $vmmName -Restart -Force
    }
        2 | Out-File -FilePath $statePath

if($state -lt 3){
            sleep 2
                        Write-Host "Добавление в домен сервера" -ForegroundColor Green
		Add-Computer -DomainName $domain -Credential $credential -Restart
           
    }
        3 | Out-File -FilePath $statePath

if($state -lt 4){
 
    write-host "Отключаем Firewall" -ForegroundColor Green
    Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

    4 | Out-File -FilePath $statePath
}

if ($state -lt 5){
    sleep 5

    Write-host "Установка необходимых компонентов" -ForegroundColor Green
    Add-WindowsFeature RSAT,RSAT-Feature-Tools,
    RSAT-DHCP, RSAT-DNS-Server, 
    RSAT-ADCS-Mgmt, 
    RSAT-Clustering, 
    RSAT-Clustering-Mgmt,
    RSAT-Clustering-PowerShell,
    RSAT-Role-Tools, 
    RSAT-Hyper-V-Tools, 
    Hyper-V-Tools, 
    Hyper-V-PowerShell, 
    RSAT-ADCS, 
    RSAT-ADCS-Mgmt, 
    RSAT-File-Services, 
    RSAT-FSRM-Mgmt, 
    RSAT-AD-Tools, 
    RSAT-AD-PowerShell, 
    RSAT-ADDS, 
    RSAT-AD-AdminCenter, 
    RSAT-ADDS-Tools,
    RSAT-NPAS,
    RSAT-Print-Services,
    GPMC,
    Web-Mgmt-Tools,
    Web-Mgmt-Service
    
    5 | Out-File -FilePath $statePath
  
    }

if ($state -lt 5){
    sleep 3

    Write-Host "Устанавливается Консоль SCCM" -ForegroundColor Green

    cmd /c \\10.138.3.201\temp\distr\Console\consolesetup.exe /q TargetDir="%ProgramFiles%\ConfigMgr Console" DefaultSiteServerName=m38-sccm-01.m38.dzm

    
    5 | Out-File -FilePath $statePath
    }

 if ($state -lt 6){
    sleep 10
    Write-host "Установка консоли VMM" -ForegroundColor Green
    cmd /c \\10.138.3.201\temp\distr\VMM\setup.exe /client /i /IACCEPTSCEULA /f \\10.138.3.201\temp\distr\VMM\VMClient.ini

    6 | Out-File -FilePath $statePath
  }
if ($state -lt 7){
      sleep 3
    Write-host "Установка необходимого патча для консоли VMM" -ForegroundColor Green
      $setupSwitches = @(
        "/passive"
        "/update"
        ("$distrPath\UPDATES\kb4518886_AdminConsole_amd64.msp")
        "/qn"
        "/norestart"
  )
    
    $msi = "$env:SystemRoot\System32\msiexec.exe"
    Start-Process -FilePath $msi -ArgumentList $setupSwitches -NoNewWindow -Wait -ErrorAction Stop
    7 | Out-File -FilePath $statePath
  }
if ($state -lt 8){
     sleep 15
    Write-host "Установка консоли администрирования касперского" -ForegroundColor Green
    cmd /c \\10.138.3.201\temp\distr\ksc\setup.exe /s /l /v"EULA=1 PRIVACYPOLICY=1"
    8 | Out-File -FilePath $statePath
  }

if ($state -lt 9){
     Write-host "Установка SQLSysClrTypes" -ForegroundColor Green
     msiexec /i \\10.138.3.201\temp\distr\scomconsol\SQLSysClrTypes.msi /qn
     9 | Out-File -FilePath $statePath
  }

if ($state -lt 10){
    sleep 5
   Write-Host "Установка ReportViewer" -ForegroundColor Yellow
   msiexec /i \\10.138.3.201\temp\distr\scomconsol\ReportViewer.msi /qn
    10 | Out-File -FilePath $statePath
  }
if ($state -lt 11){
    sleep 5
   Write-Host "Установка консоли  SCOM" -ForegroundColor Yellow
   msiexec /i \\10.138.3.201\temp\distr\SCOM\setup\AMD64\Console\OMConsole.msi /qn
    11 | Out-File -FilePath $statePath
  }

Remove-Item C:\temp\ -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "===== Установка завершена! Нажмите ENTER для выхода =====" -ForegroundColor Green
Read-Host
