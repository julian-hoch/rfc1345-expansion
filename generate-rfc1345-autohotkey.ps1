[CmdletBinding(PositionalBinding=$false)]
param(
    [Alias("p")][string]$Prefix = ",",
    [switch]$ExcludeAscii,
    [switch]$IncludeControl,
    [string]$Options = "*",
    [Alias("o")][string]$Output = "$HOME/Documents/AutoHotkey/rfc1345.ahk",
    [Alias("h","?")][switch]$Help
)

$HelpText = @'
Generate a full RFC1345/Vim digraph AutoHotkey (v2) hotstring file.

Parameters:
  -Prefix           Trigger prefix (default: ","). Use "" for none.
  -ExcludeAscii     Skip ASCII/spacing digraphs.
  -IncludeControl   Include control-character digraphs (off by default).
  -Options          Hotstring options without colons (default: "*").
  -Output           Output path (default: ~/Documents/AutoHotkey/rfc1345.ahk).

Usage examples:
  .\generate-rfc1345-autohotkey.ps1 -Output rfc1345.ahk
  .\generate-rfc1345-autohotkey.ps1 -Prefix "" -ExcludeAscii -IncludeControl -Options "" -Output rfc1345.ahk
'@

if ($Help) {
    Write-Output $HelpText
    exit 0
}

if ($Options -match ':') {
    Write-Error "Hotstring options should not contain colons; pass only the option letters."
    exit 1
}

$includeAscii = -not $ExcludeAscii
$includeControl = $IncludeControl.IsPresent
$url = 'https://raw.githubusercontent.com/vim/vim/master/runtime/doc/digraph.txt'

try {
    $content = (Invoke-WebRequest -UseBasicParsing -Uri $url).Content
} catch {
    Write-Error "Failed to download digraph table: $_"
    exit 1
}

$lines = $content -split "`n"
$seen = New-Object 'System.Collections.Generic.HashSet[string]'
$matches = New-Object System.Collections.Generic.List[object]

foreach ($line in $lines) {
    $cols = $line -split "`t"
    if ($cols.Count -lt 3) { continue }
    $digraph = $cols[1]
    $hex = $cols[2]
    if ($digraph.Length -ne 2) { continue }
    try {
        $cp = [Convert]::ToInt32($hex, 16)
    } catch {
        continue
    }
    if (-not $includeAscii -and $cp -lt 0x80) { continue }
    if (-not $includeControl -and ($cp -lt 0x20 -or $cp -eq 0x7F)) { continue }
    if (-not $seen.Add($digraph)) { continue }
    $char = [char]$cp
    $triggerRaw = if ($null -eq $Prefix) { $digraph } else { "$Prefix$digraph" }
    # Escape hotstring meta chars in trigger: colon (end marker) and backtick (escape char).
    $trigger = $triggerRaw.Replace('`', '``').Replace(':', '`:')
    $matches.Add([pscustomobject]@{ Trigger = $trigger; Char = $char })
}

$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$optionBlock = if ($Options) {":${Options}:"} else {"::"}
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('#Requires AutoHotkey v2.0')
[void]$sb.AppendLine("; Generated $stamp from Vim digraph table ($url)")
[void]$sb.AppendLine('; Prefix: "' + $Prefix + '" | Include ASCII: ' + $includeAscii + ' | Include control: ' + $includeControl + ' | Options: ' + $Options)
[void]$sb.AppendLine('#Hotstring EndChars -[]{}''";/\\,.?!``n``s``t')
[void]$sb.AppendLine()

foreach ($m in $matches) {
    # In AHK strings, ` escapes and \" is a literal quote.
    $text = [string]$m.Char
    $escaped = $text.Replace('`', '``').Replace('"', '""')
    [void]$sb.AppendLine("$optionBlock$($m.Trigger)::")
    [void]$sb.AppendLine('{')
    [void]$sb.AppendLine('    SendText "' + $escaped + '"')
    [void]$sb.AppendLine('}')
    [void]$sb.AppendLine()
}

$dir = Split-Path -Parent $Output
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
$sb.ToString() | Set-Content -Encoding UTF8 -Path $Output

Write-Output "Wrote $((Get-Content $Output).Count) lines to $Output"
Write-Output "Reload the AutoHotkey script to apply changes"
