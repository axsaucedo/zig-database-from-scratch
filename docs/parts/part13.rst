Part 13 - Updating Parent Node After a Split
==============================================

For the next step on our epic B-tree implementation journey, we're going to
handle fixing up the parent node after splitting a leaf. Consider this example:

.. code-block:: text

    Before adding key "3":          After split:
    
        [Parent: key=5]                [Parent: key=3, key=5]
             |                              /           \
        [1,2,3,4,5]  <- full!          [1,2,3]        [4,5]

The Algorithm
-------------

When we split a leaf that is NOT the root, we need to:

1. **Update the key in parent**: Change from ``old_max`` (5) to ``new_max`` (3)
2. **Insert new child/key pair**: Add a pointer to the new right leaf with its
   max key (5)

First things first, we need each node to know its parent. We add a function to
access the parent pointer stored in the common node header:

.. code-block:: zig

    pub fn nodeParent(node: []u8) *u32 {
        return @ptrCast(@alignCast(&node[PARENT_POINTER_OFFSET]));
    }

Finding the Affected Cell
-------------------------

We need to find which cell in the parent corresponds to the child we just split.
Since the child doesn't know its own page number, we search by the old maximum
key:

.. code-block:: zig

    pub fn updateInternalNodeKey(node: []u8, old_key: u32, new_key: u32) void {
        const old_child_index = internalNodeFindChild(node, old_key);
        internalNodeKey(node, old_child_index).* = new_key;
    }

Implementation
--------------

.. literalinclude:: ../../src/phase13/lib.zig
   :language: zig
   :caption: src/phase13/lib.zig
   :lines: 55-105

The ``internalNodeInsert`` function handles inserting a new child/key pair:

1. Find where the new child should go (based on its max key)
2. If it's the rightmost child, handle specially
3. Otherwise, shift existing cells right and insert

Handling the Rightmost Child
----------------------------

Because we store the rightmost child pointer separately (not in the cell array),
we handle it as a special case:

.. code-block:: zig

    if (child_max_key > getNodeMaxKey(pager, right_child)) {
        // New child becomes the rightmost
        // Old rightmost moves into cell array
        internalNodeChild(parent, original_num_keys).* = right_child_page_num;
        internalNodeKey(parent, original_num_keys).* = getNodeMaxKey(pager, right_child);
        internalNodeRightChild(parent).* = child_page_num;
    } else {
        // Insert into cell array, shifting as needed
        ...
    }

Main with Parent Updates
------------------------

.. literalinclude:: ../../src/phase13/main.zig
   :language: zig
   :caption: src/phase13/main.zig

Running Phase 13
----------------

.. code-block:: bash

    zig build run-phase13 -- mydb.db

Insert 30 rows in random order to exercise parent updates:

.. code-block:: text

    db > .btree
    - internal (size 3)
      - leaf (size 7)
        - 1 through 7
      - key 7
      - leaf (size 8)
        - 8 through 15
      - key 15
      - leaf (size 7)
        - 16 through 22
      - key 22
      - leaf (size 8)
        - 23 through 30

If we try inserting 1400 rows, we get a new error:

.. code-block:: text

    Need to implement splitting internal node

That's next!

Tests
-----

.. literalinclude:: ../../src/phase13/tests.zig
   :language: zig
   :caption: src/phase13/tests.zig
