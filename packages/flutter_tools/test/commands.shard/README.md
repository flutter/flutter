This directory contains tests for specific `flutter` commands.

Tests that are self-contained unit tests should go in `hermetic/`.

Tests that are more end-to-end, e.g. that involve actually running
subprocesses, should go in `permeable/`.

The `../../tool/coverage_tool.dart` script (which is used to collect
coverage for the tool) runs only the tests in the `hermetic` directory
when collecting coverage.
