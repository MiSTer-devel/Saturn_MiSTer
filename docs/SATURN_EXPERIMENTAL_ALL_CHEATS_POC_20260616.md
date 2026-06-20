# Saturn Experimental All-Cheats POC 20260616

This branch contains an experimental Saturn cheat proof of concept. It is not a
stable release and does not replace the existing SRMW/SRMR package or the
official MiSTer Saturn core.

## Implemented Experimental Paths

- `SRMW`: direct 16-bit one-shot write.
- `SRMR`: direct 16-bit retained refresh.
- `SRMC`: clear the retained refresh operation.
- `SRM8`: direct 8-bit one-shot write.
- `SRM9`: direct 8-bit retained refresh.
- `SRMG`: grouped 16-bit one-shot writes, up to four records.
- Converter-only opcode 06 test files represented through existing
  SRMW/SRMR/SRMG formats.

The packaged clean layout is:

```text
games/Saturn/Cheats/
  Constant/
  Trigger/
  Experimental_Grouped/
  Experimental_06TEST/
```

| Folder | Files |
|---|---:|
| Constant | 2266 |
| Trigger | 2265 |
| Experimental_Grouped | 305 |
| Experimental_06TEST | 39 |
| Total | 4875 |

Format-aware validation found no bad-size files.

## Build

Tested RBF SHA-256:

`EBF0F7C4ADA647C371E2868244E0EE48DEC1FD9C672D9EEFE08B169293D0B6A6`

Quartus completed the full compile with zero errors and 144 warnings.

| Metric | Result |
|---|---:|
| Setup slack | -0.121 ns |
| Hold slack | -0.277 ns |
| Recovery slack | +3.561 ns |
| Removal slack | +0.892 ns |
| ALMs | 40,957 / 41,910 |
| Registers | 42,155 |
| RAM blocks | 542 / 553 |
| Block memory bits | 4,004,249 / 5,662,720 |
| DSP blocks | 57 / 112 |
| PLLs | 3 / 6 |

Timing requirements were not fully met. Negative hold slack is the primary
reason this remains an experimental prerelease.

## Hardware Results

The experimental core booted multiple ROMs. No noticeable OSD lag, game lag,
or crashes were reported in the tested cases.

Confirmed paths and examples:

- Normal 16-bit cheats passed.
- 8-bit cheats passed.
- Sonic 3D Blast grouped 999-rings SRMG test passed.
- Sonic 3D Blast constant invincibility refresh passed.
- Sonic 3D Blast trigger invincibility passed.
- Bug! opcode 06 `Unlimited Energy` test passed.
- Bug! constant `256 Gems Per Level` refresh passed.
- Bug! Trigger test passed.
- `Clear Active Refresh` stopped refresh behavior.

Clear does not restore the pre-cheat value. It stops future refresh writes while
leaving the last written value in memory until the game changes or resets it.

## Limitations

- Princess Crown save visibility differed from previous core builds and needs a
  separate investigation.
- Opcode 06 remains test-only despite successful Bug! hardware testing.
- F6/B6 master/enabler runtime behavior is not implemented.
- D6 conditionals are not implemented.
- Opcode 10/30 low-work-RAM support is not implemented.
- 32-bit writes, mixed-width groups, and grouped 8-bit writes are deferred.
- The retained refresh model supports one active refresh record.

## Source and Package Policy

This branch tracks the RTL, converter/layout tooling, and supporting
documentation. The generated 4,875-file cheat tree and RBF are distributed as a
GitHub prerelease asset instead of being added to the repository.

Release tag:

`saturn-experimental-all-cheats-poc-20260616`

Package:

`Saturn_Experimental_AllCheats_POC_20260616.zip`

Package SHA-256:

`87A3CF70708BA5D490177FF58C4DD74086AEC3CAA950A096BF400F7FF9708300`
