echo "Verifying license script is still happy..."
(cd flutter/tools/licenses; pub get; dart --checked lib/main.dart ../../.. > ../../../out/license-script-output)

if cmp -s flutter/travis/licenses.golden out/license-script-output
then
    echo "Licenses are as expected."
    exit 0
else
    echo "License script got different results than expected."
    echo "Please rerun the licenses script locally to verify that it is"
    echo "correctly catching any new licenses for anything you may have"
    echo "changed, and then update this file:"
    echo "  flutter/sky/packages/sky_engine/LICENSE"
    echo "For more information, see the script in:"
    echo "  https://github.com/flutter/engine/tree/master/tools/licenses"
    echo ""
    diff -U 6 flutter/travis/licenses.golden out/license-script-output
    exit 1
fi
