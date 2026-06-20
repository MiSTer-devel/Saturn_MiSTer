param(
    [string]$ClassificationDir = "C:\MiSTer-Work\Saturn_Cheat_Sources\libretro-sega-saturn-classification",
    [string]$OutputRoot = "C:\MiSTer-Work\Saturn_Cheat_Sources"
)

$ErrorActionPreference = "Stop"

$supported16Path = Join-Path $ClassificationDir "supported_16bit.csv"
$supported8Path = Join-Path $ClassificationDir "supported_8bit.csv"
$unsupportedPath = Join-Path $ClassificationDir "unsupported.csv"
$manualPath = Join-Path $ClassificationDir "manual_review.csv"

$srmwDir = Join-Path $OutputRoot "generated_srmw_pack"
$srmrDir = Join-Path $OutputRoot "generated_srmr_pack"
$manualDir = Join-Path $OutputRoot "generated_srmw_manual_multirecord_parts"
$srm8Dir = Join-Path $OutputRoot "generated_srm8_pack"
$srm9Dir = Join-Path $OutputRoot "generated_srm9_pack"
$srmgDir = Join-Path $OutputRoot "generated_srmg_pack"

foreach ($dir in @($srmwDir, $srmrDir, $manualDir, $srm8Dir, $srm9Dir, $srmgDir)) {
    if (Test-Path -LiteralPath $dir) {
        Get-ChildItem -LiteralPath $dir -Force | Remove-Item -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

function ConvertTo-SafeName {
    param([string]$Name)

    $safe = $Name -replace "\(GameShark\)", ""
    $safe = $safe -replace "\(Action Replay\)", ""
    $safe = $safe -replace "\(RetroArch\)", ""
    $safe = $safe -replace "\.cht$", ""
    $safe = $safe -replace "[\\/:*?`"<>|]", " "
    $safe = $safe -replace "[\x00-\x1F]", " "
    $safe = $safe -replace "\s+", " "
    $safe = $safe.Trim(" .-_")
    if ($safe.Length -gt 120) { $safe = $safe.Substring(0, 120).Trim(" .-_") }
    if ([string]::IsNullOrWhiteSpace($safe)) { $safe = "Unnamed" }
    return $safe
}

function Get-UniquePath {
    param(
        [string]$Directory,
        [string]$BaseName,
        [string]$Extension = ".CHT"
    )

    $candidate = Join-Path $Directory ($BaseName + $Extension)
    if (!(Test-Path -LiteralPath $candidate)) { return $candidate }

    for ($i = 2; $i -lt 10000; $i++) {
        $candidate = Join-Path $Directory ("{0}_{1}{2}" -f $BaseName, $i, $Extension)
        if (!(Test-Path -LiteralPath $candidate)) { return $candidate }
    }

    throw "Unable to find unique filename for $BaseName"
}

function Write-Cheat16File {
    param(
        [string]$Path,
        [string]$Magic,
        [uint32]$Address,
        [uint32]$Value
    )

    $magicBytes = [Text.Encoding]::ASCII.GetBytes($Magic)
    if ($magicBytes.Length -ne 4) { throw "Magic must be exactly four ASCII bytes: $Magic" }

    [byte[]]$bytes = @(
        $magicBytes[0], $magicBytes[1], $magicBytes[2], $magicBytes[3],
        0x00, 0x00, 0x00, 0x00,
        (($Address -shr 24) -band 0xFF), (($Address -shr 16) -band 0xFF), (($Address -shr 8) -band 0xFF), ($Address -band 0xFF),
        (($Value -shr 24) -band 0xFF), (($Value -shr 16) -band 0xFF), (($Value -shr 8) -band 0xFF), ($Value -band 0xFF)
    )
    [IO.File]::WriteAllBytes($Path, $bytes)
}

function Write-Cheat8File {
    param(
        [string]$Path,
        [string]$Magic,
        [uint32]$Address,
        [uint32]$Value
    )

    if ($Value -gt 0xFF) { throw ("8-bit value exceeds 0xFF: 0x{0:X8}" -f $Value) }
    Write-Cheat16File $Path $Magic $Address $Value
}

function Write-SrmgFile {
    param(
        [string]$Path,
        [uint32[]]$Addresses,
        [uint32[]]$Values
    )

    if ($Addresses.Count -ne $Values.Count) { throw "SRMG address/value count mismatch" }
    if ($Addresses.Count -lt 1 -or $Addresses.Count -gt 4) { throw "SRMG record count must be 1..4" }

    $bytes = [System.Collections.Generic.List[byte]]::new()
    $headerMagic = [Text.Encoding]::ASCII.GetBytes("SRMG")
    foreach ($b in $headerMagic) { $bytes.Add($b) }
    $count = [uint32]$Addresses.Count
    foreach ($b in @(
        (($count -shr 24) -band 0xFF), (($count -shr 16) -band 0xFF), (($count -shr 8) -band 0xFF), ($count -band 0xFF),
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
    )) { $bytes.Add([byte]$b) }

    for ($i = 0; $i -lt $Addresses.Count; $i++) {
        $magicBytes = [Text.Encoding]::ASCII.GetBytes("SRMW")
        foreach ($b in $magicBytes) { $bytes.Add($b) }
        foreach ($b in @(0x00, 0x00, 0x00, 0x00)) { $bytes.Add([byte]$b) }
        $addr = [uint32]$Addresses[$i]
        $value = [uint32]$Values[$i]
        foreach ($b in @(
            (($addr -shr 24) -band 0xFF), (($addr -shr 16) -band 0xFF), (($addr -shr 8) -band 0xFF), ($addr -band 0xFF),
            (($value -shr 24) -band 0xFF), (($value -shr 16) -band 0xFF), (($value -shr 8) -band 0xFF), ($value -band 0xFF)
        )) { $bytes.Add([byte]$b) }
    }

    [IO.File]::WriteAllBytes($Path, $bytes.ToArray())
}

function Add-ManifestRow {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [string]$Game,
        [string]$CheatName,
        [string]$SourceFile,
        [string]$SourceCode,
        [string]$OutputFile,
        [string]$Mode,
        [string]$Address,
        [string]$Value,
        [int]$RecordIndex,
        [int]$TotalRecords,
        [string]$Notes
    )

    $Rows.Add([pscustomobject]@{
        game          = $Game
        cheat_name    = $CheatName
        source_file   = $SourceFile
        source_code   = $SourceCode
        output_file   = $OutputFile
        mode          = $Mode
        address       = $Address
        value         = $Value
        record_index  = $RecordIndex
        total_records = $TotalRecords
        notes         = $Notes
    })
}

function Add-SkippedRow {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [string]$SourceFile,
        [string]$CheatIndex,
        [string]$CheatName,
        [string]$SourceCode,
        [string]$Reason,
        [string]$Classification = ""
    )

    $Rows.Add([pscustomobject]@{
        source_file    = $SourceFile
        cheat_index    = $CheatIndex
        cheat_name     = $CheatName
        source_code    = $SourceCode
        classification = $Classification
        reason         = $Reason
    })
}

function Test-ValidRamh16 {
    param([uint32]$Address)
    return (($Address -ge 0x06000000) -and ($Address -le 0x060FFFFF) -and (($Address -band 1) -eq 0))
}

function Test-ValidRamh8 {
    param([uint32]$Address)
    return (($Address -ge 0x06000000) -and ($Address -le 0x060FFFFF))
}

if (!(Test-Path -LiteralPath $supported16Path)) {
    throw "Missing supported_16bit.csv: $supported16Path"
}

$supported16 = Import-Csv -LiteralPath $supported16Path
$supported8 = if (Test-Path -LiteralPath $supported8Path) { @(Import-Csv -LiteralPath $supported8Path) } else { @() }
$manifestRows = [System.Collections.Generic.List[object]]::new()
$manifest8Rows = [System.Collections.Generic.List[object]]::new()
$manifestGroupRows = [System.Collections.Generic.List[object]]::new()
$skippedRows = [System.Collections.Generic.List[object]]::new()
$skipped8Rows = [System.Collections.Generic.List[object]]::new()
$skippedGroupRows = [System.Collections.Generic.List[object]]::new()

