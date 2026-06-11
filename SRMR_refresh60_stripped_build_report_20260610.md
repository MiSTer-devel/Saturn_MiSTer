# Saturn SRMR REFRESH60 Stripped Build Report - 20260610

## Purpose

Single-RAM REFRESH60 test build with one additional strip change to reduce timing/resource pressure.

## Strip change

Disabled Saturn video_mixer gamma correction through a new compile macro:

- Added MISTER_DISABLE_GAMMA=1
- video_mixer GAMMA parameter is now 0 when MISTER_DISABLE_GAMMA is defined

Existing disables remained enabled:

- MISTER_DISABLE_YC
- MISTER_DISABLE_ADAPTIVE
- MISTER_DISABLE_ALSA
- lightgun disabled
- Saturn mouse/keyboard disabled
- composite blend disabled
- shadowmask disabled

## Cheat behavior

Unchanged:

- SRMW one-shot behavior
- SRMR magic/file format
- SRMR one active refresh record
- SRMR 60-vblank refresh cadence
- SRMC clear behavior

ddram.sv and sdram2.sv were not touched.

## Build result

Quartus full compilation successful.

- Errors: 0
- Warnings: 144
- Setup slack: -0.313
- Hold slack: -0.478
- Recovery slack: 4.203
- Removal slack: 1.083
- ALM usage: 41,025 / 41,910 (98%)
- RAM blocks: 542 / 553 (98%)
- Block memory bits: 4,004,249 / 5,662,720 (71%)

## RBF

- Local: output_files/Saturn.rbf
- MiSTer: \\MiSTer\sdcard\_Console\TEST_SRMR_REFRESH60_STRIPPED_Saturn_20260610.rbf
- Size: 4,619,064 bytes
- SHA256: 699FC545652CCA747F8D9AEB024CF525383D8BA95BC972FDE7A9301E92BC7C7E

## Comparison vs REFRESH60

- Setup improved from -0.463 to -0.313
- Hold improved from -0.610 to -0.478
- Saved 46 ALMs
- Saved 1 RAM block

## Status

Still timing-negative, but improved. Next step is hardware comparison of OSD/gameplay lag against the non-stripped REFRESH60 build.
