# SRMR One-Record Refresh POC Hardware Test Report

Date: 2026-06-06
Branch: feature/cheat-support-poc

## Core Under Test

- RBF: TEST_SRMR_REFRESH_Saturn_20260606.rbf
- SHA256: BB73045D6F28301D77480518C3D297F7B5BF2C6387023C70EFAA8549BBAF8343
- Local build output: output_files/Saturn.rbf

## Build Result

Quartus Prime Standard 25.1 seed 9 completed full compilation successfully.

Timing was not closed, so this remains a risky experimental build:

- Setup slack: -0.576 ns
- Hold slack: -0.353 ns
- Recovery slack: +4.259 ns
- Removal slack: +1.080 ns

Utilization:

- ALMs: 40,462 / 41,910 (97%)
- RAM blocks: 543 / 553 (98%)
- Block memory bits: 4,010,393 / 5,662,720 (71%)
- DSP blocks: 57 / 112 (51%)

## Hardware Results

Passed:

- Base Saturn boots correctly in 4:3 after global video-mode correction.
- SRMR test core boots.
- OSD/controller responsive.
- Normal CHD boot works.
- Sonic R SRMW parser16 regression works.
- Alien Trilogy SRMR refresh works.

Functional conclusion:

- Guarded SRMW read-modify-write injector works for one-shot 16-bit RMW.
- Guarded SRMR refresh path works for one retained single-record 16-bit RMW refresh.

## Tested Games / Files

Sonic R:

- File: SRMW_Sonic_R_parser16.CHT
- Purpose: one-shot SRMW regression
- Result: PASS

Alien Trilogy:

- File: SRMR_Alien_Trilogy_Health_parser16.CHT
- Purpose: refreshed one-record 16-bit RMW health cheat
- Result: PASS

Normal CHD boot:

- Result: PASS

## Known Video-Mode Correction

The invalid format/fullscreen issue was caused by global MiSTer video settings, not the SRMR core.

Problem setting:

- video_mode=12 / 1920x1440

Correction:

- Set video_mode=8
- Set video_mode_ntsc=8
- Set video_mode_pal=8

Result:

- Standard 1080p output restored.
- Saturn 4:3 display restored.

## Safety Notes

- No ddram.sv changes.
- No sdram2.sv changes.
- RAMH read-to-MEM_DI remains direct.
- No read substitution/read overlay.
- No direct byte-enable injection.
- No patch_be plumbing.
- No ioctl_wait.
- v1 SCHT one-shot path preserved.
- SRMW one-shot parser16 path preserved.
- SRMR is one retained refresh record guarded by SATURN_CHEAT_RMW_REFRESH_POC.
- SRMC clears refresh_valid; one already-accepted RAM-domain request may still complete once.

## Recommendation Snapshot

The smallest next step toward practical cheat use should be converter tooling, not more RTL yet.

Update the PC-side converter to emit parser-compatible 16-byte SRMW/SRMR files:

- SRMW for one-shot test writes.
- SRMR for single-record constant/repeat cheats.
- Keep multi-record cheats flagged as unsupported or split into manual sequential files for now.

Two-record refresh support can wait until the converter proves enough single-record cheats are useful and the current timing risk is understood.