$singleRecordCheats = 0
$multiRecordCheats = 0
$srmgCandidateCheats = 0
$srmgFiles = 0
$srmgSkippedTooLarge = 0
$srmwFiles = 0
$srmrFiles = 0
$manualPartFiles = 0
$invalidSupportedRows = 0
$total8Rows = $supported8.Count
$singleRecord8Cheats = 0
$multiRecord8Cheats = 0
$srm8Files = 0
$srm9Files = 0
$invalidSupported8Rows = 0

foreach ($row in $supported16) {
    $totalRecords = [int]$row.record_count
    $game = ConvertTo-SafeName $row.source_file
    $cheat = ConvertTo-SafeName $row.description
    $records = @($row.normalized_records -split ";" | Where-Object { $_ })
    $addresses = @($row.ramh_addresses -split ";" | Where-Object { $_ })
    $values = @($row.values -split ";" | Where-Object { $_ })

    if ($records.Count -ne $totalRecords -or $addresses.Count -ne $totalRecords -or $values.Count -ne $totalRecords) {
        $invalidSupportedRows++
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code "normalized record/address/value count mismatch" $row.classification
        if ($totalRecords -gt 1) {
            Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code "SRMG skipped: normalized record/address/value count mismatch" $row.classification
        }
        continue
    }

    $validated = $true
    for ($i = 0; $i -lt $totalRecords; $i++) {
        $addr = [Convert]::ToUInt32(($addresses[$i] -replace "^0x", ""), 16)
        $value = [Convert]::ToUInt32(($values[$i] -replace "^0x", ""), 16)
        if (!(Test-ValidRamh16 $addr) -or $value -gt 0xFFFF) {
            $validated = $false
            break
        }
    }

    if (!$validated) {
        $invalidSupportedRows++
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code "record failed RAMH/alignment/value validation during generation" $row.classification
        if ($totalRecords -gt 1) {
            Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code "SRMG skipped: record failed RAMH/even-alignment/value validation during generation" $row.classification
        }
        continue
    }

    if ($totalRecords -eq 1) {
        $singleRecordCheats++
        $addr = [Convert]::ToUInt32(($addresses[0] -replace "^0x", ""), 16)
        $value = [Convert]::ToUInt32(($values[0] -replace "^0x", ""), 16)
        $addrText = "0x{0:X8}" -f $addr
        $valueText = "0x{0:X4}" -f $value
        $base = ConvertTo-SafeName ("{0} - {1} - {2}" -f $game, $cheat, $addrText)

        $srmwPath = Get-UniquePath $srmwDir ($base + " - SRMW")
        Write-Cheat16File $srmwPath "SRMW" $addr $value
        $srmwFiles++
        Add-ManifestRow $manifestRows $game $row.description $row.source_file $row.original_code $srmwPath "SRMW" $addrText $valueText 1 1 "one-shot parser-compatible 16-byte SRMW"

        $srmrPath = Get-UniquePath $srmrDir ($base + " - SRMR")
        Write-Cheat16File $srmrPath "SRMR" $addr $value
        $srmrFiles++
        Add-ManifestRow $manifestRows $game $row.description $row.source_file $row.original_code $srmrPath "SRMR" $addrText $valueText 1 1 "refresh parser-compatible 16-byte SRMR"
    }
    elseif ($totalRecords -gt 1) {
        $multiRecordCheats++
        if ($totalRecords -le 4) {
            $srmgCandidateCheats++
            [uint32[]]$srmgAddresses = @()
            [uint32[]]$srmgValues = @()
            for ($i = 0; $i -lt $totalRecords; $i++) {
                $srmgAddresses += [Convert]::ToUInt32(($addresses[$i] -replace "^0x", ""), 16)
                $srmgValues += [Convert]::ToUInt32(($values[$i] -replace "^0x", ""), 16)
            }

            $baseAddresses = @($srmgAddresses | ForEach-Object { "0x{0:X8}" -f $_ }) -join "_"
            $base = ConvertTo-SafeName ("{0} - {1} - {2} records - {3}" -f $game, $cheat, $totalRecords, $baseAddresses)
            $srmgPath = Get-UniquePath $srmgDir ($base + " - SRMG")
            Write-SrmgFile $srmgPath $srmgAddresses $srmgValues
            $expectedSize = 16 * ($totalRecords + 1)
            $actualSize = (Get-Item -LiteralPath $srmgPath).Length
            if ($actualSize -ne $expectedSize) {
                throw "SRMG size validation failed for $srmgPath; expected $expectedSize, got $actualSize"
            }
            $srmgFiles++

            for ($i = 0; $i -lt $totalRecords; $i++) {
                $addrText = "0x{0:X8}" -f $srmgAddresses[$i]
                $valueText = "0x{0:X4}" -f $srmgValues[$i]
                Add-ManifestRow $manifestGroupRows $game $row.description $row.source_file $row.original_code $srmgPath "SRMG" $addrText $valueText ($i + 1) $totalRecords "one-shot grouped direct 16-bit record; file size $actualSize bytes"
            }
        }
        else {
            $srmgSkippedTooLarge++
            Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code "SRMG skipped: group has $totalRecords records; first pass supports 2 to 4 direct 16-bit records only" $row.classification
        }

        for ($i = 0; $i -lt $totalRecords; $i++) {
            $addr = [Convert]::ToUInt32(($addresses[$i] -replace "^0x", ""), 16)
            $value = [Convert]::ToUInt32(($values[$i] -replace "^0x", ""), 16)
            $addrText = "0x{0:X8}" -f $addr
            $valueText = "0x{0:X4}" -f $value
            $base = ConvertTo-SafeName ("{0} - {1} - part {2:D2} of {3:D2} - {4}" -f $game, $cheat, ($i + 1), $totalRecords, $addrText)

            $manualPathOut = Get-UniquePath $manualDir ($base + " - manual_SRMR")
            Write-Cheat16File $manualPathOut "SRMR" $addr $value
            $manualPartFiles++
            Add-ManifestRow $manifestRows $game $row.description $row.source_file $row.original_code $manualPathOut "manual_part" $addrText $valueText ($i + 1) $totalRecords "manual one-record SRMR part only; real usability requires future multi-slot refresh support"
        }
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code "multi-record simple 16-bit cheat split into manual parts; not emitted as a combined usable cheat yet" $row.classification
    }
}

$clearPath = Join-Path $srmrDir "SRMC_Clear_Refresh.CHT"
Write-Cheat16File $clearPath "SRMC" 0 0
Add-ManifestRow $manifestRows "Global" "Clear Refresh" "generated" "SRMC" $clearPath "SRMR" "0x00000000" "0x0000" 0 0 "clears retained SRMR refresh record"

