# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Interface for the delegate of ApplicationImpl."""

import mojo_application.application_impl
import mojo_application.service_provider_impl
import shell_mojom

import mojo_system

# pylint: disable=unused-argument
class ApplicationDelegate:
  def Initialize(self, shell, application):
    """
    Called from ApplicationImpl's Initialize() method.
    """
    pass

  def OnAcceptConnection(self,
                         requestor_url,
                         resolved_url,
                         service_provider,
                         exposed_services):
    """
    Called from ApplicationImpl's OnAcceptConnection() method. Returns a bool
    indicating whether this connection should be accepted.
    """
    return False
