Part 4 - Our First Tests (and Bugs)
===================================

We've got the ability to insert rows into our database and to print out all
rows. Let's take a moment to test what we've got so far.

In the original C tutorial, tests are written in Ruby using RSpec. In Zig,
we'll use the built-in test framework, which integrates with ``zig build test``.

Input Validation
----------------

Reading through the code we have so far, there are several edge cases we
need to handle:

1. **Table full**: What happens when we try to insert more rows than fit?
2. **Strings too long**: What if username or email exceed their limits?
3. **Negative IDs**: IDs should be positive integers.

Let's add validation:

.. literalinclude:: ../../src/phase04/main.zig
   :language: zig
   :caption: src/phase04/main.zig

Key validations:

- Check if ``id`` is negative and return ``ID must be positive.``
- Check if username length > 32 or email length > 255
- Check for table full condition

Zig's Advantage
---------------

Zig's explicit error handling shines here. Instead of C's approach of
returning magic numbers or setting errno, we use error unions:

.. code-block:: zig

    const PrepareResult = enum {
        success,
        syntax_error,
        string_too_long,
        negative_id,
        unrecognized_statement,
    };

The compiler ensures we handle every case in our switch statements. If we
add a new error variant, the compiler will point out every place we need
to handle it.

Running Phase 4
---------------

.. code-block:: bash

    zig build run-phase04

Try inserting invalid data:

.. code-block:: text

    db > insert -1 cstack foo@bar.com
    ID must be positive.
    db > insert 1 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa a@b.com
    String is too long.

Tests
-----

Our tests verify:

- Basic insert and retrieval works
- Maximum length strings are accepted
- Strings that are too long are rejected
- Negative IDs are rejected

.. literalinclude:: ../../src/phase04/tests.zig
   :language: zig
   :caption: src/phase04/tests.zig

Run tests with:

.. code-block:: bash

    zig build test

Now would be a great time to add persistence. Next we'll save our database
to a file and read it back out again. It's gonna be great.
