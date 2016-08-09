# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'targets': [
    {
      'target_name': 'some',
      'type': 'none',
      'dependencies': [
        # This file is intended to be locally modified. List the targets you use
        # regularly. The generated some.sln will contains projects for only
        # those targets and the targets they are transitively dependent on. This
        # can result in a solution that loads and unloads faster in Visual
        # Studio.
        #
        # Tip: Create a dummy CL to hold your local edits to this file, so they
        # don't accidentally get added to another CL that you are editing.
        #
        # Example:
        # '../chrome/chrome.gyp:chrome',
      ],
    },
  ],
}
