#!/bin/bash
set -e
shopt -s nullglob

echo "Verifying license script is still happy..."
echo "Using pub from `which pub`, dart from `which dart`"

exitStatus=0

dart --version

(cd flutter/tools/licenses; pub get; dart --enable-asserts lib/main.dart --src ../../.. --out ../../../out/license_script_output --golden ../../ci/licenses_golden)

for f in out/license_script_output/licenses_*; do
    if ! cmp -s flutter/ci/licenses_golden/$(basename $f) $f
    then
        echo "============================= ERROR ============================="
        echo "License script got different results than expected for $f."
        echo "Please rerun the licenses script locally to verify that it is"
        echo "correctly catching any new licenses for anything you may have"
        echo "changed, and then update this file:"
        echo "  flutter/sky/packages/sky_engine/LICENSE"
        echo "For more information, see the script in:"
        echo "  https://github.com/flutter/engine/tree/master/tools/licenses"
        echo ""
        diff -U 6 flutter/ci/licenses_golden/$(basename $f) $f
        echo "================================================================="
        echo ""
        exitStatus=1
    fi
done

echo "Verifying license tool signature..."
if ! cmp -s flutter/ci/licenses_golden/tool_signature out/license_script_output/tool_signature
then
    echo "============================= ERROR ============================="
    echo "The license tool signature has changed. This is expected when"
    echo "there have been changes to the license tool itself. Licenses have"
    echo "been re-computed for all components. If only the license script has"
    echo "changed, no diffs are typically expected in the output of the"
    echo "script. Verify the output, and if it looks correct, update the"
    echo "license tool signature golden file:"
    echo "  ci/licenses_golden/tool_signature"
    echo "For more information, see the script in:"
    echo "  https://github.com/flutter/engine/tree/master/tools/licenses"
    echo ""
    diff -U 6 flutter/ci/licenses_golden/tool_signature out/license_script_output/tool_signature
    echo "================================================================="
    echo ""
    exitStatus=1
fi

echo "Checking license count in licenses_flutter..."
actualLicenseCount=`tail -n 1 flutter/ci/licenses_golden/licenses_flutter | tr -dc '0-9'`
expectedLicenseCount=2 # When changing this number: Update the error message below as well describing all expected license types.

if [ "$actualLicenseCount" -ne "$expectedLicenseCount" ]
then
    echo "=============================== ERROR ==============================="
    echo "The total license count in flutter/ci/licenses_golden/licenses_flutter"
    echo "changed from $expectedLicenseCount to $actualLicenseCount."
    echo "It's very likely that this is an unintentional change. Please"
    echo "double-check that all newly added files have a BSD-style license"
    echo "header with the following copyright:"
    echo "    Copyright 2013 The Flutter Authors. All rights reserved."
    echo "Files in 'third_party/txt' may have an Apache license header instead."
    echo "If you're absolutely sure that the change in license count is"
    echo "intentional, update 'flutter/ci/licenses.sh' with the new count."
    echo "================================================================="
    echo ""
    exitStatus=1
fi

if [ "$exitStatus" -eq "0" ]
then
  echo "Licenses are as expected."
fi
exit $exitStatus
