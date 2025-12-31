Part 4 - Our First Tests (and Bugs)
====================================

We've been adding capabilities to insert rows and print them out. Let's add some tests and fix bugs.

In the original C tutorial, rspec tests were used. In Zig, we'll use the built-in test framework for unit tests, and the executables can be tested interactively.

Imports from Previous Phases
----------------------------

Phase 04 imports from all previous phases:

.. code-block:: zig

    const phase01 = @import("phase01");  // Input handling
    const phase02 = @import("phase02");  // Meta commands
    const phase03 = @import("phase03");  // Row, Table

Validation Module
-----------------

We need to validate input before inserting:

1. **Negative IDs**: The id should be positive
2. **Long strings**: Username and email have maximum lengths

Extended ``prepareInsert`` with validation:

.. literalinclude:: ../../src/phase04/validation.zig
   :language: zig
   :caption: src/phase04/validation.zig
   :linenos:

Key Validation Logic
~~~~~~~~~~~~~~~~~~~~

.. code-block:: zig

    // Parse ID - check for negative
    const signed_id = std.fmt.parseInt(i64, id_str, 10) catch return .syntax_error;
    if (signed_id < 0) {
        return .negative_id;
    }
    
    // Parse username - check length
    if (username.len > phase03.COLUMN_USERNAME_SIZE) {
        return .string_too_long;
    }

Unit Tests
----------

Comprehensive tests for validation edge cases:

.. literalinclude:: ../../src/phase04/tests.zig
   :language: zig
   :caption: src/phase04/tests.zig
   :linenos:

Main Entry Point
----------------

.. literalinclude:: ../../src/phase04/main.zig
   :language: zig
   :caption: src/phase04/main.zig
   :linenos:

Let's Try It
------------

.. code-block:: shell

    $ zig build run-phase04
    db > insert -1 user foo@bar.com
    ID must be positive.
    db > insert 1 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa foo@bar.com
    String is too long.
    db > insert 1 alice alice@example.com
    Executed.
    db > select
    (1, alice, alice@example.com)
    Executed.
    db > .exit

Running Tests
~~~~~~~~~~~~~

.. code-block:: shell

    $ zig build test-phase04
    All 8 tests passed.

Test Cases Covered
------------------

1. Valid input accepted
2. Negative ID rejected
3. Username too long rejected
4. Max-length username accepted
5. Missing fields rejected
6. Non-numeric ID rejected
7. Select statement recognized
8. Unknown statement rejected

Exports for Next Phase
----------------------

* ``PrepareResult`` - Extended with ``negative_id``, ``string_too_long``
* ``Statement`` - With validated row data
* ``prepareInsert()`` - With full validation
* ``prepareStatement()`` - Delegates to prepareInsert for inserts

Zig vs C: Type Safety
---------------------

In C, we would check return values manually. In Zig, the type system enforces error handling:

.. code-block:: zig

    switch (validation.prepareStatement(input, &statement)) {
        .success => {},
        .negative_id => {
            stdout.print("ID must be positive.\n", .{}) catch {};
            continue;
        },
        .string_too_long => {
            stdout.print("String is too long.\n", .{}) catch {};
            continue;
        },
        // ... all cases must be handled
    }

If we add a new error case to ``PrepareResult``, the compiler will force us to handle it everywhere.

Next: :doc:`part05` - Persistence to Disk
