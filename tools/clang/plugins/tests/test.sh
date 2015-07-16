#!/bin/bash
#
# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Hacky, primitive testing: This runs the style plugin for a set of input files
# and compares the output with golden result files.

E_BADARGS=65
E_FAILEDTEST=1

failed_any_test=

THIS_DIR="$(dirname "${0}")"

# Prints usage information.
usage() {
  echo "Usage: $(basename "${0}")" \
    "<path to clang>" \
    "<path to plugin>"
  echo ""
  echo "  Runs all the libFindBadConstructs unit tests"
  echo ""
}

# Runs a single test case.
do_testcase() {
  local flags=""
  if [ -e "${3}" ]; then
    flags="$(cat "${3}")"
  fi

  # TODO(thakis): Remove once the tests are standalone, http://crbug.com/486559
  if [[ "$(uname -s)" == "Darwin" ]]; then
    flags="${flags} -isysroot $(xcrun --show-sdk-path)"
  fi
  if [[ "$(uname -s)" == "Darwin" && "${flags}" != *-target* ]]; then
    flags="${flags} -stdlib=libstdc++"
  fi

  flags="${flags} -Xclang -plugin-arg-find-bad-constructs \
      -Xclang with-ast-visitor"

  local output="$("${CLANG_PATH}" -fsyntax-only -Wno-c++11-extensions \
      -Wno-inconsistent-missing-override \
      -isystem ${THIS_DIR}/system \
      -Xclang -load -Xclang "${PLUGIN_PATH}" \
      -Xclang -add-plugin -Xclang find-bad-constructs ${flags} ${1} 2>&1)"
  local diffout="$(echo "${output}" | diff - "${2}")"
  if [ "${diffout}" = "" ]; then
    echo "PASS: ${1}"
  else
    failed_any_test=yes
    echo "FAIL: ${1}"
    echo "Output of compiler:"
    echo "${output}"
    cat > ${2}-actual << EOF
${output}
EOF

    echo "Expected output:"
    cat "${2}"
    echo
  fi
}

# Validate input to the script.
if [[ -z "${1}" ]]; then
  usage
  exit ${E_BADARGS}
elif [[ -z "${2}" ]]; then
  usage
  exit ${E_BADARGS}
elif [[ ! -x "${1}" ]]; then
  echo "${1} is not an executable"
  usage
  exit ${E_BADARGS}
elif [[ ! -f "${2}" ]]; then
  echo "${2} could not be found"
  usage
  exit ${E_BADARGS}
else
  export CLANG_PATH="${1}"
  export PLUGIN_PATH="${2}"
  echo "Using clang ${CLANG_PATH}..."
  echo "Using plugin ${PLUGIN_PATH}..."

  # The golden files assume that the cwd is this directory. To make the script
  # work no matter what the cwd is, explicitly cd to there.
  cd "${THIS_DIR}"
fi

for input in *.cpp; do
  do_testcase "${input}" "${input%cpp}txt" "${input%cpp}flags"
done

for input in *.c; do
  do_testcase "${input}" "${input%c}txt" "${input%c}flags"
done

if [[ "${failed_any_test}" ]]; then
  exit ${E_FAILEDTEST}
fi
