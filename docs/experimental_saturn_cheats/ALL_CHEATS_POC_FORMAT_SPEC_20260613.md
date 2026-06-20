# Saturn All-Cheats POC Format Spec - 20260613

This experiment keeps the existing MiSTer .CHT parser-compatible 16-byte record shape and adds only formats whose source semantics are already understood from the converter classification.

## Implemented Active Formats

### SRMW - direct 16-bit one-shot

- File size: 16 bytes.
- Offset 0x00: magic `SRMW`.
- Offset 0x04: reserved, zero.
- Offset 0x08: big-endian 32-bit Saturn RAMH address.
- Offset 0x0C: big-endian value; low 16 bits are written.
- Supported addresses: `0x06000000` through `0x060FFFFF`.
- Address must be even-aligned.
- Converted from GameShark/PAR-style `16xxxxxx yyyy` direct 16-bit writes.

### SRMR - direct 16-bit 60-frame refresh

- File size: 16 bytes.
- Layout matches SRMW except magic is `SRMR`.
- Retains one active refresh record.
- Refreshed every 60 vblank events.
- `SRMC` clears the active refresh state.

### SRMC - clear active refresh

- File size: 16 bytes.
- Offset 0x00: magic `SRMC`.
- Remaining fields are reserved.
- Clears retained SRMR/SRM9 refresh state and cancels any pending SRMG group state.

### SRM8 - direct 8-bit one-shot

- File size: 16 bytes.
- Offset 0x00: magic `SRM8`.
- Offset 0x04: reserved, zero.
- Offset 0x08: big-endian 32-bit Saturn RAMH byte address.
- Offset 0x0C: big-endian value; low 8 bits are written.
- Supported addresses: `0x06000000` through `0x060FFFFF`.
- Odd and even byte addresses are allowed.
- Converted from confirmed direct 8-bit writes.

### SRM9 - direct 8-bit 60-frame refresh

- File size: 16 bytes.
- Layout matches SRM8 except magic is `SRM9`.
- Retains one active byte refresh record.
- Refreshed every 60 vblank events.
- Cleared by `SRMC`.

### SRMG - grouped direct 16-bit one-shot

- File size: 32, 48, 64, or 80 bytes for 1 to 4 embedded records.
- Generated files currently use 2 to 4 records.
- Header record:
  - Offset 0x00: magic `SRMG`.
  - Offset 0x04: big-endian record count, 1 through 4.
  - Offset 0x08: reserved, zero.
  - Offset 0x0C: reserved, zero.
- Embedded records:
  - Offset 0x00: magic `SRMW`.
  - Offset 0x04: reserved, zero.
  - Offset 0x08: big-endian 32-bit Saturn RAMH address.
  - Offset 0x0C: big-endian value; low 16 bits are written.
- Supported addresses: `0x06000000` through `0x060FFFFF`.
- Address must be even-aligned.
- Values must be `0x0000` through `0xFFFF`.
- Runtime applies one embedded write at a time through the existing RAMH read-modify-write path.
- Runtime storage is explicit scalar registers for four address/value slots, not inferred RAM.

## Deferred Formats

- `SRGA` grouped 8-bit: deferred. Current runtime supports one active byte write/refresh record, but no byte-group executor.
- `SRMX` mixed 16-bit and 8-bit groups: deferred. No mixed per-record width dispatch is implemented in this build.
- `SR32` and `SR3R` 32-bit direct writes: deferred. Source prefix semantics are not confirmed and no 32-bit active format is implemented.
- Odd-aligned 16-bit writes: deferred unless a source can be safely represented as byte writes.
- Conditionals, including D6 forms: deferred. No read/compare/apply-next engine is implemented.
- Master/enabler runtime handling: deferred. Opcode behavior is not implemented.
- Unknown prefixes such as `10`, `06`, and `30`: report-only until semantics are confirmed.

## Current Generated Counts

- SRMW normal files: 1120.
- SRMR normal files: 1120, plus one SRMC clear file in the SRMR folder.
- SRM8 files: 164.
- SRM9 files: 164.
- SRMG files: 181.
- Manual split/reference SRMW parts: 597.
