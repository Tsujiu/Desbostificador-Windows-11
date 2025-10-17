# desbotificador-launcher-material2.ps1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Elevação ---
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    [System.Windows.Forms.MessageBox]::Show("Este script precisa ser executado como Administrador!","Aviso",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
    Start-Process powershell "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Funcoes ---
function Status-Servico { param($nome) $svc = Get-Service -Name $nome -ErrorAction SilentlyContinue; if (!$svc) { return }; if ($svc.Status -eq 'Running') { Stop-Service $nome -Force; Set-Service $nome -StartupType Disabled } else { Set-Service $nome -StartupType Disabled } }
function Status-Tarefa { param($nome) $t = schtasks /Query /TN $nome 2>$null; if (!$t) { return }; schtasks /Change /TN $nome /Disable | Out-Null }
function Remover-App { param($name) $pkg = Get-AppxPackage -AllUsers -Name $name -ErrorAction SilentlyContinue; $prov = Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like "*$name*"}; if ($pkg) { $pkg | Remove-AppxPackage -ErrorAction SilentlyContinue }; if ($prov) { $prov | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue } } }
function Desativar-Telemetria { $regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }; Set-ItemProperty -Path $regPath -Name 'AllowTelemetry' -Value 0 -Type DWord -Force; $servicos = @('DiagTrack','dmwappushservice'); foreach ($s in $servicos) { Status-Servico $s }; $tarefas = @('\Microsoft\Windows\ApplicationExperience\ProgramDataUpdater','\Microsoft\Windows\Customer Experience Improvement Program\Consolidator','\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip','\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask'); foreach ($t in $tarefas) { Status-Tarefa $t } }
function Remover-Apps { $toRemove = @('Microsoft.BingNews','Microsoft.BingWeather','Microsoft.Getstarted','Microsoft.XboxApp','Microsoft.YourPhone','Microsoft.WindowsFeedbackHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.XboxGameOverlay','Microsoft.MSPaint','Microsoft.MixedReality.Portal','Microsoft.Microsoft3DViewer'); foreach ($app in $toRemove) { Remover-App $app } }
function Desativar-Cortana { Stop-Service 'WSearch' -Force -ErrorAction SilentlyContinue; Set-Service 'WSearch' -StartupType Disabled }
function Desativar-OneDrive { $onedrive = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"; if (Test-Path $onedrive) { Start-Process "$onedrive" "/uninstall" -Wait } }
function Desativar-Teams { $teams = Get-AppxPackage -AllUsers -Name "*Teams*" -ErrorAction SilentlyContinue; if ($teams) { $teams | Remove-AppxPackage -ErrorAction SilentlyContinue } }
function Desativar-Anuncios { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Force }
function Limpar-Telemetria-Logs { $paths = @("$env:SystemRoot\System32\winevt\Logs\Microsoft-Windows-DiagTrack%4Operational.evtx"); foreach ($p in $paths) { if (Test-Path $p) { Clear-Content $p -ErrorAction SilentlyContinue } } }
function Remover-Taskbar-Buttons { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSearch" -Value 0 -Force; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Force; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Force; Stop-Process -Name explorer -Force; Start-Process explorer }

# --- Log ---
$logBox = $null
function Write-Log { param([string]$text) $textClean = $text -replace '[áàâãä]','a' -replace '[éèêë]','e' -replace '[íìîï]','i' -replace '[óòôõö]','o' -replace '[úùûü]','u' -replace 'ç','c'; $logBox.AppendText("$textClean`r`n"); $logBox.SelectionStart = $logBox.Text.Length; $logBox.ScrollToCaret() }
function Executar {
    Write-Log "Desativando Telemetria..."
    Desativar-Telemetria
    Write-Log "Removendo Apps desnecessarios..."
    Remover-Apps
    Write-Log "Desativando Cortana..."
    Desativar-Cortana
    Write-Log "Desativando OneDrive..."
    Desativar-OneDrive
    Write-Log "Desativando Teams..."
    Desativar-Teams
    Write-Log "Desativando anuncios..."
    Desativar-Anuncios
    Write-Log "Limpando logs de telemetria..."
    Limpar-Telemetria-Logs
    Write-Log "Removendo botoes da barra de tarefas..."
    Remover-Taskbar-Buttons
    Write-Log "Todas as funcoes foram executadas!"
    [System.Windows.Forms.MessageBox]::Show("Todas as funcoes foram executadas!","Concluido",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# --- GUI Material Preto ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Desbotificador Windows 11"
$form.Size = New-Object System.Drawing.Size(720,550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.Topmost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.Opacity = 0.96

# Nome do launcher
$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "Desbotificador Windows 11"
$labelTitle.ForeColor = [System.Drawing.Color]::MediumPurple
$labelTitle.Font = New-Object System.Drawing.Font("Segoe UI",22,[System.Drawing.FontStyle]::Bold)
$labelTitle.AutoSize = $true
$labelTitle.Location = New-Object System.Drawing.Point(120,20)
$form.Controls.Add($labelTitle)

# Log preto
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = 'Vertical'
$logBox.Size = New-Object System.Drawing.Size(670,300)
$logBox.Location = New-Object System.Drawing.Point(25,80)
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::Black
$logBox.ForeColor = [System.Drawing.Color]::MediumPurple
$logBox.Font = New-Object System.Drawing.Font("Consolas",10)
$form.Controls.Add($logBox)

# Botao Executar arredondado
$btnExecutar = New-Object System.Windows.Forms.Button
$btnExecutar.Size = New-Object System.Drawing.Size(280,50)
$btnExecutar.Location = New-Object System.Drawing.Point(60,400)
$btnExecutar.Text = "Executar"
$btnExecutar.BackColor = [System.Drawing.Color]::MediumPurple
$btnExecutar.ForeColor = [System.Drawing.Color]::White
$btnExecutar.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnExecutar.FlatStyle = 'Flat'
$btnExecutar.FlatAppearance.BorderSize = 0
$btnExecutar.Region = [System.Drawing.Region]::FromHrgn((New-Object System.Drawing.Drawing2D.GraphicsPath).AddArc(0,0,20,20,180,90))
$btnExecutar.Add_Click({ Executar})
$form.Controls.Add($btnExecutar)

# Botao Fechar arredondado
$btnFechar = New-Object System.Windows.Forms.Button
$btnFechar.Size = New-Object System.Drawing.Size(150,50)
$btnFechar.Location = New-Object System.Drawing.Point(400,400)
$btnFechar.Text = "Fechar"
$btnFechar.BackColor = [System.Drawing.Color]::DarkRed
$btnFechar.ForeColor = [System.Drawing.Color]::White
$btnFechar.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnFechar.FlatStyle = 'Flat'
$btnFechar.FlatAppearance.BorderSize = 0
$btnFechar.Region = [System.Drawing.Region]::FromHrgn((New-Object System.Drawing.Drawing2D.GraphicsPath).AddArc(0,0,20,20,180,90))
$btnFechar.Add_Click({ $form.Close() })
$form.Controls.Add($btnFechar)

# Rodape
$footer = New-Object System.Windows.Forms.Label
$footer.Text = "by MuTsuJii - GuildMaster"
$footer.ForeColor = [System.Drawing.Color]::MediumPurple
$footer.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Italic)
$footer.AutoSize = $true
$footer.Location = New-Object System.Drawing.Point(230,470)
$form.Controls.Add($footer)

$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
