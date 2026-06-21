# Deferred Saturn Cheat Research

This folder documents Saturn cheat rows that are not active supported cheats in
the Saturn Experimental All-Cheats POC 20260616.

The current supported experimental release already includes 4,875 active cheats:

- Constant: 2,285
- Trigger: 2,590

The files here are research material for future contributors. They should not
be copied directly into MiSTer as working cheats. Some categories require new
RTL paths, better opcode documentation, value tables, or more hardware testing
before they can become usable.

## Deferred Pools

| Category | Count | Status |
|---|---:|---|
| F6 master/enabler | 230 | Deferred; opcode behavior is not confirmed. |
| Prefix 30/36 low-work-RAM 8-bit | 215 | Deferred; needs a safe RAML byte-write path. |
| Prefix 10 low-work-RAM 16-bit | 204 | Deferred; needs a safe RAML 16-bit write path. |
| D6/button conditional | 181 | Deferred; needs a confirmed conditional engine. |
| Modifier placeholder | 103 | Deferred; needs value tables or user selection. |
| Malformed/unknown | 49 | Deferred; source cleanup or opcode research needed. |
| Prefix 06 leftovers | 20 | Deferred; mostly conditional or mixed leftovers. |
| Duplicate | 14 | Preserved for audit; not active conversions. |
| Odd-aligned 16-bit | 3 | Deferred; unsafe as normal 16-bit writes. |
| Out-of-range | 2 | Deferred; target address is outside supported range. |
| D6 + 06 dependency | 1 | Deferred with conditionals. |

## Contents

- `DEFERRED_POOL_INDEX.csv`: concise category index.
- `IMPLEMENTATION_ROADMAP.md`: future implementation notes and risk order.
- `reports/`: copied analysis reports from the cheat-source workspace.

The most useful starting points are:

- `reports/MAXATTEMPT_REMAINING_POOL_SUMMARY_20260620.txt`
- `reports/MAXATTEMPT_ENGINE_DESIGN_20260620.md`
- `reports/MAXATTEMPT_PREBUILD_DECISION_20260620.txt`
- `reports/UNKNOWN_OPCODE_IMPLEMENTATION_RECOMMENDATION_20260613.md`
