Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === Глобальные переменные ===
$script:version = $null
$script:fileName = $null
$script:platform = $null
$script:custom = $null

# === Форма ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "Firmware Downloader for Tina Allwinner v851se"
$form.Size = New-Object System.Drawing.Size(440, 150)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Click 'Check' to search for a new firmware version"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($label)

# === Кнопка 'Проверить' ===
$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Text = "Check"
$checkButton.Size = New-Object System.Drawing.Size(100,30)
$checkButton.Location = New-Object System.Drawing.Point(20,60)

# === Кнопка 'Скачать' ===
$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Text = "Download"
$downloadButton.Size = New-Object System.Drawing.Size(100,30)
$downloadButton.Location = New-Object System.Drawing.Point(305,60)
$downloadButton.Enabled = $false

# === Обработка 'Проверить' ===
$checkButton.Add_Click({
    try {
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"

        $response = Invoke-WebRequest -UseBasicParsing -Uri "http://120.79.59.57:8080/device-web/upgrade/queryDeviceVersion" `
            -Method "POST" -WebSession $session `
            -Headers @{
                "Accept"="*/*"
                "Accept-Encoding"="gzip, deflate"
                "Accept-Language"="be,ru-RU;q=0.9,ru;q=0.8,en-US;q=0.7,en;q=0.6"
                "DNT"="1"
                "Origin"="http://192.168.1.101"
                "Referer"="http://192.168.1.101/"
            } `
            -ContentType "application/json" `
            -Body '{"version":"","platform":"v851se","custom":"leshida"}'

        $json = $response.Content | ConvertFrom-Json

        if ($json.errorCode -eq "200" -and $json.data.Count -gt 0) {
            $script:version   = $json.data[0].version
            $script:fileName  = $json.data[0].fileName
            $script:platform  = $json.data[0].platform
            $script:custom    = $json.data[0].custom

            $label.Text = "New firmware version: $version"
            $downloadButton.Enabled = $true
        } else {
            $label.Text = "There is no new firmware"
            $downloadButton.Enabled = $false
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error during firmware check: $_", "Error", "OK", "Error")
    }
})

# === Обработка 'Скачать' ===
$downloadButton.Add_Click({
    try {
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"

		$shell = New-Object -ComObject Shell.Application
        $downloads = $shell.NameSpace('shell:Downloads').Self.Path
        $outputPath = Join-Path $downloads $fileName

        Invoke-WebRequest -UseBasicParsing -Uri "http://120.79.59.57:8080/device-web/upgrade/downLoad" `
            -Method "POST" `
			-WebSession $session `
            -Headers @{
                "Accept"="*/*"
                "Accept-Encoding"="gzip, deflate"
                "Accept-Language"="be,ru-RU;q=0.9,ru;q=0.8,en-US;q=0.7,en;q=0.6"
                "DNT"="1"
                "Origin"="http://192.168.1.101"
                "Referer"="http://192.168.1.101/"
            } `
            -ContentType "application/json" `
            -Body "{`"version`":`"$version`",`"platform`":`"$platform`",`"custom`":`"$custom`"}" `
            -OutFile $outputPath

        [System.Windows.Forms.MessageBox]::Show("Frimware downloaded:`n$outputPath", "Success", "OK", "Information")
    } catch {
        $errMsg = if ($_.Exception) { $_.Exception.Message } else { $_.ToString() }
		[System.Windows.Forms.MessageBox]::Show("Download error:`n$errMsg", "Error", "OK", "Error")
    }
})

$form.Controls.Add($checkButton)
$form.Controls.Add($downloadButton)
$form.Topmost = $true
$form.ShowDialog()
