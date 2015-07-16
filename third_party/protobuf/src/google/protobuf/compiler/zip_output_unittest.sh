#!/bin/sh
#
# Protocol Buffers - Google's data interchange format
# Copyright 2009 Google Inc.  All rights reserved.
# http://code.google.com/p/protobuf/
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Author: kenton@google.com (Kenton Varda)
#
# Test protoc's zip output mode.

fail() {
  echo "$@" >&2
  exit 1
}

TEST_TMPDIR=.
PROTOC=./protoc

echo '
  syntax = "proto2";
  option java_multiple_files = true;
  option java_package = "test.jar";
  option java_outer_classname = "Outer";
  message Foo {}
  message Bar {}
' > $TEST_TMPDIR/testzip.proto

$PROTOC \
    --cpp_out=$TEST_TMPDIR/testzip.zip --python_out=$TEST_TMPDIR/testzip.zip \
    --java_out=$TEST_TMPDIR/testzip.jar -I$TEST_TMPDIR testzip.proto \
    || fail 'protoc failed.'

echo "Testing output to zip..."
if unzip -h > /dev/null; then
  unzip -t $TEST_TMPDIR/testzip.zip > $TEST_TMPDIR/testzip.list || fail 'unzip failed.'

  grep 'testing: testzip\.pb\.cc *OK$' $TEST_TMPDIR/testzip.list > /dev/null \
    || fail 'testzip.pb.cc not found in output zip.'
  grep 'testing: testzip\.pb\.h *OK$' $TEST_TMPDIR/testzip.list > /dev/null \
    || fail 'testzip.pb.h not found in output zip.'
  grep 'testing: testzip_pb2\.py *OK$' $TEST_TMPDIR/testzip.list > /dev/null \
    || fail 'testzip_pb2.py not found in output zip.'
  grep -i 'manifest' $TEST_TMPDIR/testzip.list > /dev/null \
    && fail 'Zip file contained manifest.'
else
  echo "Warning:  'unzip' command not available.  Skipping test."
fi

echo "Testing output to jar..."
if jar c $TEST_TMPDIR/testzip.proto > /dev/null; then
  jar tf $TEST_TMPDIR/testzip.jar > $TEST_TMPDIR/testzip.list || fail 'jar failed.'

  grep '^test/jar/Foo\.java$' $TEST_TMPDIR/testzip.list > /dev/null \
    || fail 'Foo.java not found in output jar.'
  grep '^test/jar/Bar\.java$' $TEST_TMPDIR/testzip.list > /dev/null \
    || fail 'Bar.java not found in output jar.'
  grep '^test/jar/Outer\.java$' $TEST_TMPDIR/testzip.list > /dev/null \
    || fail 'Outer.java not found in output jar.'
  grep '^META-INF/MANIFEST\.MF$' $TEST_TMPDIR/testzip.list > /dev/null \
    || fail 'Manifest not found in output jar.'
else
  echo "Warning:  'jar' command not available.  Skipping test."
fi

echo PASS
