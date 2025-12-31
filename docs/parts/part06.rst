Part 6 - The Cursor Abstraction
================================

This should be a shorter part than the last one. We're just going to refactor
a bit to make it easier to start the B-Tree implementation.

We're going to add a ``Cursor`` object which represents a location in the table.
Things you might want to do with cursors:

- Create a cursor at the beginning of the table
- Create a cursor at the end of the table
- Access the row the cursor is pointing to
- Advance the cursor to the next row

Those are the behaviors we're going to implement now. Later, we will also want
to:

- Delete the row pointed to by a cursor
- Modify the row pointed to by a cursor
- Search a table for a given ID, and create a cursor pointing to the row with
  that ID

The Cursor
----------

.. literalinclude:: ../../src/phase06/cursor.zig
   :language: zig
   :caption: src/phase06/cursor.zig

The cursor has:

- ``page_num``: Which page we're on
- ``cell_num``: Which cell/row within the page
- ``end_of_table``: Boolean indicating we're past the last row

Given our current table data structure, all you need to identify a location in
a table is the row number (which we convert to page_num + cell_num).

A cursor also has a reference to the table it's part of, so our cursor functions
can take just the cursor as a parameter.

Cursor Operations
-----------------

Key operations:

- ``tableStart()``: Creates a cursor at row 0
- ``tableEnd()``: Creates a cursor one past the last row (for inserting)
- ``value()``: Returns a pointer to the current row's data
- ``advance()``: Moves to the next row

This will become more complicated with a B-tree, but for now advancing the
cursor is as simple as incrementing the row number.

Main with Cursor
----------------

.. literalinclude:: ../../src/phase06/main.zig
   :language: zig
   :caption: src/phase06/main.zig

The changes to the VM (Virtual Machine) methods:

**Insert**: We open a cursor at the end of table, write to that cursor location,
then advance.

**Select**: We open a cursor at the start of the table, print the row, then
advance the cursor to the next row. Repeat until we've reached the end of the
table.

Running Phase 6
---------------

.. code-block:: bash

    zig build run-phase06 -- mydb.db

The cursor abstraction doesn't change external behavior but enables future
improvements. ``execute_select()`` and ``execute_insert()`` can interact with
the table entirely through the cursor without assuming anything about how the
table is stored.

Like I said, this was a shorter refactor that should help us as we rewrite
our table data structure into a B-Tree.

Tests
-----

.. literalinclude:: ../../src/phase06/tests.zig
   :language: zig
   :caption: src/phase06/tests.zig
