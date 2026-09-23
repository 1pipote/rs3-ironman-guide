<#
Consistency check for guide.txt: quote/apostrophe style, trailing whitespace,
legacy dialogue notation, known misspellings, known item-casing regressions,
and Bank header sequencing.

Usage:
  powershell -File tools\check_consistency.ps1              # report only
  powershell -File tools\check_consistency.ps1 -Fix          # also fixes the
                                                              # mechanical issues
                                                              # (curly quotes,
                                                              # trailing whitespace)

Everything else (dialogue notation, misspellings, item casing, bank headers)
is report-only on purpose -- those need a human to judge context before
changing anything. Extend $Misspellings / $ItemCasing as new issues are found;
they are seed lists, not exhaustive.

Exit code: 0 if clean, 1 if anything was flagged (fixed mechanical issues do
not count against this -- only unresolved/report-only findings do).
#>
param(
  [string]$Path = (Join-Path $PSScriptRoot "..\guide.txt"),
  [switch]$Fix
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Path)) { throw "File not found: $Path" }

$curlyApos1 = [char]0x2019
$curlyApos2 = [char]0x2018
$curlyOpenQ = [char]0x201C
$curlyCloseQ = [char]0x201D

$lines = Get-Content $Path -Encoding UTF8
$issues = @()   # each: [pscustomobject]@{ Line=n; Category='...'; Detail='...' }

# --- known misspellings (case-insensitive substring). Seed list -- extend as found. ---
$Misspellings = @(
  @{ Wrong = 'Geilinor';   Right = 'Gielinor' }
  @{ Wrong = 'Archeology'; Right = 'Archaeology' }
  @{ Wrong = 'Taverly';    Right = 'Taverley' }
  @{ Wrong = 'Al-khaird';  Right = 'Al Kharid' }
  @{ Wrong = 'Alkharid';   Right = 'Al Kharid' }
  @{ Wrong = 'Barcrawl';   Right = 'Bar Crawl' }
)

# --- missing apostrophe in common contractions (case-insensitive whole word) ---
$Contractions = @('dont','wont','cant','arent','isnt','wasnt','werent','youre','theyre','weve','ive','doesnt','didnt')

# --- known item-casing regressions (case-SENSITIVE exact form). Seed list from
#     the 2026-09 wiki-verification pass -- extend as new items get verified. ---
$ItemCasing = @(
  @{ Wrong = 'Archaeology Journal';   Right = 'Archaeology journal' }
  @{ Wrong = 'Jug of Water';          Right = 'Jug of water' }
  @{ Wrong = 'Rotten Tomato';         Right = 'Rotten tomato' }
  @{ Wrong = 'Rat Poison';            Right = 'Rat poison' }
  @{ Wrong = 'Purple Dye';            Right = 'Purple dye' }
  @{ Wrong = 'Gnome Spice';           Right = 'Gnome spice' }
  @{ Wrong = 'Elemental Bars';        Right = 'Elemental bars' }
  @{ Wrong = 'Iron Chainbody';        Right = 'Iron chainbody' }
  @{ Wrong = 'Oak Longbow';           Right = 'Oak longbow' }
  @{ Wrong = 'Willow Longbow';        Right = 'Willow longbow' }
  @{ Wrong = 'Studded Body & Chaps';  Right = 'Studded body & chaps' }
  @{ Wrong = 'Shiny Money Pouch';     Right = 'Shiny money pouch' }
  @{ Wrong = 'Monkey Paw';            Right = 'Monkey paw' }
  @{ Wrong = 'Grimey Rogue''s Purse'; Right = 'Grimy rogue''s purse' }
  @{ Wrong = 'Shiny Light foot';      Right = 'Shiny light foot' }
)

for ($i = 0; $i -lt $lines.Count; $i++) {
  $ln = $i + 1
  $l = $lines[$i]

  if ($l -match [regex]::Escape($curlyApos1) -or $l -match [regex]::Escape($curlyApos2)) {
    $issues += [pscustomobject]@{ Line=$ln; Category='curly-apostrophe'; Detail=$l.Trim() }
  }
  if ($l -match [regex]::Escape($curlyOpenQ) -or $l -match [regex]::Escape($curlyCloseQ)) {
    $issues += [pscustomobject]@{ Line=$ln; Category='curly-quote'; Detail=$l.Trim() }
  }
  if ($l -match '[ \t]+$') {
    $issues += [pscustomobject]@{ Line=$ln; Category='trailing-whitespace'; Detail=$l.Trim() }
  }
  if ($l -match '(?i)\bOption\s+\d' -or $l -match '(?i)\(Chat\s+\d+\)') {
    $issues += [pscustomobject]@{ Line=$ln; Category='legacy-dialogue-notation'; Detail=$l.Trim() }
  }
  foreach ($m in $Misspellings) {
    if ($l -match [regex]::Escape($m.Wrong)) {
      $issues += [pscustomobject]@{ Line=$ln; Category='misspelling'; Detail="'$($m.Wrong)' -> should be '$($m.Right)' | $($l.Trim())" }
    }
  }
  foreach ($w in $Contractions) {
    if ($l -match "(?i)\b$w\b") {
      $issues += [pscustomobject]@{ Line=$ln; Category='missing-apostrophe'; Detail="'$w' | $($l.Trim())" }
    }
  }
  foreach ($c in $ItemCasing) {
    if ($l -cmatch [regex]::Escape($c.Wrong)) {
      $issues += [pscustomobject]@{ Line=$ln; Category='item-casing'; Detail="'$($c.Wrong)' -> should be '$($c.Right)' | $($l.Trim())" }
    }
  }
}

# --- Bank header sequencing ---
$bankLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^#\s*Bank\s+(\d+)\s*$') { $bankLines += [pscustomobject]@{ Line=$i+1; Num=[int]$Matches[1] } }
}
for ($i = 1; $i -lt $bankLines.Count; $i++) {
  $prev = $bankLines[$i-1].Num
  $cur = $bankLines[$i].Num
  if ($cur -ne $prev + 1) {
    $issues += [pscustomobject]@{ Line=$bankLines[$i].Line; Category='bank-sequence'; Detail="Bank $cur follows Bank $prev (expected Bank $($prev+1))" }
  }
}

# --- apply mechanical fixes if requested ---
if ($Fix) {
  $changed = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $orig = $lines[$i]
    $l = $orig -replace [regex]::Escape($curlyApos1), "'" -replace [regex]::Escape($curlyApos2), "'"
    $l = $l -replace [regex]::Escape($curlyOpenQ), '"' -replace [regex]::Escape($curlyCloseQ), '"'
    $l = $l -replace '[ \t]+$', ''
    if ($l -ne $orig) { $lines[$i] = $l; $changed = $true }
  }
  if ($changed) {
    $out = ($lines -join "`r`n")
    [System.IO.File]::WriteAllText($Path, $out, [System.Text.UTF8Encoding]::new($false))
    Write-Output "Fixed curly quotes/apostrophes and trailing whitespace in place."
  } else {
    Write-Output "No mechanical fixes needed."
  }
  $issues = $issues | Where-Object { $_.Category -notin @('curly-apostrophe','curly-quote','trailing-whitespace') }
}

# --- report ---
if ($issues.Count -eq 0) {
  Write-Output "guide.txt is consistent: no issues found."
  exit 0
}

Write-Output "Found $($issues.Count) issue(s):"
$issues | Group-Object Category | Sort-Object Name | ForEach-Object {
  Write-Output ""
  Write-Output "== $($_.Name) ($($_.Count)) =="
  $_.Group | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.Line, $_.Detail) }
}
exit 1
