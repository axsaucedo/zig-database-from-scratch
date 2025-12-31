Part 7 - Introduction to the B-Tree
====================================

The B-Tree is the data structure SQLite uses to represent both tables and indexes,
so it's a pretty central idea. This article introduces the data structure conceptually
before we start implementing it in the next part.

Why is a Tree a Good Data Structure?
------------------------------------

- **Searching** for a particular value is fast (logarithmic time)
- **Inserting / deleting** a value you've already found is fast (constant-ish time to rebalance)
- **Traversing** a range of values is fast (unlike a hash map)

B-Tree vs Binary Tree
---------------------

A B-Tree is different from a binary tree (the "B" probably stands for the inventor's
name, but could also stand for "balanced"). Unlike a binary tree, each node in a
B-Tree can have **more than 2 children**.

Each node can have up to ``m`` children, where ``m`` is called the tree's "order".
To keep the tree mostly balanced, we also say nodes have to have at least ``m/2``
children (rounded up).

**Exceptions:**

- Leaf nodes have 0 children
- The root node can have fewer than ``m`` children but must have at least 2
- If the root node is a leaf node (the only node), it still has 0 children

B-Tree vs B+ Tree
-----------------

SQLite uses a variation called a **B+ tree** for storing tables:

+-------------------------------+------------------+---------------------+
|                               | B-tree           | B+ tree             |
+===============================+==================+=====================+
| Pronounced                    | "Bee Tree"       | "Bee Plus Tree"     |
+-------------------------------+------------------+---------------------+
| Used to store                 | Indexes          | Tables              |
+-------------------------------+------------------+---------------------+
| Internal nodes store keys     | Yes              | Yes                 |
+-------------------------------+------------------+---------------------+
| Internal nodes store values   | Yes              | No                  |
+-------------------------------+------------------+---------------------+
| Number of children per node   | Less             | More                |
+-------------------------------+------------------+---------------------+
| Internal nodes vs. leaf nodes | Same structure   | Different structure |
+-------------------------------+------------------+---------------------+

Until we get to implementing indexes, we'll focus on B+ trees, but refer to them
simply as "B-trees" or "btrees".

Internal Nodes vs Leaf Nodes
----------------------------

Nodes with children are called "internal" nodes. Internal nodes and leaf nodes
are structured differently:

+------------------------+-------------------------------+---------------------+
| For an order-m tree... | Internal Node                 | Leaf Node           |
+========================+===============================+=====================+
| Stores                 | keys and pointers to children | keys and values     |
+------------------------+-------------------------------+---------------------+
| Number of keys         | up to m-1                     | as many as will fit |
+------------------------+-------------------------------+---------------------+
| Number of pointers     | number of keys + 1            | none                |
+------------------------+-------------------------------+---------------------+
| Number of values       | none                          | number of keys      |
+------------------------+-------------------------------+---------------------+
| Key purpose            | used for routing              | paired with value   |
+------------------------+-------------------------------+---------------------+
| Stores values?         | No                            | Yes                 |
+------------------------+-------------------------------+---------------------+

How the Tree Grows
------------------

Let's work through an example to see how a B-tree grows as you insert elements.
To keep things simple, the tree will be order 3. That means:

- up to 3 children per internal node
- up to 2 keys per internal node
- at least 2 children per internal node
- at least 1 key per internal node

**Empty Tree:**

An empty B-tree has a single node: the root node. The root node starts as a
leaf node with zero key/value pairs.

.. code-block:: text

    [empty]

**After inserting a few key/value pairs:**

They are stored in the leaf node in sorted order:

.. code-block:: text

    [3, 5]

**When the leaf is full and we insert another:**

We split the leaf node and create a new internal node (root):

.. code-block:: text

         [5]          <- internal node (root)
        /   \
    [3]     [5, 7]    <- leaf nodes

The internal node has 1 key and 2 pointers to child nodes. If we want to look up
a key that is less than or equal to 5, we look in the left child. If we want to
look up a key greater than 5, we look in the right child.

**The tree continues to grow:**

As we add more keys, leaves split and internal nodes may also split:

.. code-block:: text

              [7]
            /     \
        [3]       [12]
       /   \     /    \
    [1,2] [5] [7,9] [12,15]

The depth of the tree only increases when we split the root node. Every leaf
node has the same depth and close to the same number of key/value pairs, so
the tree remains balanced and quick to search.

Page-Based Implementation
-------------------------

When we implement this data structure, each node will correspond to one page.
The root node will exist in page 0. Child pointers will simply be the page
number that contains the child node.

.. note::

    We won't implement any code in this part. The next part begins the actual
    B-Tree implementation.

Next Time
---------

Next time, we start implementing the btree by defining the leaf node format!
