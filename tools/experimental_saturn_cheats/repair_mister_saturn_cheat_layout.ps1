[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SaturnRoot = "\\MiSTer\sdcard\games\Saturn",
    [string]$OutputRoot = "C:\MiSTer-Work\Saturn_Cheat_Sources",
    [string]$DryRunReportPath = "C:\MiSTer-Work\Saturn_Cheat_Sources\CHEAT_LAYOUT_REPAIR_DRYRUN_20260613.txt",
    [switch]$Execute
)

$ErrorActionPreference = "Stop"

function Get-ChtPathList {
    param([string]$Folder)

    if (!(Test-Path -LiteralPath $Folder)) { return @() }
    $lines = @(cmd /c dir "$Folder\*.CHT" /s /b /a-d 2^>nul | Where-Object { $_ -like "\\MiSTer\*" })
    return $lines
}

function ConvertTo-SafeName {
    param(
        [string]$Name,
        [int]$MaxLength = 120
    )

    $safe = $Name
    $safe = $safe -replace "^(libretro-sega-saturn|manual_import_queue_20260613)\s+", ""
    $safe = $safe -replace "\.cht\s+-\s+", " - "
    $safe = $safe -replace "\((GameShark|GameHacking|Action Replay|RetroArch)\)", ""
    $safe = $safe -replace "\b(SRMW|SRMR|SRM8|SRM9|SRMG)\b", ""
    $safe = $safe -replace "\b06TEST\b", ""
    $safe = $safe -replace "\bSUB\s+-\s+", ""
    $safe = $safe -replace "\btest\b", ""
    $safe = $safe -replace "\s+-\s+0x[0-9A-Fa-f_]+.*$", ""
    $safe = $safe -replace "\s+-\s+\d+\s+records?.*$", ""
    $safe = $safe -replace "0x[0-9A-Fa-f]{6,8}", ""
    $safe = $safe -replace "[\\/:*?`"<>|]", " "
    $safe = $safe -replace "[\x00-\x1F]", " "
    $safe = $safe -replace "\s+", " "
    $safe = $safe.Trim(" .-_")
    if ($safe.Length -gt $MaxLength) { $safe = $safe.Substring(0, $MaxLength).Trim(" .-_") }
    if ([string]::IsNullOrWhiteSpace($safe)) { $safe = "Unnamed" }
    return $safe
}

function Get-FormatFromName {
    param([string]$Path)

    $name = [IO.Path]::GetFileName($Path)
    if ($name -match " - (SRMW|SRMR|SRM8|SRM9|SRMG)(?:_\d+)?\.CHT$") { return $Matches[1] }
    return "UNKNOWN"
}

function Get-Bucket {
    param([string]$Game)

    if ([string]::IsNullOrWhiteSpace($Game)) { return "0-9" }
    $c = $Game.Substring(0, 1).ToUpperInvariant()
    if ($c -match "^[A-Z]$") { return $c }
    return "0-9"
}

function Get-ShortHash {
    param([string]$Text)

    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
    return (($hash | ForEach-Object { $_.ToString("x2") }) -join "").Substring(0, 8)
}

