# SRMW/SRMR/SRMC Cheat Timing Path Analysis - 2026-06-11

## Scope

This is an analysis-only comparison between:

- Clean upstream stripped baseline: `C:\MiSTer-Work\Saturn_MiSTer_UPSTREAM_CLEAN`
- Cheat proof branch: `C:\MiSTer-Work\Saturn_MiSTer-q25-chtloader-wrappercut-test`

No source files were edited for this analysis. The only generated artifacts were timing extraction/report files.

Supporting timing extracts:

- Upstream: `C:\MiSTer-Work\Saturn_MiSTer_UPSTREAM_CLEAN\timing_paths_upstream_stripped_seed9_20260611.txt`
- Cheat: `C:\MiSTer-Work\Saturn_MiSTer-q25-chtloader-wrappercut-test\timing_paths_cheat_refresh60_stripped_20260611.txt`

## Build Comparison

| Metric | Upstream Stripped Seed 9 | Cheat REFRESH60 Stripped Seed 9 | Delta / Note |
|---|---:|---:|---|
| Full compile | Successful | Successful | Both fit |
| Errors | 0 | 0 | Same |
| Warnings | 140 | 144 | Cheat +4 |
| Setup slack | -0.177 ns | -0.313 ns | Cheat worse by 0.136 ns |
| Hold slack | +0.072 ns | -0.478 ns | Cheat worse by 0.550 ns |
| Recovery slack | +3.021 ns | +4.203 ns | Cheat better |
| Removal slack | +0.888 ns | +1.083 ns | Cheat better |
| ALMs | 41,390 / 41,910, 99% | 41,025 / 41,910, 98% | Cheat uses 365 fewer ALMs |
| RAM blocks | 545 / 553, 99% | 542 / 553, 98% | Cheat uses 3 fewer RAM blocks |
| Block memory bits | 4,013,207 / 5,662,720, 71% | 4,004,249 / 5,662,720, 71% | Cheat uses 8,958 fewer bits |
| RBF size | 4,626,620 bytes | 4,619,064 bytes | Cheat is 7,556 bytes smaller |
| SHA256 | `1633B05EB11FFA73ACD2C1C65E7DFBC4A9BE83D80310DBA9FE5574750EBDCD95` | `699FC545652CCA747F8D9AEB024CF525383D8BA95BC972FDE7A9301E92BC7C7E` | Different builds |

Both builds use the same main failing generated clock family:

- 57.28 MHz generated clock: `emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk`
- 114.55 MHz generated clock: `emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk`

## Worst Setup Path Summary

### Cheat REFRESH60 Stripped

The worst setup paths are from SH7604 bus control logic into the high RAM / DDR RAMH interface.

Representative worst path:

- Slack: `-0.313 ns`
- From: `emu:emu|Saturn:saturn|SH7604:MSH|SH7604_BSC:bsc|MST_BUS_RLS`
- To: `emu:emu|ramh_din[17]`
- Launch clock: 57.28 MHz PLL generated clock
- Latch clock: 114.55 MHz PLL generated clock

Other top setup endpoints are also `ramh_din[...]`, followed by DDR cache-related RAMH endpoints such as:

- `emu:emu|ddram:ddram|ramh_rcache_addr[3][14]`
- `emu:emu|ddram:ddram|ramh_rcache_lru[1][0]`
- `emu:emu|ddram:ddram|ramh_rcache_lru[1][1]`

Top setup path family:

`SH7604_BSC` -> RAMH data/control/address path -> top-level `ramh_din` / `ddram` RAMH cache logic.

### Upstream Stripped Baseline

The upstream stripped build has the same setup path family.

Representative worst path:

- Slack: `-0.177 ns`
- From: `emu:emu|Saturn:saturn|SH7604:MSH|SH7604_BSC:bsc|MST_BUS_RLS`
- To: `emu:emu|ramh_din[24]`
- Launch clock: 57.28 MHz PLL generated clock
- Latch clock: 114.55 MHz PLL generated clock

Other top setup endpoints are also `ramh_din[...]` and DDR RAMH cache/LRU signals.

### Setup Interpretation

The worst setup family is not new. It exists in the stripped upstream baseline and remains the worst setup family in the cheat build.

However, the cheat branch plausibly worsens this pre-existing path because it adds muxing and gating directly around the RAMH path:

- `ramh_addr` selection between `MEM_A[19:2]` and `cheat_patch_addr_ram`
- `ramh_din` selection between normal RAMH data and `cheat_patch_data_ram`
- `ramh_wr` selection/suppression during `cheat_patch_hold`
- `ramh_rd` suppression during `cheat_patch_hold` plus cheat read injection
- `MEM_WAIT_N` gating with `~cheat_patch_hold`

The direct top setup endpoint is often `ramh_din[...]`, so the cheat-side RAMH muxing is the most likely source-level contributor to the extra setup pressure. This does not mean the SRMW/SRMR/SRMC parser itself is in the failing path; the likely pressure point is the final RAMH injection/control interface.