foreach ($row in $supported8) {
    $totalRecords = [int]$row.record_count
    $game = ConvertTo-SafeName $row.source_file
    $cheat = ConvertTo-SafeName $row.description
    $records = @($row.normalized_records -split ";" | Where-Object { $_ })
    $addresses = @($row.ramh_addresses -split ";" | Where-Object { $_ })
    $values = @($row.values -split ";" | Where-Object { $_ })

    if ($records.Count -ne $totalRecords -or $addresses.Count -ne $totalRecords -or $values.Count -ne $totalRecords) {
        $invalidSupported8Rows++
        Add-SkippedRow $skipped8Rows $row.source_file $row.cheat_index $row.description $row.original_code "normalized record/address/value count mismatch" $row.classification
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code "8-bit row handled by SRM8/SRM9 path: normalized record/address/value count mismatch" $row.classification
        if ($totalRecords -gt 1) {
            Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code "SRMG skipped: 8-bit group normalized record/address/value count mismatch" $row.classification
        }
        continue
    }

    $validated = $true
    $failureReason = ""
    for ($i = 0; $i -lt $totalRecords; $i++) {
        $addr = [Convert]::ToUInt32(($addresses[$i] -replace "^0x", ""), 16)
        $value = [Convert]::ToUInt32(($values[$i] -replace "^0x", ""), 16)
        if (!(Test-ValidRamh8 $addr)) {
            $validated = $false
            $failureReason = "record failed RAMH address validation during 8-bit generation"
            break
        }
        if ($value -gt 0xFF) {
            $validated = $false
            $failureReason = "8-bit value exceeds 0xFF; skipped rather than masking ambiguous source value"
            break
        }
    }

    if (!$validated) {
        $invalidSupported8Rows++
        Add-SkippedRow $skipped8Rows $row.source_file $row.cheat_index $row.description $row.original_code $failureReason $row.classification
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code "8-bit row handled by SRM8/SRM9 path: $failureReason" $row.classification
        if ($totalRecords -gt 1) {
            Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code "SRMG skipped: 8-bit group is out of scope; $failureReason" $row.classification
        }
        continue
    }

    if ($totalRecords -eq 1) {
        $singleRecord8Cheats++
        $addr = [Convert]::ToUInt32(($addresses[0] -replace "^0x", ""), 16)
        $value = [Convert]::ToUInt32(($values[0] -replace "^0x", ""), 16)
        $addrText = "0x{0:X8}" -f $addr
        $valueText = "0x{0:X2}" -f $value
        $base = ConvertTo-SafeName ("{0} - {1} - {2}" -f $game, $cheat, $addrText)

        $srm8Path = Get-UniquePath $srm8Dir ($base + " - SRM8")
        Write-Cheat8File $srm8Path "SRM8" $addr $value
        $srm8Files++
        Add-ManifestRow $manifest8Rows $game $row.description $row.source_file $row.original_code $srm8Path "SRM8" $addrText $valueText 1 1 "one-shot parser-compatible 16-byte SRM8; value stored in low byte"

        $srm9Path = Get-UniquePath $srm9Dir ($base + " - SRM9")
        Write-Cheat8File $srm9Path "SRM9" $addr $value
        $srm9Files++
        Add-ManifestRow $manifest8Rows $game $row.description $row.source_file $row.original_code $srm9Path "SRM9" $addrText $valueText 1 1 "refresh parser-compatible 16-byte SRM9; value stored in low byte"
    }
    elseif ($totalRecords -gt 1) {
        $multiRecord8Cheats++
        Add-SkippedRow $skipped8Rows $row.source_file $row.cheat_index $row.description $row.original_code "multi-record simple 8-bit cheat skipped; current proof supports one active refresh record only" $row.classification
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code "8-bit row handled by SRM8/SRM9 path: multi-record simple 8-bit cheat skipped; current proof supports one active refresh record only" $row.classification
        Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code "SRMG skipped: 8-bit groups are out of scope for direct 16-bit SRMG" $row.classification
    }
}

if (Test-Path -LiteralPath $unsupportedPath) {
    foreach ($row in (Import-Csv -LiteralPath $unsupportedPath)) {
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code $row.reason $row.classification
        Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code ("SRMG skipped: unsupported/non-direct-16-bit source - " + $row.reason) $row.classification
        if ($row.original_code -match '(^|\+)36[0-9A-Fa-f]{6}') {
            Add-SkippedRow $skipped8Rows $row.source_file $row.cheat_index $row.description $row.original_code $row.reason $row.classification
        }
    }
}

if (Test-Path -LiteralPath $manualPath) {
    foreach ($row in (Import-Csv -LiteralPath $manualPath)) {
        Add-SkippedRow $skippedRows $row.source_file $row.cheat_index $row.description $row.original_code $row.reason $row.classification
        Add-SkippedRow $skippedGroupRows $row.source_file $row.cheat_index $row.description $row.original_code ("SRMG skipped: manual-review/non-direct-16-bit source - " + $row.reason) $row.classification
        if ($row.original_code -match '(^|\+)36[0-9A-Fa-f]{6}') {
            Add-SkippedRow $skipped8Rows $row.source_file $row.cheat_index $row.description $row.original_code $row.reason $row.classification
        }
    }
}

$manifestPath = Join-Path $OutputRoot "generated_srmw_srmr_manifest.csv"
$skippedPath = Join-Path $OutputRoot "generated_srmw_srmr_unsupported_or_skipped.csv"
$summaryPath = Join-Path $OutputRoot "generated_srmw_srmr_summary.txt"
$manifest8Path = Join-Path $OutputRoot "generated_srm8_srm9_manifest.csv"
$skipped8Path = Join-Path $OutputRoot "generated_srm8_srm9_unsupported_or_skipped.csv"
$summary8Path = Join-Path $OutputRoot "generated_srm8_srm9_summary.txt"
$manifestGroupPath = Join-Path $OutputRoot "generated_srmg_manifest.csv"
$skippedGroupPath = Join-Path $OutputRoot "generated_srmg_unsupported_or_skipped.csv"
$summaryGroupPath = Join-Path $OutputRoot "generated_srmg_summary.txt"

$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation
$skippedRows | Export-Csv -LiteralPath $skippedPath -NoTypeInformation
$manifest8Rows | Export-Csv -LiteralPath $manifest8Path -NoTypeInformation
$skipped8Rows | Export-Csv -LiteralPath $skipped8Path -NoTypeInformation
$manifestGroupRows | Export-Csv -LiteralPath $manifestGroupPath -NoTypeInformation
$skippedGroupRows | Export-Csv -LiteralPath $skippedGroupPath -NoTypeInformation

# Put convenience copies in each output folder too, so every generated pack is self-describing.
foreach ($dir in @($srmwDir, $srmrDir, $manualDir)) {
    $manifestRows | Export-Csv -LiteralPath (Join-Path $dir "manifest.csv") -NoTypeInformation
    $skippedRows | Export-Csv -LiteralPath (Join-Path $dir "unsupported_or_skipped.csv") -NoTypeInformation
}
foreach ($dir in @($srm8Dir, $srm9Dir)) {
    $manifest8Rows | Export-Csv -LiteralPath (Join-Path $dir "manifest.csv") -NoTypeInformation
    $skipped8Rows | Export-Csv -LiteralPath (Join-Path $dir "unsupported_or_skipped.csv") -NoTypeInformation
}
$manifestGroupRows | Export-Csv -LiteralPath (Join-Path $srmgDir "manifest.csv") -NoTypeInformation
$skippedGroupRows | Export-Csv -LiteralPath (Join-Path $srmgDir "unsupported_or_skipped.csv") -NoTypeInformation

$recommendationWords = "infinite|health|life|lives|energy|ammo|bullets|fuel|grenades|charges|rings|time|armor|battery|batteries|weapon|money|credits"
$top20 = $manifestRows |
    Where-Object { $_.mode -eq "SRMR" -and $_.game -ne "Global" } |
    Sort-Object @{ Expression = {
        $text = ($_.cheat_name + " " + $_.game).ToLowerInvariant()
        if ($text -match $recommendationWords) { 0 } else { 1 }
    }}, game, cheat_name |
    Select-Object -First 20

$summary = @"
SRMW/SRMR parser-compatible 16-byte pack generation summary
Generated: $(Get-Date -Format s)

Input:
$supported16Path

Output folders:
$srmwDir
$srmrDir
$manualDir
$srmgDir

Report files:
$manifestPath
$skippedPath
$summaryPath
$manifestGroupPath
$skippedGroupPath
$summaryGroupPath

