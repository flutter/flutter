# Tracing tests

The tests in this folder must be run with `flutter test --enable-vmservice`,
since they test that trace data is written to the timeline by connecting to
the observatory.

These tests will fail if run without this flag.