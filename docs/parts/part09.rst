Part 9 - Binary Search and Duplicate Keys
==========================================

Last time we noted that we're still storing keys in unsorted order. We're going
to fix that problem, plus detect and reject duplicate keys.

The Problem
-----------

Right now, our ``execute_insert()`` function always chooses to insert at the
end of the table. Instead, we should search the table for the correct place to
insert, then insert there. If the key already exists, return an error.

Binary Search
-------------

Instead of ``table_end()``, we introduce ``table_find()`` which searches the
tree for a given key. It returns a cursor pointing to:

- The position of the key (if found), or
- The position where the key should be inserted (if not found)

Since we only have a single leaf node right now, we use binary search within
that leaf:

.. literalinclude:: ../../src/phase09/lib.zig
   :language: zig
   :caption: src/phase09/lib.zig

The binary search returns either:

1. The position of the key (exact match)
2. The position of another key that we'll need to move if we want to insert
3. The position one past the last key

Node Type Functions
-------------------

Since we're now checking node type, we need functions to get and set the type
in a node. We also initialize the node type when creating new nodes:

.. code-block:: zig

    pub fn getNodeType(node: []u8) NodeType {
        return @enumFromInt(node[NODE_TYPE_OFFSET]);
    }

    pub fn setNodeType(node: []u8, node_type: NodeType) void {
        node[NODE_TYPE_OFFSET] = @intFromEnum(node_type);
    }

Duplicate Key Detection
-----------------------

When inserting, after calling ``table_find()``, we check if the returned
position contains a matching key:

.. code-block:: zig

    if (cursor.cell_num < num_cells) {
        const key_at_index = btree.leafNodeKey(node, cursor.cell_num).*;
        if (key_at_index == key_to_insert) {
            return error.DuplicateKey;
        }
    }

Main with Binary Search
-----------------------

.. literalinclude:: ../../src/phase09/main.zig
   :language: zig
   :caption: src/phase09/main.zig

Running Phase 9
---------------

.. code-block:: bash

    zig build run-phase09 -- mydb.db

Now keys are stored in sorted order, and duplicate keys are rejected:

.. code-block:: text

    db > insert 3 user3 person3@example.com
    Executed.
    db > insert 1 user1 person1@example.com
    Executed.
    db > insert 2 user2 person2@example.com
    Executed.
    db > .btree
    Tree:
    - leaf (size 3)
      - 1
      - 2
      - 3
    db > insert 1 duplicate person1@example.com
    Error: Duplicate key.

Tests
-----

.. literalinclude:: ../../src/phase09/tests.zig
   :language: zig
   :caption: src/phase09/tests.zig
