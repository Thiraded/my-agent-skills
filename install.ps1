# Install skills from this library into a project (Windows PowerShell).
# usage: .\install.ps1 -List
#        .\install.ps1 <name|category>... [-Project DIR] [-Prefix P] [-Agents claude,codex] [-Link]
[CmdletBinding(PositionalBinding=$false)]
param(
  [Parameter(ValueFromRemainingArguments)][string[]]$Names,
  [string]$Project = (Get-Location).Path,
  [string]$Prefix = '',
  [string[]]$Agents = @('claude', 'codex'),
  [switch]$Link,
  [switch]$List
)
$sk = Join-Path $PSScriptRoot 'skills'
if ($List) {
  Get-ChildItem $sk -Directory | ForEach-Object { "[$($_.Name)]"; Get-ChildItem $_.FullName -Directory | ForEach-Object { "  $($_.Name)" } }
  return
}
if (-not $Names) { throw 'nothing to install (try -List)' }
if ($Prefix -and $Link) { throw '-Prefix cannot be combined with -Link' }
if (-not (Test-Path $Project)) { throw "project dir not found: $Project" }
$src = foreach ($n in $Names) {
  if (Test-Path (Join-Path $sk $n)) { Get-ChildItem (Join-Path $sk $n) -Directory }
  else {
    $m = Get-ChildItem $sk -Directory | ForEach-Object { Get-ChildItem $_.FullName -Directory -Filter $n } | Select-Object -First 1
    if (-not $m) { throw "not found: $n" }
    $m
  }
}
foreach ($t in $Agents) {
  $dest = switch ($t) {
    'claude' { Join-Path $Project '.claude\skills' }
    'codex' { Join-Path $Project '.agents\skills' }
    default { throw "unknown agent: $t" }
  }
  New-Item -ItemType Directory -Force $dest | Out-Null
  foreach ($s in $src) {
    $out = Join-Path $dest ($Prefix + $s.Name)
    if (Test-Path $out) { "skip (exists): $out"; continue }
    if ($Link) { New-Item -ItemType Junction -Path $out -Target $s.FullName | Out-Null }
    else {
      Copy-Item $s.FullName $out -Recurse
      if ($Prefix) {
        $f = Join-Path $out 'SKILL.md'
        $c = Get-Content $f -Raw
        ([regex]'(?m)^name:.*$').Replace($c, "name: $Prefix$($s.Name)", 1) | Set-Content $f -NoNewline
      }
    }
    "installed: $out"
  }
}
