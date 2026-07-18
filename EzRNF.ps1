﻿# EzRNF Version 1.2
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$currentVersion = "1.2"
$rawBase        = "https://raw.githubusercontent.com/tyler-eaker/EzRNF/main"
$scriptPath     = $MyInvocation.MyCommand.Path

try {
    $latestVersion = (Invoke-WebRequest -Uri "$rawBase/version.txt" -UseBasicParsing -TimeoutSec 5).Content.Trim()
    if ([version]$latestVersion -gt [version]$currentVersion) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "A new version of EzRNF is available ($latestVersion).`nWould you like to update now?",
            "Update Available",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $latestScript = (Invoke-WebRequest -Uri "$rawBase/EzRNF.ps1" -UseBasicParsing -TimeoutSec 30).Content
            if (-not [string]::IsNullOrWhiteSpace($latestScript)) {
                [System.IO.File]::WriteAllText($scriptPath, $latestScript, (New-Object System.Text.UTF8Encoding $false))
                [System.Windows.Forms.MessageBox]::Show(
                    "Updated to version $latestVersion.`nThe application will now restart.",
                    "Update Complete",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                ) | Out-Null
                Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""
                exit
            } else {
                [System.Windows.Forms.MessageBox]::Show("Download failed. Please try again later.", "Update Failed", 0, 16) | Out-Null
            }
        }
    }
} catch {
    # No internet or repo unreachable - continue normally
}

 $script:Config = @{
    SshHost         = "salt.colorimageinc.com"
    SshPort         = "22"
    DbName          = "salt"
    NetworkCsvPath  = "\\salt.colorimageinc.com\public\archive"
    SettingsPath    = Join-Path $env:APPDATA "EzRNF\settings.json"
    HistoryPath     = Join-Path $env:APPDATA "EzRNF\history.json"
    ErrorLogPath    = Join-Path $env:APPDATA "EzRNF\error.log"
    CreatedByGfid   = "01KQ7NCP5KYGVBEDX7NRVPZJVF"
    DefaultSulid    = "01GPY0D43RDM84F371FNNWMTV8"
    DefaultSchan    = "10000000000000301"
    DtsSchan        = "10000000000000303"
    BrandGfid       = "10000000000000101"
}

 $script:activeSshUser  = ""
 $script:activeSshPass  = ""
 $script:activeDbPass   = ""
 $script:csvOrders      = New-Object System.Collections.Generic.List[PSCustomObject]
 $script:lastRunData    = @()
 $script:scanDepth      = 24
 $script:batchSize      = 3
 $script:lang           = "EN"

 $script:locationPids = @{
    "NV" = "01GRSJYY0X0DQYCHV7Z20APEMF"
    "MD" = "01FWMD304FT9TK0NY2GPWCTZH2"
    "TX" = "01K333QC0Y6CZZEZHZPHZA9D98"
}

 $script:typToTag = @{
    "274186969883621376" = "XFER"
    "14000000000000310"  = "REPLEN"
    "14000000000000320"  = "LAUNCH"
    "14000000000000325"  = "GWP"
    "14000000000000370"  = "NEW"
    "14000000000000380"  = "WEB"
    "14000000000000381"  = "WEB Spc"
    "14000000000000382"  = "WEB Intl"
}

 $script:countryToCarrierGfid = @{
    "GB" = "10000000000001660"; "FR" = "10000000000001660"; "IT" = "10000000000001660"
    "IE" = "10000000000001660"; "NL" = "10000000000001660"
}

 $script:csvCarrierToCgfid = @{
    "GLOBALE/"="296246482205620224"; "PURLTR/EXPRS"="287555332212797440"
    "SHPIUM/01"="295570239302875136"; "SHPIUM/02"="295570271917783040"
    "SHPIUM/05"="295570292872525824"; "FEDEX/92"="10000000000001650"
    "FEDEX/05"="10000000000001650"; "FEDEX/90"="10000000000001650"
    "OTHER/AIR"="10000000000001650"; "UPS/03"="10000000000001609"
    "UPS/01"="10000000000001609"; "UPS/12"="10000000000001609"
    "UPS/13"="10000000000001609"; "UPS/02"="10000000000001608"
    "FEDEX/03"="10000000000001602"; "DHLEX/EXDDP"="10000000000001601"
    "DHLW/EXDDPW"="10000000000001601"; "DHLW/EXDDP"="10000000000001601"
    "DHLC/DHL_C"="10000000000001601"; "OTHER/TEC"="10000000000001605"
}

 $script:intakeCarrierToCgfid = @{
    "GLOBALE-DHL"="296246482205620224"; "GLOBALE-FEDEX"="296246482205620224"
    "PURLTR_XP"="287555332212797440"; "GROUND_SRS"="10000000000001609"
    "UPS GROUND"="10000000000001609"; "UPS-3DAY"="10000000000001609"
    "2DAY_SRS"="10000000000001608"; "UPS-2ND DAY EOD"="10000000000001608"
    "UPS SATURDAY"="10000000000001608"; "NEXTDAY_SRS"="10000000000001650"
    "UPS-1NXTDAY SVR"="10000000000001650"; "UPS-1NXT DAY"="10000000000001650"
    "FEDEX-1STD"="10000000000001650"; "AIR"="10000000000001650"
    "FEDEX GROUND"="10000000000001602"; "DHL_EXPRESS_DDP"="10000000000001601"
}

 $script:tagToPstr = @{
    "WEB"="14000000000000380"; "WEB Spc"="14000000000000381"; "WEB Intl"="14000000000000382"
}

 $script:stsCarrierToCgfid = @{
    "DHL"          = "10000000000001601"
    "FedEx Air"    = "10000000000001650"
    "FEDEX GROUND" = "10000000000001602"
    "Geodis UK"    = "10000000000001660"
    "GLOBALEF"     = "296246482205620224"
    "PURLTR EXPRS" = "287555332212797440"
    "Shipium01"    = "295570239302875136"
    "Shipium02"    = "295570271917783040"
    "Shipium05"    = "295570292872525824"
    "TechTrans"    = "10000000000001605"
    "UPS"          = "10000000000001663"
    "UPS 2nd Day"  = "10000000000001608"
    "UPS Ground"   = "10000000000001609"
}

 $script:pidToLoc = @{}
foreach ($k in $script:locationPids.Keys) { $script:pidToLoc[$script:locationPids[$k]] = $k }

function Write-ErrorLog {
    param([string]$Message, [System.Management.Automation.ErrorRecord]$ErrorRecord)
    try {
        $dir = Split-Path $script:Config.ErrorLogPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $entry = "[$timestamp] $Message`r`n"
        if ($ErrorRecord) { $entry += $ErrorRecord | Out-String }
        $entry += "`r`n"
        Add-Content -Path $script:Config.ErrorLogPath -Value $entry
    } catch { }
}

$script:strings = @{
    EN = @{
        LblUser         = "SSH Username:"
        LblSshPass      = "SSH Password:"
        LblDbPass       = "MariaDB Password:"
        LblInput        = "Paste Orders:"
        LblOutput       = "System Output:"
        LblMode         = "Mode:"
        LblLoc          = "Location:"
        LblCarrier      = "Carrier:"
        LblOrderType    = "Order Type:"
        ChkCreateCsv    = "Create CSV when finished"
        ChkOpenCsv      = "Open CSV when finished"
        BtnProcess      = "Process Orders"
        BtnCopy         = "Copy Orders"
        BtnStsProcess   = "Wave STS Orders"
        MenuView        = "View"
        MenuClearOutput = "Clear Output"
        MenuClearInput  = "Clear Input"
        MenuAlwaysOnTop = "Always on Top"
        MenuWordWrap    = "Word Wrap"
        MenuScrollBot   = "Scroll to Bottom"
        MenuFontSize    = "Font Size"
        MenuFontSmall   = "Small (8pt)"
        MenuFontMedium  = "Medium (9pt)"
        MenuFontLarge   = "Large (11pt)"
        MenuOptions     = "Options"
        MenuCreateCsv   = "Create CSV"
        MenuOpenCsv     = "Open CSV"
        MenuScanDepth   = "Archive Scan Depth"
        MenuScan12      = "12 files (~12 hrs)"
        MenuScan24      = "24 files (~24 hrs)"
        MenuScan48      = "48 files (~48 hrs)"
        MenuBatchSize   = "Batch Size"
        MenuBatch1      = "1 file per source"
        MenuBatch3      = "3 files per source"
        MenuBatch5      = "5 files per source"
        MenuTools       = "Tools"
        MenuHistory     = "Wave History"
        MenuPlink       = "Check for plink"
        MenuClearCreds  = "Clear Saved Credentials"
        MenuLang        = "Language"
        MenuInfo        = "Info"
        StsNote         = "STS orders are always waved as B2C with trigram XXX using the selected carrier and type."
    }
    ES = @{
        LblUser         = "Usuario SSH:"
        LblSshPass      = "Contraseña SSH:"
        LblDbPass       = "Contraseña MariaDB:"
        LblInput        = "Pegar Órdenes:"
        LblOutput       = "Salida del Sistema:"
        LblMode         = "Modo:"
        LblLoc          = "Ubicación:"
        LblCarrier      = "Transportista:"
        LblOrderType    = "Tipo de Orden:"
        ChkCreateCsv    = "Crear CSV al terminar"
        ChkOpenCsv      = "Abrir CSV al terminar"
        BtnProcess      = "Procesar Órdenes"
        BtnCopy         = "Copiar Órdenes"
        BtnStsProcess   = "Wave Órdenes STS"
        MenuView        = "Vista"
        MenuClearOutput = "Limpiar Salida"
        MenuClearInput  = "Limpiar Entrada"
        MenuAlwaysOnTop = "Siempre Encima"
        MenuWordWrap    = "Ajuste de Línea"
        MenuScrollBot   = "Ir al Final"
        MenuFontSize    = "Tamaño de Fuente"
        MenuFontSmall   = "Pequeño (8pt)"
        MenuFontMedium  = "Mediano (9pt)"
        MenuFontLarge   = "Grande (11pt)"
        MenuOptions     = "Opciones"
        MenuCreateCsv   = "Crear CSV"
        MenuOpenCsv     = "Abrir CSV"
        MenuScanDepth   = "Profundidad de Búsqueda"
        MenuScan12      = "12 archivos (~12 hrs)"
        MenuScan24      = "24 archivos (~24 hrs)"
        MenuScan48      = "48 archivos (~48 hrs)"
        MenuBatchSize   = "Tamaño de Lote"
        MenuBatch1      = "1 archivo por fuente"
        MenuBatch3      = "3 archivos por fuente"
        MenuBatch5      = "5 archivos por fuente"
        MenuTools       = "Herramientas"
        MenuHistory     = "Historial de Waves"
        MenuPlink       = "Verificar plink"
        MenuClearCreds  = "Borrar Credenciales"
        MenuLang        = "Idioma"
        MenuInfo        = "Info"
        StsNote         = "Las órdenes STS siempre se procesan como B2C con trigrama XXX usando el transportista y tipo seleccionados."
    }
}

