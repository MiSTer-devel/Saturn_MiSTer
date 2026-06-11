# MiSTer Saturn SRMW/SRMR/SRMC Cheat Proof-of-Concept

## What this is

This is an experimental MiSTer Saturn cheat proof-of-concept. It adds parser-compatible Saturn SRMW/SRMR/SRMC cheat records and provides a tested RBF plus the full currently supported single-record cheat pack.

This is not an official MiSTer-devel release.

## What is included

Tested RBF:

`release_packages/Saturn_SRM_Cheat_POC_20260611/_Console/TEST_SRMR_REFRESH60_RAMH_CLEANUP_Saturn_20260611.rbf`

Cheat folders:

`release_packages/Saturn_SRM_Cheat_POC_20260611/games/Saturn/Cheats_Trigger`

`release_packages/Saturn_SRM_Cheat_POC_20260611/games/Saturn/Cheats_60Frames`

Clear file:

`release_packages/Saturn_SRM_Cheat_POC_20260611/games/Saturn/SRMC_Clear_Refresh.CHT`

The package also includes `README.md` and `MANIFEST_SHA256.txt`.

## Install layout

Copy the RBF to:

`/media/fat/_Console/`

Copy `Cheats_Trigger` to:

`/media/fat/games/Saturn/`

Copy `Cheats_60Frames` to:

`/media/fat/games/Saturn/`

Copy `SRMC_Clear_Refresh.CHT` to:

`/media/fat/games/Saturn/`

## How to use

`Cheats_Trigger` contains one-shot SRMW cheats.

`Cheats_60Frames` contains SRMR refresh cheats, applied every 60 vblanks.

`SRMC_Clear_Refresh.CHT` clears the currently active SRMR refresh cheat.

Try `Cheats_Trigger` first. If the value drains or resets, try the matching cheat from `Cheats_60Frames`. If a refresh cheat causes problems, run `SRMC_Clear_Refresh.CHT`.

## Why only these cheats are included

This package includes currently generated supported single-record cheats only. These are codes the current SRMW/SRMR/SRMC engine can represent.

Unsupported code types are intentionally not included.

## Limitations

- No master/enabler support.
- No conditional code support.
- No unsupported prefix support.
- No 8-bit write support yet.
- No true multi-record cheat group support.
- Only one active SRMR refresh record at a time.
- No hotkey retrigger of last SRMW cheat yet.
- This is proof-of-concept, not an official MiSTer-devel release.

## Testing status

The broad pack has not been fully tested. Some cheats may do nothing, crash, behave incorrectly, or be unsafe as refresh cheats.

Alien Trilogy and Mega Man X4 had successful tests. Die Hard Arcade showed cheat effect then crash and is currently believed to be code-specific or unsafe, not a general engine failure.

Earlier lag was traced to the 8BitDo Bluetooth mode/RF path. XInput Bluetooth mode and USB wired had no noticeable lag.

## Checksums

RBF SHA256:

`95CF0F8270CACBEEAEDE13F0534395483CD35DB8AA6C0C90D11384C9499322D6`

## Branch/source notes

- Branch: `feature/cheat-support-srmw-srmr`
- Package path: `release_packages/Saturn_SRM_Cheat_POC_20260611`
- Package commit: `f4bf121 Add Saturn SRM cheat proof package`
