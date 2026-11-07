---
name: principle-boundary-discipline
description: Validate at the edge and trust internal types. Used by kevbot when wiring CLI, config, network, or framework adapters.
user-invocable: false
---

# Boundary discipline

Parse, validate, and handle errors where data enters the system:
CLI args, config, HTTP, RPC, files, env. Inside, trust the type.

Do not re-check the same fact three layers down. Do not leak
transport or framework types through the public surface. Business
logic is a pure function of already-valid values.

The test: if this value is not crossing a boundary right now, a
guard here is noise.
