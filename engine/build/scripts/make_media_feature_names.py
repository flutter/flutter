#!/usr/bin/env python

# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import in_generator
import make_names
import media_feature_symbol


class MakeMediaFeatureNamesWriter(make_names.MakeNamesWriter):
    pass

MakeMediaFeatureNamesWriter.filters['symbol'] = media_feature_symbol.getMediaFeatureSymbolWithSuffix('MediaFeature')

if __name__ == "__main__":
    in_generator.Maker(MakeMediaFeatureNamesWriter).main(sys.argv)
