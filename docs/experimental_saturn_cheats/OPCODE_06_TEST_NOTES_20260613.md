# Opcode 06 Test Pack Notes - 20260613

This pack is a converter-only experiment for `06xxxxxx+yyyy` Saturn cheat rows.

## Inference

Local opcode research showed that clean `06` rows have even address fields inside the same offset window used by RAMH-targeted 16-bit writes. This pass maps `06xxxxxx+yyyy` to inferred address `0x06xxxxxx` and writes `yyyy` as a direct 16-bit value.

This is not a confirmed opcode implementation. It is a test pack for the existing experimental all-cheats core formats.

## Included

- Clean rows containing only `06` records.
- Values <= `0xFFFF`.
- Inferred addresses `0x06000000` through `0x060FFFFF`.
- Even-aligned 16-bit addresses.
- SRMW and SRMR files per clean record.
- SRMG one-shot files for all-clean 2 to 4 record rows.

## Excluded

- `D6 + 06` conditional rows.
- `F6`/`B6` master/enabler rows.
- Mixed opcode rows, including `06 + 16`.
- Placeholder values such as `????`.
- Odd-aligned, out-of-range, malformed, or value-too-wide rows.

## Testing

Use these only with the experimental all-cheats core. Start with SRMW one-shot tests. Use SRMR only when the game behavior suggests the value must be retained. SRMG files are one-shot grouped writes only.

Do not copy this pack into stable active folders until specific cheats are tested.
