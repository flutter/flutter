#!/usr/bin/env bash
pushd "$(dirname "$0")" > /dev/null || exit
cd ..
dart ./util/lib/main.dart "$@"
popd > /dev/null || exit
