[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot
)

$ErrorActionPreference = "Stop"

function Convert-HexValue {
    param([string]$Value)

    return [Convert]::ToUInt32(($Value.Trim() -replace "^0x", ""), 16)
}

function Write-Record {
    param(
        [string]$Path,
        [string]$Magic,
        [uint32]$Address,
        [uint32]$Value
    )

    if ($Magic.Length -ne 4) {
        throw "Magic must contain four ASCII characters: $Magic"
    }

    $magicBytes = [Text.Encoding]::ASCII.GetBytes($Magic)
    [byte[]]$bytes = @(
        $magicBytes[0], $magicBytes[1], $magicBytes[2], $magicBytes[3],
        0x00, 0x00, 0x00, 0x00,
        (($Address -shr 24) -band 0xFF),
        (($Address -shr 16) -band 0xFF),
        (($Address -shr 8) -band 0xFF),
        ($Address -band 0xFF),
        (($Value -shr 24) -band 0xFF),
        (($Value -shr 16) -band 0xFF),
        (($Value -shr 8) -band 0xFF),
        ($Value -band 0xFF)
    )
    [IO.File]::WriteAllBytes($Path, $bytes)
}

function Write-Group {
    param(
        [string]$Path,
        [uint32[]]$Addresses,
        [uint32[]]$Values
    )

    if ($Addresses.Count -ne $Values.Count) {
        throw "SRMG address/value count mismatch"
    }
    if ($Addresses.Count -lt 1 -or $Addresses.Count -gt 4) {
        throw "SRMG supports one to four records"
    }

    $bytes = [Collections.Generic.List[byte]]::new()
    foreach ($byte in [Text.Encoding]::ASCII.GetBytes("SRMG")) {
        $bytes.Add($byte)
    }

    $count = [uint32]$Addresses.Count
    foreach ($byte in @(
        (($count -shr 24) -band 0xFF),
        (($count -shr 16) -band 0xFF),
        (($count -shr 8) -band 0xFF),
        ($count -band 0xFF),
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
    )) {
        $bytes.Add([byte]$byte)
    }

    for ($index = 0; $index -lt $Addresses.Count; $index++) {
        $recordPath = [IO.Path]::GetTempFileName()
        try {
            Write-Record $recordPath "SRMW" $Addresses[$index] $Values[$index]
            foreach ($byte in [IO.File]::ReadAllBytes($recordPath)) {
                $bytes.Add($byte)
            }
        }
        finally {
            Remove-Item -LiteralPath $recordPath -Force -ErrorAction SilentlyContinue
        }
    }

    [IO.File]::WriteAllBytes($Path, $bytes.ToArray())
}

if (!(Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Manifest not found: $ManifestPath"
}

$rows = @(Import-Csv -LiteralPath $ManifestPath)
if (!$rows.Count) {
    throw "Manifest contains no rows: $ManifestPath"
}

foreach ($row in $rows) {
    if ($row.output_format -notin "SRMW", "SRMR", "SRMG") {
        throw "Unsupported output format: $($row.output_format)"
    }

    $sourceOutput = [IO.Path]::GetFullPath($row.output_path)
    $gameDirectory = Split-Path -Leaf (Split-Path -Parent $sourceOutput)
    $bucketDirectory = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $sourceOutput))
    $targetDirectory = Join-Path $OutputRoot (Join-Path $row.output_format (Join-Path $bucketDirectory $gameDirectory))
    New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
    $targetPath = Join-Path $targetDirectory ([IO.Path]::GetFileName($sourceOutput))

    if ($row.output_format -eq "SRMG") {
        [uint32[]]$addresses = @($row.inferred_address -split ";" | ForEach-Object { Convert-HexValue $_ })
        [uint32[]]$values = @($row.inferred_value -split ";" | ForEach-Object { Convert-HexValue $_ })
        Write-Group $targetPath $addresses $values
    }
    else {
        $address = Convert-HexValue $row.inferred_address
        $value = Convert-HexValue $row.inferred_value
        Write-Record $targetPath $row.output_format $address $value
    }
}

Write-Output "Generated $($rows.Count) opcode-06 test files under $OutputRoot"
