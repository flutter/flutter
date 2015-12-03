#!/bin/bash
set -ex

dart dev/update_packages.dart
(cd packages/unit; ../../bin/flutter cache populate)