Counts:
- Single-record 16-bit cheats converted: $singleRecordCheats
- SRMW files generated: $srmwFiles
- SRMR files generated: $srmrFiles
- Multi-record simple cheats split into manual parts: $multiRecordCheats
- Manual part files generated: $manualPartFiles
- SRMG candidate 2-4 record direct 16-bit groups: $srmgCandidateCheats
- SRMG one-shot group files generated: $srmgFiles
- SRMG groups skipped because record count exceeds 4: $srmgSkippedTooLarge
- Skipped/unsupported rows reported: $($skippedRows.Count)
- Invalid supported_16bit rows skipped during generation: $invalidSupportedRows
- SRMC clear files generated: 1

Format:
- SRMW: 0x00 magic "SRMW", 0x04 reserved 0, 0x08 address, 0x0C value
- SRMR: 0x00 magic "SRMR", 0x04 reserved 0, 0x08 address, 0x0C value
- SRMG: 0x00 header magic "SRMG", 0x04 record_count, 0x08 reserved 0, 0x0C reserved 0, followed by 2-4 embedded SRMW records
- SRMC: 0x00 magic "SRMC", remaining words zero
- All fields are big-endian.

Notes:
- Only simple 16-bit RAMH writes are emitted.
- SRMG files are one-shot only and do not create refresh state.
- Simple single-record 8-bit RAMH writes are emitted separately as SRM8/SRM9.
- Conditionals, master/enabler codes, unknown values/modifiers, and RetroArch address/value-style entries are skipped.
- Multi-record simple cheats are still split into manual one-record SRMR parts for reference. Direct 16-bit groups with 2-4 records are additionally emitted as SRMG one-shot files.

Top 20 recommended single-record SRMR cheats to test:
$($top20 | ForEach-Object { "- $($_.game): $($_.cheat_name) [$($_.address) = $($_.value)] -> $($_.output_file)" } | Out-String)
"@

$summary | Set-Content -LiteralPath $summaryPath -Encoding UTF8
foreach ($dir in @($srmwDir, $srmrDir, $manualDir)) {
    $summary | Set-Content -LiteralPath (Join-Path $dir "summary.txt") -Encoding UTF8
}

$srm8Games = @($manifest8Rows | Where-Object { $_.mode -eq "SRM8" } | Select-Object -ExpandProperty game -Unique | Sort-Object)
$srm9Games = @($manifest8Rows | Where-Object { $_.mode -eq "SRM9" } | Select-Object -ExpandProperty game -Unique | Sort-Object)
$skipped8ReasonCounts = $skipped8Rows |
    Group-Object reason |
    Sort-Object @{ Expression = "Count"; Descending = $true }, Name |
    ForEach-Object { "- $($_.Count): $($_.Name)" }
$top20Srm9 = $manifest8Rows |
    Where-Object { $_.mode -eq "SRM9" } |
    Sort-Object @{ Expression = {
        $text = ($_.cheat_name + " " + $_.game).ToLowerInvariant()
        if ($text -match $recommendationWords) { 0 } else { 1 }
    }}, game, cheat_name |
    Select-Object -First 20

$summary8 = @"
SRM8/SRM9 parser-compatible 16-byte pack generation summary
Generated: $(Get-Date -Format s)

Input:
$supported8Path

Output folders:
$srm8Dir
$srm9Dir

Report files:
$manifest8Path
$skipped8Path
$summary8Path

Counts:
- Total simple 8-bit source rows found: $total8Rows
- Single-record 8-bit cheats converted: $singleRecord8Cheats
- SRM8 files generated: $srm8Files
- SRM9 files generated: $srm9Files
- Multi-record simple 8-bit cheats skipped: $multiRecord8Cheats
- Invalid supported_8bit rows skipped during generation: $invalidSupported8Rows
- Skipped/unsupported 8-bit rows reported: $($skipped8Rows.Count)
- Games represented by SRM8: $($srm8Games.Count)
- Games represented by SRM9: $($srm9Games.Count)

Format:
- SRM8: 0x00 magic "SRM8", 0x04 reserved 0, 0x08 address, 0x0C value in low byte
- SRM9: 0x00 magic "SRM9", 0x04 reserved 0, 0x08 address, 0x0C value in low byte
- All fields are big-endian.

Notes:
- Only simple single-record 8-bit RAMH writes are emitted as active cheats.
- Values must be 0x00-0xFF; larger values are skipped rather than masked.
- Multi-record 8-bit groups, mixed 8/16-bit groups, conditionals, master/enabler codes, and modifier placeholders are not emitted.
- SRM9 uses the same one-active-refresh-record model as SRMR.

Games represented by SRM8/SRM9:
$($srm8Games | ForEach-Object { "- $_" } | Out-String)
Skipped/unsupported 8-bit rows by reason:
$($skipped8ReasonCounts | Out-String)
Top 20 recommended single-record SRM9 cheats to test:
$($top20Srm9 | ForEach-Object { "- $($_.game): $($_.cheat_name) [$($_.address) = $($_.value)] -> $($_.output_file)" } | Out-String)
"@

$summary8 | Set-Content -LiteralPath $summary8Path -Encoding UTF8
foreach ($dir in @($srm8Dir, $srm9Dir)) {
    $summary8 | Set-Content -LiteralPath (Join-Path $dir "summary.txt") -Encoding UTF8
}

$srmgGames = @($manifestGroupRows | Where-Object { $_.mode -eq "SRMG" } | Select-Object -ExpandProperty game -Unique | Sort-Object)
$skippedGroupReasonCounts = $skippedGroupRows |
    Group-Object reason |
    Sort-Object @{ Expression = "Count"; Descending = $true }, Name |
    ForEach-Object { "- $($_.Count): $($_.Name)" }
$top20Srmg = $manifestGroupRows |
    Where-Object { $_.mode -eq "SRMG" -and $_.record_index -eq 1 } |
    Sort-Object @{ Expression = {
        $text = ($_.cheat_name + " " + $_.game).ToLowerInvariant()
        if ($text -match $recommendationWords) { 0 } else { 1 }
    }}, game, cheat_name |
    Select-Object -First 20

$summaryGroup = @"
SRMG parser-compatible grouped one-shot pack generation summary
Generated: $(Get-Date -Format s)

Input:
$supported16Path

Output folder:
$srmgDir

Report files:
$manifestGroupPath
$skippedGroupPath
$summaryGroupPath

Counts:
- SRMG candidate 2-4 record direct 16-bit groups: $srmgCandidateCheats
- SRMG files generated: $srmgFiles
- SRMG manifest records: $($manifestGroupRows.Count)
- Games represented by SRMG: $($srmgGames.Count)
- Groups skipped because record count exceeds 4: $srmgSkippedTooLarge
- SRMG skipped/unsupported rows reported: $($skippedGroupRows.Count)

Format:
- Header record: 0x00 magic "SRMG", 0x04 record_count 1..4, 0x08 reserved 0, 0x0C reserved 0
- Embedded direct records: 0x00 magic "SRMW", 0x04 reserved 0, 0x08 address, 0x0C 16-bit value in low half
- Generated files contain 2 to 4 direct records, so file sizes are 48, 64, or 80 bytes.
- All fields are big-endian.

Rules:
- One-shot only.
- Direct 16-bit RAMH writes only.
- Address range 0x06000000 through 0x060FFFFF.
- Even-aligned addresses only.
- Values must be <= 0xFFFF.
- Groups with more than 4 records are skipped.
- 8-bit, mixed-width, conditional, master/enabler, pointer/indirect, placeholder, malformed, 32-bit, and odd-aligned groups are skipped.

Games represented by SRMG:
$($srmgGames | ForEach-Object { "- $_" } | Out-String)
Skipped/unsupported SRMG rows by reason:
$($skippedGroupReasonCounts | Out-String)
Top 20 recommended SRMG cheats to test:
$($top20Srmg | ForEach-Object { "- $($_.game): $($_.cheat_name) [$($_.total_records) records] -> $($_.output_file)" } | Out-String)
"@

