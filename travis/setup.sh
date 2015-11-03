#!/bin/bash
set -ex

(cd packages/cassowary; pub get)
(cd packages/newton; pub get)

pub global activate tuneup
