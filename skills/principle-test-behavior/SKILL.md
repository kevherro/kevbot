---
name: principle-test-behavior
description: A test asserts what callers can observe; it fails when behavior breaks and survives a refactor. Used by kevbot when writing, changing, or keeping a test.
user-invocable: false
---

# Test behavior

Each test asserts something on behalf of the code's consumers: a
caller, a person, another service. Consumers see outputs, raised
errors, state they can query later, and side effects beyond the
process (an outbound request, a stored row, a published event).
They do not observe private helpers, internal call order, or which
collaborator did the work.

Run two thought experiments on every test you write or keep.

1. **Break it.** Return a wrong value, drop an effect, or do it
   twice. A test that still passes proves nothing. Usual causes: a
   check weaker than what is promised, an expected value produced by the
   very code being tested, a copied constant that never exercises
   the code that reads it, an assertion on fixture data the test
   built itself.
2. **Restructure it.** Keep every observable result and change the
   internals. A test that now fails is pinned to the implementation.
   It costs a rewrite on every refactor and catches nothing.

Keep tests that fail the first and pass the second. Fix or delete
the rest.

To write one: drive the public interface with a concrete input.
Take the expected value from the requirement, not from running the
code. Assert exactly what the contract promises.

The contract decides what counts. If the promise is "an empty cart
is never charged", asserting zero calls to the payment client is
behavior. Add a sibling case that does charge, proving the test
would notice a call. The payload an external service receives is
behavior. A call to an internal helper is not. The error type
callers branch on is contract. The exact message text usually is
not.

An invariant can be the behavior: two stores that must agree on a
key, or a type assertion that must compile.
