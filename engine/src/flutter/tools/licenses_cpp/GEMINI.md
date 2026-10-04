# Licenses_cpp

A tool run during ci to collect and verify source code's licenses.

## Targets

- `//flutter/tools/licenses_cpp` - the license checker (best run with a profile
  config)
- `//flutter/tools/licenses_cpp:licenses_cpp_testrunner` - the tests

## Directories

- `data/` - data files for licenses_cpp, contains things like regexs
- `src/` - source code

## Build and run tests

```sh
../../bin/et build --no-rbe -c host_debug_unopt_arm64 //flutter/tools/licenses_cpp:licenses_cpp_testrunner
../../../out/host_debug_unopt_arm64/licenses_cpp_testrunner
```

## Build and run license check on one file

```sh
../../bin/et build --no-rbe -c host_profile_arm64 //flutter/tools/licenses_cpp
../../../out/host_profile_arm64/licenses_cpp \
  --working_dir ../.. \
  --data_dir ./data  \
  --licenses_path licenses.txt \
  --input ../../third_party/icu/source/i18n/collunsafe.h \
  --v=3
```