function Set-Language {
    param([string]$Lang)
    $script:lang = $Lang
    $s = $script:strings[$Lang]
    $lblUser.Text              = $s.LblUser
    $lblSshPass.Text           = $s.LblSshPass
    $lblDbPass.Text            = $s.LblDbPass
    $inputLabel.Text           = $s.LblInput
    $outputLabel.Text          = $s.LblOutput
    $modeLabel.Text            = $s.LblMode
    $stsLocLabel.Text          = $s.LblLoc
    $stsCarrierLabel.Text      = $s.LblCarrier
    $stsTagLabel.Text          = $s.LblOrderType
    $createCsvCheckbox.Text    = $s.ChkCreateCsv
    $openCsvCheckbox.Text      = $s.ChkOpenCsv
    $processButton.Text        = $s.BtnProcess
    $copyOrdersButton.Text     = $s.BtnCopy
    $menuView.Text             = $s.MenuView
    $menuClearOutput.Text      = $s.MenuClearOutput
    $menuClearInput.Text       = $s.MenuClearInput
    $menuAlwaysOnTop.Text      = $s.MenuAlwaysOnTop
    $menuWordWrap.Text         = $s.MenuWordWrap
    $menuScrollBottom.Text     = $s.MenuScrollBot
    $menuFontSize.Text         = $s.MenuFontSize
    $menuFontSmall.Text        = $s.MenuFontSmall
    $menuFontMedium.Text       = $s.MenuFontMedium
    $menuFontLarge.Text        = $s.MenuFontLarge
    $menuOptions.Text          = $s.MenuOptions
    $menuCreateCsv.Text        = $s.MenuCreateCsv
    $menuOpenCsv.Text          = $s.MenuOpenCsv
    $menuScanDepth.Text        = $s.MenuScanDepth
    $menuScan12.Text           = $s.MenuScan12
    $menuScan24.Text           = $s.MenuScan24
    $menuScan48.Text           = $s.MenuScan48
    $menuBatchSize.Text        = $s.MenuBatchSize
    $menuBatch1.Text           = $s.MenuBatch1
    $menuBatch3.Text           = $s.MenuBatch3
    $menuBatch5.Text           = $s.MenuBatch5
    $menuTools.Text            = $s.MenuTools
    $menuWaveHistory.Text      = $s.MenuHistory
    $menuCheckPlink.Text       = $s.MenuPlink
    $menuClearCreds.Text       = $s.MenuClearCreds
    $menuLang.Text             = $s.MenuLang
    $menuLangEN.Checked        = ($Lang -eq "EN")
    $menuLangES.Checked        = ($Lang -eq "ES")
}

function Save-Settings {
    $sshPassToSave = ""
    if (-not [string]::IsNullOrEmpty($txtSshPass.Text)) {
        $sshPassToSave = ConvertFrom-SecureString (ConvertTo-SecureString $txtSshPass.Text -AsPlainText -Force)
    }
    $dbPassToSave = ""
    if (-not [string]::IsNullOrEmpty($txtDbPass.Text)) {
        $dbPassToSave = ConvertFrom-SecureString (ConvertTo-SecureString $txtDbPass.Text -AsPlainText -Force)
    }

    $settings = @{
        SshUser     = $txtUser.Text.Trim()
        SshPass     = $sshPassToSave
        DbPass      = $dbPassToSave
        CreateCsv   = $createCsvCheckbox.Checked
        OpenCsv     = $openCsvCheckbox.Checked
        AlwaysOnTop = $mainForm.TopMost
        WordWrap    = $outputTextBox.WordWrap
        FontSize    = $outputTextBox.Font.Size
        ScanDepth   = $script:scanDepth
        BatchSize   = $script:batchSize
        Language    = $script:lang
    }
    $dir = Split-Path $script:Config.SettingsPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $settings | ConvertTo-Json | Set-Content -Path $script:Config.SettingsPath -Encoding UTF8
}

