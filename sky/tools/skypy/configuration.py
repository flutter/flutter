# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import optparse


def add_arguments(parser):
    parser.add_argument("-t", "--target", dest="configuration",
        help="Specify the target configuration to use (Debug/Release)", default='Release')
    parser.add_argument('--debug', action='store_const', const='Debug', dest="configuration",
        help='Set the configuration to Debug')
    parser.add_argument('--release', action='store_const', const='Release', dest="configuration",
        help='Set the configuration to Release')

