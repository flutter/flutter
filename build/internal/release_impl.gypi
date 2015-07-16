# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'includes': ['release_defaults.gypi'],
  'msvs_settings': {
    'VCCLCompilerTool': {
      'OmitFramePointers': 'false',
      # The above is not sufficient (http://crbug.com/106711): it
      # simply eliminates an explicit "/Oy", but both /O2 and /Ox
      # perform FPO regardless, so we must explicitly disable.
      # We still want the false setting above to avoid having
      # "/Oy /Oy-" and warnings about overriding.
      'AdditionalOptions': ['/Oy-'],
    },
  },
}
