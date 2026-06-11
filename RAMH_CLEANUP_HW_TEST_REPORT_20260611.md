# RAMH Cleanup Hardware Test Report - 20260611

## Build tested

RBF:
\\MiSTer\sdcard\_Console\TEST_SRMR_REFRESH60_RAMH_CLEANUP_Saturn_20260611.rbf

Local build:
C:\MiSTer-Work\Saturn_MiSTer-q25-chtloader-wrappercut-test\output_files\Saturn.rbf

SHA256:
95CF0F8270CACBEEAEDE13F0534395483CD35DB8AA6C0C90D11384C9499322D6

Size:
4,606,872 bytes

## Timing result

Before RAMH cleanup:

- Setup slack: -0.313
- Hold slack: -0.478
- ALMs: 41,025 / 41,910
- RAM blocks: 542 / 553

After RAMH cleanup:

- Setup slack: -0.156
- Hold slack: +0.147
- Recovery slack: +3.965
- Removal slack: +1.111
- ALMs: 41,018 / 41,910
- RAM blocks: 542 / 553
- Block memory bits: 4,004,249 / 5,662,720

Improvement:

- Setup improved by +0.157 ns
- Hold improved by +0.625 ns
- ALMs reduced by 7
- RAM blocks unchanged

## Hardware test environment notes

Controller lag was separately isolated to 8BitDo Bluetooth controller mode/RF path.

Validated no noticeable lag using:

- 8BitDo SN30 Pro in XInput Bluetooth mode
- USB wired controller

USB wired and Bluetooth XInput both behaved cleanly after controller mode testing.

## Hardware test results

### Stock/core lag investigation

The Saturn autoboot MGL was verified to launch the known stock base core:

- \\MiSTer\sdcard\_Console\Saturn_20251003.rbf
- SHA256: A78FC42B1890E4293E259DACFC871D906873A90013EAB5DCB22F6B48ADF11A37

Lag was reproduced outside the cheat build before controller mode was corrected, so the original lag concern was not caused by SRMW/SRMR/SRMC.

### RAMH cleanup build

Result:

- No noticeable controller lag over Bluetooth XInput
- No noticeable controller lag over USB wired
- Cheats worked with the RAMH cleanup build
- SRMW/SRMR/SRMC behavior preserved in hardware testing

### Games tested

Alien Trilogy:

- SRMR health: PASS
- SRMR bullets: PASS
- No noticeable lag in XInput Bluetooth mode

Mega Man X4:

- SRMR lives: PASS
- No noticeable lag in XInput Bluetooth mode

Die Hard Arcade:

- SRMR credits/effect: cheat effect worked
- Game later crashed
- Classification: PASS_EFFECT_THEN_CRASH_PROBABLY_CODE_SPECIFIC
- Current interpretation: likely unsafe/bad cheat code or refresh target, not a general core/engine failure

Contra / other core comparison:

- Bluetooth mode issue reproduced outside Saturn
- USB wired had no lag
- Supports conclusion that prior lag was Bluetooth/controller-mode related

## Classification

RAMH_CLEANUP_BUILD: PASS_PLAYABLE

SRMW/SRMR/SRMC_ENGINE: PASS

BLUETOOTH_XINPUT_MODE: PASS

DIE_HARD_ARCADE_SPECIFIC_CHEAT: PARTIAL_EFFECT_UNSAFE

## Conclusion

The RAMH cleanup is a successful timing and hardware validation step.

It improved setup and hold timing significantly while preserving SRMW/SRMR/SRMC behavior and cheat file formats.

This patch should be kept.
