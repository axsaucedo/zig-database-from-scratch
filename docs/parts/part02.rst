Part 2 - World's Simplest SQL Compiler and Virtual Machine
==========================================================

We're making a clone of SQLite. The "front-end" of SQLite is a SQL compiler that
parses a string and outputs an internal representation called bytecode.

This bytecode is passed to the virtual machine, which executes it.

Breaking things into two steps like this has a couple advantages:

- Reduces the complexity of each part (e.g. virtual machine does not worry about
  syntax errors)
- Allows compiling common queries once and caching the bytecode for improved
  performance

With this in mind, let's refactor our ``main`` function and support two new
keywords in the process.

Meta-Commands vs SQL Statements
-------------------------------

Non-SQL statements like ``.exit`` are called "meta-commands". They all start with
a dot, so we check for them and handle them in a separate function.

Next, we add a step that converts the line of input into our internal representation
of a statement. This is our hacky version of the SQLite front-end.

Lastly, we pass the prepared statement to ``execute_statement``. This function will
eventually become our virtual machine.

The Parser
----------

We use enums for result codes. Zig enums are type-safe and the compiler will warn
if we don't handle all cases in a switch:

.. literalinclude:: ../../src/phase02/parser.zig
   :language: zig
   :caption: src/phase02/parser.zig

Notice that we use ``strncmp`` logic for "insert" (checking the first 6 characters)
since the "insert" keyword will be followed by data (e.g. ``insert 1 cstack foo@bar.com``).

Key Zig features:

- **Enums**: Type-safe result codes that replace C's #define constants
- **std.mem.eql**: Safe string comparison
- **Slice syntax**: ``input[0..6]`` for substring access with bounds checking

Main with Parsing
-----------------

The main loop now routes commands appropriately:

.. literalinclude:: ../../src/phase02/main.zig
   :language: zig
   :caption: src/phase02/main.zig

The flow is:

1. Check if input starts with ``.`` (meta-command)
2. If meta-command, handle it specially
3. Otherwise, try to parse as SQL statement
4. Execute the statement (currently just prints a message)

Running Phase 2
---------------

.. code-block:: bash

    zig build run-phase02

With these refactors, we now recognize two new keywords:

.. code-block:: text

    ~ zig build run-phase02
    db > insert foo bar
    Executed.
    db > delete foo
    Unrecognized keyword.
    db > select
    Executed.
    db > .tables
    Unrecognized command '.tables'
    db > .exit
    ~

The skeleton of our database is taking shape... wouldn't it be nice if it stored
data? In the next part, we'll implement ``insert`` and ``select``, creating the
world's worst data store.

Tests
-----

.. literalinclude:: ../../src/phase02/tests.zig
   :language: zig
   :caption: src/phase02/tests.zig
