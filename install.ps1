# Install skills from this library into a project (Windows PowerShell).
# usage: .\install.ps1 -List
#        .\install.ps1 -Pick [options]    (numbered menu)
#        .\install.ps1 <name|category>... [-Project DIR] [-Prefix P] [-Agents claude,codex] [-Link]
#        add -Scaffold to also create docs/tasks, scripts/task.mjs and the AGENTS.md pointer
#        Claude only: -Agents claude   (default installs for claude AND codex)
[CmdletBinding(PositionalBinding=$false)]
param(
  [Parameter(ValueFromRemainingArguments)][string[]]$Names,
  [string]$Project = (Get-Location).Path,
  [string]$Prefix = '',
  [string[]]$Agents = @('claude', 'codex'),
  [switch]$Link,
  [switch]$List,
  [switch]$Pick,
  [switch]$Scaffold
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
  $all = @(); $i = 0
  foreach ($c in Get-ChildItem $sk -Directory) {
    "[$($c.Name)]  (in this repo)"
    foreach ($d in Get-ChildItem $c.FullName -Directory) { $all += $d.Name; $i++; '{0,3}) {1}' -f $i, $d.Name }
  }
  '[external]  (downloaded from the author''s GitHub)'
  foreach ($e in $ext) { $all += $e.Name; $i++; '{0,3}) {1,-30} github.com/{2}' -f $i, $e.Name, $e.Repo }
  ''
  'Type the numbers to install, separated by spaces (ranges ok: 1 3 7-9), or ''all''.'
  'You can use several lines. Press Enter on an empty line to finish.'
  $sel = ''
  while ($true) { $line = Read-Host; if (-not $line) { break }; $sel += " $line" }
  if ($sel.Trim() -eq 'all') { $sel = "1-$($all.Count)" }
  $Names = foreach ($t in ($sel -split '\s+' | Where-Object { $_ })) {
    if ($t -match '^(\d+)-(\d+)$') { $lo = [int]$Matches[1]; $hi = [int]$Matches[2] }
    elseif ($t -match '^\d+$') { $lo = $hi = [int]$t }
    else { Write-Warning "ignored (not a number): $t"; continue }
    foreach ($j in $lo..$hi) { if ($j -ge 1 -and $j -le $all.Count) { $all[$j - 1] } else { Write-Warning "ignored (out of range): $j" } }
  }
}
if (-not $Names -and -not $Scaffold) {
  'nothing selected. Examples:'
  '  .\install.ps1 -List                 see everything'
  '  .\install.ps1 -Pick                 choose from a numbered menu'
  '  .\install.ps1 06-setup -Scaffold    skills + task workflow into the current folder'
  '  .\install.ps1 tdd -Agents claude    one skill, Claude only'
  return
}
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
if ($src) {
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
        if ($t -eq 'claude') { Remove-Item (Join-Path $out 'agents\openai.yaml') -ErrorAction SilentlyContinue; Remove-Item (Join-Path $out 'agents') -ErrorAction SilentlyContinue }
        if ($Prefix) {
          $f = Join-Path $out 'SKILL.md'
          $c = Get-Content $f -Raw
          ([regex]'(?m)^name:.*$').Replace($c, "name: $Prefix$($s.Name)", 1) | Set-Content $f -NoNewline
        }
      }
      "installed: $out"
    }
  }
  "installed for: $($Agents -join ',')  (Claude only: -Agents claude). Start a new session to load them."
}
if (Test-Path $cache) { Remove-Item $cache -Recurse -Force }
if ($Scaffold) {
  $A = Join-Path $sk '06-setup\setup-project\assets'
  New-Item -ItemType Directory -Force (Join-Path $Project 'docs\tasks'), (Join-Path $Project 'scripts') | Out-Null
  foreach ($m in @(@('WORKFLOW.md', 'docs\tasks\WORKFLOW.md'), @('TASK-TEMPLATE.md', 'docs\tasks\TEMPLATE.md'), @('task.mjs', 'scripts\task.mjs'))) {
    $to = Join-Path $Project $m[1]
    if (Test-Path $to) { "skip (exists): $to" } else { Copy-Item (Join-Path $A $m[0]) $to; "created: $to" }
  }
  $ptr = Join-Path $Project 'AGENTS.md'
  if (-not (Test-Path $ptr) -and (Test-Path (Join-Path $Project 'CLAUDE.md'))) { $ptr = Join-Path $Project 'CLAUDE.md' }
  if ((Test-Path $ptr) -and (Select-String -Path $ptr -SimpleMatch 'docs/tasks/WORKFLOW.md' -Quiet)) { "skip (pointer exists): $ptr" }
  else {
    $ptrText = "`n## Tasks`nWork is tracked as cards in ``docs/tasks/``. Read ``docs/tasks/WORKFLOW.md`` once.`nCreate: ``node scripts/task.mjs create --title `"...`"``; list: ``node scripts/task.mjs list``.`n"
    [IO.File]::AppendAllText($ptr, $ptrText, (New-Object Text.UTF8Encoding $false))
    "updated: $ptr"
  }
}
