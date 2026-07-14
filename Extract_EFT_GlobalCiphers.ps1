# Location of ServerConfig.DB on Globalscape EFT server
$db = "C:\ProgramData\Globalscape\EFT Server\ServerConfig.db"

# Query SecurityTab column of the SERVER table from the ServiceConfig.db database
$query = @"
SELECT SecurityTab
FROM Server;
"@

# sqlite3.exe extracted from https://www.sqlite.org/2026/sqlite-tools-win-x64-3530300.zip
$sqlite = ".\sqlite3.exe"

# Run SQLITE3 command to get the data from SecurityTab relating to EFT Global Ciphers
$json = & $sqlite $db $query

$security = $json | ConvertFrom-Json

$output = @{
    TLS_Minimum = $security.TlsParams.MinimumTlsVersion
    TLS_Maximum = $security.TlsParams.MaximumTlsVersion
    TLS_Ciphers = $security.TlsParams.TreeCipherSelection
    TLS_ResultingCipherList = $security.TlsParams.CipherList
    TLS_ManualCipherList = $security.TlsParams.ManualCipherSelection
    TLS_ManualCipherEnabled = $security.TlsParams.ManualCiphersSelection

    SSH_Ciphers = $security.SshParams.Ciphers
    SSH_KEX = $security.SshParams.KEXes
    SSH_MACs = $security.SshParams.MACs
    SSH_Version = $security.SshParams.SotfwareVersion

    TLS_FIPS = $security.SslFipsEnabled
    SSH_FIPS = $security.SshFipsEnabled
}

################ JSON Output
$output | ConvertTo-Json -Depth 5 |
    Out-File ".\EFT-Security-Report.json"

################ CSV Output
$output.GetEnumerator() |
    Sort-Object Name |
    Select-Object Name, Value |
    Export-Csv ".\EFT-Security-Report.csv" -NoTypeInformation

################ Markdown Output
$output.GetEnumerator() |
    Sort-Object Name |
    ForEach-Object {
        $value = $_.Value -replace '[:,]', '<br>'
        "| $($_.Name) | $value |"
    } |
    ForEach-Object -Begin {
        "| Name | Value |"
        "|------|-------|"
    } -Process {
        $_
    } | Out-File ".\EFT-Security-Report.txt"
