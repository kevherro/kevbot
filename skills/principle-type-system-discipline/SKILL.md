---
name: principle-type-system-discipline
description: Make illegal states unrepresentable and refuse to lie to the compiler. Used by kevbot when designing types or signatures.
user-invocable: false
---

# Type system discipline

The type checker is a proof assistant. Prefer constructions that
cannot hold a bad value over runtime handlers for that value.

Brand primitives that mean different things. Parse untrusted
input at the boundary; do not cast it into the model. Match
variants so a new case is a compile error. Derive types from the
schema that owns the shape.

Strengthen a type only where the code would otherwise panic or
lie. A comment that explains when a field combination is valid
means the type is too loose. Split it.
