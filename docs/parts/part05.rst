Part 5 - Persistence to Disk
============================

    "Nothing in the world can take the place of persistence." -- Calvin Coolidge

Our database lets you insert records and read them back out, but only as long
as you keep the program running. If you kill the program and start it back up,
all your records are gone.

Like SQLite, we're going to persist records by saving the entire database to
a file. We already set ourselves up to do that by serializing rows into
page-sized memory blocks. To add persistence, we can simply write those blocks
of memory to a file, and read them back into memory the next time the program
starts up.

The Pager Abstraction
---------------------

To make this easier, we introduce the **Pager** abstraction. We ask the pager
for page number ``x``, and the pager gives us back a block of memory. It first
looks in its cache. On a cache miss, it copies data from disk into memory (by
reading the database file).

The Pager accesses the page cache and the file. The Table object makes requests
for pages through the pager:

.. literalinclude:: ../../src/phase05/pager.zig
   :language: zig
   :caption: src/phase05/pager.zig

Key operations:

- ``pagerOpen(filename)``: Opens the database file and initializes the pager
- ``getPage(page_num)``: Returns a page, loading from disk if needed
- ``pagerFlush(page_num)``: Writes a dirty page to disk
- ``pagerClose()``: Flushes all pages and closes the file

File Operations
---------------

We use Zig's ``std.fs`` for file operations:

- ``std.fs.cwd().createFile()`` or ``openFile()`` for file access
- ``file.seekTo()`` for seeking to page offsets
- ``file.read()`` and ``file.write()`` for I/O

Zig's explicit error handling ensures we never silently ignore file errors.

Opening the Database
--------------------

The ``db_open()`` function now:

1. Opens the database file (creating if needed)
2. Initializes the pager
3. Calculates how many rows exist based on file size

Main with Persistence
---------------------

.. literalinclude:: ../../src/phase05/main.zig
   :language: zig
   :caption: src/phase05/main.zig

Running Phase 5
---------------

.. code-block:: bash

    zig build run-phase05 -- mydb.db

With these changes, we're able to close then reopen the database, and our
records are still there!

.. code-block:: text

    ~ zig build run-phase05 -- mydb.db
    db > insert 1 cstack foo@bar.com
    Executed.
    db > insert 2 voltorb volty@example.com
    Executed.
    db > .exit
    ~
    ~ zig build run-phase05 -- mydb.db
    db > select
    (1, cstack, foo@bar.com)
    (2, voltorb, volty@example.com)
    Executed.
    db > .exit
    ~

Examining the File
------------------

For extra fun, let's look at how our data is stored. You can use a hex editor:

The first four bytes are the id of the first row (4 bytes because we store a
``u32``). It's stored in little-endian byte order on most machines.

The next 33 bytes store the username as a null-terminated string. The next 256
bytes store the email in the same way.

Conclusion
----------

We've got persistence. It's not the greatest. For example if you kill the
program without typing ``.exit``, you lose your changes. Additionally, we're
writing all pages back to disk, even pages that haven't changed since we read
them from disk. These are issues we can address later.

Next time we'll introduce cursors, which should make it easier to implement
the B-tree.

Tests
-----

.. literalinclude:: ../../src/phase05/tests.zig
   :language: zig
   :caption: src/phase05/tests.zig