function Get-GameAndCheat {
    param(
        [string]$SourceRoot,
        [string]$SourcePath
    )

    $relative = $SourcePath.Substring($SourceRoot.Length).TrimStart("\")
    $parts = $relative -split "\\"
    $stem = [IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $format = Get-FormatFromName $SourcePath

    $stemNoFormat = $stem -replace "\s+-\s+(SRMW|SRMR|SRM8|SRM9|SRMG)(?:_\d+)?$", ""
    $stemNoFormat = $stemNoFormat -replace "\s+-\s+0x[0-9A-Fa-f_]+.*$", ""
    $stemNoFormat = $stemNoFormat -replace "\s+-\s+\d+\s+records?.*$", ""

    if ($parts.Count -ge 3 -and $parts[0] -match "^[A-Z0-9#]$") {
        $game = ConvertTo-SafeName $parts[1] 90
        $cheat = $stemNoFormat
        $cheat = $cheat -replace "^(libretro-sega-saturn|manual_import_queue_20260613)\s+", ""
        $cheat = $cheat -replace "^.*\.cht\s+-\s+", ""
        $cheat = $cheat -replace ("^" + [regex]::Escape($game) + "\s+-\s+"), ""
        $cheat = ConvertTo-SafeName $cheat 120
    } else {
        $clean = ConvertTo-SafeName $stemNoFormat 180
        $chunks = @($clean -split "\s+-\s+" | Where-Object { $_.Trim() })
        if ($chunks.Count -ge 2) {
            $game = ConvertTo-SafeName (($chunks[0..($chunks.Count - 2)] -join " - ")) 90
            $cheat = ConvertTo-SafeName $chunks[-1] 120
        } else {
            $game = "Unknown"
            $cheat = ConvertTo-SafeName $clean 120
        }
    }

    if ($format -eq "SRMR" -or $format -eq "SRM9") {
        $kind = "Refresh"
    } elseif ($format -eq "SRMG") {
        $kind = "Grouped"
    } else {
        $kind = "Trigger"
    }

    return [pscustomobject]@{
        Game       = $game
        Cheat      = $cheat
        Format     = $format
        KindSuffix = $kind
    }
}

function Add-PlannedFile {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [hashtable]$PathCounts,
        [ref]$CollisionCount,
        [ref]$SanitizedCount,
        [string]$SourceRoot,
        [string]$SourcePath,
        [string]$DestinationRoot,
        [string]$DestinationClass,
        [bool]$IsUtility = $false
    )

    $info = Get-GameAndCheat $SourceRoot $SourcePath
    $originalStem = [IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $sanitized = ($originalStem -ne $info.Cheat)
    if ($sanitized) { $SanitizedCount.Value++ }

    $bucket = Get-Bucket $info.Game
    $destDir = Join-Path (Join-Path $DestinationRoot $bucket) $info.Game
    $baseName = $info.Cheat
    $plannedPath = Join-Path $destDir ($baseName + ".CHT")
    $collisionKey = $plannedPath.ToLowerInvariant()

    if ($PathCounts.ContainsKey($collisionKey)) {
        $CollisionCount.Value++
        $PathCounts[$collisionKey]++
        $suffix = $info.KindSuffix
        $candidate = Join-Path $destDir ("$baseName - $suffix.CHT")
        $candidateKey = $candidate.ToLowerInvariant()
        if ($PathCounts.ContainsKey($candidateKey)) {
            $hash = Get-ShortHash $SourcePath
            $candidate = Join-Path $destDir ("$baseName - $hash.CHT")
            $candidateKey = $candidate.ToLowerInvariant()
        }
        $plannedPath = $candidate
        $PathCounts[$candidateKey] = 1
    } else {
        $PathCounts[$collisionKey] = 1
    }

    $size = [System.IO.FileInfo]::new($SourcePath).Length
    $Rows.Add([pscustomobject]@{
        Source             = $SourcePath
        Destination        = $plannedPath
        DestinationClass   = $DestinationClass
        Game               = $info.Game
        Cheat              = $info.Cheat
        Format             = $info.Format
        SizeBytes          = $size
        Sanitized          = $sanitized
        IsUtility          = $IsUtility
    })
}

function Copy-PlannedRows {
    param([System.Collections.Generic.List[object]]$Rows)

    foreach ($row in $Rows) {
        if ($PSCmdlet.ShouldProcess($row.Destination, "Copy cheat file")) {
            $dir = Split-Path -Parent $row.Destination
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            Copy-Item -LiteralPath $row.Source -Destination $row.Destination -Force
        }
    }
}

if (!(Test-Path -LiteralPath $SaturnRoot)) {
    throw "Saturn root not found: $SaturnRoot"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $OutputRoot "MISTER_SATURN_CHEATS_LAYOUT_BACKUP_$timestamp"
$postReport = Join-Path $OutputRoot "MISTER_SATURN_CHEATS_LAYOUT_REPAIR_REPORT_$timestamp.txt"
$manifestPath = Join-Path $OutputRoot "CHEAT_LAYOUT_REPAIR_DRYRUN_MANIFEST_20260613.csv"

$rows = [System.Collections.Generic.List[object]]::new()
$pathCounts = @{}
$collisionCount = 0
$sanitizedCount = 0
$ambiguous = [System.Collections.Generic.List[object]]::new()

$constantRoot = Join-Path $SaturnRoot "Cheats\Constant"
$triggerRoot = Join-Path $SaturnRoot "Cheats\Trigger"
$groupedRoot = Join-Path $SaturnRoot "Cheats\Experimental_Grouped"
$test06Root = Join-Path $SaturnRoot "Cheats\Experimental_06TEST"

$sourceSpecs = @(
    @{ Source = "Cheats_60Frames";                    Dest = $constantRoot; Class = "Constant"; Formats = @("SRMR") },
    @{ Source = "Cheats_60Frames_8bit";               Dest = $constantRoot; Class = "Constant"; Formats = @("SRM9") },
    @{ Source = "Cheats_Trigger";                     Dest = $triggerRoot;  Class = "Trigger";  Formats = @("SRMW") },
    @{ Source = "Cheats_Trigger_8bit";                Dest = $triggerRoot;  Class = "Trigger";  Formats = @("SRM8") },
    @{ Source = "Cheats_Grouped_Experimental";        Dest = $groupedRoot;  Class = "Experimental_Grouped"; Formats = @("SRMG") },
    @{ Source = "Cheats_Master_SubOnly_Experimental"; Dest = $constantRoot; Class = "Constant"; Formats = @("SRMR", "SRM9") },
    @{ Source = "Cheats_Master_SubOnly_Experimental"; Dest = $triggerRoot;  Class = "Trigger";  Formats = @("SRMW", "SRM8") },
    @{ Source = "Cheats_Master_SubOnly_Experimental"; Dest = $groupedRoot;  Class = "Experimental_Grouped"; Formats = @("SRMG") },
    @{ Source = "Cheats_06TEST_Experimental";         Dest = $test06Root;   Class = "Experimental_06TEST"; Formats = @("SRMW", "SRMR", "SRMG") }
)

foreach ($spec in $sourceSpecs) {
    $sourceRoot = Join-Path $SaturnRoot $spec.Source
    $files = Get-ChtPathList $sourceRoot
    foreach ($file in $files) {
        $format = Get-FormatFromName $file
        if ($spec.Formats -contains $format) {
            Add-PlannedFile $rows $pathCounts ([ref]$collisionCount) ([ref]$sanitizedCount) $sourceRoot $file $spec.Dest $spec.Class $false
        } elseif ($spec.Source -eq "Cheats_Master_SubOnly_Experimental" -and $format -eq "UNKNOWN") {
            $ambiguous.Add([pscustomobject]@{
                Source = $file
                Reason = "Master_SubOnly file has unknown format suffix"
            })
        }
    }
}

$srmcSource = Join-Path $SaturnRoot "SRMC_Clear_Refresh.CHT"
$srmcDest = Join-Path $constantRoot "G\Global\Clear Active Refresh.CHT"
if (Test-Path -LiteralPath $srmcSource) {
    $srmcDir = Split-Path -Parent $srmcDest
    $srmcSize = [System.IO.FileInfo]::new($srmcSource).Length
    $rows.Add([pscustomobject]@{
        Source             = $srmcSource
        Destination        = $srmcDest
        DestinationClass   = "Constant"
        Game               = "Global"
        Cheat              = "Clear Active Refresh"
        Format             = "SRMC"
        SizeBytes          = $srmcSize
        Sanitized          = $true
        IsUtility          = $true
    })
    $sanitizedCount++
} else {
    $ambiguous.Add([pscustomobject]@{
        Source = $srmcSource
        Reason = "SRMC clear file missing"
    })
}

$rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation

$constantCheats = @($rows | Where-Object { $_.DestinationClass -eq "Constant" -and -not $_.IsUtility })
$triggerCheats = @($rows | Where-Object { $_.DestinationClass -eq "Trigger" })
$groupedCheats = @($rows | Where-Object { $_.DestinationClass -eq "Experimental_Grouped" })
$test06Cheats = @($rows | Where-Object { $_.DestinationClass -eq "Experimental_06TEST" })
$utilityRows = @($rows | Where-Object { $_.IsUtility })

$expectedConstant = 2265
$expectedTrigger = 2265
$expectedGrouped = 305
$expected06 = 39

$badPlanned = @($rows | Where-Object {
    if ($_.Format -eq "SRMG") { $_.SizeBytes -notin 32,48,64,80 }
    elseif ($_.Format -eq "SRMC") { $_.SizeBytes -ne 16 }
    else { $_.SizeBytes -ne 16 }
})

$sampleRows = @($rows | Select-Object -First 20)

$dryRunLines = [System.Collections.Generic.List[string]]::new()
$dryRunLines.Add("Saturn Cheat Layout Repair Dry Run - 20260613")
$dryRunLines.Add("Generated: $((Get-Date).ToString('s'))")
$dryRunLines.Add("Execute: $Execute")
$dryRunLines.Add("Saturn root: $SaturnRoot")
$dryRunLines.Add("")
$dryRunLines.Add("Planned counts:")
$dryRunLines.Add("- Constant cheat files: $($constantCheats.Count), expected $expectedConstant")
$dryRunLines.Add("- Trigger cheat files: $($triggerCheats.Count), expected $expectedTrigger")
$dryRunLines.Add("- Experimental_Grouped files: $($groupedCheats.Count), expected $expectedGrouped")
$dryRunLines.Add("- Experimental_06TEST files: $($test06Cheats.Count), expected $expected06")
$dryRunLines.Add("- SRMC utility files: $($utilityRows.Count)")
$dryRunLines.Add("- Constant total including SRMC utility: $($constantCheats.Count + $utilityRows.Count)")
$dryRunLines.Add("")
$dryRunLines.Add("Planned SRMC copy path:")
$dryRunLines.Add("- $srmcDest")
$dryRunLines.Add("")
$dryRunLines.Add("Sanitization/collisions:")
$dryRunLines.Add("- Filenames that will be sanitized: $sanitizedCount")
$dryRunLines.Add("- Filename collisions detected before suffixing: $collisionCount")
$dryRunLines.Add("- Ambiguous/unclassified files: $($ambiguous.Count)")
$dryRunLines.Add("- Planned bad-size files: $($badPlanned.Count)")
$dryRunLines.Add("")
$dryRunLines.Add("Sample before/after paths:")
foreach ($row in $sampleRows) {
    $dryRunLines.Add("- BEFORE: $($row.Source)")
    $dryRunLines.Add("  AFTER:  $($row.Destination)")
}
$dryRunLines.Add("")
$dryRunLines.Add("Ambiguous/unclassified files:")
if ($ambiguous.Count) {
    foreach ($a in $ambiguous) { $dryRunLines.Add("- $($a.Source): $($a.Reason)") }
} else {
    $dryRunLines.Add("- none")
}
$dryRunLines.Add("")
$dryRunLines.Add("Confirmation:")
if ($Execute) {
    $dryRunLines.Add("- This was an execute run; files may have been copied after backup.")
} else {
    $dryRunLines.Add("- Dry-run only: no files were moved, copied, renamed, or deleted.")
}
$dryRunLines.Add("- Old Cheats_* folders are not deleted by this script.")
$dryRunLines.Add("- Manifest: $manifestPath")
$dryRunLines | Set-Content -LiteralPath $DryRunReportPath -Encoding UTF8

if ($Execute) {
    if ($PSCmdlet.ShouldProcess($backupDir, "Create timestamped backup before repair")) {
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        foreach ($folder in @("Cheats_Trigger","Cheats_60Frames","Cheats_Trigger_8bit","Cheats_60Frames_8bit","Cheats_Grouped_Experimental","Cheats_Master_SubOnly_Experimental","Cheats_06TEST_Experimental")) {
            $src = Join-Path $SaturnRoot $folder
            if (Test-Path -LiteralPath $src) {
                Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $folder) -Recurse -Force
            }
        }
        if (Test-Path -LiteralPath $srmcSource) {
            Copy-Item -LiteralPath $srmcSource -Destination (Join-Path $backupDir "SRMC_Clear_Refresh.CHT") -Force
        }
    }

    Copy-PlannedRows $rows

    $post = @()
    $post += "Saturn Cheat Layout Repair Post-Run Report"
    $post += "Generated: $((Get-Date).ToString('s'))"
    $post += "Backup: $backupDir"
    $post += "Dry-run/report: $DryRunReportPath"
    $post += "Manifest: $manifestPath"
    foreach ($dest in @($constantRoot, $triggerRoot, $groupedRoot, $test06Root)) {
        $files = @(Get-ChildItem -LiteralPath $dest -Recurse -Filter "*.CHT" -File -ErrorAction SilentlyContinue)
        $bad = @($files | Where-Object {
            if ($_.Name -match "Grouped|SRMG") { $_.Length -notin 32,48,64,80 } else { $_.Length -ne 16 }
        })
        $post += "- $dest files=$($files.Count), bad_size=$($bad.Count)"
    }
    $post | Set-Content -LiteralPath $postReport -Encoding UTF8
}

[pscustomobject]@{
    Execute = [bool]$Execute
    ConstantCheats = $constantCheats.Count
    TriggerCheats = $triggerCheats.Count
    ExperimentalGrouped = $groupedCheats.Count
    Experimental06TEST = $test06Cheats.Count
    SRMCUtility = $utilityRows.Count
    Sanitized = $sanitizedCount
    Collisions = $collisionCount
    Ambiguous = $ambiguous.Count
    BadPlanned = $badPlanned.Count
    DryRunReport = $DryRunReportPath
    Manifest = $manifestPath
} | Format-List
