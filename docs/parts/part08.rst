Part 8 - B-Tree Leaf Node Format
=================================

We're changing the format of our table from an unsorted array of rows to a
B-Tree. This is a pretty big change that is going to take multiple articles
to implement. By the end of this article, we'll define the layout of a leaf
node and support inserting key/value pairs into a single-node tree.

Alternative Table Formats
-------------------------

With the current format, each page stores only rows (no metadata) so it is
pretty space efficient. Insertion is also fast because we just append to the
end. However, finding a particular row can only be done by scanning the entire
table.

If we stored the table as a sorted array, we could use binary search to find
a particular id. However, insertion would be slow because we would have to move
a lot of rows to make space.

Instead, we're going with a tree structure:

+---------------+------------------------+----------------------+----------------------+
|               | Unsorted Array of rows | Sorted Array of rows | Tree of nodes        |
+===============+========================+======================+======================+
| Pages contain | only data              | only data            | metadata, keys, data |
+---------------+------------------------+----------------------+----------------------+
| Rows per page | more                   | more                 | fewer                |
+---------------+------------------------+----------------------+----------------------+
| Insertion     | O(1)                   | O(n)                 | O(log(n))            |
+---------------+------------------------+----------------------+----------------------+
| Deletion      | O(n)                   | O(n)                 | O(log(n))            |
+---------------+------------------------+----------------------+----------------------+
| Lookup by id  | O(n)                   | O(log(n))            | O(log(n))            |
+---------------+------------------------+----------------------+----------------------+

Node Header Format
------------------

Leaf nodes and internal nodes have different layouts. Every node stores:

- **Node type**: Leaf or Internal (1 byte)
- **Is root**: Whether this is the root node (1 byte)
- **Parent pointer**: Page number of parent (4 bytes)

This gives us a 6-byte common header.

Leaf Node Format
----------------

In addition to the common header, leaf nodes need:

- **Num cells**: How many key/value pairs (4 bytes)
- **Next leaf**: Page number of sibling leaf (4 bytes)

The body is an array of cells. Each cell is a key (4 bytes) followed by a
value (the serialized row).

.. literalinclude:: ../../src/phase08/btree.zig
   :language: zig
   :caption: src/phase08/btree.zig

Key Zig features:

- **comptime**: Compile-time calculation of layout sizes
- **@offsetOf**: Get field offsets in packed structs
- **Pointer arithmetic**: Using slice indexing for memory access

Pager Integration
-----------------

We update the pager to track the number of pages:

.. literalinclude:: ../../src/phase08/pager.zig
   :language: zig
   :caption: src/phase08/pager.zig

Changes to the Table
--------------------

Now it makes more sense to store the number of pages rather than rows. A btree
is identified by its root node page number:

- ``root_page_num``: Page number of the root node
- When the database is empty, page 0 becomes an empty leaf node (the root)

Main with B-Tree
----------------

.. literalinclude:: ../../src/phase08/main.zig
   :language: zig
   :caption: src/phase08/main.zig

Debugging Commands
------------------

We add two meta-commands to help with debugging:

- ``.constants``: Print layout constants
- ``.btree``: Print the tree structure

Running Phase 8
---------------

.. code-block:: bash

    zig build run-phase08 -- mydb.db

Use ``.btree`` to visualize the tree structure:

.. code-block:: text

    db > insert 3 user3 person3@example.com
    db > insert 1 user1 person1@example.com
    db > insert 2 user2 person2@example.com
    db > .btree
    Tree:
    - leaf (size 3)
      - 3
      - 1
      - 2

Note that rows are still not stored in sorted order! We'll fix that next time.

Tests
-----

.. literalinclude:: ../../src/phase08/tests.zig
   :language: zig
   :caption: src/phase08/tests.zig
