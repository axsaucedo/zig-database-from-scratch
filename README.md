# SQLite Clone Tutorial - Zig Edition

A port of the [cstack/db_tutorial](https://cstack.github.io/db_tutorial/) from C to Zig using an **incremental module system** where each phase builds upon and imports from previous phases.

## Architecture

Each phase is a self-contained Zig module that:
- **Imports** reusable components from previous phases
- **Exports** new functions and types for subsequent phases
- Contains **unit tests** that validate the phase's functionality
- Can be run as a **standalone executable** for end-to-end testing

```
Phase 01 (REPL) ──► Phase 02 (Parser) ──► Phase 03 (Storage) ──► Phase 04 (Validation) ──► ...
    ▲                    ▲                     ▲                      ▲
    │                    │                     │                      │
  input.zig           parser.zig          row.zig, table.zig     validation.zig
  tests.zig           tests.zig           tests.zig              tests.zig
  main.zig            main.zig            main.zig               main.zig
```

## Quick Start

```bash
# Build all phases
zig build

# Run a specific phase
zig build run-phase01
zig build run-phase04

# Run all tests
zig build test

# Run tests for a specific phase
zig build test-phase03
```

## Project Structure

```
db_tutorial_zig/
├── build.zig                    # Build system with module dependencies
├── PLAN.md                      # Detailed implementation plan
├── README.md                    # This file
│
├── src/
│   ├── phase01/                 # REPL & Input Buffer
│   │   ├── input.zig           # InputBuffer, printPrompt, readInput (exports)
│   │   ├── tests.zig           # Unit tests for input module
│   │   └── main.zig            # Standalone demo executable
│   │
│   ├── phase02/                 # SQL Parsing
│   │   ├── parser.zig          # Statement, PrepareResult, prepareStatement (exports)
│   │   ├── tests.zig           # Unit tests for parser
│   │   └── main.zig            # Demo (imports phase01)
│   │
│   ├── phase03/                 # In-Memory Storage
│   │   ├── row.zig             # Row struct, serialize/deserialize (exports)
│   │   ├── table.zig           # Table struct (exports)
│   │   ├── tests.zig           # Unit tests
│   │   └── main.zig            # Demo (imports phase01, phase02)
│   │
│   ├── phase04/                 # Input Validation
│   │   ├── validation.zig      # Validation functions (exports)
│   │   ├── tests.zig           # Unit tests
│   │   └── main.zig            # Demo (imports phase01-03)
│   │
│   └── ... (phases 05-14)
│
├── docs/                        # Sphinx documentation
│   ├── conf.py
│   ├── index.rst
│   └── parts/                   # Tutorial parts referencing source files
│
└── tests/
    └── e2e/                     # End-to-end integration tests
```

## Phase Overview

| Phase | Topic | Exports | Status |
|-------|-------|---------|--------|
| 01 | REPL & Input | `InputBuffer`, `printPrompt`, `readInput` | ✅ |
| 02 | SQL Parsing | `Statement`, `prepareStatement`, `doMetaCommand` | ✅ |
| 03 | In-Memory Storage | `Row`, `Table`, serialize/deserialize | ✅ |
| 04 | Input Validation | `prepareInsert` with validation | ✅ |
| 05 | Persistence | `Pager` with file I/O | 🚧 |
| 06 | Cursor | `Cursor` abstraction | 🚧 |
| 08 | B-Tree Leaf | Leaf node layout and functions | 🚧 |
| 09 | Binary Search | Search in leaf nodes | 🚧 |
| 10 | Leaf Splitting | Split full leaf nodes | 🚧 |
| 11 | Internal Nodes | Search internal nodes | 🚧 |
| 12 | Multi-Level Scan | Traverse siblings | 🚧 |
| 13 | Parent Updates | Update parent after split | 🚧 |
| 14 | Internal Split | Split internal nodes | 🚧 |

## Module Import Pattern

Each phase imports from previous phases:

```zig
// In phase04/main.zig
const phase01 = @import("phase01");  // InputBuffer, printPrompt, readInput
const phase02 = @import("phase02");  // isMetaCommand, doMetaCommand
const phase03 = @import("phase03");  // Row, Table, serializeRow

// Use imported functions
var input_buffer = try phase01.InputBuffer.init(allocator);
phase01.printPrompt();
```

## Testing Strategy

### Unit Tests (per phase)
```bash
zig build test-phase01   # Test InputBuffer
zig build test-phase03   # Test Row/Table serialization
zig build test-phase04   # Test validation
```

### All Tests
```bash
zig build test           # Run all phase tests
```

### Interactive Demo
```bash
# Run Phase 04 with full validation
zig build run-phase04

db > insert 1 user1 user1@example.com
Executed.
db > insert -1 bad user@bad.com
ID must be positive.
db > select
(1, user1, user1@example.com)
Executed.
db > .exit
```

## Documentation

Documentation uses Sphinx with `literalinclude` to embed actual source:

```rst
InputBuffer Module
------------------

.. literalinclude:: ../../src/phase01/input.zig
   :language: zig
   :caption: src/phase01/input.zig
   :linenos:
```

Build docs:
```bash
cd docs && sphinx-build -b html . _build/html
# Or from project root:
# sphinx-build -b html docs docs/_build/html
```

## Key Zig Concepts Demonstrated

- **Explicit Allocators**: Memory management is visible and testable
- **Error Unions**: Errors are part of the type system (`!T`)
- **Defer**: Automatic cleanup via `defer`
- **Module System**: Clean imports across phases
- **Testing**: Built-in test blocks alongside code

## References

- [Original C Tutorial](https://cstack.github.io/db_tutorial/)
- [Zig Documentation](https://ziglang.org/documentation/master/)
- [GRPO Project Structure](https://github.com/...) - Similar phase-based architecture

## License

MIT
