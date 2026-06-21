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
```

| Folder | Files |
|---|---:|
| Constant | 2285 |
| Trigger | 2590 |
| Total | 4875 |

Format-aware validation found no bad-size files.

`Constant` contains refresh/always-on cheats. `Trigger` contains one-shot
cheats, including grouped one-shot cheats and opcode-06-derived trigger-style
test cheats. The earlier internal `Experimental_Grouped` and
`Experimental_06TEST` folders were merged into this final Constant/Trigger
layout.

The refresh clear utility is included at:

```text
games/Saturn/Cheats/Constant/G/Global/Clear Active Refresh.CHT
```

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

## Deferred / Unused Cheat Research

The repository includes the remaining unsupported Saturn cheat pools for future
contributors under
[`docs/saturn_cheats_deferred/`](saturn_cheats_deferred/README.md). These files
are research and classification material only. They are not active supported
cheats and should not be copied directly into a MiSTer cheat folder.

The deferred research covers master/enabler rows, low-work-RAM candidates,
conditionals, placeholders, malformed rows, odd-aligned writes, out-of-range
addresses, and other cases that need new RTL, opcode confirmation, or value
tables before they can become working cheats.

## Source and Package Policy

This branch tracks the RTL, converter/layout tooling, and supporting
documentation. The generated 4,875-file cheat tree and RBF are distributed as a
GitHub prerelease asset instead of being added to the repository.

Release tag:

`saturn-experimental-all-cheats-poc-20260616`

Package:

`Saturn_Experimental_AllCheats_POC_20260620_FinalLayout.zip`

Package SHA-256:

`B9BBC8B3343077108A7F247010A3BC6D1A84E5FF0CCEB64CB23C77ACD8A1844F`
