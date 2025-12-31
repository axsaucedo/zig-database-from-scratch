Part 10 - Splitting a Leaf Node
================================

Our B-Tree doesn't feel like much of a tree with only one node. To fix that,
we need some code to split a leaf node in twain. And after that, we need to
create an internal node to serve as a parent for the two leaf nodes.

Basically our goal for this article is to go from this:

.. code-block:: text

    [ 1 | 2 | 3 | ... | 13 ]   <- single leaf node

to this:

.. code-block:: text

           [7]                 <- new internal root
          /   \
    [1..7]     [8..13]         <- two leaf nodes

The Split Algorithm
-------------------

From *SQLite Database System: Design and Implementation*:

    If there is no space on the leaf node, we would split the existing entries
    and the new one into two equal halves: lower and upper halves. We allocate
    a new leaf node, and move the upper half into the new node.

Steps:

1. Create a new leaf node
2. Move half the cells to the new node
3. Insert the new cell in the appropriate node
4. If splitting the root, create a new internal root node
5. Otherwise, update the parent (next part)

.. literalinclude:: ../../src/phase10/split.zig
   :language: zig
   :caption: src/phase10/split.zig

Allocating New Pages
--------------------

We add ``getUnusedPageNum()`` to find the next available page:

.. code-block:: zig

    pub fn getUnusedPageNum(pager: *Pager) u32 {
        return pager.num_pages;
    }

For now, we assume pages 0..N-1 are allocated and N is the next free page.
Later, after we implement deletion, we could recycle freed pages.

Internal Node Format
--------------------

When we split the root, we create an internal node. Internal nodes have:

- Common header (6 bytes)
- Number of keys (4 bytes)
- Right child pointer (4 bytes)
- Body: array of (child pointer, key) pairs

Each key is the maximum key contained in its left child.

Lib with Splitting
------------------

.. literalinclude:: ../../src/phase10/lib.zig
   :language: zig
   :caption: src/phase10/lib.zig

Creating a New Root
-------------------

When we split the root, we:

1. Copy the old root to a new page (becomes left child)
2. Allocate the right child (already done during split)
3. Reinitialize the root page as an internal node
4. Set up the root to point to both children

Main with Splitting
-------------------

.. literalinclude:: ../../src/phase10/main.zig
   :language: zig
   :caption: src/phase10/main.zig

Running Phase 10
----------------

.. code-block:: bash

    zig build run-phase10 -- mydb.db

Insert enough rows to trigger a split:

.. code-block:: text

    db > insert 1 user1 user1@test.com
    ...
    db > insert 14 user14 user14@test.com
    db > .btree
    Tree:
    - internal (size 1)
      - leaf (size 7)
        - 1
        - 2
        - 3
        - 4
        - 5
        - 6
        - 7
      - key 7
      - leaf (size 7)
        - 8
        - 9
        - 10
        - 11
        - 12
        - 13
        - 14

Our leaf node can hold 13 cells. When we try to insert the 14th, we split!

A Major Problem
---------------

If you try to insert a 15th row:

.. code-block:: text

    db > insert 15 user15 person15@example.com
    Need to implement searching an internal node

We'll fix this next time by implementing search on multi-level trees.

Tests
-----

.. literalinclude:: ../../src/phase10/tests.zig
   :language: zig
   :caption: src/phase10/tests.zig
