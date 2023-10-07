#####   NOME:                   ChecaIP-ChecaMenECPU.ps1
#####   VERSÃO:                 1.0
#####   DESCRIÇÃO:              Configura dependências de subida dos serviços do TactiumIP
#####   DATA DA CRIAÇÃO:        04/05/2023
#####   DATA DA MODIFICAÇÃO:    Sem modificações
#####   ESCRITO POR:            David Portela

<#
.SINOPSE
    Checa a comunicação entre a PA e o Servidor do IPServer, memória e porcessador da PA.

.DESCRIÇÃO
    O cmdlet ChecaIP-ChecaMenECPU testa a disponibilidade entre a PA e o servidor bem como os consumos de recurso da máquina.

.EXEMPLO
    ChecaIP-ChecaMenECPU -IPAdress '8.8.8.8' -MemoryThreshold '70' -CPUThreshold '70'
    Ao setar as informações de do IP do servidor que deseja atingir, percentual de CPU e Memória. Sempre que a comunicação falhar com o IP destino ou os percentuais forem 
    atingidos será salvo um log no disco local "C:" com o nome Auditoria.log.

.PARAMETER IPAddress
    O IP do host que deseja ser atingido e testada a comunicação.

.PARAMETER MemoryThreshold
    % de memória considarado crítico no teste.

.PARAMETER CPUThreshold
    % de CPU considerado crítico no teste.

#>

param(
    [Parameter(
            Mandatory=$true)]
    [string]$IPAddress,         # Endereço IP a ser monitorado

    [Parameter(
            Mandatory=$false,
            HelpMessage='Percentual de uso de memória considerado pico ? O Padrão é 95%.'
    )]
    [int]$MemoryThreshold = 95,      # Limite de uso de memória em porcentagem

    [Parameter(
            Mandatory=$false,
            HelpMessage='Percentual de uso de cpu considerado pico ? O Padrão é 90%.'
    )]
    [int]$CPUThreshold = 90         # Limite de uso de CPU em porcentagem

   
)

$Count = 0
$Legend = "Endereço IP: $IPAddress | Limite de Memória: $MemoryThreshold% | Limite de CPU: $CPUThreshold%"
$Separator = "---------------------"

do {
    Start-Sleep 1
    # Verificar se há conexão com o endereço IP especificado
    $TestConnection = Test-Connection $IPAddress -Count 1 -Quiet
    
    # Obter a carga média da CPU
    $CPUMedia = (Get-CimInstance -ClassName Win32_Processor | Select-Object -Property LoadPercentage).LoadPercentage
    $CPUUsage = "Carga Média da CPU: $CPUMedia%", (Get-Date)

    # Obter a carga média da CPU
    $CPUMedia = (Get-CimInstance -ClassName Win32_Processor | Select-Object -Property LoadPercentage).LoadPercentage
    $CPUUsage = "CPU Média: $CPUMedia %", (Get-Date)

    # Obter informações de uso de memória
    $FPMemory = (Get-CimInstance -Class Win32_OperatingSystem |
        Select-Object FreePhysicalMemory |
        Measure-Object -Property FreePhysicalMemory -Sum).Sum / 1MB

    $TVMemorySize = (Get-CimInstance -Class Win32_OperatingSystem |
        Select-Object TotalVisibleMemorySize |
        Measure-Object -Property TotalVisibleMemorySize -Sum).Sum / 1MB

    $MemoryUsage = "Uso de Memória: {0:F2}% - Livre: {1:F2}MB / Total: {2:F2}MB" -f (100 - ($FPMemory * 100 / $TVMemorySize)), $FPMemory, $TVMemorySize

    # Verificar se houve falha na conexão
    if ($TestConnection -eq $false) {
        $Count = $Count + 1
        
        if ($Count -eq 1) {
            Write-Host "Falha na conexão detectada"
            $ExecutedAt = "Executado em:", (Get-Date)
            $LogContent = $Separator, $ExecutedAt, $Legend, $MemoryUsage, $CPUUsage, $Separator
            Add-Content -Path "C:\Auditoria.log" -Value $LogContent -PassThru
            $Count = 0
        }
    } else {
        $Count = 0
    }

    # Verificar se o uso de CPU ou memória ultrapassou os limites definidos
    if ($CPUMedia -gt $CPUThreshold -or (100 - ($FPMemory * 100 / $TVMemorySize)) -gt $MemoryThreshold) {
        Write-Host "Alto uso de memória ou CPU detectado"
        $MemoryUsage
        $CPUUsage
        $LogContent = $MemoryUsage, $CPUUsage, $Separator
        Add-Content -Path "C:\Auditoria.log" -Value $LogContent -PassThru
    }

    $Count
    $CPUUsage
    $MemoryUsage
    Write-Host $Separator
} until ($Count -eq 5)
