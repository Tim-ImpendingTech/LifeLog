$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..' 'fetch_lifelogs_redacted.ps1'
$lines = Get-Content $scriptPath
$funcBlock = $lines[31..40] -join "`n"
Invoke-Expression $funcBlock

Describe 'Decode-Cursor' {
    It 'returns decoded cursor value for valid input' {
        $cursorValue = 'mycursor'
        $json = @{ cursorValue = $cursorValue } | ConvertTo-Json -Compress
        $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
        Decode-Cursor -cursor $encoded | Should -Be $cursorValue
    }

    It 'returns failure message for invalid input' {
        Decode-Cursor -cursor 'invalid' | Should -Be 'Failed to decode cursor'
    }
}
