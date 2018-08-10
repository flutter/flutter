#!/bin/bash
set -e
shopt -s nullglob

echo "Verifying license script is still happy..."
(cd flutter/tools/licenses; pub get; dart --enable-asserts lib/main.dart --src ../../.. --out ../../../out/license_script_output --golden ../../ci/licenses_golden)

for f in out/license_script_output/licenses_*; do
    if ! cmp -s flutter/ci/licenses_golden/$(basename $f) $f
    then
        echo "License script got different results than expected for $f."
        echo "Please rerun the licenses script locally to verify that it is"
        echo "correctly catching any new licenses for anything you may have"
        echo "changed, and then update this file:"
        echo "  flutter/sky/packages/sky_engine/LICENSE"
        echo "For more information, see the script in:"
        echo "  https://github.com/flutter/engine/tree/master/tools/licenses"
        echo ""
        diff -U 6 flutter/ci/licenses_golden/$(basename $f) $f
        exit 1
    fi
done

echo "Licenses are as expected."
exit 0