## Worst Hold Path Summary

### Cheat REFRESH60 Stripped

The worst hold paths are not through the cheat parser or RAMH write injection. They are VDP2 VRAM address paths into the `sdram1` read-address registers.

Representative worst path:

- Slack: `-0.478 ns`
- From: `emu:emu|Saturn:saturn|VDP2:VDP2|VRAMB1_A[16]_OTERM1611`
- To: `emu:emu|sdram1:sdram1|raddr23[1][14]`
- Launch clock: 57.28 MHz PLL generated clock
- Latch clock: 114.55 MHz PLL generated clock

Other top hold endpoints include:

- `sdram1:sdram1|raddr23[1][3]`
- `sdram1:sdram1|raddr23[1][5]`
- `sdram1:sdram1|raddr23[0][4]`
- `sdram1:sdram1|raddr23[0][5]`
- `sdram1:sdram1|raddr23[1][14]`
- `sdram1:sdram1|raddr23[0][14]`
- `sdram1:sdram1|raddr23[0][13]`
- `sdram1:sdram1|raddr23[0][16]`

Top hold path family:

`VDP2` VRAM address outputs -> `sdram1` read address registers.

### Upstream Stripped Baseline

The upstream stripped baseline has positive hold slack.

Representative worst hold path:

- Slack: `+0.072 ns`
- From: `emu:emu|sd_lba[5]`
- To: `emu:emu|ddram:ddram|bsram_rcache_addr[14]`
- Launch clock: 57.28 MHz PLL generated clock
- Latch clock: 114.55 MHz PLL generated clock

The upstream top hold list does not show the same VDP2-to-`sdram1|raddr23` family as its worst hold path.

### Hold Interpretation

The worst hold violation in the cheat build does not appear directly cheat-related. The failing path is VDP2 video RAM addressing into `sdram1`, not the SRMW/SRMR/SRMC parser, ioctl path, HPS bridge, RMW state machine, or RAMH cheat write path.

The most likely explanation is placement/routing perturbation in an already extremely full Q25 single-RAM build. The cheat branch uses fewer ALMs and RAM blocks overall due to extra stripping, but the design is still around 98% full, and small logic changes can move unrelated high-pressure paths into worse physical placement.

In short:

- Setup degradation appears partly source-related because the changed RAMH muxing sits on the same family as the worst setup path.
- Hold degradation appears mostly placement/routing-related because the worst path is VDP2-to-`sdram1`, away from the cheat logic.

## Source Diff Focus

Main changed files relevant to this analysis:

- `Saturn.qsf`
- `Saturn.sv`

The SRMW/SRMR/SRMC implementation is concentrated in `Saturn.sv`, with compile-time controls in `Saturn.qsf`.

### Saturn.qsf

The cheat branch keeps the stripped baseline-style options:

- `SEED 9`
- `MISTER_DISABLE_YC=1`
- `MISTER_DISABLE_ADAPTIVE=1`
- `MISTER_DISABLE_ALSA=1`
- local `sys/pll_q25.qip`

The cheat branch also includes additional stripping:

- `SATURN_DISABLE_LIGHTGUN=1`
- `SATURN_DISABLE_SATURN_MOUSE_KEYBOARD=1`
- `SATURN_DISABLE_COMPOSITE_BLEND=1`
- `MISTER_DISABLE_SHADOWMASK=1`
- `MISTER_DISABLE_GAMMA=1`

And cheat proof-of-concept macros:

- `SATURN_CHEAT_POC=1`
- `SATURN_CHEAT_RMW_POC=1`
- `SATURN_CHEAT_RMW_REFRESH_POC=1`

These explain why the cheat branch can use fewer ALMs/RAM blocks than the upstream stripped build while still timing worse.

### Saturn.sv

The cheat branch adds:

- Cheat file loader entry for `CHT`
- `cht_download = ioctl_download & (ioctl_index == 8'h08)`
- `saturn_cheat_poc` parser module
- Magic handling for:
  - `CHT`
  - `SRMW`
  - `SRMR`
  - `SRMC`
- One active SRMR refresh record
- 60-vblank refresh divider
- RAM-domain request/ack synchronization
- RAM-domain read-modify-write state machine

Relevant parser/refresh state includes:

- `u32_hi`
- `record_addr`
- `magic_ok`
- `rmw_magic_ok`
- `rmr_magic_ok`
- `refresh_valid`
- `refresh_addr`
- `refresh_data`
- `refresh_half`
- `refresh_div[5:0]`
- `old_vbl_n`
- `patch_req`
- `patch_ack`
- `request_active`

Relevant RAM-domain injection state includes:

- `cheat_patch_req_meta`
- `cheat_patch_req_sync`
- `cheat_patch_req_seen`
- `cheat_patch_ack_ram`
- `cheat_patch_state[3:0]`
- `cheat_patch_addr_ram`
- `cheat_patch_data_ram`
- `cheat_patch_wr`
- `cheat_patch_hold`
- `cheat_patch_rd`
- `cheat_patch_half_ram`
- `cheat_patch_read_data`

