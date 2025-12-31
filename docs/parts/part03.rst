Part 3 - An In-Memory, Append-Only, Single-Table Database
==========================================================

We're going to start small by putting a lot of limitations on our database. For now, it will:

* Support two operations: inserting a row and printing all rows
* Reside only in memory (no persistence to disk)
* Support a single, hard-coded table

Our hard-coded table is going to store users and look like this:

+-----------+--------------+
| column    | type         |
+===========+==============+
| id        | integer      |
+-----------+--------------+
| username  | varchar(32)  |
+-----------+--------------+
| email     | varchar(255) |
+-----------+--------------+

This is a simple schema, but it gets us to supporting multiple data types and multiple sizes of text data types.

Row Structure
-------------

In Zig, we define our Row as a struct with fixed-size arrays:

.. code-block:: zig

    pub const COLUMN_USERNAME_SIZE: usize = 32;
    pub const COLUMN_EMAIL_SIZE: usize = 255;

    pub const Row = struct {
        id: u32,
        username: [COLUMN_USERNAME_SIZE + 1]u8,
        email: [COLUMN_EMAIL_SIZE + 1]u8,
    };

We allocate one extra byte for the null terminator to maintain compatibility with C-style strings when needed.

Serialization
-------------

We need to copy the row data into a compact format that can be stored in a page:

+----------+--------------+---------+
| column   | size (bytes) | offset  |
+==========+==============+=========+
| id       | 4            | 0       |
+----------+--------------+---------+
| username | 33           | 4       |
+----------+--------------+---------+
| email    | 256          | 37      |
+----------+--------------+---------+
| total    | 293          |         |
+----------+--------------+---------+

Row Module
----------

The Row module defines serialization and deserialization:

.. literalinclude:: ../../src/phase03/row.zig
   :language: zig
   :caption: src/phase03/row.zig
   :linenos:

Table Structure
---------------

Pages are allocated on demand. Our table uses page-based storage:

.. code-block:: zig

    pub const PAGE_SIZE: usize = 4096;
    pub const TABLE_MAX_PAGES: usize = 100;
    pub const ROWS_PER_PAGE: usize = PAGE_SIZE / ROW_SIZE;
    pub const TABLE_MAX_ROWS: usize = ROWS_PER_PAGE * TABLE_MAX_PAGES;

Table Module
------------

.. literalinclude:: ../../src/phase03/table.zig
   :language: zig
   :caption: src/phase03/table.zig
   :linenos:

Module Root
-----------

The lib.zig file re-exports all types for use by downstream phases:

.. literalinclude:: ../../src/phase03/lib.zig
   :language: zig
   :caption: src/phase03/lib.zig
   :linenos:

Unit Tests
----------

Tests validate serialization and table operations:

.. literalinclude:: ../../src/phase03/tests.zig
   :language: zig
   :caption: src/phase03/tests.zig
   :linenos:

Main Entry Point
----------------

The main function now implements actual insert and select:

.. literalinclude:: ../../src/phase03/main.zig
   :language: zig
   :caption: src/phase03/main.zig
   :linenos:

Let's Try It
------------

.. code-block:: shell

    $ zig build run-phase03
    db > insert 1 cstack foo@bar.com
    Executed.
    db > insert 2 bob bob@example.com
    Executed.
    db > select
    (1, cstack, foo@bar.com)
    (2, bob, bob@example.com)
    Executed.
    db > insert foo bar 1
    Syntax error. Could not parse statement.
    db > .exit

We now have persistence! ...Just kidding. The data is only in memory.

Exports for Next Phase
----------------------

* ``Row`` - Database row struct
* ``Table`` - Page-based table storage
* ``serializeRow()`` / ``deserializeRow()`` - Convert to/from bytes
* ``printRow()`` - Print row to stdout
* Size constants: ``ROW_SIZE``, ``TABLE_MAX_ROWS``, etc.

Now would be a great time to write some tests, for a couple reasons:

* We're planning to dramatically change the data structure storing our table, and tests would catch regressions.
* There are a couple edge cases we haven't tested manually (e.g. filling up the table)

We'll address those issues in the next part.

Next: :doc:`part04` - Our First Tests (and Bugs)
