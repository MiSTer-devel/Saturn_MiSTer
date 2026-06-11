# RAMH Cheat Timing Cleanup - 2026-06-11

## Files Changed

- `Saturn.sv`

No changes were made to:

- `Saturn.qsf`
- `ddram.sv`
- `sdram2.sv`
- PLL/QIP setup
- Cheat file generation or cheat file formats

## Exact Timing Path Targeted

This cleanup targets the setup-pressure area identified in `CHEAT_TIMING_PATH_ANALYSIS_20260611.md`:

- Path family: SH7604 bus control / high RAM path into RAMH
- Representative cheat-build setup path:
  - Slack: `-0.313 ns`
  - From: `emu:emu|Saturn:saturn|SH7604:MSH|SH7604_BSC:bsc|MST_BUS_RLS`
  - To: `emu:emu|ramh_din[17]`
  - Launch clock: 57.28 MHz PLL generated clock
  - Latch clock: 114.55 MHz PLL generated clock

The cleanup does not attempt to fix the VDP2-to-`sdram1|raddr23` hold path. That path appears unrelated to the cheat logic and is treated as placement/routing fallout in this pass.

## What Changed

The inline RAMH cheat injection expressions were pulled out of the `ddram` and `sdram2` port maps into named boundary wires:

- `cheat_ramh_hold`
- `cheat_ramh_addr`
- `cheat_ramh_din`
- `cheat_ramh_wr`
- `cheat_ramh_rd`
- `ramh_addr_bus`
- `ramh_din_bus`
- `ramh_wr_bus`
- `ramh_rd_bus`

These wires precompute/decompose the final RAMH selection terms before the memory backend port boundary.

The same boundary wires are used by:

- The active single-RAM `ddram` RAMH connection
- The guarded `MISTER_DUAL_SDRAM` `sdram2` RAMH connection
- The RAMH wait-state suppression term through `cheat_ramh_hold`

## Behavior Intentionally Left Unchanged

The following behavior is intentionally unchanged:

- SRMW one-shot behavior
- SRMR retained-refresh behavior
- SRMR 60-vblank refresh cadence
- SRMC clear behavior
- One active SRMR refresh record
- SRMW/SRMR/SRMC magic handling and file formats
- Cheat parser state machine
- RMW state machine sequencing
- RAMH target address/data semantics
- Injected full-word RAMH write byte enables, still `4'hF`
- Normal RAMH write suppression while `cheat_patch_hold` is active
- Normal RAMH read suppression while `cheat_patch_hold` is active
- Cheat RMW read assertion through `cheat_patch_rd`

No extra cheat features, menu entries, refresh modes, or record slots were added.

## Why This Should Help Setup Pressure

The previous code placed the cheat RAMH selection logic directly inside the memory backend port expressions:

- `ramh_addr`
- `ramh_din`
- `ramh_wr`
- `ramh_rd`
- `MEM_WAIT_N`

Those expressions sit at the boundary involved in the known SH7604-to-RAMH setup-pressure area. Decomposing the inline mux/control logic into named boundary wires gives Quartus a smaller and more explicit final selection structure to optimize and place.

This is intentionally conservative: it does not add a new cycle, does not change the RMW flow, and does not alter visible cheat behavior. The expected benefit is modest, but it is aimed at the right boundary before trying riskier RTL or constraint changes.

## Risk Introduced

Risk is low, but not zero.

Functional risk:

- The change is intended to be logically equivalent to the previous inline port expressions.
- The main risk is a preprocessor or expression-precedence mistake, so the next step should include a clean Quartus compile before hardware testing.

Timing risk:

- This may improve setup by making the RAMH boundary simpler for synthesis and placement.
- It may have little effect if the worst setup path is dominated by unrelated placement or the existing `ramh_din` register input path.
- It is not expected to fix the VDP2-to-`sdram1` hold violation by itself.

## Recommended Build Command

From:

`C:\MiSTer-Work\Saturn_MiSTer-q25-chtloader-wrappercut-test`

Run:

```powershell
& 'C:\intelFPGA_standard\25.1\quartus\bin64\quartus_sh.exe' --flow compile Saturn
```

Then compare against the current REFRESH60_STRIPPED cheat build:

- Setup slack target: improve from `-0.313 ns` toward the upstream stripped baseline of `-0.177 ns`
- Hold slack may remain negative because the current worst hold path is likely VDP2-to-`sdram1` placement/routing fallout
- Resource usage should remain very close to the previous cheat stripped build

## Expected Comparison Target

Previous cheat REFRESH60_STRIPPED:

- Setup slack: `-0.313 ns`
- Hold slack: `-0.478 ns`
- ALMs: `41,025 / 41,910`
- RAM blocks: `542 / 553`
- Block memory bits: `4,004,249 / 5,662,720`

Clean upstream stripped seed 9:

- Setup slack: `-0.177 ns`
- Hold slack: `+0.072 ns`

Success for this pass would be a setup improvement without breaking SRMW/SRMR/SRMC behavior. Hold should be evaluated, but a remaining VDP2-to-`sdram1` hold issue should not be treated as proof that the RAMH cleanup failed.
