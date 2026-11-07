# Install skills from this library into a project (Windows PowerShell).
# usage: .\install.ps1 -List
#        .\install.ps1 -Pick [options]    (numbered menu)
#        .\install.ps1 <name|category>... [-Project DIR] [-Prefix P] [-Agents claude,codex] [-Link]
[CmdletBinding(PositionalBinding=$false)]
param(
  [Parameter(ValueFromRemainingArguments)][string[]]$Names,
  [string]$Project = (Get-Location).Path,
  [string]$Prefix = '',
  [string[]]$Agents = @('claude', 'codex'),
  [switch]$Link,
  [switch]$List,
  [switch]$Pick
)
$sk = Join-Path $PSScriptRoot 'skills'
# external.tsv: skills fetched from the original author's GitHub repo at install time
$ext = @(Get-Content (Join-Path $PSScriptRoot 'external.tsv') -Encoding UTF8 | Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object { $f = $_ -split "`t"; [pscustomobject]@{ Name = $f[0]; Repo = $f[1]; Path = $f[2] } })
if ($List) {
  Get-ChildItem $sk -Directory | ForEach-Object { "[$($_.Name)]"; Get-ChildItem $_.FullName -Directory | ForEach-Object { "  $($_.Name)" } }
  '[external - fetched from the author''s GitHub]'
  $ext | ForEach-Object { '  {0,-30} https://github.com/{1}/tree/HEAD/{2}' -f $_.Name, $_.Repo, $_.Path }
  return
}
if ($Pick) {
  $all = @(Get-ChildItem $sk -Directory | ForEach-Object { Get-ChildItem $_.FullName -Directory } | ForEach-Object { $_.Name }) + @($ext | ForEach-Object { $_.Name })
  for ($i = 0; $i -lt $all.Count; $i++) { '{0,3}) {1}' -f ($i + 1), $all[$i] }
  $sel = Read-Host "numbers to install (e.g. 1 3 7-9, or 'all')"
  if ($sel -eq 'all') { $sel = "1-$($all.Count)" }
  $Names = foreach ($t in ($sel -split '\s+' | Where-Object { $_ })) {
    if ($t -match '^(\d+)-(\d+)$') { [int]$Matches[1]..[int]$Matches[2] | ForEach-Object { $all[$_ - 1] } } else { $all[[int]$t - 1] }
  }
}
if (-not $Names) { throw 'nothing to install (try -List or -Pick)' }
$cache = Join-Path ([IO.Path]::GetTempPath()) ("skills-" + [guid]::NewGuid())
if ($Prefix -and $Link) { throw '-Prefix cannot be combined with -Link' }
if (-not (Test-Path $Project)) { throw "project dir not found: $Project" }
$src = foreach ($n in $Names) {
  if (Test-Path (Join-Path $sk $n)) { Get-ChildItem (Join-Path $sk $n) -Directory }
  else {
    $m = Get-ChildItem $sk -Directory | ForEach-Object { Get-ChildItem $_.FullName -Directory -Filter $n } | Select-Object -First 1
    if (-not $m) {
      $e = $ext | Where-Object Name -eq $n
      if (-not $e) { throw "not found: $n" }
      if ($Link) { throw "external skills cannot use -Link: $n" }
      $dir = Join-Path $cache ($e.Repo -replace '/', '_')
      if (-not (Test-Path $dir)) { git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$($e.Repo).git" $dir 2>&1 | Out-Null }
      git -C $dir sparse-checkout add $e.Path 2>&1 | Out-Null
      $m = Get-Item (Join-Path $dir $e.Path)
    }
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
if (Test-Path $cache) { Remove-Item $cache -Recurse -Force }
