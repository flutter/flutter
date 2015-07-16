# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

class URLMappings(object):
    def __init__(self, src_root, build_dir):
        self.mappings = {
            'dart:mojo.internal': os.path.join(src_root, 'mojo/public/dart/sdk_ext/internal.dart'),
            'dart:sky': os.path.join(build_dir, 'gen/sky/bindings/dart_sky.dart'),
            'dart:sky.internals': os.path.join(src_root, 'sky/engine/bindings/sky_internals.dart'),
            'dart:sky_builtin_natives': os.path.join(src_root, 'sky/engine/bindings/builtin_natives.dart'),
        }
        self.packages_root = os.path.join(build_dir, 'gen/dart-pkg/packages')

    @property
    def as_args(self):
        return map(lambda item: '--url-mapping=%s,%s' % item, self.mappings.items())
    