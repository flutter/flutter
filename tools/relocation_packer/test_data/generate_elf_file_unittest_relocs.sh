#!/bin/bash
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generates elf_file_unittest_relocs_arm{32,64}{,_packed}.so test data files
# from elf_file_unittest_relocs.cc.  Run once to create these test data
# files; the files are checked into the source tree.
#
# To use:
#   ./generate_elf_file_unittest_relocs.sh
#   git add elf_file_unittest_relocs_arm{32,64}{,_packed}.so

function main() {
  local '-r' test_data_directory="$(pwd)"
  cd '../../..'

  source tools/cr/cr-bash-helpers.sh
  local arch
  for arch in 'arm32' 'arm64'; do
    cr 'init' '--platform=android' '--type=Debug' '--architecture='"${arch}"
    cr 'build' 'relocation_packer_unittests_test_data'
  done

  local '-r' packer='out_android/Debug/obj/tools/relocation_packer'
  local '-r' gen="${packer}/relocation_packer_unittests_test_data.gen"

  cp "${gen}/elf_file_unittest_relocs_arm"{32,64}{,_packed}'.so' \
     "${test_data_directory}"

  return 0
}

main
