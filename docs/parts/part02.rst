Part 2 - World's Simplest SQL Compiler and Virtual Machine
============================================================

We're making a clone of SQLite. The "front-end" of SQLite is a SQL compiler that parses a string and outputs an internal representation called bytecode.

This bytecode is passed to the virtual machine, which executes it.

Breaking things into two steps like this has a couple advantages:

* Reduces the complexity of each part (e.g. virtual machine does not worry about syntax errors)
* Allows compiling common queries once and caching the bytecode for improved performance

Imports from Phase 01
---------------------

Phase 02 imports the input handling from Phase 01:

.. code-block:: zig

    const phase01 = @import("phase01");
    
    // Use imported types
    var input_buffer = try phase01.InputBuffer.init(allocator);
    phase01.printPrompt();
    phase01.readInput(&input_buffer);

Meta Commands
-------------

Non-SQL statements like ``.exit`` are called "meta-commands". They all start with a dot, so we check for them and handle them in a separate function.

In Zig, we use enums to represent the different possible results:

.. code-block:: zig

    pub const MetaCommandResult = enum {
        success,
        unrecognized_command,
    };

Unlike C, Zig enums are type-safe and the compiler will warn if a switch statement doesn't handle all cases.

Statement Parsing
-----------------

Next, we add a step that converts the line of input into our internal representation of a statement:

.. code-block:: zig

    pub const PrepareResult = enum {
        success,
        syntax_error,
        unrecognized_statement,
    };

    pub const StatementType = enum {
        insert,
        select,
    };

    pub const Statement = struct {
        statement_type: StatementType,
    };

Parser Module
-------------

The complete parser module:

.. literalinclude:: ../../src/phase02/parser.zig
   :language: zig
   :caption: src/phase02/parser.zig
   :linenos:

Unit Tests
----------

Tests validate our parser:

.. literalinclude:: ../../src/phase02/tests.zig
   :language: zig
   :caption: src/phase02/tests.zig
   :linenos:

Main Entry Point
----------------

The main function ties it all together:

.. literalinclude:: ../../src/phase02/main.zig
   :language: zig
   :caption: src/phase02/main.zig
   :linenos:

Let's Try It
------------

.. code-block:: shell

    $ zig build run-phase02
    db > insert foo bar
    This is where we would do an insert.
    Executed.
    db > delete foo
    Unrecognized keyword at start of 'delete foo'.
    db > select
    This is where we would do a select.
    Executed.
    db > .exit

Zig Switch Expressions
----------------------

Unlike C's switch statements, Zig's ``switch`` is an expression that can return values. Combined with enums, the compiler ensures all cases are handled:

.. code-block:: zig

    switch (parser.doMetaCommand(input)) {
        .success => continue,
        .unrecognized_command => {
            stdout.print("Unrecognized command\n", .{}) catch {};
            continue;
        },
    }

If we forgot to handle a case, the compiler would error.

Exports for Next Phase
----------------------

* ``Statement`` - Parsed statement struct
* ``StatementType`` - enum { insert, select }
* ``PrepareResult`` - Parsing result enum
* ``MetaCommandResult`` - Meta command result enum
* ``prepareStatement()`` - Parse input into statement
* ``doMetaCommand()`` - Handle meta commands
* ``isMetaCommand()`` - Check if input starts with '.'

The skeleton of our database is taking shape! In the next part, we'll implement actual ``insert`` and ``select`` operations.

Next: :doc:`part03` - An In-Memory, Append-Only, Single-Table Database
