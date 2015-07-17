#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Sometimes there isn't a pre-generated configure script, and we must first run
# autogen.sh to generate it. Even if there is one, sometimes we need to
# re-generate it (in particular, the autoconf version on Trusty is newer than
# what is expected by pre-generated configure scripts in some packages).

# Unfortunately, we can't run autogen.sh unconditionally whenever it's present,
# as that sometimes breaks build. Which is why we have this file.

# Also, some packages may or may not have an autogen script, depending on
# version. Rather than clutter the GYP file with conditionals, we simply do
# nothing if the file is not present.

if [ -x ./autogen.sh ]
then
   NOCONFIGURE=1 ./autogen.sh
fi
