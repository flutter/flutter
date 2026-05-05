#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ----------------------------------------------------------------------
# SECURITY NOTE
# ----------------------------------------------------------------------
# Print argv using printf with quoted expansion so arguments containing shell
# metacharacters remain data and are not interpreted by the shell.
# ----------------------------------------------------------------------

printf 'Mock Git: %s\n' "$*"
