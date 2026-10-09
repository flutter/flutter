#!/usr/bin/env python3
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Inert marker for a controlled CI trust-boundary test.

This file is not called by Flutter or by the build scripts. The initial commit
has no network access, does not read credentials, and does not change resources.
"""


def main() -> None:
  print('Controlled CI boundary marker; no probe is active.')


if __name__ == '__main__':
  main()
