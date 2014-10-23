#!/bin/bash

#
# Copyright (C) 2011 Google Inc. All rights reserved.
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
#

# This script checks a WebCore static library for potential Objective-C
# class name collisions with the system's copy of the WebCore framework.
# See the postbuild action that calls it from ../WebCore.gyp for details.

set -e
set -o pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: ${0} class_whitelist_pattern category_whitelist_pattern" >& 2
  exit 1
fi

lib="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
nm_pattern='[atsATS] ([+-]\[|\.objc_class_name_)'

class_whitelist_pattern="${1}"
category_whitelist_pattern="${2}"

# Send nm's stderr in the pipeline to /dev/null to avoid spewing
# "nm: no name list" messages. This means that if the pipelined nm fails, there
# won't be any output, so if the entire assignment fails, run nm again to get
# some output.
violators=$(nm -p "${lib}" 2> /dev/null | \
    (grep -E "${nm_pattern}" || true) | \
    (grep -Ev "${nm_pattern}(${class_whitelist_pattern})" || true) | \
    (grep -Ev "\((${category_whitelist_pattern})\)" || true)) || nm -p "${lib}"

if [[ -z "${violators}" ]]; then
  # An empty list means that everything's clean.
  exit 0
fi

cat << __EOF__ >&2
These Objective-C symbols may clash with those provided by the system's own
WebCore framework:
${violators}

These symbols were found in:
${lib}

This should be corrected by adding the appropriate definitions to
$(dirname ${0})/../WebCore.gyp
or by updating the whitelist in
${0}
__EOF__

exit 1
