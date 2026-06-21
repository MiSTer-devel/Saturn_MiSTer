# MAXATTEMPT Engine Design - 20260620

Decision: do not implement new RTL in this pass.

The current experimental all-cheats core already supports SRMW, SRMR, SRMC, SRM8, SRM9, SRMG grouped 16-bit one-shot, and clean standalone 06 rows through existing RAMH formats. The remaining high-volume pools do not have enough evidence or a low-risk hardware path to implement safely in the already timing-constrained core.

## A. D6 conditional engine

Local evidence says D6 is probably a read/compare/apply-next opcode, but the exact semantics are not confirmed. Some rows are D6 followed by direct-looking writes; others have awkward shapes. A correct implementation would need a new .CHT format, a read/compare state, and a gated direct-write executor. This would add control logic on top of an already negative-hold experimental build. Deferred.

## B. Low-work-RAM prefix 10/30

Prefix 10 strongly resembles 16-bit writes to 0x002xxxxx low work RAM. Prefix 30/36 strongly resembles 8-bit writes to the same region. The current cheat injector is explicitly wired into the RAMH path only. Saturn.sv exposes RAML through a separate RAML_CS_N/raml_addr/raml_wr path, including different DDRAM/SDRAM arbitration. Adding SRL1/SRL2/SRL8/SRL9 would require an isolated low-work-RAM injector and bus arbitration design. No such path is already present. Deferred.

## C. F6/B6 master/enabler

F6/B6 rows appear as original GameShark/PAR master/enabler metadata, commonly F6000914+C305 and B6002800+0000. Treating them as direct RAM writes risks patching code/handler state incorrectly. Existing SUB-only variants are the safe experiment. Runtime F6/B6 support remains deferred until opcode behavior is documented.

## D. Grouped 8-bit and mixed-width groups

This is technically the most plausible future extension because the current RAMH RMW path already supports byte writes and SRMG uses scalar buffers. A safe implementation would extend SRMG with per-record width and byte lane metadata. It was not implemented here because it still changes tested RTL and the existing build had negative setup/hold slack. Converter-only generation would be useless without RTL support.

## E. 32-bit writes

No confirmed aligned 32-bit direct-write pool was found. Unaligned 32-bit writes are explicitly unsafe. Deferred.

## F. Modifier placeholders

Rows containing ??/???? are not concrete cheats. No blind variant generation was done.

## Resulting implementation model

No new runtime formats were added. The max-attempt local layout preserves the currently tested fully clean Constant/Trigger set and reports the remaining pools for future targeted work.
