# Saturn SRMR REFRESH60 Build Report - 20260610

## Purpose

Focused single-RAM experiment to reduce SRMR runtime refresh pressure.

The previous SRMR proof refreshed approximately every 8 vblanks. This build changes SRMR refresh to every 60 vblanks while preserving the same SRMW/SRMR/SRMC file formats.

## Changed behavior

- SRMW one-shot behavior unchanged.
- SRMR file format unchanged.
- SRMR still supports one active refresh record.
- SRMR refresh cadence changed from every 8 vblanks to every 60 vblanks.
- SRMC clear behavior unchanged.
- ddram.sv and sdram2.sv were not touched.
- Stock Saturn_20251003.rbf was not overwritten.

## Build result

Quartus full compilation successful.

- Errors: 0
- Warnings: 144
- Setup slack: -0.463
- Hold slack: -0.610
- Recovery slack: 2.855
- Removal slack: 0.976
- ALM usage: 41,071 / 41,910 (98%)
- RAM blocks: 543 / 553 (98%)
- Block memory bits: 4,010,393 / 5,662,720 (71%)

## RBF

- Local: output_files/Saturn.rbf
- MiSTer: \\MiSTer\sdcard\_Console\TEST_SRMR_REFRESH60_Saturn_20260610.rbf
- Size: 4,615,148 bytes
- SHA256: A243D4C926680526B7D1D1D2AB831D8096BA5F903435F02D99B4CFEFC5B03937

## Test focus

Compare against previous SRMR refresh build:

- Alien Trilogy health/bullets
- Mega Man X4 lives
- Die Hard Arcade credits
- Fighting Vipers timer
- Battle Arena Toshinden URA timer
- Castlevania health/hearts/magic/money
