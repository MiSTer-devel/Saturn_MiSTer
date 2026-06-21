# Unknown Opcode Implementation Recommendation - 20260613

Local evidence only. No opcode is marked confirmed without external documentation or hardware-specific evidence.

## Summary Recommendation

| Opcode | Recommendation | Needs RTL | Converter-only possible | Testable with current Experimental_AllCheats RBF | Likely payoff | Timing/resource risk | Correctness risk |
|---|---|---:|---:|---:|---:|---|---|
| F6 | Defer / never convert blindly; metadata only | No useful runtime path yet | No | SUB-only tests already possible by dropping it | 0 direct rows | Low if ignored | High if executed blindly |
| B6 | Defer / never convert blindly; paired metadata only | No useful runtime path yet | No | SUB-only tests already possible by dropping it | 0 direct rows | Low if ignored | High if executed blindly |
| D6 | Defer until conditional engine is designed | Yes | No | No | 151 conditional-direct candidates | Medium to high | Medium-high |
| 10 | Defer; likely low-work-RAM 16-bit writes | Yes, non-RAMH target path | No | No | 385 clean-looking rows | High in current near-full core | Medium-high |
| 30 | Defer; likely low-work-RAM 8-bit writes | Yes, non-RAMH byte-lane path | No | No | 68 clean-looking rows | High in current near-full core | Medium-high |
| 06 | Implement next as test-only converter mapping for clean rows | No, if mapped to existing SRMW/SRMR/SRMG | Yes | Yes | 19 clean non-conditional rows | Low | Medium |

## F6

- Observed rows: 207 across 207 games.
- Pattern: first record in every deduped occurrence; common values are C305 and FFFF, common addresses are 000914 and 000924.
- Local conclusion: master/enabler metadata or AR/PAR handler behavior, not a normal RAM cheat value.
- Recommendation: do not implement now. Keep ignoring/dropping for SUB-only variants. MC-included variants remain unsafe until F6 semantics are documented.

## B6

- Observed rows: 164 across 164 games.
- Pattern: normally the second record after F6; overwhelmingly B6002800+0000.
- Local conclusion: secondary master/enabler record, likely hardware/handler setup, not a standalone direct write.
- Recommendation: do not implement now. Treat as metadata only.

## D6

- Observed rows: 174; direct-following candidates: 151.
- Pattern: usually followed by a 16-prefix direct write, occasionally 36/06, with RAMH-candidate even addresses and 16-bit compare values.
- Local conclusion: likely conditional compare/apply-next. Confidence medium, not confirmed.
- Recommendation: defer. A safe implementation needs a new conditional .CHT format and RTL sequence: read target, compare value, then apply one following supported direct record. This cannot be tested with the current RBF.

## 10

- Observed rows: 393; clean non-placeholder rows: 385.
- Pattern: all deduped addresses are even and in 0x00200000-0x002FFFFF if interpreted as literal Saturn low work RAM. Values are mostly 16-bit-looking.
- Local conclusion: likely direct 16-bit writes to low work RAM, not RAMH. This is plausible but not confirmed.
- Recommendation: defer. It needs RTL support for low work RAM writes, not just converter changes. Do not remap to RAMH.

## 30

- Observed rows: 68; clean rows: 68.
- Pattern: all values are byte-looking; addresses sit in the same 0x002xxxxx region and are often odd.
- Local conclusion: likely direct 8-bit writes to low work RAM. Plausible but not confirmed.
- Recommendation: defer with 10 until a low work RAM byte-lane path exists.

## 06

- Observed rows: 36; clean non-conditional rows suitable for a test-only converter pass: 19.
- Pattern: address fields are all even and within the current RAMH offset window; values are 16-bit-looking except a few placeholders/conditional blocks.
- Local conclusion: likely direct RAMH 16-bit writes or code patches. Confidence medium because local sources do not document the prefix.
- Recommendation: implement next as a converter-only experimental pack for clean standalone 06 rows, mapped into existing SRMW/SRMR/SRMG records. Skip D6-linked 06 rows, placeholder values, and any group that exceeds existing SRMG constraints.

## Safe Next Work

1. Add an experimental converter switch/report for clean `06xxxxxx+yyyy` rows only, output to a separate folder, and do not merge into stable packs yet.
2. Use the existing Experimental_AllCheats_Saturn.rbf to test a small number of 06 candidates because the output can use existing SRMW/SRMR/SRMG formats.
3. Design a separate low-work-RAM access plan before attempting `10` or `30`; this is not converter-only work.
4. Design a separate conditional format before attempting `D6`; avoid implementing a broad conditional engine in the current near-full timing state.
