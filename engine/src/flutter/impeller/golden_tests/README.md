# Impeller Golden Tests

This is the executable that will generate the golden image results that can then
be sent to Skia Gold vial the
[golden_tests_harvester]("../golden_tests_harvester").

Running these tests should happen from
[//flutter/testing/run_tests.py](../../testing/run_tests.py). That will do all
the steps to generate the golden images and transmit them to Skia Gold. If you
run the tests locally it will not actually upload anything. That only happens if
the script is executed from LUCI.

Example invocation:

```sh
./run_tests.py --variant="host_debug_unopt_arm64" --type="impeller-golden"
```

Currently these tests are only supported on macOS and only test the Metal
backend to Impeller.
