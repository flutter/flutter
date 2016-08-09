#!/bin/bash
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -eu

supported_build_types="msan-no-origins msan-chained-origins"
supported_releases="precise trusty"
ubuntu_release=$(lsb_release -cs)

function show_help {
  echo "Usage: build_and_package.sh <build_type>"
  echo "Supported build types: all ${supported_build_types}"
}

function build_libraries {
  local build_type=$1
  case ${build_type} in
    "msan-chained-origins")
      local gyp_defines="msan=1 msan_track_origins=2"
      ;;
    "msan-no-origins")
      local gyp_defines="msan=1 msan_track_origins=0"
      ;;
    *)
      show_help
      exit 1
      ;;
  esac
  
  local archive_name=${build_type}-${ubuntu_release}
  local out_dir=out-${archive_name}

  echo "Building instrumented libraries in ${out_dir}..."

  rm -rf $out_dir
  mkdir $out_dir

  GYP_DEFINES="${gyp_defines} \
               use_instrumented_libraries=1 instrumented_libraries_jobs=8" \
  GYP_GENERATOR_FLAGS="output_dir=${out_dir}" \
  gclient runhooks

  ninja -j4 -C ${out_dir}/Release instrumented_libraries

  echo "Creating archive ${archive_name}.tgz..."

  files=$(ls -1 ${out_dir}/Release/instrumented_libraries)

  tar zcf ${archive_name}.tgz -C ${out_dir}/Release/instrumented_libraries \
      --exclude="?san/*.txt" ${files}

  echo To upload, run:
  echo upload_to_google_storage.py -b \
       chromium-instrumented-libraries ${archive_name}.tgz
  echo You should then commit the resulting .sha1 file.
}

if ! [[ "${supported_releases}" =~ ${ubuntu_release} ]]
then
  echo "Unsupported Ubuntu release: ${ubuntu_release}"
  echo "Supported releases: ${supported_releases}"
  exit 1
fi

if [ -z "${1-}" ]
then
  show_help
  exit 0
fi

if ! [[ "all ${supported_build_types}" =~ $1 ]]
then
  show_help
  exit 1
fi
if [ "$1" == "all" ]
then
  for build_type in ${supported_build_types}
  do
    build_libraries ${build_type}
  done
else
  build_libraries $1
fi

