#####   NOME:                   VerificaIPeHardware
#####   VERSÃO:                 1.2
#####   DESCRIÇÃO:              Configura dependências de subida dos serviços do TactiumIP
#####   DATA DA CRIAÇÃO:        04/05/2023
#####   DATA DA MODIFICAÇÃO:    16/11/2023
#####   ESCRITO POR:            David Portela

<#
.SINOPSE
    Checa a comunicação entre a PA e o Servidor do IPServer, memória e porcessador da PA.

.DESCRIÇÃO
    O cmdlet ChecaIP-ChecaMenECPU testa a disponibilidade entre a PA e o servidor bem como os consumos de recurso da máquina.

.EXEMPLO
    Ao setar as informações de percentual do IP do servidor que deseja atingir, percentual de CPU e Memória. Sempre que a comunicação falhar com o IP destino ou os percentuais forem 
    atingidos será salvo um log no disco local "C:" com o nome Auditoria.log

#>

$Count = 0
$IP = Read-Host -Prompt 'Digite o endereço IP que deseja monitorar'
$MemoriaPercent = Read-Host -Prompt 'Indique o % de memória que deseja monitorar'
$CPUPercent = Read-Host -Prompt 'Indique o % de cpu que deseja monitorar'

do {
    Start-Sleep 1
    $TestConnection = Test-Connection $IP -Count 1 -Quiet
    
    # Obter a carga média da CPU
    $CPUMedia = (Get-CimInstance -ClassName Win32_Processor | Select-Object -Property LoadPercentage).LoadPercentage
    $CPUUsage = "CPU Média: $CPUMedia %"

    # Obter informações de uso de memória
    $FPMemory = (Get-CimInstance -class Win32_OperatingSystem |
        Select-Object FreePhysicalMemory |
        Measure-Object -Property FreePhysicalMemory -Sum).sum / 1mb

    $TVMemorySize = (Get-CimInstance -class Win32_OperatingSystem |
        Select-Object TotalVisibleMemorySize |
        Measure-Object -Property TotalVisibleMemorySize -Sum).sum / 1mb

    $MemoryCalculo = 100 - ($FPMemory * 100 / $TVMemorySize)
    $MemoryUsage = "Memória em uso: {0:F2} %" -f $MemoryCalculo

    if ($TestConnection -eq $false) {
        $Count = $Count + 1
        
        if ($Count -eq 1) {
            Write-Host "Foi identificado falha na conexão"
            $Linhas = "---------------------"
            $exec = "Houve falha de comunicação com o $IP ás", (Get-Date)
            $Escrever = $exec, '' + $MemoryUsage, '' + $CPUUsage, '' + $Linhas
            add-content -Path "c:\Auditoria.log" -Value $Escrever -passthru
            $Count = 0
        }
    } else {
        $Count = 0
    }

    if ($CPUMedia -gt $CPUPercent -or $MemoryCalculo -gt $MemoriaPercent) {
        if($CPUUsage -gt $CPUPercent){
            Write-Host "Processador com alta em uso"
                $CPUUsage
                $Linhas = "---------------------"

                # Verificar os 5 processos com maior uso de CPU
                $TopCpuProcesses = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5
                $CpuProcesses = "Top 5 processos em uso de CPU:", ''
                foreach ($process in $TopCpuProcesses) {
                    $CpuProcesses += "Processo: $($process.ProcessName), Uso de CPU: $($process.CPU) %"
                    
                }$Escrever = $CPUUsage, (Get-Date) + '' + $CpuProcesses, '' + $Linhas
                 add-content -Path "c:\Auditoria.log" -Value $Escrever -passthru
                }
          
          if($MemoryUsage -gt $MemoriaPercent){
            Write-Host "Memória com alta em uso"
                $MemoryUsage
                $Linhas = "---------------------"

                # Verificar os 5 processos com maior uso de memória
                $TopMemoryProcesses = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5
                $MemoryProcesses = "Top 5 processos em uso de memória:", ''
                foreach ($process in $TopMemoryProcesses) {
                    $MemoryProcesses += "Processo: $($process.ProcessName), Uso de memória: {0:F2} MB" -f ($process.WorkingSet / 1mb)
                }$Escrever = $MemoryUsage, (Get-Date) + ''  + $MemoryProcesses, '' +$Linhas
                add-content -Path "c:\Auditoria.log" -Value $Escrever -passthru
                }
                
  }
        

    $CPUUsage
    $MemoryUsage
    Write-Host "----------------------" 
} until ($Count -eq 5)