function Load-Settings {
    if (-not (Test-Path $script:Config.SettingsPath)) { return }
    try {
        $s = Get-Content $script:Config.SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($s.SshUser) { $txtUser.Text = $s.SshUser }
        if ($s.SshPass) { $txtSshPass.Text = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((ConvertTo-SecureString $s.SshPass))) }
        if ($s.DbPass)  { $txtDbPass.Text  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((ConvertTo-SecureString $s.DbPass))) }

        $createCsvCheckbox.Checked = if ($null -ne $s.CreateCsv) { [bool]$s.CreateCsv } else { $true }
        $openCsvCheckbox.Checked   = if ($null -ne $s.OpenCsv) { [bool]$s.OpenCsv } else { $true }
        $script:scanDepth          = if ($null -ne $s.ScanDepth) { [int]$s.ScanDepth } else { 24 }
        $script:batchSize          = if ($null -ne $s.BatchSize) { [int]$s.BatchSize } else { 3 }
        $openCsvCheckbox.Enabled   = $createCsvCheckbox.Checked
        if ($null -ne $s.AlwaysOnTop -and [bool]$s.AlwaysOnTop) { $mainForm.TopMost = $true }
        if ($null -ne $s.WordWrap) { $outputTextBox.WordWrap = [bool]$s.WordWrap }
        if ($null -ne $s.FontSize -and $s.FontSize -gt 0) {
            $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", [float]$s.FontSize)
        }
        if ($null -ne $s.Language -and $s.Language -ne "") { $script:lang = $s.Language }
    } catch { Write-ErrorLog -Message "Failed to load settings" -ErrorRecord $_ }
}

 $bgScript = {
    param($ctx)
    
    $Config = $ctx.Config
    $LocationPids = $ctx.LocationPids
    $TypToTag = $ctx.TypToTag
    $CountryToCarrierGfid = $ctx.CountryToCarrierGfid
    $CsvCarrierToCgfid = $ctx.CsvCarrierToCgfid
    $IntakeCarrierToCgfid = $ctx.IntakeCarrierToCgfid
    $TagToPstr = $ctx.TagToPstr
    $PidToLoc = $ctx.PidToLoc
    
    $script:activeSshUser = $ctx.User
    $script:activeSshPass = $ctx.SshPass
    $script:activeDbPass  = $ctx.DbPass
    $script:scanDepth     = $ctx.ScanDepth
    $script:batchSize     = $ctx.BatchSize
    
    $createCsv = $ctx.CreateCsv
    $openCsv   = $ctx.OpenCsv
    $uiQueue = $ctx.uiQueue
    $statusQueue = $ctx.statusQueue
    $resultQueue = $ctx.resultQueue
    
    function Update-UI {
        param([string]$Text, [string]$Status = $null, [switch]$AlwaysShow)
        if ($Text) { $uiQueue.Enqueue($Text) }
        if ($Status) { $statusQueue.Enqueue($Status) }
    }

    function Write-ErrorLog {
        param([string]$Message, [System.Management.Automation.ErrorRecord]$ErrorRecord)
        try {
            $dir = Split-Path $Config.ErrorLogPath
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $entry = "[$timestamp] $Message`r`n"
            if ($ErrorRecord) { $entry += $ErrorRecord | Out-String }
            Add-Content -Path $Config.ErrorLogPath -Value $entry
        } catch { }
    }

    function Invoke-PlinkQuery {
        param([string]$Sql)
        $plinkPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot "plink.exe" } else { ".\plink.exe" }
        if (-not (Test-Path $plinkPath)) { return "ERROR: plink.exe not found" }

        $tempPassFile = [System.IO.Path]::GetTempFileName()
        $process = $null
        try {
            [System.IO.File]::WriteAllText($tempPassFile, $script:activeSshPass)
            $args = "-ssh -P $($Config.SshPort) $($script:activeSshUser)@$($Config.SshHost) -pwfile `"$tempPassFile`" -batch `"/usr/bin/mysql -u root -p`"$($script:activeDbPass)`" -D $($Config.DbName) -sN`""
            
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = $plinkPath
            $processInfo.Arguments = $args
            $processInfo.RedirectStandardInput = $true
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.UseShellExecute = $false
            $processInfo.CreateNoWindow = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            $process.Start() | Out-Null

            $process.StandardInput.WriteLine($Sql)
            $process.StandardInput.Close()
            
            $output = $process.StandardOutput.ReadToEnd()
            $error  = $process.StandardError.ReadToEnd()
            
            $process.WaitForExit()

            if (-not [string]::IsNullOrWhiteSpace($error) -and $error -notmatch "Using a password on the command line interface can be insecure") {
                return "ERROR: $error"
            }
            return $output -split "`r`n|`n" | Where-Object { $_ -match '\S' }
        }
        catch {
            Write-ErrorLog -Message "Failed to execute Plink query" -ErrorRecord $_
            return "ERROR: $($_.Exception.Message)"
        }
        finally {
            if (Test-Path $tempPassFile) { Remove-Item $tempPassFile -Force -ErrorAction SilentlyContinue }
            if ($process) { $process.Dispose() }
        }
    }

    function Save-History {
        param([int]$TotalOrders, [int]$Waved, [int]$AlreadyInWave, [string[]]$Locations)
        try {
            $dir = Split-Path $Config.HistoryPath
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

            $existing = @()
            if (Test-Path $Config.HistoryPath) {
                try {
                    $raw = ConvertFrom-Json ([System.IO.File]::ReadAllText($Config.HistoryPath))
                    $existing = @($raw | ForEach-Object { $_ })
                } catch { $existing = @() }
            }

            $entry = [PSCustomObject]@{
                Timestamp     = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                TotalOrders   = $TotalOrders
                Waved         = $Waved
                AlreadyInWave = $AlreadyInWave
                Locations     = ($Locations | Sort-Object -Unique) -join ", "
            }

            $combined = @($entry) + $existing
            if ($combined.Count -gt 100) { $combined = $combined[0..99] }

            [System.IO.File]::WriteAllText($Config.HistoryPath, (ConvertTo-Json -InputObject $combined -Depth 10))
        } catch { Write-ErrorLog -Message "Failed to save history" -ErrorRecord $_ }
    }

    $parsedOrdersList = New-Object System.Collections.Generic.List[PSCustomObject]
    $regex = [regex]'\b(\d{8})(?:[-_]?(\d{2}))?\b'
    foreach ($match in $regex.Matches($ctx.OrdersText)) {
        $base   = $match.Groups[1].Value
        $suffix = if ($match.Groups[2].Success) { $match.Groups[2].Value } else { "00" }
        $parsedOrdersList.Add([PSCustomObject]@{ Base = $base; Suffix = $suffix; FullOrder = "$base-$suffix" })
    }
    $parsedOrders = @($parsedOrdersList | Group-Object FullOrder | ForEach-Object { $_.Group[0] })

    if ($parsedOrders.Count -eq 0) {
        Update-UI "No valid orders found in the input box.`r`n" -AlwaysShow
        return
    }

    Update-UI "Processing $($parsedOrders.Count) unique order(s)...`r`n`r`n" -Status "Authenticating..."
    Update-UI "[1/4] Authenticating credentials...`r`n"
    
    $testConnection = Invoke-PlinkQuery -Sql "SELECT 1;"
    $testStr = $testConnection -join "`n"

    if ($testStr -match "ERROR 1045" -or $testStr -match "Access denied for user") { Update-UI "ERROR: MariaDB password is incorrect.`r`n" -AlwaysShow; return }
    elseif ($testStr -match "host key in batch mode") { Update-UI "CRITICAL ERROR: Unverified SSH Host.`r`nPlease run plink manually to accept the key.`r`n" -AlwaysShow; return }
    elseif ($testStr -match "Access denied" -or $testStr -match "FATAL ERROR" -or $testStr -match "Authentication failed") { Update-UI "ERROR: SSH Username or Password is incorrect.`r`n" -AlwaysShow; return }
    elseif ($testStr -notmatch "(?m)^1$") { Update-UI "ERROR: Unknown connection issue. Output:`r`n$testStr`r`n" -AlwaysShow; return }

    Update-UI "      -> SSH and Database connected successfully.`r`n" -Status "Syncing carriers..."
    Update-UI "      -> Syncing carrier display names from database...`r`n"

    $cgfidToCarrier = @{}
    $carrierRows = Invoke-PlinkQuery -Sql "SELECT GFID, Label1 FROM udc WHERE TopGFID IN ('10000000000001500', '10000000000001600');"
    if ($carrierRows -join "`n" -match "ERROR") { Update-UI "`r`nCRITICAL ERROR: Failed to query UDC carrier mappings.`r`n" -AlwaysShow; return }
    foreach ($row in $carrierRows) {
        $cols = $row -split "`t"
        if ($cols.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($cols[0])) { $cgfidToCarrier[$cols[0].Trim()] = $cols[1].Trim() }
    }

    $tableData = New-Object System.Collections.Generic.List[PSCustomObject]
    $wavedCount = 0
    $inWaveCount = 0
    $locationsUsed = New-Object System.Collections.Generic.List[string]
    $csvOrders = New-Object System.Collections.Generic.List[PSCustomObject]

    $unixMidnightUtc = [Math]::Floor((New-TimeSpan -Start (Get-Date "1970-01-01") -End (Get-Date).ToUniversalTime().Date).TotalSeconds)
    $unixCurrentTime = [Math]::Floor((New-TimeSpan -Start (Get-Date "1970-01-01") -End (Get-Date).ToUniversalTime()).TotalSeconds)

    if ($ctx.IsSts) {
        $selectedLoc = $ctx.StsLoc
        $selectedCarrier = $ctx.StsCarrier
        $selectedTag = $ctx.StsTag
        $rstr = $ctx.StsCarrierCgfid
        $pstr = $TagToPstr[$selectedTag]
        $activePid = $LocationPids[$selectedLoc]
        $sulid = $Config.DefaultSulid
        $schan = $Config.DefaultSchan

        Update-UI "[2/4] STS Mode: Bypassing archive scan.`r`n"
        Update-UI "[3/4] STS Mode: Bypassing DTS/Abhive sync.`r`n"
        Update-UI "[4/4] Processing final database operations... " -Status "Executing DB operations..."
        
        $existingOrders = @{}
        $safeBases = $parsedOrders.Base | Where-Object { $_ -match '^\d{8}$' } | Select-Object -Unique
        $inClause = "'" + ($safeBases -join "','") + "'"
        $dbRows = Invoke-PlinkQuery -Sql "SELECT ID, BO, Status FROM rdvorderhead WHERE ID IN ($inClause);"
        if ($dbRows -join "`n" -match "ERROR") { Update-UI "`r`nCRITICAL ERROR: Failed to query existing DB statuses.`r`n" -AlwaysShow; return }
        foreach ($row in $dbRows) {
            $cols = $row -split "`t"
            if ($cols.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($cols[0])) {
                $dbId = $cols[0].Trim()
                $dbBo = $cols[1].Trim()
                $boSuffix = if ($dbBo -match '^\d+$') { "{0:D2}" -f [int]$dbBo } else { "00" }
                $fullOrderKey = "$dbId-$boSuffix"
                $existingOrders[$fullOrderKey] = @{ Status = $cols[2].Trim() }
            }
        }

        $pendingInserts = New-Object System.Collections.Generic.List[PSCustomObject]
        $insertCounter = 0

        foreach ($order in $parsedOrders) {
            $base = $order.Base
            if ($existingOrders.ContainsKey($order.FullOrder)) {
                $status = $existingOrders[$order.FullOrder].Status
                if ($status -eq "10") {
                    $tableData.Add([PSCustomObject]@{ Order=$order.FullOrder; Status="10"; Loc=$selectedLoc; Carrier=$selectedCarrier; OD=$selectedTag; Action="Already in Wave"; IsNone=1 })
                    $inWaveCount++
                } else {
                    $tableData.Add([PSCustomObject]@{ Order=$order.FullOrder; Status=$status; Loc=$selectedLoc; Carrier=$selectedCarrier; OD=$selectedTag; Action="None"; IsNone=0 })
                }
                continue
            }

            $insertCounter++
            $safeGfid = "305" + (Get-Date -Format "yyMMddHHmmss") + "{0:D3}" -f $insertCounter
            $boInt = [int]$order.Suffix
            $insertQuery = @"
INSERT INTO rdvorderhead 
(GFID, PULID, Brand, ID, ID2, BO, SChan, SULID, PGFID, OrderHostCode, PricePfx, PriceSfx, Typ, PO, Customer, BillToCode, ShipTo, ShipToCode, CtnQty, LnQty, ItemQty, CtnPicked, CtnPacked, UnixOrder, UnixPickup, UnixShip, UnixDelivery, CGFID, Tracking, Note, Msg, Confirmed, Status, UnixCreated, CreatedBy, UnixDropped, DroppedBy, UnixShipped, ShippedBy, UnixLast, LastBy, LastFGFID) 
VALUES 
('$safeGfid', '$activePid', '$($Config.BrandGfid)', '$base', '', '$boInt', '$schan', '$sulid', '0', '', '', '', '$pstr', '', '', '', '', '', '0', '0', '0', '0', '0', '$unixMidnightUtc', '$unixMidnightUtc', '0', '$unixMidnightUtc', '$rstr', '', '', '', '0', '10', '$unixCurrentTime', '$($Config.CreatedByGfid)', '0', '', '0', '', '0', '', '0');
"@
            $pendingInserts.Add([PSCustomObject]@{ Query=$insertQuery; Order=$order.FullOrder; Loc=$selectedLoc; Carrier=$selectedCarrier; Tag=$selectedTag })
        }

        if ($pendingInserts.Count -gt 0) {
            Update-UI " Executing $($pendingInserts.Count) insert(s)..."
            $batchSql = ($pendingInserts | Select-Object -ExpandProperty Query) -join "`n"
            $batchResult = Invoke-PlinkQuery -Sql $batchSql
            $batchStr = $batchResult -join "`n"

            if ($batchStr -match "ERROR") {
                Update-UI "`r`nSQL ERROR: $batchStr`r`n" -AlwaysShow
                foreach ($p in $pendingInserts) { $tableData.Add([PSCustomObject]@{ Order=$p.Order; Status="RNF"; Loc=$p.Loc; Carrier=$p.Carrier; OD=$p.Tag; Action="FAILED (SQL Error)"; IsNone=1 }) }
            } else {
                foreach ($p in $pendingInserts) {
                    $tableData.Add([PSCustomObject]@{ Order=$p.Order; Status="RNF"; Loc=$p.Loc; Carrier=$p.Carrier; OD=$p.Tag; Action="WAVED"; IsNone=1 })
                    $wavedCount++
                }
            }
        }

        $locationsUsed.Add($selectedLoc)
        foreach ($p in $tableData) {
            if ($p.Action -eq "WAVED" -or $p.Action -eq "Already in Wave") {
                $csvOrders.Add([PSCustomObject]@{ Order = $p.Order; Loc = $p.Loc })
            }
        }
    } else {
        $uniqueBases = $parsedOrders.Base | Select-Object -Unique

        $existingOrders = @{}
        $safeBases = $uniqueBases | Where-Object { $_ -match '^\d{8}$' }
        $inClause = "'" + ($safeBases -join "','") + "'"
        
        $dbRows = Invoke-PlinkQuery -Sql "SELECT ID, BO, Status, PULID, Typ, CGFID FROM rdvorderhead WHERE ID IN ($inClause);"
        if ($dbRows -join "`n" -match "ERROR") { Update-UI "`r`nCRITICAL ERROR: Failed to query existing DB statuses.`r`n" -AlwaysShow; return }
        foreach ($row in $dbRows) {
            $cols = $row -split "`t"
            if ($cols.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($cols[0])) {
                $dbId = $cols[0].Trim()
                $dbBo = $cols[1].Trim()
                $boSuffix = if ($dbBo -match '^\d+$') { "{0:D2}" -f [int]$dbBo } else { "00" }
                $fullOrderKey = "$dbId-$boSuffix"
                $existingOrders[$fullOrderKey] = @{ Status = $cols[2].Trim(); Pulid = $cols[3].Trim(); Typ = $cols[4].Trim(); CgfId = $cols[5].Trim() }
            }
        }

        $targetLookup = @{}
        foreach ($order in $parsedOrders) { if (-not $existingOrders.ContainsKey($order.FullOrder)) { $targetLookup[$order.FullOrder] = $true } }

        $csvDataMap = @{}

        if ($targetLookup.Count -gt 0) {
            Update-UI "[2/4] Searching public archive for $($targetLookup.Count) missing order(s)...`r`n" -Status "Scanning archives..."
            $recentCsvs = @(Get-ChildItem -Path $Config.NetworkCsvPath -Filter "*carton3_status_alo_avatam*.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First $script:scanDepth)
            $intakeCsvs = @(Get-ChildItem -Path $Config.NetworkCsvPath -Filter "*_alo_orderintake.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First $script:scanDepth)

            $cartonIdx = 0; $intakeIdx = 0; $allDone = $false
            Update-UI "[3/4] Interleaved scan: up to $script:scanDepth carton + $script:scanDepth intake files in batches of $script:batchSize...`r`n"

            $cartonChecked = 0; $cartonFound = 0; $intakeChecked = 0; $intakeFound = 0

            while (-not $allDone -and ($cartonIdx -lt $recentCsvs.Count -or $intakeIdx -lt $intakeCsvs.Count)) {
                $cartonBatchEnd = [Math]::Min($cartonIdx + $script:batchSize, $recentCsvs.Count)
                while ($cartonIdx -lt $cartonBatchEnd) {
                    $file = $recentCsvs[$cartonIdx]; $cartonIdx++; $cartonChecked++
                    $foundInThisFile = 0
                    $reader = $null
                    try {
                        $reader = [System.IO.File]::OpenText($file.FullName)
                        $headerLine = $reader.ReadLine()
                        if ($headerLine) {
                            $headers = $headerLine -split ','
                            $hMap = @{}
                            for ($i=0; $i -lt $headers.Length; $i++) { $hMap[$headers[$i].Trim('"')] = $i }
                            $idxOrder = $hMap["Order"]; $idxHazmat = $hMap["Hazmat"]; $idxGift = $hMap["Gift Card"]
                            $idxWH = $hMap["WH"]; $idxCarrier = $hMap["Carrier/Service"]; $idxOrderCode = $hMap["Order Code"]; $idxCustNum = $hMap["Cust Number"]
                            
                            while ($null -ne ($line = $reader.ReadLine())) {
                                $cols = $line -split ','
                                
                                $orderRaw = if ($idxOrder -ne $null -and $idxOrder -lt $cols.Length) { $cols[$idxOrder].Trim('"') } else { "" }
                                $orderFull = if ($orderRaw -match '^(\d{8})$') { "$orderRaw-00" } elseif ($orderRaw -match '^(\d{8})[-_]?(\d{2})$') { "$($Matches[1])-$($Matches[2])" } else { $orderRaw }
                                if ($targetLookup.ContainsKey($orderFull)) {
                                    $isHazmat = if ($idxHazmat -ne $null -and $idxHazmat -lt $cols.Length) { $cols[$idxHazmat].Trim('"') -match "Y|1|True" } else { $false }
                                    $isGift   = if ($idxGift -ne $null -and $idxGift -lt $cols.Length) { $cols[$idxGift].Trim('"') -match "Y|1|True" } else { $false }

                                    if (-not $csvDataMap.ContainsKey($orderBase)) {
                                        $wh = if ($idxWH -ne $null -and $idxWH -lt $cols.Length) { $cols[$idxWH].Trim('"').ToLower() } else { "" }
                                        $csvDataMap[$orderBase] = [PSCustomObject]@{
                                            Carrier   = if ($idxCarrier -ne $null -and $idxCarrier -lt $cols.Length) { $cols[$idxCarrier].Trim('"') } else { "" }
                                            OrderCode = if ($idxOrderCode -ne $null -and $idxOrderCode -lt $cols.Length) { $cols[$idxOrderCode].Trim('"') } else { "" }
                                            IsHazmat  = $isHazmat; IsGift = $isGift
                                            Loc       = switch ($wh) { "av" {"NV"} "am" {"MD"} "at" {"TX"} default {"N/A"} }
                                            Source    = "carton"
                                            CustNum   = if ($idxCustNum -ne $null -and $idxCustNum -lt $cols.Length) { $cols[$idxCustNum].Trim('"') } else { "" }
                                            Ctry      = ""
                                        }
                                        $foundInThisFile++
                                    } elseif ($csvDataMap[$orderBase].Source -eq "intake" -and ($isHazmat -or $isGift)) {
                                        $csvDataMap[$orderBase].IsHazmat = $isHazmat; $csvDataMap[$orderBase].IsGift = $isGift
                                    }
                                }
                            }
                        }
                    } catch { Write-ErrorLog -Message "Failed reading carton CSV $($file.FullName)" -ErrorRecord $_ }
                    finally { if ($reader) { $reader.Dispose() } }
                    $cartonFound += $foundInThisFile
                    Update-UI -Status "Scanning... [Carton: $cartonChecked checked, $cartonFound found] [Intake: $intakeChecked checked, $intakeFound found]"
                }

                $resolvedCount = 0
                foreach ($k in $targetLookup.Keys) { if ($csvDataMap.ContainsKey($k)) { if ($csvDataMap[$k].OrderCode -match "(?i)AYStoreF") { if ($csvDataMap[$k].CustNum -match "[A-Za-z]") { $resolvedCount++ } } else { $resolvedCount++ } } }
                if ($resolvedCount -ge $targetLookup.Count) { $allDone = $true; break }

                $intakeBatchEnd = [Math]::Min($intakeIdx + $script:batchSize, $intakeCsvs.Count)
                while ($intakeIdx -lt $intakeBatchEnd) {
                    $file = $intakeCsvs[$intakeIdx]; $intakeIdx++; $intakeChecked++
                    $foundInThisFile = 0
                    $reader = $null
                    try {
                        $reader = [System.IO.File]::OpenText($file.FullName)
                        $headerLine = $reader.ReadLine()
                        if ($headerLine) {
                            $headers = $headerLine -split ','
                            $hMap = @{}
                            for ($i=0; $i -lt $headers.Length; $i++) { $hMap[$headers[$i].Trim('"')] = $i }
                            $idxOrder = $hMap["Order #"]; $idxAddrNo = $hMap["Address No"]; $idxCtry = $hMap["Ctry"]
                            $idxWH = $hMap["Warehouse"]; $idxCarrier = $hMap["Carrier"]; $idxOrderCode = $hMap["Order Code"]

                            while ($null -ne ($line = $reader.ReadLine())) {
                                $cols = $line -split ','
                                
                                $orderNum = if ($idxOrder -ne $null -and $idxOrder -lt $cols.Length) { $cols[$idxOrder].Trim('"') } else { "" }
                                if ($orderNum -match '^(\d{8})(?:[-_]?(\d{2}))?') {
                                    $orderBase = $Matches[1]
                                    $orderSuf = if ($Matches[2]) { $Matches[2] } else { "00" }
                                    $orderFull = "$orderBase-$orderSuf"
                                    if ($targetLookup.ContainsKey($orderFull)) {
                                        $addrNo = if ($idxAddrNo -ne $null -and $idxAddrNo -lt $cols.Length) { $cols[$idxAddrNo].Trim('"') } else { "" }
                                        $ctry = if ($idxCtry -ne $null -and $idxCtry -lt $cols.Length) { $cols[$idxCtry].Trim('"').ToUpper() } else { "" }
                                        if (-not $csvDataMap.ContainsKey($orderBase)) {
                                            $wh = if ($idxWH -ne $null -and $idxWH -lt $cols.Length) { $cols[$idxWH].Trim('"').ToUpper() } else { "" }
                                            $intakeCarrier = if ($idxCarrier -ne $null -and $idxCarrier -lt $cols.Length) { $cols[$idxCarrier].Trim('"') } else { "" }
                                            $csvDataMap[$orderBase] = [PSCustomObject]@{
                                                Carrier   = $intakeCarrier
                                                OrderCode = if ($idxOrderCode -ne $null -and $idxOrderCode -lt $cols.Length) { $cols[$idxOrderCode].Trim('"') } else { "" }
                                                IsHazmat  = $false; IsGift = $false
                                                Loc       = switch ($wh) { "AV" {"NV"} "AM" {"MD"} "AT" {"TX"} "ATC" {"TX"} default {"N/A"} }
                                                Ctry      = $ctry; Source = "intake"; CustNum = $addrNo
                                            }
                                            $foundInThisFile++
                                        } elseif ($csvDataMap[$orderBase].OrderCode -match "(?i)AYStoreF" -and $csvDataMap[$orderBase].CustNum -notmatch "[A-Za-z]") {
                                            $csvDataMap[$orderBase].Ctry = $ctry
                                            if ($addrNo -match "[A-Za-z]") { $csvDataMap[$orderBase].CustNum = $addrNo; $foundInThisFile++ }
                                        }
                                    }
                                }
                            }
                        }
                    } catch { Write-ErrorLog -Message "Failed reading intake CSV $($file.FullName)" -ErrorRecord $_ }
                    finally { if ($reader) { $reader.Dispose() } }
                    $intakeFound += $foundInThisFile
                    Update-UI -Status "Scanning... [Carton: $cartonChecked checked, $cartonFound found] [Intake: $intakeChecked checked, $intakeFound found]"
                }

                $resolvedCount = 0
                foreach ($k in $targetLookup.Keys) { if ($csvDataMap.ContainsKey($k)) { if ($csvDataMap[$k].OrderCode -match "(?i)AYStoreF") { if ($csvDataMap[$k].CustNum -match "[A-Za-z]") { $resolvedCount++ } } else { $resolvedCount++ } } }
                if ($resolvedCount -ge $targetLookup.Count) { $allDone = $true }
            }
        } else {
            Update-UI "[2/4] All orders already exist in DB. Skipping carton status downloads.`r`n"
            Update-UI "[3/4] Database pre-flight complete.`r`n"
        }

        $dtsCustNums = @()
        foreach ($v in $csvDataMap.Values) {
            if ($v.OrderCode -match "(?i)DTS|DTW|AYStoreF") {
                $cn = $v.CustNum.Trim().Replace("'", "''").ToUpper()
                if ($cn -match "[A-Za-z]") { $dtsCustNums += $cn }
            }
        }
        $dtsCustNums = $dtsCustNums | Select-Object -Unique

        $abhiveDict = @{}
        if ($dtsCustNums.Count -gt 0) {
            Update-UI "      -> Syncing DTS Store locations from abhive...`r`n" -Status "Syncing DTS..."
            $inCust = "'" + ($dtsCustNums -join "','") + "'"
            $abhiveRows = Invoke-PlinkQuery -Sql "SELECT Label2, ULID FROM abhive WHERE Label2 IN ($inCust);"
            if ($abhiveRows -join "`n" -match "ERROR") { Update-UI "`r`nCRITICAL ERROR: Failed to query abhive mappings.`r`n" -AlwaysShow; return }
            foreach ($row in $abhiveRows) {
                $cols = $row -split "`t"
                if ($cols.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($cols[0])) { $abhiveDict[$cols[0].Trim().ToUpper()] = $cols[1].Trim() }
            }
        }

        Update-UI "[4/4] Processing final database operations... " -Status "Executing DB operations..."
        $pendingInserts  = New-Object System.Collections.Generic.List[PSCustomObject]
        $insertCounter   = 0

        foreach ($order in $parsedOrders) {
            $base = $order.Base
            $fullOrder = $order.FullOrder

            if ($existingOrders.ContainsKey($fullOrder)) {
                $existing  = $existingOrders[$fullOrder]
                $dbLoc     = if ($PidToLoc[$existing.Pulid]) { $PidToLoc[$existing.Pulid] } else { "--" }
                $dbTag     = if ($TypToTag.ContainsKey($existing.Typ)) { $TypToTag[$existing.Typ] } else { "--" }
                $dbCarrier = if ($cgfidToCarrier.ContainsKey($existing.CgfId)) { $cgfidToCarrier[$existing.CgfId] } else { $existing.CgfId }
                if ($existing.Status -eq "10") {
                    $csvOrders.Add([PSCustomObject]@{ Order = $order.FullOrder; Loc = $dbLoc })
                    $tableData.Add([PSCustomObject]@{ Order=$order.FullOrder; Status="10"; Loc=$dbLoc; Carrier=$dbCarrier; OD=$dbTag; Action=if ($createCsv) { "Added to CSV" } else { "In Wave" }; IsNone=1 })
                } else {
                    $tableData.Add([PSCustomObject]@{ Order=$order.FullOrder; Status=$existing.Status; Loc=$dbLoc; Carrier=$dbCarrier; OD=$dbTag; Action="None"; IsNone=0 })
                }
                continue
            }

            $localData = $csvDataMap[$fullOrder]
            if ($null -eq $localData) { $tableData.Add([PSCustomObject]@{ Order=$order.FullOrder; Status="RNF"; Loc="--"; Carrier="--"; OD="--"; Action="Manual Wave"; IsNone=1 }); continue }

            $displayLoc = $localData.Loc
            if ($displayLoc -eq "N/A" -or -not $LocationPids.ContainsKey($displayLoc)) {
                $cleanCarrier = if ([string]::IsNullOrWhiteSpace($localData.Carrier)) { "--" } else { $localData.Carrier.Trim() }
                $tableData.Add([PSCustomObject]@{ Order=$order.FullOrder; Status="RNF"; Loc="--"; Carrier=$cleanCarrier; OD="--"; Action="Unknown WH"; IsNone=1 })
                continue
            }

            $isDTS      = ($localData.OrderCode -match "(?i)DTS|DTW|AYStoreF")
            $ctry       = if ($null -ne $localData.Ctry) { $localData.Ctry.Trim().ToUpper() } else { "" }
            $rawCarrier = if ($null -ne $localData.Carrier) { $localData.Carrier.Trim() } else { "" }

            $tag = "WEB"
            if ($isDTS) { $tag = "DTS" }
            elseif ($localData.Source -eq "intake") {
                if ($rawCarrier -match "(?i)GLOBALE" -or ($ctry -and $ctry -ne "US")) { $tag = "WEB Intl" }
            } else {
                if ($rawCarrier -match "(?i)GLOBALE" -or $localData.OrderCode -match "(?i)intl") { $tag = "WEB Intl" }
                elseif ($localData.IsHazmat -or $localData.IsGift) { $tag = "WEB Spc" }
            }

            $schan = $Config.DefaultSchan
            $sulid = $Config.DefaultSulid

            if ($tag -eq "DTS") {
                $custNum = $localData.CustNum.ToUpper()
                if (-not [string]::IsNullOrWhiteSpace($custNum) -and $abhiveDict.ContainsKey($custNum)) {
                    $sulid = $abhiveDict[$custNum]
                } else {
                    $tableData.Add([PSCustomObject]@{ Order=$order.FullOrder; Status="RNF"; Loc=$displayLoc; Carrier=$rawCarrier; OD="DTS"; Action="Missing Abhive ($custNum)"; IsNone=1 })
                    continue
                }
                $schan = $Config.DtsSchan
                $pstr  = "14000000000000310"
            } else {
                $pstr = $TagToPstr[$tag]
            }

            if ($tag -eq "DTS") {
                if ($CountryToCarrierGfid.ContainsKey($ctry)) { $rstr = $CountryToCarrierGfid[$ctry] }
                elseif ($localData.Source -eq "intake" -and $IntakeCarrierToCgfid.ContainsKey($rawCarrier)) { $rstr = $IntakeCarrierToCgfid[$rawCarrier] }
                elseif ($localData.Source -eq "carton" -and $CsvCarrierToCgfid.ContainsKey($rawCarrier)) { $rstr = $CsvCarrierToCgfid[$rawCarrier] }
                else { $rstr = "0" }
            } elseif ($tag -eq "WEB Intl") {
                $rstr = "296246482205620224"
            } else {
                if ($localData.Source -eq "intake" -and $IntakeCarrierToCgfid.ContainsKey($rawCarrier)) { $rstr = $IntakeCarrierToCgfid[$rawCarrier] }
                elseif ($localData.Source -eq "carton" -and $CsvCarrierToCgfid.ContainsKey($rawCarrier)) { $rstr = $CsvCarrierToCgfid[$rawCarrier] }
                else { $rstr = "10000000000001601" }
            }

            $cleanCarrier = if ($rstr -eq "0") { "None" } elseif ($cgfidToCarrier.ContainsKey($rstr)) { $cgfidToCarrier[$rstr] } else { $rstr }

            $activePid = $LocationPids[$displayLoc]
            $boInt     = [int]$order.Suffix
            $insertCounter++
            $safeGfid  = "305" + (Get-Date -Format "yyMMddHHmmss") + "{0:D3}" -f $insertCounter

            $insertQuery = @"
INSERT INTO rdvorderhead 
(GFID, PULID, Brand, ID, ID2, BO, SChan, SULID, PGFID, OrderHostCode, PricePfx, PriceSfx, Typ, PO, Customer, BillToCode, ShipTo, ShipToCode, CtnQty, LnQty, ItemQty, CtnPicked, CtnPacked, UnixOrder, UnixPickup, UnixShip, UnixDelivery, CGFID, Tracking, Note, Msg, Confirmed, Status, UnixCreated, CreatedBy, UnixDropped, DroppedBy, UnixShipped, ShippedBy, UnixLast, LastBy, LastFGFID) 
VALUES 
('$safeGfid', '$activePid', '$($Config.BrandGfid)', '$base', '', '$boInt', '$schan', '$sulid', '0', '', '', '', '$pstr', '', '', '', '', '', '0', '0', '0', '0', '0', '$unixMidnightUtc', '$unixMidnightUtc', '0', '$unixMidnightUtc', '$rstr', '', '', '', '0', '10', '$unixCurrentTime', '$($Config.CreatedByGfid)', '0', '', '0', '', '0', '', '0');
"@
            $pendingInserts.Add([PSCustomObject]@{ Query=$insertQuery; Order=$order.FullOrder; Loc=$displayLoc; Carrier=$cleanCarrier; Tag=if ($tag -eq "DTS") { "REPLEN" } else { $tag } })
        }

        if ($pendingInserts.Count -gt 0) {
            Update-UI " Executing $($pendingInserts.Count) insert(s)..."
            $batchSql    = ($pendingInserts | Select-Object -ExpandProperty Query) -join "`n"
            $batchResult = Invoke-PlinkQuery -Sql $batchSql
            $batchStr    = $batchResult -join "`n"

            if ($batchStr -match "ERROR") {
                Update-UI "`r`nSQL ERROR: $batchStr`r`n" -AlwaysShow
                foreach ($p in $pendingInserts) { $tableData.Add([PSCustomObject]@{ Order=$p.Order; Status="RNF"; Loc=$p.Loc; Carrier=$p.Carrier; OD=$p.Tag; Action="FAILED (SQL Error)"; IsNone=1 }) }
            } else {
                foreach ($p in $pendingInserts) {
                    $csvOrders.Add([PSCustomObject]@{ Order = $p.Order; Loc = $p.Loc })
                    $tableData.Add([PSCustomObject]@{ Order=$p.Order; Status="RNF"; Loc=$p.Loc; Carrier=$p.Carrier; OD=$p.Tag; Action="WAVED"; IsNone=1 })
                    $wavedCount++
                }
            }
        }
        
        foreach ($row in $tableData) {
            if ($row.Action -match "Added to CSV|In Wave") { $inWaveCount++ }
            if (-not [string]::IsNullOrWhiteSpace($row.Loc) -and $row.Loc -notmatch "--|N/A") { $locationsUsed.Add($row.Loc) }
        }
    }

    Update-UI " Done!`r`n`r`n" -Status "Rendering results..."
    
    $lineFormat = "{0,-14}{1,-8}{2,-6}{3,-18}{4,-16}{5}`r`n"
    Update-UI ($lineFormat -f "Order:", "Status:", "Loc:", "Carrier:", "OD:", "Action:")
    Update-UI ("-" * 80 + "`r`n")

    $sortProps = @(
        @{ Expression = {
            if ($_.Action -eq "None") { 0 }
            elseif ($_.Action -match "(?i)In Wave|Added to CSV|Already in Wave") { 1 }
            elseif ($_.Action -match "(?i)WAVED") { 2 }
            else { 3 }
          }; Ascending = $true },
        @{ Expression = {
            if ($_.Loc -eq "MD") { 0 }
            elseif ($_.Loc -eq "TX") { 1 }
            elseif ($_.Loc -eq "NV") { 2 }
            else { 3 }
          }; Ascending = $true },
        @{ Expression = { try { [int]$_.Status } catch { 0 } }; Ascending = $false },
        @{ Expression = {
            if ($_.OD -eq "WEB") { 1 }
            elseif ($_.OD -eq "WEB Spc") { 2 }
            elseif ($_.OD -eq "WEB Intl") { 3 }
            elseif ($_.OD -match "^WEB") { 4 }
            else { 0 }
          }; Ascending = $true },
        @{ Expression = { $_.Carrier }; Ascending = $true }
    )
    
    $sortedData = $tableData | Sort-Object $sortProps

    foreach ($row in $sortedData) { Update-UI ($lineFormat -f $row.Order, $row.Status, $row.Loc, $row.Carrier, $row.OD, $row.Action) }

    Update-UI "`r`nExecution finished.`r`n" -AlwaysShow
    
    if ($createCsv -and $csvOrders.Count -gt 0) {
        $csvDir = Join-Path $env:USERPROFILE "Downloads"
        if (-not (Test-Path $csvDir)) { New-Item -ItemType Directory -Path $csvDir -Force | Out-Null }
        $timestamp = Get-Date -Format 'MMddyyyyHHmm'

        foreach ($group in ($csvOrders | Group-Object Loc)) {
            $locTag   = if ([string]::IsNullOrWhiteSpace($group.Name)) { "UNK" } else { $group.Name -replace '[^A-Za-z0-9]', '' }
            $filePath = Join-Path $csvDir "$($locTag)$timestamp.csv"
            [System.IO.File]::WriteAllText($filePath, (($group.Group | Select-Object -ExpandProperty Order) -join "`r`n") + "`r`n")
            Update-UI "`r`n[+] Created CSV: $(Split-Path $filePath -Leaf) in Downloads.`r`n" -AlwaysShow
            if ($openCsv) { Invoke-Item $filePath }
        }
        Update-UI "`r`n" -AlwaysShow
    }

    Save-History -TotalOrders $parsedOrders.Count -Waved $wavedCount -AlreadyInWave $inWaveCount -Locations ($locationsUsed.ToArray())
    
    $lastRunData = @($sortedData | Where-Object { $_.Action -match "(?i)WAVED|Add(ed)? to CSV|In Wave|Already in Wave" } | Select-Object Order, Loc)
    $resultQueue.Enqueue(@{ LastRunData = $lastRunData })
}

 $mainForm = New-Object System.Windows.Forms.Form
 $mainForm.Text = "EZ-RNF"
 $mainForm.ClientSize = New-Object System.Drawing.Size(800, 565)
 $mainForm.StartPosition = "CenterScreen"
 $mainForm.FormBorderStyle = "Sizable"
 $mainForm.MaximizeBox = $true
 $mainForm.MinimumSize = New-Object System.Drawing.Size(800, 565)

 $menuStrip = New-Object System.Windows.Forms.MenuStrip

 $menuView = New-Object System.Windows.Forms.ToolStripMenuItem("View")
 $menuClearOutput = New-Object System.Windows.Forms.ToolStripMenuItem("Clear Output")
 $menuClearInput  = New-Object System.Windows.Forms.ToolStripMenuItem("Clear Input")
 $menuAlwaysOnTop = New-Object System.Windows.Forms.ToolStripMenuItem("Always on Top")
 $menuAlwaysOnTop.CheckOnClick = $true
 $menuWordWrap    = New-Object System.Windows.Forms.ToolStripMenuItem("Word Wrap")
 $menuWordWrap.CheckOnClick = $true
 $menuScrollBottom = New-Object System.Windows.Forms.ToolStripMenuItem("Scroll to Bottom")

 $menuFontSize    = New-Object System.Windows.Forms.ToolStripMenuItem("Font Size")
 $menuFontSmall   = New-Object System.Windows.Forms.ToolStripMenuItem("Small (8pt)")
 $menuFontMedium  = New-Object System.Windows.Forms.ToolStripMenuItem("Medium (9pt)")
 $menuFontLarge   = New-Object System.Windows.Forms.ToolStripMenuItem("Large (11pt)")
 $menuFontMedium.Checked = $true
 $menuFontSize.DropDownItems.AddRange(@($menuFontSmall, $menuFontMedium, $menuFontLarge))

 $menuView.DropDownItems.AddRange(@(
    $menuClearOutput, $menuClearInput, (New-Object System.Windows.Forms.ToolStripSeparator),
    $menuAlwaysOnTop, $menuWordWrap, $menuScrollBottom, (New-Object System.Windows.Forms.ToolStripSeparator),
    $menuFontSize
))

 $menuOptions   = New-Object System.Windows.Forms.ToolStripMenuItem("Options")
 $menuCreateCsv = New-Object System.Windows.Forms.ToolStripMenuItem("Create CSV")
 $menuCreateCsv.CheckOnClick = $true
 $menuOpenCsv   = New-Object System.Windows.Forms.ToolStripMenuItem("Open CSV")
 $menuOpenCsv.CheckOnClick = $true

 $menuScanDepth  = New-Object System.Windows.Forms.ToolStripMenuItem("Archive Scan Depth")
 $menuScan12     = New-Object System.Windows.Forms.ToolStripMenuItem("12 files (~12 hrs)")
 $menuScan24     = New-Object System.Windows.Forms.ToolStripMenuItem("24 files (~24 hrs)")
 $menuScan48     = New-Object System.Windows.Forms.ToolStripMenuItem("48 files (~48 hrs)")
 $menuScan24.Checked = $true
 $menuScanDepth.DropDownItems.AddRange(@($menuScan12, $menuScan24, $menuScan48))

 $menuBatchSize  = New-Object System.Windows.Forms.ToolStripMenuItem("Batch Size")
 $menuBatch1     = New-Object System.Windows.Forms.ToolStripMenuItem("1 file per source")
 $menuBatch3     = New-Object System.Windows.Forms.ToolStripMenuItem("3 files per source")
 $menuBatch5     = New-Object System.Windows.Forms.ToolStripMenuItem("5 files per source")
 $menuBatch3.Checked = $true
 $menuBatchSize.DropDownItems.AddRange(@($menuBatch1, $menuBatch3, $menuBatch5))

 $menuOptions.DropDownItems.AddRange(@(
    $menuCreateCsv, $menuOpenCsv, (New-Object System.Windows.Forms.ToolStripSeparator),
    $menuScanDepth, $menuBatchSize
))

 $menuTools        = New-Object System.Windows.Forms.ToolStripMenuItem("Tools")
 $menuWaveHistory  = New-Object System.Windows.Forms.ToolStripMenuItem("Wave History")
 $menuCheckPlink   = New-Object System.Windows.Forms.ToolStripMenuItem("Check for plink")
 $menuClearCreds   = New-Object System.Windows.Forms.ToolStripMenuItem("Clear Saved Credentials")
 $menuTools.DropDownItems.AddRange(@($menuWaveHistory, (New-Object System.Windows.Forms.ToolStripSeparator), $menuCheckPlink, $menuClearCreds))

 $menuLang   = New-Object System.Windows.Forms.ToolStripMenuItem("Language")
 $menuLangEN = New-Object System.Windows.Forms.ToolStripMenuItem("English")
 $menuLangES = New-Object System.Windows.Forms.ToolStripMenuItem("Español")
 $menuLangEN.CheckOnClick = $true
 $menuLangES.CheckOnClick = $true
 $menuLangEN.Checked = $true
 $menuLang.DropDownItems.AddRange(@($menuLangEN, $menuLangES))

 $menuStrip.Items.AddRange(@($menuView, $menuOptions, $menuTools, $menuLang))
 $mainForm.MainMenuStrip = $menuStrip
 $mainForm.Controls.Add($menuStrip)

 $lblUser = New-Object System.Windows.Forms.Label; $lblUser.Location = New-Object System.Drawing.Point(20, 39); $lblUser.Size = New-Object System.Drawing.Size(150, 15); $lblUser.Text = "SSH Username:"
 $txtUser = New-Object System.Windows.Forms.TextBox; $txtUser.Location = New-Object System.Drawing.Point(20, 54); $txtUser.Size = New-Object System.Drawing.Size(150, 20)

 $lblSshPass = New-Object System.Windows.Forms.Label; $lblSshPass.Location = New-Object System.Drawing.Point(20, 79); $lblSshPass.Size = New-Object System.Drawing.Size(150, 15); $lblSshPass.Text = "SSH Password:"
 $txtSshPass = New-Object System.Windows.Forms.TextBox; $txtSshPass.Location = New-Object System.Drawing.Point(20, 94); $txtSshPass.Size = New-Object System.Drawing.Size(150, 20); $txtSshPass.PasswordChar = '*'

 $lblDbPass = New-Object System.Windows.Forms.Label; $lblDbPass.Location = New-Object System.Drawing.Point(20, 119); $lblDbPass.Size = New-Object System.Drawing.Size(150, 15); $lblDbPass.Text = "MariaDB Password:"
 $txtDbPass = New-Object System.Windows.Forms.TextBox; $txtDbPass.Location = New-Object System.Drawing.Point(20, 134); $txtDbPass.Size = New-Object System.Drawing.Size(150, 20); $txtDbPass.PasswordChar = '*'

 $inputLabel = New-Object System.Windows.Forms.Label; $inputLabel.Location = New-Object System.Drawing.Point(20, 164); $inputLabel.Size = New-Object System.Drawing.Size(150, 15); $inputLabel.Text = "Paste Orders:"
 $inputTextBox = New-Object System.Windows.Forms.RichTextBox; $inputTextBox.Location = New-Object System.Drawing.Point(20, 179); $inputTextBox.Size = New-Object System.Drawing.Size(150, 230); $inputTextBox.WordWrap = $false
 $inputTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

 $inputTextBox.Add_KeyDown({
    param($s, $e)
    if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::V) {
        $e.SuppressKeyPress = $true
        $clipText = [System.Windows.Forms.Clipboard]::GetText()
        if (-not [string]::IsNullOrEmpty($clipText)) {
            $cleaned  = ($clipText -split "`r`n|`n|`r" | Where-Object { $_ -match '\S' }) -join "`r`n"
            $selStart = $inputTextBox.SelectionStart
            $selLen   = $inputTextBox.SelectionLength
            $before   = $inputTextBox.Text.Substring(0, $selStart)
            $after    = $inputTextBox.Text.Substring($selStart + $selLen)
            $needsNewlineBefore = $before.Length -gt 0 -and -not $before.EndsWith("`n")
            $insert = $(if ($needsNewlineBefore) { "`r`n" } else { "" }) + $cleaned + "`r`n"
            $inputTextBox.Text = $before + $insert + $after
            $inputTextBox.SelectionStart = $selStart + $insert.Length
        }
    }
})

 $createCsvCheckbox = New-Object System.Windows.Forms.CheckBox; $createCsvCheckbox.Location = New-Object System.Drawing.Point(20, 417); $createCsvCheckbox.Size = New-Object System.Drawing.Size(160, 20); $createCsvCheckbox.Text = "Create CSV when finished"; $createCsvCheckbox.Checked = $true
 $createCsvCheckbox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

 $openCsvCheckbox = New-Object System.Windows.Forms.CheckBox; $openCsvCheckbox.Location = New-Object System.Drawing.Point(20, 440); $openCsvCheckbox.Size = New-Object System.Drawing.Size(160, 20); $openCsvCheckbox.Text = "Open CSV when finished"; $openCsvCheckbox.Checked = $true
 $openCsvCheckbox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

 $processButton = New-Object System.Windows.Forms.Button; $processButton.Location = New-Object System.Drawing.Point(20, 469); $processButton.Size = New-Object System.Drawing.Size(150, 35); $processButton.Text = "Process Orders"; $processButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
 $processButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

 $copyOrdersButton = New-Object System.Windows.Forms.Button; $copyOrdersButton.Location = New-Object System.Drawing.Point(20, 508); $copyOrdersButton.Size = New-Object System.Drawing.Size(150, 22); $copyOrdersButton.Text = "Copy Orders"; $copyOrdersButton.Font = New-Object System.Drawing.Font("Segoe UI", 8); $copyOrdersButton.Enabled = $false
 $copyOrdersButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

 $outputLabel = New-Object System.Windows.Forms.Label; $outputLabel.Location = New-Object System.Drawing.Point(190, 39); $outputLabel.Size = New-Object System.Drawing.Size(200, 15); $outputLabel.Text = "System Output:"
 $outputTextBox = New-Object System.Windows.Forms.TextBox; $outputTextBox.Location = New-Object System.Drawing.Point(190, 54); $outputTextBox.Size = New-Object System.Drawing.Size(590, 440); $outputTextBox.Multiline = $true; $outputTextBox.ScrollBars = "Both"; $outputTextBox.ReadOnly = $true; $outputTextBox.BackColor = [System.Drawing.Color]::White; $outputTextBox.WordWrap = $false; $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
 $outputTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

 $modeLabel = New-Object System.Windows.Forms.Label; $modeLabel.Location = New-Object System.Drawing.Point(190, 503); $modeLabel.Size = New-Object System.Drawing.Size(35, 15); $modeLabel.Text = "Mode:"
 $modeLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

 $modeDropdown = New-Object System.Windows.Forms.ComboBox; $modeDropdown.Location = New-Object System.Drawing.Point(225, 500); $modeDropdown.Size = New-Object System.Drawing.Size(130, 22); $modeDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
 $modeDropdown.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
 $modeDropdown.Items.AddRange(@("B2C / DTS", "STS"))
 $modeDropdown.SelectedIndex = 0

 $stsPanel = New-Object System.Windows.Forms.Panel
 $stsPanel.Location = New-Object System.Drawing.Point(190, 54)
 $stsPanel.Size = New-Object System.Drawing.Size(590, 60)
 $stsPanel.Visible = $false
 $stsPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

 $stsLocLabel = New-Object System.Windows.Forms.Label; $stsLocLabel.Location = New-Object System.Drawing.Point(0, 5); $stsLocLabel.Size = New-Object System.Drawing.Size(60, 15); $stsLocLabel.Text = "Location:"
 $stsLocDropdown = New-Object System.Windows.Forms.ComboBox; $stsLocDropdown.Location = New-Object System.Drawing.Point(0, 22); $stsLocDropdown.Size = New-Object System.Drawing.Size(100, 22); $stsLocDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
 $stsLocDropdown.Items.AddRange(@("NV", "MD", "TX"))
 $stsLocDropdown.SelectedIndex = 0

 $stsCarrierLabel = New-Object System.Windows.Forms.Label; $stsCarrierLabel.Location = New-Object System.Drawing.Point(120, 5); $stsCarrierLabel.Size = New-Object System.Drawing.Size(60, 15); $stsCarrierLabel.Text = "Carrier:"
 $stsCarrierDropdown = New-Object System.Windows.Forms.ComboBox; $stsCarrierDropdown.Location = New-Object System.Drawing.Point(120, 22); $stsCarrierDropdown.Size = New-Object System.Drawing.Size(150, 22); $stsCarrierDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
 $stsCarrierDropdown.Items.AddRange(@("DHL", "FedEx Air", "FEDEX GROUND", "Geodis UK", "GLOBALEF", "PURLTR EXPRS", "Shipium01", "Shipium02", "Shipium05", "TechTrans", "UPS", "UPS 2nd Day", "UPS Ground", "UPS Next Day"))
 $stsCarrierDropdown.SelectedIndex = 0

 $stsTagLabel = New-Object System.Windows.Forms.Label; $stsTagLabel.Location = New-Object System.Drawing.Point(290, 5); $stsTagLabel.Size = New-Object System.Drawing.Size(80, 15); $stsTagLabel.Text = "Order Type:"
 $stsTagDropdown = New-Object System.Windows.Forms.ComboBox; $stsTagDropdown.Location = New-Object System.Drawing.Point(290, 22); $stsTagDropdown.Size = New-Object System.Drawing.Size(120, 22); $stsTagDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
 $stsTagDropdown.Items.AddRange(@("WEB", "WEB Spc", "WEB Intl"))
 $stsTagDropdown.SelectedIndex = 0

 $stsPanel.Controls.AddRange(@($stsLocLabel, $stsLocDropdown, $stsCarrierLabel, $stsCarrierDropdown, $stsTagLabel, $stsTagDropdown))

 $statusStrip = New-Object System.Windows.Forms.StatusStrip
 $statusStrip.SizingGrip = $false
 $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
 $statusLabel.Spring = $true
 $statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
 $creditLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
 $creditLabel.Text = "© 2026 Tyler Eaker"
 $creditLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
 $statusStrip.Items.Add($statusLabel) | Out-Null
 $statusStrip.Items.Add($creditLabel) | Out-Null

 $mainForm.Controls.AddRange(@($lblUser, $txtUser, $lblSshPass, $txtSshPass, $lblDbPass, $txtDbPass, $inputLabel, $inputTextBox, $createCsvCheckbox, $openCsvCheckbox, $processButton, $copyOrdersButton, $modeLabel, $modeDropdown, $outputLabel, $outputTextBox, $stsPanel, $statusStrip))

 $modeDropdown.Add_SelectedIndexChanged({
    $rightWidth = $mainForm.ClientSize.Width - 190 - 10
    $bottomY    = $mainForm.ClientSize.Height - $statusStrip.Height - 55
    if ($modeDropdown.SelectedItem -eq "STS") {
        $stsPanel.Visible = $true
        $outputLabel.Location = New-Object System.Drawing.Point(190, 120)
        $outputTextBox.Location = New-Object System.Drawing.Point(190, 136)
        $outputTextBox.Size = New-Object System.Drawing.Size($rightWidth, ($bottomY - 136))
    } else {
        $stsPanel.Visible = $false
        $outputLabel.Location = New-Object System.Drawing.Point(190, 39)
        $outputTextBox.Location = New-Object System.Drawing.Point(190, 54)
        $outputTextBox.Size = New-Object System.Drawing.Size($rightWidth, ($bottomY - 54))
    }
})

 $createCsvCheckbox.Add_CheckedChanged({
    $openCsvCheckbox.Enabled = $createCsvCheckbox.Checked
    $menuCreateCsv.Checked   = $createCsvCheckbox.Checked
    $menuOpenCsv.Enabled     = $createCsvCheckbox.Checked
})
 $openCsvCheckbox.Add_CheckedChanged({ $menuOpenCsv.Checked = $openCsvCheckbox.Checked })
 $copyOrdersButton.Add_Click({
    if ($script:lastRunData.Count -gt 0) {
        $sb = New-Object System.Text.StringBuilder
        foreach ($group in ($script:lastRunData | Group-Object Loc)) {
            foreach ($order in $group.Group) {
                [void]$sb.AppendLine($order.Order)
            }
            [void]$sb.AppendLine("")
        }
        [System.Windows.Forms.Clipboard]::SetText($sb.ToString().TrimEnd("`r`n"))
    }
})

 $menuClearOutput.Add_Click({ $outputTextBox.Clear() })
 $menuClearInput.Add_Click({ $inputTextBox.Clear() })
 $menuAlwaysOnTop.Add_Click({ $mainForm.TopMost = $menuAlwaysOnTop.Checked })
 $menuWordWrap.Add_Click({
    $outputTextBox.WordWrap = $menuWordWrap.Checked
    $outputTextBox.ScrollBars = if ($menuWordWrap.Checked) { "Vertical" } else { "Both" }
})
 $menuScrollBottom.Add_Click({ $outputTextBox.SelectionStart = $outputTextBox.Text.Length; $outputTextBox.ScrollToCaret() })

 $menuFontSmall.Add_Click({ $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 8); $menuFontSmall.Checked=$true; $menuFontMedium.Checked=$false; $menuFontLarge.Checked=$false })
 $menuFontMedium.Add_Click({ $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9); $menuFontSmall.Checked=$false; $menuFontMedium.Checked=$true; $menuFontLarge.Checked=$false })
 $menuFontLarge.Add_Click({ $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 11); $menuFontSmall.Checked=$false; $menuFontMedium.Checked=$false; $menuFontLarge.Checked=$true })

 $menuCreateCsv.Add_Click({ $createCsvCheckbox.Checked = $menuCreateCsv.Checked })
 $menuOpenCsv.Add_Click({
    if ($menuOpenCsv.Checked -and -not $createCsvCheckbox.Checked) { $menuOpenCsv.Checked = $false; return }
    $openCsvCheckbox.Checked = $menuOpenCsv.Checked
})

