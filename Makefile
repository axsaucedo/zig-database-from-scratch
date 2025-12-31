.PHONY: build test run-phase01 run-phase02 run-phase03 run-phase04 docs docs-serve clean

# Build all executables
build:
	zig build

# Run all tests
test:
	zig build test

# Run individual phases
run-phase01:
	zig build run-phase01

run-phase02:
	zig build run-phase02

run-phase03:
	zig build run-phase03

run-phase04:
	zig build run-phase04

# Build documentation
docs:
	sphinx-build -b html docs docs/_build/html

# Serve documentation locally
docs-serve: docs
	cd docs/_build/html && python3 -m http.server 8000

# Clean build artifacts
clean:
	rm -rf zig-out .zig-cache docs/_build
