#!/bin/bash
set -ex

(cd packages/cassowary; pub global run tuneup check; pub run test -j1)
(cd packages/newton; pub global run tuneup check; pub run test -j1)
