# [Sega Saturn](https://en.wikipedia.org/wiki/Sega_Saturn) for MiSTer

## Hardware Requirements

- 128 MB SDRAM Module (Primary)
- SDRAM Module of any size (32MB-128MB) (Secondary)

> **Note:** Dual SDRAM modules is recommended for better compatibility.

## Status

The core has matured substantially, with many games tested over the course of development.

Known issues and limitations are tracked in this repository's issue list rather than in a game-by-game list here.

## Analog Video H-Pos / V-Pos

Analog Video H-Pos / V-Pos allow shifting the HSYNC and VSYNC pulses for the analog (VGA) output, so the picture can be centered on a CRT. Range is 0..16 and -15..-1 for each axis (positive shifts the sync later, negative shifts it earlier). These options affect the analog output only and have no effect on HDMI.

