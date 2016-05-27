#!/bin/sh
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

RunCommand() {
  echo "♦ " $@
  $@
  return $?
}

EchoError() {
  echo "$@" 1>&2
}

AssertExists() {
  RunCommand ls $1
  if [ $? -ne 0 ]; then
    EchoError "The path $1 does not exist"
    exit -1
  fi
  return 0
}

BuildApp() {
  local project_path=${FLUTTER_APPLICATION_PATH}
  AssertExists ${project_path}

  local derived_dir=${SOURCE_ROOT}/Flutter
  RunCommand mkdir -p $derived_dir
  AssertExists $derived_dir

  RunCommand rm -f ${derived_dir}/Flutter.framework
  RunCommand rm -f ${derived_dir}/app.so
  RunCommand rm -f ${derived_dir}/app.flx
  RunCommand cp -r ${FLUTTER_FRAMEWORK_DIR}/Flutter.framework ${derived_dir}
  RunCommand pushd ${project_path}

  local local_engine_flag=""
  if [[ -n "$LOCAL_ENGINE" ]]; then
    local_engine_flag="--local-engine=$LOCAL_ENGINE"
  fi

  if [[ $CURRENT_ARCH != "x86_64" ]]; then
    local interpreter_flag="--interpreter"
    if [[ "$DART_EXPERIMENTAL_INTERPRETER" != "1" ]]; then
      interpreter_flag=""
    fi

    RunCommand ${FLUTTER_ROOT}/bin/flutter --suppress-analytics build aot \
      --target-platform=ios                                               \
      --release                                                           \
      ${interpreter_flag}                                                 \
      ${local_engine_flag}

    if [[ $? -ne 0 ]]; then
      EchoError "Failed to build ${project_path}."
      exit -1
    fi

    RunCommand cp build/aot/app.so ${derived_dir}/app.so
  else
    RunCommand eval "$(echo \"static const int Moo = 88;\" | xcrun clang -x c --shared -o ${derived_dir}/app.so -)"
  fi

  local precompilation_flag=""
  if [[ $CURRENT_ARCH != "x86_64" ]] && [[ "$DART_EXPERIMENTAL_INTERPRETER" != "1" ]]; then
    precompilation_flag="--precompiled"
  fi

  RunCommand ${FLUTTER_ROOT}/bin/flutter --suppress-analytics build flx \
    --output-file=${derived_dir}/app.flx                                \
    ${precompilation_flag}                                              \
    ${local_engine_flag}                                                \

  if [[ $? -ne 0 ]]; then
    EchoError "Failed to package ${project_path}."
    exit -1
  fi

  RunCommand popd

  echo "Project ${project_path} built and packaged successfully."
  return 0
}

BuildApp
