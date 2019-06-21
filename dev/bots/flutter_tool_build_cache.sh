#!/bin/bash

pushd packages/flutter_tool

pub run build_runner build_runner

popd packages/flutter_tool