The most timing-sensitive source changes are the RAMH interface muxes/gates:

- `ramh_addr` muxed by `cheat_patch_hold`
- `ramh_din` muxed by `cheat_patch_wr`
- `ramh_wr` overridden/suppressed by `cheat_patch_wr` and `cheat_patch_hold`
- `ramh_rd` suppressed during `cheat_patch_hold` and asserted for cheat reads
- `MEM_WAIT_N` gated by `~cheat_patch_hold`

The parser and ioctl-side logic are not visible in the worst timing paths. The RAMH injection muxing is the likely direct setup contributor.

## Cheat-Related vs Baseline-Related

| Path Type | Cheat-Related? | Assessment |
|---|---|---|
| Worst setup, SH7604 BSC -> `ramh_din` / DDR RAMH cache | Partly | The path family is baseline, but cheat RAMH muxing likely worsened it. |
| Worst hold, VDP2 VRAM address -> `sdram1|raddr23` | Not directly | This appears to be unrelated core/video/memory logic affected by placement/routing. |
| Parser/ioctl/HPS bridge | No evidence in top paths | Not present in worst setup or hold paths. |
| SRMR 60-vblank refresh divider | No evidence in top paths | Refresh cadence is unlikely to be the direct timing issue. |
| RMW state machine | Indirect only | The FSM itself is not the top path, but its RAMH mux controls can affect normal RAMH timing. |

## Top 3 Safest Source-Level Timing Cleanup Ideas

1. Restore the normal RAMH data path shape as much as possible.

   The top setup endpoint is frequently `ramh_din[...]`. The safest first cleanup is to reduce or isolate the cheat muxing on `ramh_din` so the normal SH7604-to-RAMH data path resembles upstream when no cheat write is active. Keep SRMW/SRMR/SRMC behavior unchanged; only reduce the amount of extra logic carried by the normal path.

2. Localize and register the cheat injection controls before the final RAMH boundary.

   `cheat_patch_hold`, `cheat_patch_wr`, `cheat_patch_rd`, and the selected address/data can be made stable before they reach the final RAMH control selection. The goal is not a new feature, only cleaner timing: a small, registered injection path with fewer high-fanout control terms on `ramh_wr`, `ramh_rd`, and `MEM_WAIT_N`.

3. Keep the parser untouched and focus only on the RAM-domain handoff/interface.

   The timing reports do not implicate `saturn_cheat_poc`, ioctl download parsing, or the 60-vblank refresh counter. The safest cleanup area is the narrow RAM-domain injection boundary, not the file parser or refresh policy.

## Top 3 Risky Changes To Avoid

1. Do not modify `ddram.sv` or `sdram2.sv` for this issue yet.

   The worst hold path is VDP2-to-`sdram1`, and the worst setup path is a known high-pressure RAMH family. Editing memory controller internals could easily destabilize working single-RAM behavior without addressing the actual source-level contributor.

2. Do not use broad false-path, multicycle, or generated-clock hacks to hide the VDP2-to-`sdram1` hold violation.

   The clocks are related PLL-generated clocks, and the paths appear real. Masking them would make timing reports less useful and could hide hardware failures.

3. Do not change SRMW/SRMR/SRMC semantics while chasing timing.

   Avoid file format changes, multi-record support, multiple refresh slots, new refresh rates, or menu changes. The current feature behavior works; the next experiment should only clean up timing pressure around the existing RAMH injection path.

## Recommendation For Next Build Attempt

The next build should be a minimal source-level timing cleanup around the RAMH cheat injection boundary, still using SRMR refresh every 60 vblanks and the same SRMW/SRMR/SRMC formats.

Recommended target:

- Leave the parser, magic handling, SRMC clear behavior, SRMW one-shot behavior, and SRMR 60-vblank refresh behavior unchanged.
- Keep `ddram.sv` and `sdram2.sv` untouched.
- Reduce the normal-path impact of the cheat injection muxes around `ramh_din`, `ramh_wr`, `ramh_rd`, `ramh_addr`, and `MEM_WAIT_N`.
- Build seed 9 again and compare against both current stripped builds.

Expected outcome:

- If setup improves on the SH7604-to-RAMH path, the RAMH mux cleanup helped.
- If hold remains negative on VDP2-to-`sdram1`, that hold issue is probably dominated by placement/routing in the nearly full Q25 single-RAM design.
- If setup improves but hold remains unstable, a follow-up experiment should compare a small number of seeds with the cleaned source before making invasive RTL changes.

Bottom line:

The cheat POC does not appear to introduce a new worst hold path. It likely perturbs placement enough to expose a vulnerable VDP2-to-`sdram1` hold path, while also directly worsening an already-negative SH7604-to-RAMH setup path through the added RAMH injection muxing. The safest next step is a narrow RAMH-interface timing cleanup, not more stripping and not memory-controller surgery.
