# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Helper for running Mojo applications in Python."""

from mojo_application.application_impl import ApplicationImpl

import mojo_system

def RunMojoApplication(application_delegate, app_request_handle):
  loop = mojo_system.RunLoop()

  application = ApplicationImpl(application_delegate, app_request_handle)
  application.manager.AddOnErrorCallback(loop.Quit)

  loop.Run()
