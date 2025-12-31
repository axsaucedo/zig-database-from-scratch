.PHONY: build test clean docs docs-serve

build:
	zig build

test:
	zig build test

run-phase01:
	zig build run-phase01

run-phase02:
	zig build run-phase02

run-phase03:
	zig build run-phase03

run-phase04:
	zig build run-phase04

run-phase05:
	zig build run-phase05 -- mydb.db

run-phase06:
	zig build run-phase06 -- mydb.db

run-phase08:
	zig build run-phase08 -- mydb.db

run-phase09:
	zig build run-phase09 -- mydb.db

run-phase10:
	zig build run-phase10 -- mydb.db

run-phase11:
	zig build run-phase11 -- mydb.db

run-phase12:
	zig build run-phase12 -- mydb.db

run-phase13:
	zig build run-phase13 -- mydb.db

run-phase14:
	zig build run-phase14 -- mydb.db

docs:
	cd docs && sphinx-build -b html . _build/html

docs-serve:
	cd docs/_build/html && python3 -m http.server 8000

clean:
	rm -rf zig-out .zig-cache docs/_build
