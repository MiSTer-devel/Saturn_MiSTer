# Deferred Saturn Cheat Implementation Roadmap

This document summarizes what remains after the Saturn Experimental All-Cheats
POC 20260616 and what would be required to support more cheat types.

## Current Supported Formats

- `SRMW`: RAMH 16-bit one-shot write.
- `SRMR`: RAMH 16-bit refresh/constant write.
- `SRMC`: clear active refresh.
- `SRM8`: RAMH 8-bit one-shot write.
- `SRM9`: RAMH 8-bit refresh/constant write.
- `SRMG`: grouped RAMH 16-bit one-shot writes, up to four records.
- Clean standalone `06` rows that map into the existing RAMH formats.

## Deferred Categories

### Prefix 10 Low-Work-RAM 16-bit

Likely 16-bit writes to `0x002xxxxx` low work RAM. The current cheat injector is
RAMH-only, so this needs a new isolated RAML/low-work-RAM path. Do not remap
these rows to RAMH.

### Prefix 30/36 Low-Work-RAM 8-bit

Likely byte writes to low work RAM. This should be designed alongside prefix 10
support, with explicit byte-lane handling.

### D6 / Button Conditionals

Likely compare/apply-next or input-gated behavior, but local evidence is not
enough to treat it as confirmed. A future implementation should start with one
conditional group, direct writes only, and no nested conditionals.

### Modifier Placeholders

Rows with `??` or `????` are not concrete cheats. They need a value table or a
user-facing selection mechanism before conversion.

### F6/B6 Master/Enabler

These appear to be original cheat-device master/enabler rows, commonly
`F6000914+C305` and `B6002800+0000`. They should remain metadata until opcode
behavior is documented or proven on hardware. Do not execute them blindly.

### 32-bit / Odd-Aligned / Mixed-Width

These should be later-stage work. Odd-aligned 16-bit rows may need byte splits
or explicit semantic confirmation. Mixed-width groups should wait until grouped
8-bit support exists.

## Recommended Implementation Order

1. Low-work-RAM prefix 10/30 support, if a safe RAML path is found.
2. D6 conditional engine, limited to direct-write-only apply-next behavior.
3. Modifier placeholder value-table UX.
4. F6/B6 master/enabler runtime only after opcode behavior is confirmed.
5. 32-bit, odd-aligned, grouped 8-bit, and mixed-width support later.

## Testing Requirements

- Keep every new cheat type in a separate experimental folder or package first.
- Test boot/no-cheat behavior before enabling new formats.
- Re-test existing SRMW/SRMR/SRM8/SRM9/SRMG paths after every RTL change.
- Include Clear Active Refresh regression tests.
- Record game, ROM region, exact cheat path, expected effect, actual effect,
  stability, and whether failure means cheat removal or core investigation.

## Timing And Resource Risks

The all-cheats POC already had negative setup and hold slack. New RAML paths,
conditional sequencing, or grouped mixed-width logic may further stress timing.
Favor small, isolated engines with scalar buffers and avoid block RAM unless a
reviewed design explicitly requires it.
