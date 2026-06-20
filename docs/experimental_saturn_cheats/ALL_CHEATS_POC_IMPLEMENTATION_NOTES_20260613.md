# Saturn All-Cheats POC Implementation Notes - 20260613

## Starting Point

This experiment is based on the stripped-down core configuration because it had the best prior timing. The active QSF includes the stripped feature macros for ALSA, lightgun, Saturn mouse/keyboard, composite blend, shadow mask, gamma, YC, and adaptive video, plus the existing cheat proof macros.

Branch:

- `feature/cheat-support-all-cheats-poc`

Worktree:

- `C:\MiSTer-Work\Saturn_MiSTer-q25-chtloader-wrappercut-test`

## RTL Scope

Implemented:

- Preserve SRMW direct 16-bit one-shot behavior.
- Preserve SRMR direct 16-bit 60-frame refresh behavior.
- Preserve SRMC clear behavior and extend clear to cancel byte refresh and pending grouped state.
- Preserve SRM8 direct 8-bit one-shot behavior.
- Preserve SRM9 direct 8-bit 60-frame refresh behavior.
- Keep SRMG as grouped direct 16-bit one-shot, up to four embedded records.
- Refactor SRMG storage from address/value arrays to scalar registers:
  - `rmg_addr0` through `rmg_addr3`.
  - `rmg_data0` through `rmg_data3`.
  - muxed issue address/value selection.
- Run grouped writes sequentially through the existing RAMH read-modify-write path.

Intentionally not implemented:

- Grouped 8-bit active format.
- Mixed-width grouped active format.
- 32-bit active write/refresh format.
- Conditional runtime engine.
- Master/enabler runtime engine.
- Unknown prefix handling.

No block RAM was intentionally added. The SRMG address/value buffers use scalar registers only.

## Converter Scope

The converter now emits combined all-cheats POC reports in addition to the existing format-specific reports:

- `ALL_CHEATS_POC_CONVERTED_20260613.csv`
- `ALL_CHEATS_POC_SKIPPED_20260613.csv`
- `ALL_CHEATS_POC_SUMMARY_20260613.txt`

Generated output from `mister_library_classification_20260613`:

- SRMW files: 1120.
- SRMR files: 1120 normal refresh files plus one SRMC clear file.
- SRM8 files: 164.
- SRM9 files: 164.
- SRMG files: 181.
- Manual split/reference files: 597.

Converted manifest records by format:

- SRMW: 1120.
- SRMR: 1121 including SRMC.
- SRM8: 164.
- SRM9: 164.
- SRMG: 392 embedded records across 181 grouped files.
- Manual split parts: 597.

Games represented by active format:

- SRMW/SRMR: 226 games.
- SRM8/SRM9: 42 games.
- SRMG: 78 games.

## Risk Before Build

The implementation is coherent enough for one experimental compile:

- It stays on the stripped base configuration.
- It does not add new inferred RAM for SRMG record storage.
- It keeps the existing one-active-refresh model.
- It avoids conditionals, master/enabler execution, unknown prefixes, and 32-bit writes.

Remaining risk:

- Timing is still experimental because byte RMW and grouped sequential execution add control paths to the cheat patch engine.
- SRMG is one-shot only and untested on hardware in this scalar-buffer form.
- SRMR and SRM9 still share one active retained refresh record model.

## Build Result

The single compile attempt completed on 2026-06-15.

- Analysis and synthesis: successful, 0 errors, 116 warnings.
- Fitter: successful, 0 errors, 16 warnings.
- Assembler: successful, 0 errors, 0 warnings.
- Timing analyzer: successful, 0 errors, 12 warnings, but timing requirements were not met.
- Final shell result: successful, 0 errors, 144 warnings.

Generated RBF:

- Local path: `C:\MiSTer-Work\Saturn_MiSTer-q25-chtloader-wrappercut-test\output_files\Saturn.rbf`
- SHA256: `EBF0F7C4ADA647C371E2868244E0EE48DEC1FD9C672D9EEFE08B169293D0B6A6`

Timing:

- Setup slack: `-0.121 ns`
- Hold slack: `-0.277 ns`
- Recovery slack: `3.561 ns`
- Removal slack: `0.892 ns`

Resources:

- ALMs: `40,957 / 41,910` (`98%`)
- Registers: `42,155`
- Block memory bits: `4,004,249 / 5,662,720` (`71%`)
- RAM blocks: `542 / 553` (`98%`)
- DSP blocks: `57 / 112` (`51%`)
- PLLs: `3 / 6` (`50%`)

No block RAM was intentionally added by the SRMG scalar-buffer refactor.

## MiSTer Copy Result

The target core share `\\MiSTer\sdcard_Console` was not reachable from PowerShell, so the experimental RBF was not copied to `\\MiSTer\sdcard_Console\Experimental_AllCheats_Saturn.rbf`.

The Saturn games share was reachable, and separate experimental cheat folders were copied:

- `\\MiSTer\sdcard\games\Saturn\Cheats_Trigger_8bit`: 164 SRM8 files, all 16 bytes.
- `\\MiSTer\sdcard\games\Saturn\Cheats_60Frames_8bit`: 164 SRM9 files, all 16 bytes.
- `\\MiSTer\sdcard\games\Saturn\Cheats_Grouped_Experimental`: 181 SRMG files, sizes 48/64/80 bytes.

Stable active folders were not modified:

- `\\MiSTer\sdcard\games\Saturn\Cheats_Trigger`: 1120 files, all 16 bytes.
- `\\MiSTer\sdcard\games\Saturn\Cheats_60Frames`: 1120 files, all 16 bytes.

`\\MiSTer\sdcard\games\Saturn\SRMC_Clear_Refresh.CHT` remained present, 16 bytes, SHA256 `EF72445E6AE2E4E22735830DAA3EF4ADABDF37E1A0D8E35F6937AAFA537E57F1`.
