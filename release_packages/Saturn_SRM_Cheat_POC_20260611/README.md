# MiSTer Saturn SRMW/SRMR/SRMC Cheat Proof-of-Concept Package

This package is a MiSTer Sega Saturn SRMW/SRMR/SRMC cheat proof-of-concept release. It contains a tested experimental Saturn RBF plus the expanded clean generated compatible cheat library in an A-Z/game-folder layout.

This proof RBF was built and tested for HDMI output. It is not intended to represent a full-feature replacement for the official MiSTer Saturn core. Some optional video/output features were stripped or may be disabled/untested to make room for the cheat proof-of-concept and improve timing closure.

Use the official MiSTer Saturn release for normal everyday play or for features outside this proof package. The test environment was HDMI-focused; analog, composite, and YC paths should be considered disabled or untested for this proof package.

## Install Paths

Copy these files and folders to your MiSTer SD card:

- Copy `_Console/TEST_SRMR_REFRESH60_RAMH_CLEANUP_Saturn_20260611.rbf` to `/media/fat/_Console/`
- Copy `games/Saturn/Cheats_Trigger` to `/media/fat/games/Saturn/`
- Copy `games/Saturn/Cheats_60Frames` to `/media/fat/games/Saturn/`
- Copy `games/Saturn/SRMC_Clear_Refresh.CHT` to `/media/fat/games/Saturn/`

## Cheat Library Contents

- Full clean compatible active/generated SRMW one-shot files: 1120.
- Full clean compatible active/generated SRMR normal refresh files: 1120.
- Manual multi-record split/reference files: 597 in `manual_multirecord_parts`.
- The active MiSTer install was deduped from the prior additive install and now matches the full generated compatible set: 1120 SRMW and 1120 SRMR.
- Princess Crown and Saturn Bomberman were added and user-tested successfully.

## Folder Meanings

- `Cheats_Trigger`: SRMW one-shot trigger cheats.
- `Cheats_60Frames`: SRMR retained refresh cheats applied every 60 vblanks.
- `SRMC_Clear_Refresh.CHT`: clears/stops the currently active SRMR refresh cheat.
- `manual_multirecord_parts`: offline/reference-only split records for compatible multi-record source cheats. These are not true grouped active cheats and are not copied to the active normal folders.
- `reports`: conversion, skipped-code, dedupe, and active-copy reports for this expanded package update.

## How To Use

1. Try a cheat from `Cheats_Trigger` first.
2. If the value drains, resets, or is quickly overwritten by the game, try the matching cheat from `Cheats_60Frames`.
3. If a `Cheats_60Frames` refresh cheat causes instability, run `SRMC_Clear_Refresh.CHT` from the Saturn games folder to stop the active refresh slot.

## Why Only These Cheats Are Included

This package includes currently generated supported direct 16-bit write cheats only. These are codes the current SRMW/SRMR/SRMC engine can represent.

Unsupported normal active cheat types remain unsupported:

- 8-bit writes.
- 32-bit writes.
- Conditionals.
- Master/enabler codes.
- Odd-aligned writes.
- Out-of-range writes.
- True grouped multi-record cheats.

Manual multi-record split files are included only for reference/manual experimentation, not as true grouped active cheats.

## Limitations

Core/build limitations:

- HDMI-focused and HDMI-tested proof RBF.
- Analog, composite, and YC output paths are not validated for this proof package.
- Optional video/output extras may be disabled or untested.
- Use the official MiSTer Saturn release for normal everyday play or features outside this proof package.

Cheat limitations:

- No master/enabler support.
- No conditional code support.
- No unsupported prefix support.
- No 8-bit write support yet.
- No 32-bit write support yet.
- No true multi-record cheat group support.
- Only one active SRMR refresh record at a time.
- No hotkey retrigger of last SRMW cheat yet.

## Testing Status

The broad cheat pack has not been fully tested. Some cheats may do nothing, crash, behave incorrectly, or be unsafe as refresh cheats.

Hardware testing confirmed that the SRMW/SRMR/SRMC paths work in several tested cases with no noticeable input lag after controller mode was corrected. Princess Crown and Saturn Bomberman were added and user-tested successfully.

## Tested RBF Checksum

```text
SHA256 95CF0F8270CACBEEAEDE13F0534395483CD35DB8AA6C0C90D11384C9499322D6  _Console/TEST_SRMR_REFRESH60_RAMH_CLEANUP_Saturn_20260611.rbf
```

## Controller Lag Note

Earlier lag was traced to 8BitDo Bluetooth controller mode/RF path. XInput Bluetooth mode and USB wired testing showed no noticeable lag.
