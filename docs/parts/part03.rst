Part 3 - An In-Memory, Append-Only, Single-Table Database
=========================================================

We're going to start small by putting a lot of limitations on our database.
For now, it will:

- support two operations: inserting a row and printing all rows
- reside only in memory (no persistence to disk)
- support a single, hard-coded table

Our hard-coded table is going to store users and look like this:

+----------+--------------+
| column   | type         |
+==========+==============+
| id       | integer      |
+----------+--------------+
| username | varchar(32)  |
+----------+--------------+
| email    | varchar(255) |
+----------+--------------+

This is a simple schema, but it gets us to support multiple data types and
multiple sizes of text data types.

``insert`` statements now look like this:

.. code-block:: text

    insert 1 cstack foo@bar.com

The Row Structure
-----------------

We store rows in a compact binary format. Our ``Row`` struct in Zig:

- ``id``: u32 (4 bytes)
- ``username``: 33 bytes (32 chars + null terminator)
- ``email``: 256 bytes (255 chars + null terminator)

The serialized layout:

+----------+--------------+--------------+
| column   | size (bytes) | offset       |
+==========+==============+==============+
| id       | 4            | 0            |
+----------+--------------+--------------+
| username | 33           | 4            |
+----------+--------------+--------------+
| email    | 256          | 37           |
+----------+--------------+--------------+
| total    | 293          |              |
+----------+--------------+--------------+

.. literalinclude:: ../../src/phase03/row.zig
   :language: zig
   :caption: src/phase03/row.zig

Key Zig features:

- **@sizeOf**: Compile-time size calculation
- **Fixed arrays**: ``[32]u8`` instead of ``char[32]``
- **@memcpy**: Safe memory copy with compile-time size checking
- **std.mem.bytesToValue**: Safe type punning for deserialization

Page-Based Storage
------------------

We store rows in blocks of memory called pages:

- Each page is 4096 bytes (same as OS virtual memory page)
- Rows are serialized into a compact representation
- Pages are only allocated as needed

.. literalinclude:: ../../src/phase03/lib.zig
   :language: zig
   :caption: src/phase03/lib.zig

We use 4 KB pages because it's the same size as a page used in the virtual
memory systems of most computer architectures. This means one page in our
database corresponds to one page used by the operating system.

Main with Table
---------------

.. literalinclude:: ../../src/phase03/main.zig
   :language: zig
   :caption: src/phase03/main.zig

Running Phase 3
---------------

.. code-block:: bash

    zig build run-phase03

With those changes we can actually save data in our database!

.. code-block:: text

    ~ zig build run-phase03
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
    ~

Now would be a great time to write some tests. We'll address that in the next
part.

Tests
-----

.. literalinclude:: ../../src/phase03/tests.zig
   :language: zig
   :caption: src/phase03/tests.zig
