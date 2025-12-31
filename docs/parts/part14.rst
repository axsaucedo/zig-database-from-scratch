Part 14 - Splitting Internal Nodes
===================================

The final major piece! When an internal node is full, we split it just like we
split leaf nodes. This enables trees of arbitrary depth.

When Does This Happen?
----------------------

With ``INTERNAL_NODE_MAX_CELLS = 3``, after adding the 4th child to an internal
node, we must split. Consider this example:

.. code-block:: text

    Before (internal node is full with 3 keys):
    
              [5 | 10 | 15]         <- 3 keys, 4 children
             /   |    |    \
          [1-5] [6-10] [11-15] [16-20]
    
    After adding a 5th child (triggers split):
    
                  [10]               <- new root
                 /    \
           [5]          [15]         <- two internal nodes
          /   \        /    \
       [1-5] [6-10] [11-15] [16-20]

The Algorithm
-------------

Splitting an internal node:

1. Create a sibling node to store (n-1)/2 of the original node's keys
2. Move these keys from the original node to the sibling
3. The middle key moves UP to the parent
4. Update the parent (may trigger recursive split!)

The ``splitting_root`` Flag
---------------------------

We need to track whether we're splitting the root node:

- **If splitting root**: Create a new root with ``create_new_root()``
- **If not splitting root**: Insert the new sibling into the existing parent

This distinction is important because when splitting the root, the new root
is already set up to contain both children. When splitting a non-root, we
need to insert the sibling into the parent after splitting.

Implementation
--------------

.. literalinclude:: ../../src/phase14/lib.zig
   :language: zig
   :caption: src/phase14/lib.zig
   :lines: 81-155

Key steps in ``internalNodeSplitAndInsert``:

1. Save the old node's max key (needed to update parent later)
2. If splitting root, call ``createNewRoot()``
3. Move right child and half the keys to the new sibling
4. Update parent pointers for moved children
5. Insert the triggering child into the appropriate node
6. Update the old node's key in the parent
7. If not splitting root, insert sibling into parent (may recurse!)

Updating ``createNewRoot``
--------------------------

When the old root was an internal node (not a leaf), we need to:

1. Initialize both children as internal nodes
2. Copy all content to the left child
3. Update parent pointers for all the left child's children

.. code-block:: zig

    if (getNodeType(root) == .internal) {
        initializeInternalNode(right_child);
        initializeInternalNode(left_child);
    }

    // Copy root to left child
    @memcpy(left_child, root);
    setNodeRoot(left_child, false);

    // Update parent pointers for left child's children
    if (getNodeType(left_child) == .internal) {
        for (0..internalNodeNumKeys(left_child).*) |i| {
            const child = getPage(pager, internalNodeChild(left_child, i).*);
            nodeParent(child).* = left_child_page_num;
        }
        const right = getPage(pager, internalNodeRightChild(left_child).*);
        nodeParent(right).* = left_child_page_num;
    }

The ``INVALID_PAGE_NUM`` Sentinel
---------------------------------

We define a sentinel value for empty internal nodes:

.. code-block:: zig

    const INVALID_PAGE_NUM: u32 = std.math.maxInt(u32);

When an internal node is initialized, its right child is set to
``INVALID_PAGE_NUM`` to indicate it's empty. This prevents a subtle bug where
an uninitialized right child might be 0 (the root page number).

Main with Full B-Tree
---------------------

.. literalinclude:: ../../src/phase14/main.zig
   :language: zig
   :caption: src/phase14/main.zig

Running Phase 14
----------------

.. code-block:: bash

    zig build run-phase14 -- mydb.db

Insert 64 rows to create a 3-level tree:

.. code-block:: text

    db > .btree
    Tree:
    - internal (size 1)
      - internal (size 2)
        - leaf (size 7)
          - 1 through 7
        - key 8
        - leaf (size 11)
          ...
        - key 22
        - leaf (size 8)
          ...
      - key 35
      - internal (size 3)
        - leaf (size 12)
          ...

Congratulations!
----------------

You now have a fully functional B-Tree implementation that can:

- **Insert** records in O(log n) time
- **Search** records in O(log n) time  
- **Scan** all records efficiently using leaf sibling pointers
- **Persist** to disk
- **Handle arbitrary tree depth** through recursive internal node splitting

Tests
-----

.. literalinclude:: ../../src/phase14/tests.zig
   :language: zig
   :caption: src/phase14/tests.zig