$summaryGroup | Set-Content -LiteralPath $summaryGroupPath -Encoding UTF8
$summaryGroup | Set-Content -LiteralPath (Join-Path $srmgDir "summary.txt") -Encoding UTF8

$allConvertedPath = Join-Path $OutputRoot "ALL_CHEATS_POC_CONVERTED_20260613.csv"
$allSkippedPath = Join-Path $OutputRoot "ALL_CHEATS_POC_SKIPPED_20260613.csv"
$allSummaryPath = Join-Path $OutputRoot "ALL_CHEATS_POC_SUMMARY_20260613.txt"

$allConvertedRows = [System.Collections.Generic.List[object]]::new()
foreach ($row in $manifestRows) {
    $allConvertedRows.Add([pscustomobject]@{
        format        = $row.mode
        game          = $row.game
        cheat_name    = $row.cheat_name
        source_file   = $row.source_file
        source_code   = $row.source_code
        output_file   = $row.output_file
        address       = $row.address
        value         = $row.value
        record_index  = $row.record_index
        total_records = $row.total_records
        notes         = $row.notes
    })
}
foreach ($row in $manifest8Rows) {
    $allConvertedRows.Add([pscustomobject]@{
        format        = $row.mode
        game          = $row.game
        cheat_name    = $row.cheat_name
        source_file   = $row.source_file
        source_code   = $row.source_code
        output_file   = $row.output_file
        address       = $row.address
        value         = $row.value
        record_index  = $row.record_index
        total_records = $row.total_records
        notes         = $row.notes
    })
}
foreach ($row in $manifestGroupRows) {
    $allConvertedRows.Add([pscustomobject]@{
        format        = $row.mode
        game          = $row.game
        cheat_name    = $row.cheat_name
        source_file   = $row.source_file
        source_code   = $row.source_code
        output_file   = $row.output_file
        address       = $row.address
        value         = $row.value
        record_index  = $row.record_index
        total_records = $row.total_records
        notes         = $row.notes
    })
}

$allSkippedRows = [System.Collections.Generic.List[object]]::new()
foreach ($row in $skippedRows) {
    $allSkippedRows.Add([pscustomobject]@{
        scope              = "SRMW_SRMR_manual"
        source_file        = $row.source_file
        cheat_index        = $row.cheat_index
        cheat_name         = $row.cheat_name
        source_code        = $row.source_code
        source_class       = $row.classification
        reason             = $row.reason
    })
}
foreach ($row in $skipped8Rows) {
    $allSkippedRows.Add([pscustomobject]@{
        scope              = "SRM8_SRM9"
        source_file        = $row.source_file
        cheat_index        = $row.cheat_index
        cheat_name         = $row.cheat_name
        source_code        = $row.source_code
        source_class       = $row.classification
        reason             = $row.reason
    })
}
foreach ($row in $skippedGroupRows) {
    $allSkippedRows.Add([pscustomobject]@{
        scope              = "SRMG"
        source_file        = $row.source_file
        cheat_index        = $row.cheat_index
        cheat_name         = $row.cheat_name
        source_code        = $row.source_code
        source_class       = $row.classification
        reason             = $row.reason
    })
}

$allConvertedRows | Export-Csv -LiteralPath $allConvertedPath -NoTypeInformation
$allSkippedRows | Export-Csv -LiteralPath $allSkippedPath -NoTypeInformation

$convertedCountsByFormat = $allConvertedRows |
    Group-Object format |
    Sort-Object Name |
    ForEach-Object { "- $($_.Name): $($_.Count)" }
$skippedCountsByReason = $allSkippedRows |
    Group-Object reason |
    Sort-Object @{ Expression = "Count"; Descending = $true }, Name |
    Select-Object -First 40 |
    ForEach-Object { "- $($_.Count): $($_.Name)" }
$gamesByFormat = $allConvertedRows |
    Where-Object { $_.format -ne "manual_part" -and $_.game -ne "Global" } |
    Group-Object format |
    Sort-Object Name |
    ForEach-Object {
        $gameCount = @($_.Group | Select-Object -ExpandProperty game -Unique).Count
        "- $($_.Name): $gameCount games"
    }

$allSummary = @"
All-cheats POC converter summary
Generated: $(Get-Date -Format s)

Classification input:
$ClassificationDir

Implemented active formats:
- SRMW: direct 16-bit one-shot
- SRMR: direct 16-bit 60-frame refresh
- SRM8: direct 8-bit one-shot
- SRM9: direct 8-bit 60-frame refresh
- SRMG: grouped direct 16-bit one-shot, 1..4 records in parser, generated groups are 2..4 records
- SRMC: clear active refresh state; generated in SRMR folder only

Deferred formats:
- SRGA grouped 8-bit: deferred; current refresh model supports one active byte record and no 8-bit group executor.
- SRMX mixed-width groups: deferred; no mixed group record-width dispatch in this build.
- SR32/SR3R 32-bit writes: deferred; no confirmed source-prefix mapping and no RTL format in this build.
- Conditionals: deferred; no runtime read/compare/apply-next engine.
- Master/enabler runtime: deferred; opcode behavior is not implemented.
- Unknown prefixes: report only.

Converted counts by format:
$($convertedCountsByFormat | Out-String)
Games represented by active format:
$($gamesByFormat | Out-String)
Skipped/reported rows by top reason:
$($skippedCountsByReason | Out-String)
Output reports:
- $allConvertedPath
- $allSkippedPath
- $allSummaryPath
"@
$allSummary | Set-Content -LiteralPath $allSummaryPath -Encoding UTF8

$masterGroupMcDir = Join-Path $OutputRoot "generated_master_group_mc_included_pack"
$masterGroupSubDir = Join-Path $OutputRoot "generated_master_group_sub_only_pack"
$masterVariantManifestPath = Join-Path $OutputRoot "MASTER_GROUP_VARIANTS_MANIFEST_20260613.csv"
$masterVariantSkippedPath = Join-Path $OutputRoot "MASTER_GROUP_VARIANTS_SKIPPED_20260613.csv"
$masterVariantSummaryPath = Join-Path $OutputRoot "MASTER_GROUP_VARIANTS_SUMMARY_20260613.txt"
$masterVariantNotesPath = Join-Path $OutputRoot "MASTER_GROUP_VARIANTS_NOTES_20260613.md"

