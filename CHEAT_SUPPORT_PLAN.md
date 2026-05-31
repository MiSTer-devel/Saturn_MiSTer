# Saturn MiSTer Cheat Support Plan

## 1. MiSTer Cheat Input Path

MiSTer cheat files are delivered to a core through the existing `hps_io`
download interface. The Saturn wrapper already exposes that interface in
`Saturn.sv`:

- `ioctl_download` indicates an active transfer.
- `ioctl_index` identifies the transfer type.
- `ioctl_addr` is the byte offset within the transferred data.
- `ioctl_data` carries the downloaded data.
- `ioctl_wr` marks a valid write beat.

Other MiSTer console cores declare `"C,Cheats;"` in `CONF_STR` and treat an
all-ones ioctl index (`8'hFF`) as a cheat-code download. Cheat records commonly
contain flags, an address, an optional compare value, and a replacement value.

The Saturn core currently has no cheat menu declaration or cheat record loader.
The existing path in `Saturn.sv` is sufficient to receive records without
changing `sys/hps_io.sv`.

## 2. Likely Saturn Memory Hook Points

The preferred integration point is the root `Saturn.sv` wrapper, where Saturn
memory buses are connected to their storage backends.

Primary CPU-visible targets:

- High work RAM (`RAMH`): `ramh_din`, `ramh_wr`, and the `MEM_DI` read mux.
- Low work RAM (`RAML`): `raml_din`, `raml_wr`, and the `MEM_DI` read mux.
- Backup SRAM: potentially useful later, but not required for the first proof
  of concept.

High work RAM needs particular care because it has two backends:

- Single-SDRAM builds route it through `rtl/ddram.sv`.
- Dual-SDRAM builds route it through `rtl/sdram2.sv`.

The root wrapper sees both configurations and is therefore a better initial
hook point than modifying only `rtl/ddram.sv`.

Additional memory regions can be considered after the work-RAM path is proven:

- Cartridge DRAM and backup cartridge RAM
- CD RAM
- VDP1 VRAM
- ST-V-specific cartridge and RAX memory

These are not Stage 1 targets.

## 3. SH-2 Cache Risks

Both Saturn SH-2 CPUs instantiate `SH7604_CACHE` through
`rtl/SH/SH7604/SH7604.sv`. A cheat write performed only in external RAM is not
guaranteed to become immediately visible to code reading a cached line.

Important consequences:

- Direct DDR3 or SDRAM patching can leave stale values in either SH-2 cache.
- Periodic freeze writes alone may not be sufficient for cached variables.
- Read replacement at the external memory mux only affects cache misses and
  uncached reads.
- A complete design may need cache-aware replacement, invalidation, or an
  explicit purge path for both SH-2 instances.

Stage 1 should avoid claiming general cheat compatibility until cache behavior
has been measured with a real title.

## 4. Staged Implementation Plan

### Stage 1: Input and Minimal Work-RAM Proof of Concept

- Add `"C,Cheats;"` to the Saturn `CONF_STR`.
- Decode cheat downloads using `ioctl_index == 8'hFF`.
- Load a small fixed number of address/value records.
- Support a deliberately narrow work-RAM replacement path.
- Validate one known cheat against a real game on hardware.
- Document whether the tested variable is cached and whether read replacement,
  write clamping, or repeated writes are required.

### Stage 2: Cache-Aware Behavior

- Define a shared cheat lookup interface for both SH-2 instances.
- Add cache-aware read replacement or targeted invalidation.
- Confirm behavior for cached and uncached aliases.
- Test compare-before-replace semantics.

### Stage 3: Freeze Writes

- Add a periodic writer for cheats that must continually restore values.
- Arbitrate writes correctly for both `rtl/ddram.sv` and `rtl/sdram2.sv`
  backends.
- Preserve normal CPU, DMA, and video memory traffic.

### Stage 4: Broader Coverage and Cleanup

- Add optional coverage for cartridge RAM, backup SRAM, CD RAM, or ST-V memory
  only where real cheats require it.
- Add record limits, reset behavior, and status reporting.
- Test both single-SDRAM and dual-SDRAM builds.

## 5. Stage 1 Proof-of-Concept Goal

The Stage 1 goal is to prove end-to-end delivery and enforcement of one simple
Saturn work-RAM cheat without changing SH-2 cache internals yet:

1. MiSTer loads one cheat record through the standard ioctl cheat download.
2. The root `Saturn.sv` wrapper stores the record.
3. The wrapper applies the replacement to a selected high- or low-work-RAM
   access.
4. A real game visibly reflects the changed value.
5. The test records whether cache effects limit reliability.

Success means the input format, address mapping, and minimal hook are correct.
It does not yet mean that arbitrary Saturn cheats are supported.
