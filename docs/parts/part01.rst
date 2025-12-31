Part 1 - Introduction and Setting up the REPL
==============================================

As developers, we use relational databases every day, but they're often a black
box to us. Some questions we might have:

- What format is data saved in? (in memory and on disk)
- When does it move from memory to disk?
- Why can there only be one primary key per table?
- How does rolling back a transaction work?
- How are indexes formatted?
- When and how does a full table scan happen?
- What format is a prepared statement saved in?

In other words, how does a database **work**?

To figure things out, we're writing a database from scratch. It's modeled off
SQLite because it is designed to be small with fewer features than MySQL or
PostgreSQL, so we have a better hope of understanding it. The entire database
is stored in a single file!

SQLite Architecture
-------------------

A query goes through a chain of components in order to retrieve or modify data.
The **front-end** consists of the:

- tokenizer
- parser
- code generator

The input to the front-end is a SQL query. The output is virtual machine bytecode.

The **back-end** consists of the:

- virtual machine
- B-tree
- pager
- OS interface

The **virtual machine** takes bytecode as instructions. It can then perform
operations on one or more tables or indexes, each of which is stored in a data
structure called a B-tree.

Each **B-tree** consists of many nodes. Each node is one page in length. The
B-tree can retrieve a page from disk or save it back to disk by issuing commands
to the pager.

The **pager** receives commands to read or write pages of data. It is responsible
for reading/writing at appropriate offsets in the database file. It also keeps a
cache of recently-accessed pages in memory.

Making a Simple REPL
--------------------

SQLite starts a read-execute-print loop when you start it from the command line:

.. code-block:: text

    ~ sqlite3
    SQLite version 3.16.0 2016-11-04 19:09:39
    Enter ".help" for usage hints.
    sqlite> create table users (id int, username varchar(255), email varchar(255));
    sqlite> .tables
    users
    sqlite> .exit
    ~

To do that, our main function will have an infinite loop that:

1. Prints a prompt (``db >``)
2. Reads a line of input
3. Processes that line of input

The Input Buffer
----------------

In C, we would use ``getline()`` to read input. In Zig, we create an ``InputBuffer``
struct that wraps an ``ArrayListUnmanaged`` for dynamic input handling:

.. literalinclude:: ../../src/phase01/input.zig
   :language: zig
   :caption: src/phase01/input.zig

Key differences from C:

- **Explicit memory management**: We use Zig's allocator interface instead of
  implicit malloc/free
- **Error handling**: Zig's error unions (``!``) make errors explicit
- **No null terminators**: Zig slices know their length, no need for null bytes

The ``printPrompt()`` function prints a prompt to the user, and ``readInput()``
reads bytes from stdin until a newline is encountered.

Main REPL Loop
--------------

The main function sets up the allocator and runs the REPL:

.. literalinclude:: ../../src/phase01/main.zig
   :language: zig
   :caption: src/phase01/main.zig

Key Zig concepts:

- **GeneralPurposeAllocator**: A safe default allocator with leak detection
- **defer**: Ensures cleanup happens when leaving scope
- **std.mem.eql**: Safe slice comparison (no buffer overflows)

Finally, we parse and execute the command. There is only one recognized command
right now: ``.exit``, which terminates the program. Otherwise we print an error
message and continue the loop.

Running Phase 1
---------------

.. code-block:: bash

    zig build run-phase01

Let's try it out:

.. code-block:: text

    ~ zig build run-phase01
    Phase 01: Basic REPL
    Type '.exit' to quit.

    db > .tables
    Unrecognized command '.tables'.
    db > .exit
    ~

Alright, we've got a working REPL. In the next part, we'll start developing our
command language.

Tests
-----

.. literalinclude:: ../../src/phase01/tests.zig
   :language: zig
   :caption: src/phase01/tests.zig
