How Does a Database Work?
=========================

We're building a clone of SQLite from scratch in Zig to understand how databases work.

Table of Contents
-----------------

.. toctree::
   :maxdepth: 2

   parts/part01
   parts/part02
   parts/part03
   parts/part04
   parts/part05
   parts/part06
   parts/part07
   parts/part08
   parts/part09
   parts/part10
   parts/part11
   parts/part12
   parts/part13
   parts/part14
   parts/part15

*"What I cannot create, I do not understand."* -- Richard Feynman

Module Architecture
-------------------

Each phase is a Zig module that imports from previous phases:

.. code-block:: text

    Phase 01 (Input) → Phase 02 (Parser) → Phase 03 (Storage) → ...
         ↓                  ↓                    ↓
    input.zig          parser.zig          row.zig, table.zig
    tests.zig          tests.zig           tests.zig
    main.zig           main.zig            main.zig

Running the Code
----------------

.. code-block:: bash

    # Run any phase
    zig build run-phase04
    
    # Run tests
    zig build test