foreach ($dir in @($masterGroupMcDir, $masterGroupSubDir)) {
    if (Test-Path -LiteralPath $dir) {
        Get-ChildItem -LiteralPath $dir -Force | Remove-Item -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

function Get-VariantGameName {
    param([string]$SourceFile)

    $leaf = [IO.Path]::GetFileNameWithoutExtension($SourceFile)
    $leaf = $leaf -replace "\(GameShark\)", ""
    $leaf = $leaf -replace "\(Action Replay\)", ""
    $leaf = $leaf -replace "\(RetroArch\)", ""
    $leaf = $leaf -replace "\(GameHacking\)", ""
    return (ConvertTo-SafeName $leaf)
}

function Get-VariantOutputDirectory {
    param(
        [string]$Root,
        [string]$Game
    )

    $trimmed = $Game.Trim()
    $letter = "0-9"
    if ($trimmed -match "^[A-Za-z]") {
        $letter = $trimmed.Substring(0, 1).ToUpperInvariant()
    }
    $dir = Join-Path (Join-Path $Root $letter) (ConvertTo-SafeName $Game)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    return $dir
}

function Test-MasterVariantRowIsMaster {
    param([object]$Row)

    if ($Row.reason -like "*master_enable*") { return $true }
    if ($Row.description -match "(?i)^(master code|\(m\))") { return $true }
    return $false
}

function ConvertTo-MasterVariantRecords {
    param(
        [object]$Row,
        [string]$Kind,
        [bool]$RequireConfirmedDirectOpcode
    )

    $records = @($Row.normalized_records -split ";" | Where-Object { $_ })
    $addresses = @($Row.ramh_addresses -split ";" | Where-Object { $_ })
    $values = @($Row.values -split ";" | Where-Object { $_ })
    $recordCount = 0
    if ($Row.record_count -match "^\d+$") { $recordCount = [int]$Row.record_count }

    if ($recordCount -lt 1 -or $records.Count -ne $recordCount -or $addresses.Count -ne $recordCount -or $values.Count -ne $recordCount) {
        return [pscustomobject]@{
            valid = $false
            reason = "normalized record/address/value count mismatch"
            records = @()
        }
    }

    $outRecords = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $recordCount; $i++) {
        $recordText = [string]$records[$i]
        $codeToken = ($recordText -split "\+")[0]
        if ($codeToken.Length -lt 2) {
            return [pscustomobject]@{
                valid = $false
                reason = "malformed opcode token in record: $recordText"
                records = @()
            }
        }

        $prefix = $codeToken.Substring(0, 2).ToUpperInvariant()
        $width = 0
        if ($Kind -eq "supported_16bit") {
            $width = 16
        }
        elseif ($Kind -eq "supported_8bit") {
            $width = 8
        }
        elseif ($RequireConfirmedDirectOpcode) {
            if ($prefix -eq "16") {
                $width = 16
            }
            elseif ($prefix -eq "36") {
                $width = 8
            }
            else {
                return [pscustomobject]@{
                    valid = $false
                    reason = "master/enabler opcode prefix $prefix is not confirmed as a direct write"
                    records = @()
                }
            }
        }
        else {
            return [pscustomobject]@{
                valid = $false
                reason = "unsupported row is not a confirmed direct write"
                records = @()
            }
        }

        $addr = [Convert]::ToUInt32(($addresses[$i] -replace "^0x", ""), 16)
        $value = [Convert]::ToUInt32(($values[$i] -replace "^0x", ""), 16)
        if ($width -eq 16) {
            if (!(Test-ValidRamh16 $addr) -or $value -gt 0xFFFF) {
                return [pscustomobject]@{
                    valid = $false
                    reason = "16-bit direct write failed RAMH/alignment/value validation"
                    records = @()
                }
            }
        }
        elseif ($width -eq 8) {
            if (!(Test-ValidRamh8 $addr) -or $value -gt 0xFF) {
                return [pscustomobject]@{
                    valid = $false
                    reason = "8-bit direct write failed RAMH/value validation"
                    records = @()
                }
            }
        }

        $outRecords.Add([pscustomobject]@{
            width = $width
            address = $addr
            value = $value
            source_record = $recordText
        })
    }

    return [pscustomobject]@{
        valid = $true
        reason = ""
        records = @($outRecords)
    }
}

function Add-MasterVariantManifestRow {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [string]$VariantType,
        [string]$SourceFile,
        [string]$GameName,
        [string]$OriginalCheatName,
        [string]$GeneratedCheatName,
        [string]$OutputPath,
        [string]$Format,
        [int]$RecordCount,
        [string]$OriginalMasterLines,
        [string]$OriginalSubLines,
        [string]$ConvertedLines,
        [string]$DroppedLines,
        [string]$Notes
    )

    $Rows.Add([pscustomobject]@{
        variant_type          = $VariantType
        source_file           = $SourceFile
        game_name             = $GameName
        original_cheat_name   = $OriginalCheatName
        generated_cheat_name  = $GeneratedCheatName
        output_path           = $OutputPath
        format                = $Format
        record_count          = $RecordCount
        original_master_lines = $OriginalMasterLines
        original_sub_lines    = $OriginalSubLines
        converted_lines       = $ConvertedLines
        dropped_lines         = $DroppedLines
        notes                 = $Notes
    })
}

function Add-MasterVariantSkippedRow {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [string]$SourceFile,
        [string]$GameName,
        [string]$CheatName,
        [string]$SkipVariantType,
        [string]$Reason,
        [string]$OriginalCodeLines,
        [string]$Notes
    )

    $Rows.Add([pscustomobject]@{
        source_file         = $SourceFile
        game_name           = $GameName
        cheat_name          = $CheatName
        skip_variant_type   = $SkipVariantType
        reason              = $Reason
        original_code_lines = $OriginalCodeLines
        notes               = $Notes
    })
}

function Write-MasterVariantFiles {
    param(
        [System.Collections.Generic.List[object]]$ManifestRows,
        [System.Collections.Generic.List[object]]$SkippedRows,
        [string]$Root,
        [string]$VariantType,
        [object]$MasterRow,
        [object]$SubRow,
        [object[]]$Records,
        [string]$GeneratedCheatName,
        [string]$DroppedLines,
        [string]$Notes
    )

    $game = Get-VariantGameName $SubRow.source_file
    $dir = Get-VariantOutputDirectory $Root $game
    $widths = @($Records | Select-Object -ExpandProperty width -Unique)
    $convertedLines = (@($Records | ForEach-Object { $_.source_record }) -join ";")
    $addresses = @($Records | ForEach-Object { [uint32]$_.address })
    $values = @($Records | ForEach-Object { [uint32]$_.value })
    $recordCount = $Records.Count

    if ($widths.Count -ne 1) {
        Add-MasterVariantSkippedRow $SkippedRows $SubRow.source_file $game $SubRow.description $VariantType "mixed-width group unsupported by current core" (($MasterRow.original_code, $SubRow.original_code) -join ";") $Notes
        return 0
    }

    $generated = 0
    if ($widths[0] -eq 16) {
        if ($recordCount -eq 1) {
            $addrText = "0x{0:X8}" -f $addresses[0]
            $valueText = "0x{0:X4}" -f $values[0]
            $base = ConvertTo-SafeName ("{0} - {1} - {2}" -f $game, $GeneratedCheatName, $addrText)

            foreach ($format in @("SRMW", "SRMR")) {
                $path = Get-UniquePath $dir ($base + " - " + $format)
                Write-Cheat16File $path $format $addresses[0] $values[0]
                $size = (Get-Item -LiteralPath $path).Length
                if ($size -ne 16) { throw "Master variant size validation failed for $path" }
                Add-MasterVariantManifestRow $ManifestRows $VariantType $SubRow.source_file $game $SubRow.description $GeneratedCheatName $path $format 1 $MasterRow.original_code $SubRow.original_code $convertedLines $DroppedLines "single direct 16-bit $format variant; $Notes; value $valueText"
                $generated++
            }
        }
        elseif ($recordCount -ge 2 -and $recordCount -le 4) {
            $baseAddresses = @($addresses | ForEach-Object { "0x{0:X8}" -f $_ }) -join "_"
            $base = ConvertTo-SafeName ("{0} - {1} - {2} records - {3}" -f $game, $GeneratedCheatName, $recordCount, $baseAddresses)
            $path = Get-UniquePath $dir ($base + " - SRMG")
            Write-SrmgFile $path ([uint32[]]$addresses) ([uint32[]]$values)
            $size = (Get-Item -LiteralPath $path).Length
            if ($size -notin 32, 48, 64, 80) { throw "Master variant grouped size validation failed for $path" }
            Add-MasterVariantManifestRow $ManifestRows $VariantType $SubRow.source_file $game $SubRow.description $GeneratedCheatName $path "SRMG" $recordCount $MasterRow.original_code $SubRow.original_code $convertedLines $DroppedLines "grouped direct 16-bit SRMG variant; file size $size bytes; $Notes"
            $generated++
        }
        else {
            Add-MasterVariantSkippedRow $SkippedRows $SubRow.source_file $game $SubRow.description $VariantType "group exceeds max 4" (($MasterRow.original_code, $SubRow.original_code) -join ";") $Notes
        }
    }
    elseif ($widths[0] -eq 8) {
        if ($recordCount -eq 1) {
            $addrText = "0x{0:X8}" -f $addresses[0]
            $valueText = "0x{0:X2}" -f $values[0]
            $base = ConvertTo-SafeName ("{0} - {1} - {2}" -f $game, $GeneratedCheatName, $addrText)

            foreach ($format in @("SRM8", "SRM9")) {
                $path = Get-UniquePath $dir ($base + " - " + $format)
                Write-Cheat8File $path $format $addresses[0] $values[0]
                $size = (Get-Item -LiteralPath $path).Length
                if ($size -ne 16) { throw "Master variant size validation failed for $path" }
                Add-MasterVariantManifestRow $ManifestRows $VariantType $SubRow.source_file $game $SubRow.description $GeneratedCheatName $path $format 1 $MasterRow.original_code $SubRow.original_code $convertedLines $DroppedLines "single direct 8-bit $format variant; $Notes; value $valueText"
                $generated++
            }
        }
        else {
            Add-MasterVariantSkippedRow $SkippedRows $SubRow.source_file $game $SubRow.description $VariantType "grouped 8-bit variants unsupported by current core" (($MasterRow.original_code, $SubRow.original_code) -join ";") $Notes
        }
    }
    else {
        Add-MasterVariantSkippedRow $SkippedRows $SubRow.source_file $game $SubRow.description $VariantType "unsupported record width" (($MasterRow.original_code, $SubRow.original_code) -join ";") $Notes
    }

    return $generated
}

