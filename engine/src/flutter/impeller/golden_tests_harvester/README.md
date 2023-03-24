# Golden Tests Harvester

Reaps the output of impeller's golden image tests and sends it to Skia gold.

## Usage

```sh
cd $SRC
./out/host_debug_unopt_arm64/impeller_golden_tests --working_dir=~/Desktop/temp
cd flutter/impeller/golden_tests_harvester
dart run ./bin/golden_tests_harvester.dart ~/Desktop/temp
```

See also [golden_tests](../golden_tests/).
