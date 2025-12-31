Part 12 - Scanning a Multi-Level B-Tree
========================================

We now support constructing a multi-level btree, but we've broken ``select``
statements in the process. Here's a test case that inserts 15 rows and then
tries to print them.

The Problem
-----------

What actually happens:

.. code-block:: text

    db > select
    (2, user1, person1@example.com)
    Executed.

That's weird. It's only printing one row, and that row looks corrupted!

The issue is that ``execute_select()`` begins at the start of the table, and
our current implementation of ``table_start()`` returns cell 0 of the root
node. But the root of our tree is now an internal node which doesn't contain
any rows.

With 15 entries, our tree structure looks like:

.. code-block:: text

    - internal (size 1)
      - leaf (size 7)     <- rows 1-7
      - key 7
      - leaf (size 8)     <- rows 8-15

But ``select`` only scans the first leaf and stops!

The Solution: Next Leaf Pointer
-------------------------------

Each leaf stores a pointer to its sibling:

- ``next_leaf``: Page number of the next leaf (0 = no sibling)

We update the leaf node header to include this field:

.. code-block:: zig

    const LEAF_NODE_NEXT_LEAF_SIZE: usize = @sizeOf(u32);
    const LEAF_NODE_NEXT_LEAF_OFFSET = LEAF_NODE_NUM_CELLS_OFFSET + LEAF_NODE_NUM_CELLS_SIZE;
    const LEAF_NODE_HEADER_SIZE = COMMON_NODE_HEADER_SIZE +
                                  LEAF_NODE_NUM_CELLS_SIZE +
                                  LEAF_NODE_NEXT_LEAF_SIZE;

Cursor Advancement
------------------

.. literalinclude:: ../../src/phase12/lib.zig
   :language: zig
   :caption: src/phase12/lib.zig
   :lines: 45-92

Key change in ``advance()``:

1. Increment cell_num
2. If past end of current leaf, check ``next_leaf``
3. If ``next_leaf != 0``, jump to sibling leaf
4. Otherwise, set ``end_of_table = true``

Updating Split Logic
--------------------

When splitting a leaf node, update the sibling pointers:

- New leaf's ``next_leaf`` = old leaf's ``next_leaf``
- Old leaf's ``next_leaf`` = new leaf's page number

This maintains the linked list of leaves for scanning.

Main with Multi-Level Scan
--------------------------

.. literalinclude:: ../../src/phase12/main.zig
   :language: zig
   :caption: src/phase12/main.zig

Running Phase 12
----------------

.. code-block:: bash

    zig build run-phase12 -- mydb.db

Now select returns all 15 rows:

.. code-block:: text

    db > select
    (1, user1, person1@example.com)
    (2, user2, person2@example.com)
    ...
    (15, user15, person15@example.com)
    Executed.

Whew! One bug after another, but we're making progress.

Tests
-----

.. literalinclude:: ../../src/phase12/tests.zig
   :language: zig
   :caption: src/phase12/tests.zig