$masterVariantManifestRows = [System.Collections.Generic.List[object]]::new()
$masterVariantSkippedRows = [System.Collections.Generic.List[object]]::new()

$classifiedRows = [System.Collections.Generic.List[object]]::new()
foreach ($row in $supported16) {
    $classifiedRows.Add([pscustomobject]@{
        source_file = $row.source_file
        cheat_index = [int]$row.cheat_index
        description = $row.description
        original_code = $row.original_code
        classification = $row.classification
        reason = $row.reason
        record_count = $row.record_count
        normalized_records = $row.normalized_records
        ramh_addresses = $row.ramh_addresses
        values = $row.values
        variant_kind = "supported_16bit"
    })
}
foreach ($row in $supported8) {
    $classifiedRows.Add([pscustomobject]@{
        source_file = $row.source_file
        cheat_index = [int]$row.cheat_index
        description = $row.description
        original_code = $row.original_code
        classification = $row.classification
        reason = $row.reason
        record_count = $row.record_count
        normalized_records = $row.normalized_records
        ramh_addresses = $row.ramh_addresses
        values = $row.values
        variant_kind = "supported_8bit"
    })
}
if (Test-Path -LiteralPath $unsupportedPath) {
    foreach ($row in (Import-Csv -LiteralPath $unsupportedPath)) {
        $idx = 0
        if ($row.cheat_index -match "^\d+$") { $idx = [int]$row.cheat_index }
        $classifiedRows.Add([pscustomobject]@{
            source_file = $row.source_file
            cheat_index = $idx
            description = $row.description
            original_code = $row.original_code
            classification = $row.classification
            reason = $row.reason
            record_count = $row.record_count
            normalized_records = $row.normalized_records
            ramh_addresses = $row.ramh_addresses
            values = $row.values
            variant_kind = "unsupported"
        })
    }
}
if (Test-Path -LiteralPath $manualPath) {
    foreach ($row in (Import-Csv -LiteralPath $manualPath)) {
        $idx = 0
        if ($row.cheat_index -match "^\d+$") { $idx = [int]$row.cheat_index }
        $classifiedRows.Add([pscustomobject]@{
            source_file = $row.source_file
            cheat_index = $idx
            description = $row.description
            original_code = $row.original_code
            classification = $row.classification
            reason = $row.reason
            record_count = $row.record_count
            normalized_records = $row.normalized_records
            ramh_addresses = $row.ramh_addresses
            values = $row.values
            variant_kind = "manual_review"
        })
    }
}

$sourceGroups = $classifiedRows | Group-Object source_file
foreach ($sourceGroup in $sourceGroups) {
    $rows = @($sourceGroup.Group | Sort-Object cheat_index)
    $masterRows = @($rows | Where-Object { Test-MasterVariantRowIsMaster $_ } | Sort-Object cheat_index)
    if ($masterRows.Count -eq 0) { continue }

    for ($m = 0; $m -lt $masterRows.Count; $m++) {
        $masterRow = $masterRows[$m]
        $nextMasterIndex = [int]::MaxValue
        if ($m + 1 -lt $masterRows.Count) { $nextMasterIndex = [int]$masterRows[$m + 1].cheat_index }
        $subRows = @($rows | Where-Object {
            ([int]$_.cheat_index -gt [int]$masterRow.cheat_index) -and
            ([int]$_.cheat_index -lt $nextMasterIndex) -and
            !(Test-MasterVariantRowIsMaster $_)
        } | Sort-Object cheat_index)

        if ($subRows.Count -eq 0) {
            $gameName = Get-VariantGameName $masterRow.source_file
            Add-MasterVariantSkippedRow $masterVariantSkippedRows $masterRow.source_file $gameName $masterRow.description "SUB_ONLY" "no following sub-code lines after master/enabler row" $masterRow.original_code "No variant generated."
            Add-MasterVariantSkippedRow $masterVariantSkippedRows $masterRow.source_file $gameName $masterRow.description "MC_INCLUDED" "no following sub-code lines after master/enabler row" $masterRow.original_code "No variant generated."
            continue
        }

        $masterRecords = ConvertTo-MasterVariantRecords $masterRow $masterRow.variant_kind $true
        foreach ($subRow in $subRows) {
            $gameName = Get-VariantGameName $subRow.source_file
            if ($subRow.variant_kind -ne "supported_16bit" -and $subRow.variant_kind -ne "supported_8bit") {
                $reason = "sub-code row is not fully supported direct write: $($subRow.reason)"
                Add-MasterVariantSkippedRow $masterVariantSkippedRows $subRow.source_file $gameName $subRow.description "SUB_ONLY" $reason $subRow.original_code "Master row $($masterRow.cheat_index): $($masterRow.original_code)"
                Add-MasterVariantSkippedRow $masterVariantSkippedRows $subRow.source_file $gameName $subRow.description "MC_INCLUDED" $reason (($masterRow.original_code, $subRow.original_code) -join ";") "Master row $($masterRow.cheat_index): $($masterRow.description)"
                continue
            }

            $subRecords = ConvertTo-MasterVariantRecords $subRow $subRow.variant_kind $false
            if (!$subRecords.valid) {
                Add-MasterVariantSkippedRow $masterVariantSkippedRows $subRow.source_file $gameName $subRow.description "SUB_ONLY" $subRecords.reason $subRow.original_code "Master row $($masterRow.cheat_index): $($masterRow.original_code)"
                Add-MasterVariantSkippedRow $masterVariantSkippedRows $subRow.source_file $gameName $subRow.description "MC_INCLUDED" $subRecords.reason (($masterRow.original_code, $subRow.original_code) -join ";") "Master row $($masterRow.cheat_index): $($masterRow.description)"
                continue
            }

            $subGeneratedName = "SUB - " + $subRow.description
            [void](Write-MasterVariantFiles $masterVariantManifestRows $masterVariantSkippedRows $masterGroupSubDir "SUB_ONLY" $masterRow $subRow ([object[]]$subRecords.records) $subGeneratedName $masterRow.original_code "master/enabler line dropped for sub-only test")

            if (!$masterRecords.valid) {
                Add-MasterVariantSkippedRow $masterVariantSkippedRows $subRow.source_file $gameName $subRow.description "MC_INCLUDED" $masterRecords.reason (($masterRow.original_code, $subRow.original_code) -join ";") "MC-included variants require the master/enabler line to use a confirmed direct write opcode."
                continue
            }

            $combinedRecords = @()
            $combinedRecords += @($masterRecords.records)
            $combinedRecords += @($subRecords.records)
            $mcGeneratedName = "MC - " + $subRow.description
            [void](Write-MasterVariantFiles $masterVariantManifestRows $masterVariantSkippedRows $masterGroupMcDir "MC_INCLUDED" $masterRow $subRow ([object[]]$combinedRecords) $mcGeneratedName "" "test-only master/enabler included variant")
        }
    }
}

