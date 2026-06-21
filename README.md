# [Sega Saturn](https://en.wikipedia.org/wiki/Sega_Saturn) for MiSTer

## Hardware Requirements

- 128 MB SDRAM Module (Primary)
- SDRAM Module of any size (32MB-128MB) (Secondary)

> **Note:** Dual SDRAM modules is recommended for better compatibility.

## Status

Current status is WIP/Beta

Known issues:


## Experimental Saturn SRM Cheat Package

The `release_packages/Saturn_SRM_Cheat_POC_20260611` package contains the HDMI-tested SRMW/SRMR/SRMC cheat proof RBF and the expanded clean compatible cheat library:

- 1120 normal SRMW one-shot cheats.
- 1120 normal SRMR 60-frame refresh cheats.
- 597 manual multi-record split files preserved offline/reference-only.
- The active MiSTer install was deduped from the prior additive install and now matches 1120 SRMW and 1120 SRMR.
- Princess Crown and Saturn Bomberman were added and user-tested successfully.

Only direct 16-bit writes are supported by the active cheat proof. Unsupported active cheat types remain unsupported: 8-bit writes, 32-bit writes, conditionals, master/enabler codes, odd-aligned writes, out-of-range writes, and true grouped multi-record cheats.

## Deferred / Unused Cheat Research

The remaining unsupported Saturn cheat pools are documented under
`docs/saturn_cheats_deferred/`. They are included for future implementation
research only and should not be copied directly into MiSTer as working cheats.
