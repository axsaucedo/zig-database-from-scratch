Part 11 - Recursively Searching the B-Tree
===========================================

Last time we ended with an error inserting our 15th row:

.. code-block:: text

    db > insert 15 user15 person15@example.com
    Need to implement searching an internal node

Now we implement recursive searching through internal nodes.

The Problem
-----------

With a multi-level tree, ``table_find()`` may encounter an internal node as
the root. We need to recursively descend the tree to find the correct leaf.

Internal Node Binary Search
---------------------------

We implement binary search on internal nodes to find which child contains a
given key. Remember that each key in an internal node represents the maximum
key in its left child:

.. code-block:: text

         [7 | 15]          <- internal node with keys 7 and 15
        /    |    \
    [1-7] [8-15] [16-20]   <- children

To find key 10, we:

1. Compare 10 with 7: 10 > 7, so go right
2. Compare 10 with 15: 10 <= 15, so use middle child
3. Search the middle child (leaf node) for key 10

.. literalinclude:: ../../src/phase11/lib.zig
   :language: zig
   :caption: src/phase11/lib.zig
   :lines: 1-65

Recursive Find
--------------

The ``internalNodeFind`` function:

1. Binary search to find the correct child index
2. Get the child page
3. If child is a leaf: use ``leafNodeFind()``
4. If child is internal: recurse with ``internalNodeFind()``

.. code-block:: zig

    fn internalNodeFind(table: *Table, page_num: u32, key: u32) !Cursor {
        const node = try pager.getPage(table.pager, page_num);
        const child_index = internalNodeFindChild(node, key);
        const child_num = internalNodeChild(node, child_index).*;
        const child = try pager.getPage(table.pager, child_num);

        return switch (getNodeType(child)) {
            .leaf => leafNodeFind(table, child_num, key),
            .internal => internalNodeFind(table, child_num, key),
        };
    }

Main with Recursive Search
--------------------------

.. literalinclude:: ../../src/phase11/main.zig
   :language: zig
   :caption: src/phase11/main.zig

Running Phase 11
----------------

.. code-block:: bash

    zig build run-phase11 -- mydb.db

Now inserting a key into a multi-node btree works:

.. code-block:: text

    db > insert 15 user15 person15@example.com
    Executed.

But there's still a problem. Let's try inserting 1400 rows... it fails with:

.. code-block:: text

    Need to implement updating parent after split

Looks like that's next on our to-do list!

Tests
-----

.. literalinclude:: ../../src/phase11/tests.zig
   :language: zig
   :caption: src/phase11/tests.zig