$masterVariantManifestRows | Export-Csv -LiteralPath $masterVariantManifestPath -NoTypeInformation
$masterVariantSkippedRows | Export-Csv -LiteralPath $masterVariantSkippedPath -NoTypeInformation

$mcFiles = @($masterVariantManifestRows | Where-Object { $_.variant_type -eq "MC_INCLUDED" } | Select-Object -ExpandProperty output_path -Unique)
$subFiles = @($masterVariantManifestRows | Where-Object { $_.variant_type -eq "SUB_ONLY" } | Select-Object -ExpandProperty output_path -Unique)
$masterVariantGames = @($masterVariantManifestRows | Select-Object -ExpandProperty game_name -Unique | Sort-Object)
$masterVariantRecords = ($masterVariantManifestRows | Measure-Object record_count -Sum).Sum
if ($null -eq $masterVariantRecords) { $masterVariantRecords = 0 }
$masterVariantAllFiles = @()
foreach ($dir in @($masterGroupMcDir, $masterGroupSubDir)) {
    $masterVariantAllFiles += @(Get-ChildItem -LiteralPath $dir -Recurse -File -Filter *.CHT -ErrorAction SilentlyContinue)
}
$masterVariantBadSize = @($masterVariantAllFiles | Where-Object {
    if ($_.Name -match "SRMG") { $_.Length -notin 32, 48, 64, 80 } else { $_.Length -ne 16 }
}).Count
$masterVariantSkippedCounts = $masterVariantSkippedRows |
    Group-Object reason |
    Sort-Object @{ Expression = "Count"; Descending = $true }, Name |
    ForEach-Object { "- $($_.Count): $($_.Name)" }
$masterVariantExamples = @()
$pairCandidates = $masterVariantManifestRows |
    Group-Object source_file, original_cheat_name |
    Where-Object {
        @($_.Group | Where-Object { $_.variant_type -eq "MC_INCLUDED" }).Count -gt 0 -and
        @($_.Group | Where-Object { $_.variant_type -eq "SUB_ONLY" }).Count -gt 0
    } |
    Select-Object -First 10
foreach ($pair in $pairCandidates) {
    $sub = @($pair.Group | Where-Object { $_.variant_type -eq "SUB_ONLY" } | Select-Object -First 1)[0]
    $mc = @($pair.Group | Where-Object { $_.variant_type -eq "MC_INCLUDED" } | Select-Object -First 1)[0]
    $masterVariantExamples += "- $($sub.game_name): $($sub.original_cheat_name) -> SUB $($sub.format), MC $($mc.format)"
}
if ($masterVariantExamples.Count -eq 0) {
    $masterVariantExamples += "- No MC/SUB pairs generated. MC-included variants were skipped where master/enabler opcodes were not confirmed direct writes."
}

$masterVariantSummary = @"
Master/enabler grouped variant generation summary
Generated: $(Get-Date -Format s)

Input classification:
$ClassificationDir

Output folders:
$masterGroupMcDir
$masterGroupSubDir

Report files:
$masterVariantManifestPath
$masterVariantSkippedPath
$masterVariantSummaryPath
$masterVariantNotesPath

Counts:
- MC-included files generated: $($mcFiles.Count)
- Sub-only files generated: $($subFiles.Count)
- Games represented: $($masterVariantGames.Count)
- Records generated: $masterVariantRecords
- Bad-size files: $masterVariantBadSize
- Skipped rows reported: $($masterVariantSkippedRows.Count)

Skipped counts by reason:
$($masterVariantSkippedCounts | Out-String)
Examples of MC/SUB pairs:
$($masterVariantExamples | Out-String)
Notes:
- MC-included variants are test-only.
- Unknown master/enabler behavior is still not broadly supported.
- Master/enabler lines with unconfirmed F6/B6-style opcodes are not converted into MC-included variants.
- Sub-only variants intentionally drop the nearest preceding master/enabler row and convert only supported direct sub-code rows.
"@

$masterVariantSummary | Set-Content -LiteralPath $masterVariantSummaryPath -Encoding UTF8

$masterVariantNotes = @"
# Master/Enabler Grouped Variant Experiment - 20260613

This experiment generates local-only cheat variants for source files that have a master/enabler row followed by direct sub-code cheat rows.

Two variants are produced when safe:

- `SUB - ...`: drops the nearest preceding master/enabler row and converts only the supported direct sub-code records.
- `MC - ...`: includes the master/enabler row first, but only if that row uses a confirmed direct write opcode that the current experimental core can represent safely.

The goal is to test whether original Action Replay/GameShark master/enabler rows were required for MiSTer, or whether the direct sub-code writes work without them.

## How To Test

1. Try the `SUB - ...` variant first.
2. If the `SUB - ...` variant fails, try the matching `MC - ...` variant if one was generated.
3. Report whether either variant worked, and whether the MC-included version behaved differently.

## Caution

MC-included variants are experimental and test-only. A master/enabler row may patch RAM or code, and unknown master/enabler behavior is not implemented broadly.

The current experimental core still only supports:

- Direct 16-bit one-shot writes with `SRMW`.
- Direct 16-bit refresh writes with `SRMR`.
- Direct 8-bit one-shot writes with `SRM8`.
- Direct 8-bit refresh writes with `SRM9`.
- Grouped direct 16-bit one-shot writes with `SRMG`, max 4 records.
- `SRMC` clear refresh.

Not supported here:

- Grouped 8-bit writes.
- Mixed-width grouped writes.
- 32-bit writes.
- Conditionals.
- Master/enabler runtime logic.
- Unknown prefixes.

Master/enabler rows using unconfirmed opcodes, including F6/B6-style master codes, are skipped for MC-included output rather than guessed.
"@

$masterVariantNotes | Set-Content -LiteralPath $masterVariantNotesPath -Encoding UTF8

[pscustomobject]@{
    single_record_16bit_cheats_converted = $singleRecordCheats
    srmw_files = $srmwFiles
    srmr_files = $srmrFiles
    multi_record_cheats_split = $multiRecordCheats
    manual_part_files = $manualPartFiles
    srmg_candidate_groups = $srmgCandidateCheats
    srmg_files = $srmgFiles
    srmg_games = $srmgGames.Count
    srmg_groups_skipped_too_large = $srmgSkippedTooLarge
    total_simple_8bit_source_rows = $total8Rows
    single_record_8bit_cheats_converted = $singleRecord8Cheats
    srm8_files = $srm8Files
    srm9_files = $srm9Files
    multi_record_8bit_cheats_skipped = $multiRecord8Cheats
    skipped_or_unsupported_rows = $skippedRows.Count
    skipped_or_unsupported_8bit_rows = $skipped8Rows.Count
    skipped_or_unsupported_srmg_rows = $skippedGroupRows.Count
    manifest = $manifestPath
    manifest_8bit = $manifest8Path
    manifest_srmg = $manifestGroupPath
    summary = $summaryPath
    summary_8bit = $summary8Path
    summary_srmg = $summaryGroupPath
    summary_all_cheats = $allSummaryPath
    unsupported_or_skipped = $skippedPath
    unsupported_or_skipped_8bit = $skipped8Path
    unsupported_or_skipped_srmg = $skippedGroupPath
    all_cheats_converted = $allConvertedPath
    all_cheats_skipped = $allSkippedPath
    master_group_mc_included_files = $mcFiles.Count
    master_group_sub_only_files = $subFiles.Count
    master_group_bad_size_files = $masterVariantBadSize
    master_group_manifest = $masterVariantManifestPath
    master_group_skipped = $masterVariantSkippedPath
    master_group_summary = $masterVariantSummaryPath
    master_group_notes = $masterVariantNotesPath
}