function Set-ScanDepthChecks {
    param([int]$Depth)
    $menuScan12.Checked = ($Depth -eq 12); $menuScan24.Checked = ($Depth -eq 24); $menuScan48.Checked = ($Depth -eq 48)
    $script:scanDepth   = $Depth
}
 $menuScan12.Add_Click({ Set-ScanDepthChecks 12 }); $menuScan24.Add_Click({ Set-ScanDepthChecks 24 }); $menuScan48.Add_Click({ Set-ScanDepthChecks 48 })

function Set-BatchSizeChecks {
    param([int]$Size)
    $menuBatch1.Checked = ($Size -eq 1); $menuBatch3.Checked = ($Size -eq 3); $menuBatch5.Checked = ($Size -eq 5)
    $script:batchSize   = $Size
}
 $menuBatch1.Add_Click({ Set-BatchSizeChecks 1 }); $menuBatch3.Add_Click({ Set-BatchSizeChecks 3 }); $menuBatch5.Add_Click({ Set-BatchSizeChecks 5 })

 $menuWaveHistory.Add_Click({
    $histForm = New-Object System.Windows.Forms.Form
    $histForm.Text = "Wave History"; $histForm.ClientSize = New-Object System.Drawing.Size(560, 400); $histForm.StartPosition = "CenterParent"; $histForm.FormBorderStyle = "FixedDialog"; $histForm.MaximizeBox = $false; $histForm.MinimizeBox = $false
    $histBox = New-Object System.Windows.Forms.TextBox
    $histBox.Location = New-Object System.Drawing.Point(10, 10); $histBox.Size = New-Object System.Drawing.Size(540, 380); $histBox.Multiline = $true; $histBox.ReadOnly = $true; $histBox.ScrollBars = "Vertical"; $histBox.BackColor = [System.Drawing.Color]::White; $histBox.Font = New-Object System.Drawing.Font("Consolas", 9); $histBox.WordWrap = $false

    if (Test-Path $script:Config.HistoryPath) {
        try {
            $raw = ConvertFrom-Json ([System.IO.File]::ReadAllText($script:Config.HistoryPath))
            $history = @($raw | ForEach-Object { $_ })
            if ($history.Count -eq 0) { $histBox.Text = "No wave history recorded yet." }
            else {
                $lines = @("{0,-22}{1,-8}{2,-8}{3,-10}{4}" -f "Timestamp","Total","Waved","In Wave","Locations")
                $lines += "-" * 70
                foreach ($e in $history) {
                    $lines += "{0,-22}{1,-8}{2,-8}{3,-10}{4}" -f $e.Timestamp, $e.TotalOrders, $e.Waved, $e.AlreadyInWave, $e.Locations
                }
                $histBox.Lines = $lines
            }
        } catch { $histBox.Text = "Could not load history file." }
    } else { $histBox.Text = "No wave history recorded yet." }
    $histForm.Controls.Add($histBox)
    $histForm.ShowDialog($mainForm) | Out-Null
})

 $menuCheckPlink.Add_Click({
    $plinkPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot "plink.exe" } else { ".\plink.exe" }
    if (Test-Path $plinkPath) { [System.Windows.Forms.MessageBox]::Show("plink.exe found at:`n$plinkPath", "plink Check", 0, 64) | Out-Null }
    else { [System.Windows.Forms.MessageBox]::Show("plink.exe NOT found.`nExpected location:`n$plinkPath", "plink Check", 0, 48) | Out-Null }
})

 $menuClearCreds.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Clear saved credentials?", "Confirm", 4, 32) -eq 6) {
        if (Test-Path $script:Config.SettingsPath) {
            try {
                $s = Get-Content $script:Config.SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $s.SshUser = ""; $s.SshPass = ""; $s.DbPass  = ""
                $s | ConvertTo-Json | Set-Content -Path $script:Config.SettingsPath -Encoding UTF8
            } catch { Write-ErrorLog -Message "Failed to clear credentials" -ErrorRecord $_ }
        }
        [System.Windows.Forms.MessageBox]::Show("Credentials cleared.", "Done", 0, 64) | Out-Null
    }
})

 $menuLangEN.Add_Click({ Set-Language "EN" })
 $menuLangES.Add_Click({ Set-Language "ES" })

 $script:uiQueue = New-Object System.Collections.Concurrent.ConcurrentQueue[string]
 $script:statusQueue = New-Object System.Collections.Concurrent.ConcurrentQueue[string]
 $script:resultQueue = New-Object System.Collections.Concurrent.ConcurrentQueue[object]

 $script:bgRunspace = $null
 $script:bgPowerShell = $null
 $script:bgHandle = $null

 $script:uiTimer = New-Object System.Windows.Forms.Timer
 $script:uiTimer.Interval = 50

 $script:uiTimer.Add_Tick({
    $msg = $null
    while ($script:statusQueue.TryDequeue([ref]$msg)) { $statusLabel.Text = $msg }
    
    $sb = New-Object System.Text.StringBuilder
    while ($script:uiQueue.TryDequeue([ref]$msg)) { [void]$sb.Append($msg) }
    if ($sb.Length -gt 0) {
        $outputTextBox.AppendText($sb.ToString())
        $outputTextBox.SelectionStart = $outputTextBox.Text.Length
        $outputTextBox.ScrollToCaret()
    }

    $res = $null
    while ($script:resultQueue.TryDequeue([ref]$res)) {
        if ($res.LastRunData) { $script:lastRunData = $res.LastRunData }
    }

    if ($null -ne $script:bgHandle -and $script:bgHandle.IsCompleted) {
        try {
            $script:bgPowerShell.EndInvoke($script:bgHandle)
        } catch {
            $outputTextBox.AppendText("`r`nCRITICAL UNHANDLED ERROR: $($_.Exception.Message)`r`n")
            Write-ErrorLog -Message "Runspace unhandled exception" -ErrorRecord $_
        }
        if ($script:bgRunspace) { $script:bgRunspace.Dispose() }
        if ($script:bgPowerShell) { $script:bgPowerShell.Dispose() }
        $script:bgHandle = $null
        $script:bgRunspace = $null
        $script:bgPowerShell = $null
        
        $processButton.Enabled = $true
        $copyOrdersButton.Enabled = ($script:lastRunData.Count -gt 0)
        $statusLabel.Text = "Idle"
        $script:uiTimer.Stop()
    }
})

 $processButton.Add_Click({
    if ($script:bgHandle -ne $null -and -not $script:bgHandle.IsCompleted) { return }
    
    $processButton.Enabled = $false
    $copyOrdersButton.Enabled = $false
    $outputTextBox.Clear()

    $plinkPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot "plink.exe" } else { ".\plink.exe" }
    if (-not (Test-Path $plinkPath)) {
        $outputTextBox.AppendText("CRITICAL ERROR: plink.exe not found.`r`nPlease ensure it is inside the same directory as this script.`r`n")
        $processButton.Enabled = $true
        return
    }

    $user = $txtUser.Text.Trim()
    $sshPass = $txtSshPass.Text
    $dbPass = $txtDbPass.Text

    if (-not $user -or -not $sshPass -or -not $dbPass) {
        $outputTextBox.AppendText("ERROR: Please enter credentials.`r`n")
        $processButton.Enabled = $true
        return
    }

    Save-Settings

    while ($script:uiQueue.TryDequeue([ref]$null)) {}
    while ($script:statusQueue.TryDequeue([ref]$null)) {}
    while ($script:resultQueue.TryDequeue([ref]$null)) {}

    $ctx = @{
        Config = $script:Config
        LocationPids = $script:locationPids
        TypToTag = $script:typToTag
        CountryToCarrierGfid = $script:countryToCarrierGfid
        CsvCarrierToCgfid = $script:csvCarrierToCgfid
        IntakeCarrierToCgfid = $script:intakeCarrierToCgfid
        TagToPstr = $script:tagToPstr
        PidToLoc = $script:pidToLoc
        
        User = $user
        SshPass = $sshPass
        DbPass = $dbPass
        OrdersText = $inputTextBox.Text
        CreateCsv = $createCsvCheckbox.Checked
        OpenCsv = $openCsvCheckbox.Checked
        ScanDepth = $script:scanDepth
        BatchSize = $script:batchSize
        
        uiQueue = $script:uiQueue
        statusQueue = $script:statusQueue
        resultQueue = $script:resultQueue
        
        IsSts = ($modeDropdown.SelectedItem -eq "STS")
    }

    if ($ctx.IsSts) {
        $ctx.StsLoc = $stsLocDropdown.SelectedItem
        $ctx.StsCarrier = $stsCarrierDropdown.SelectedItem
        $ctx.StsCarrierCgfid = $script:stsCarrierToCgfid[$ctx.StsCarrier]
        $ctx.StsTag = $stsTagDropdown.SelectedItem
    }

    $script:bgRunspace = [runspacefactory]::CreateRunspace()
    $script:bgRunspace.Open()
    
    $script:bgPowerShell = [powershell]::Create()
    $script:bgPowerShell.Runspace = $script:bgRunspace
    $script:bgPowerShell.AddScript($bgScript).AddArgument($ctx) | Out-Null
    
    $script:bgHandle = $script:bgPowerShell.BeginInvoke()
    $script:uiTimer.Start()
})

Load-Settings
Set-Language $script:lang
 $menuCreateCsv.Checked   = $createCsvCheckbox.Checked
 $menuOpenCsv.Checked     = $openCsvCheckbox.Checked
 $menuOpenCsv.Enabled     = $createCsvCheckbox.Checked
 $menuAlwaysOnTop.Checked = $mainForm.TopMost
 $menuWordWrap.Checked    = $outputTextBox.WordWrap
Set-ScanDepthChecks $script:scanDepth
Set-BatchSizeChecks $script:batchSize

 $fs = $outputTextBox.Font.Size
 $menuFontSmall.Checked  = ($fs -le 8)
 $menuFontMedium.Checked = ($fs -eq 9)
 $menuFontLarge.Checked  = ($fs -ge 11)

 $mainForm.Add_FormClosing({
    Save-Settings
    if ($script:bgRunspace) { $script:bgRunspace.Dispose() }
    if ($script:bgPowerShell) { $script:bgPowerShell.Dispose() }
})

[void]$mainForm.ShowDialog()
$mainForm.Dispose()