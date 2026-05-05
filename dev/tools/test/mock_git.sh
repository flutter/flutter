# ----------------------------------------------------------------------
# SECURITY NOTE
# ----------------------------------------------------------------------
# This script previously used echo with unquoted $@ which could lead to
# unexpected argument expansion. Using printf with "$*" ensures proper
# handling of arguments. See Flutter security guidelines for CI tooling.
# ----------------------------------------------------------------------
#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

printf 'Mock Git: %s\n' "$*"
