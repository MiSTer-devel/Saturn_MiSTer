# ST-V Shienryu 180 Flip v1.1 Final

Experimental dual-SDRAM ST-V build for testing Shienryu with a 180-degree active-video flip.

## Files

- `stv_flip_v1.1_final.rbf`
- `stv_flip_v1.1_final.rbf.sha256`

This is the physically tested `stv_flip_v1.1_rc1` build promoted to final. The RBF content is unchanged.

## Purpose

Adds an ST-V OSD option:

`Shienryu 180 Flip = Off/On`

Default is `Off`. With the option off, normal ST-V behavior is preserved. With the option on, the late scaler/ascal video path flips the active game image horizontally and vertically for a 180-degree correction. The MiSTer OSD itself is not separately rotated.

## Video Scope

The flip is applied in the HDMI/scaler output path through `ascal.vhd`. Direct analog/raw video paths are not expected to be transformed by this experimental option.

## Timing Summary

Quartus: 25.1 Standard

- Setup slack: -0.089 ns
- Hold slack: -0.330 ns
- Full compile: 00:57:02
- Fitter: 00:50:10
- Fitter peak memory: 11,194 MB

Resource summary:

- ALMs: 39,994 / 41,910 (95%)
- Registers: 41,915
- Block memory bits: 4,126,357 / 5,662,720 (73%)
- RAM blocks: 553 / 553 (100%)
- DSP blocks: 63 / 112 (56%)
- PLLs: 3 / 6 (50%)

## SHA256

`bf1a726b0e7ac5e41a8262ea1db54bcc613c56355dcb0e4bcce5826820044b31`

## Validation

- Built from the ST-V dual-SDRAM project.
- Shienryu boots.
- `Shienryu 180 Flip` was physically verified on HDMI output.
- Flip off/on behavior was checked with MiSTerClaw captures and physical monitor photos.
- Audio, controls, coin/start, and gameplay were confirmed during manual testing.

## Hardware Test Checklist

1. Install `stv_flip_v1.1_final.rbf` as an ST-V arcade core.
2. Launch Shienryu.
3. Open OSD and set `Shienryu 180 Flip` to `On`.
4. Confirm the game image is corrected by a 180-degree flip.
5. Confirm the OSD behavior separately; OSD rotation is not required.
6. Confirm controls, coin/start, audio, and gameplay still work.
7. Test one non-Shienryu ST-V game with `Shienryu 180 Flip = Off`.
