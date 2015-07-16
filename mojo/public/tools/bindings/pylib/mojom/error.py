# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

class Error(Exception):
  """Base class for Mojo IDL bindings parser/generator errors."""

  def __init__(self, filename, message, lineno=None, addenda=None, **kwargs):
    """|filename| is the (primary) file which caused the error, |message| is the
    error message, |lineno| is the 1-based line number (or |None| if not
    applicable/available), and |addenda| is a list of additional lines to append
    to the final error message."""
    Exception.__init__(self, **kwargs)
    self.filename = filename
    self.message = message
    self.lineno = lineno
    self.addenda = addenda

  def __str__(self):
    if self.lineno:
      s = "%s:%d: Error: %s" % (self.filename, self.lineno, self.message)
    else:
      s = "%s: Error: %s" % (self.filename, self.message)
    return "\n".join([s] + self.addenda) if self.addenda else s

  def __repr__(self):
    return str(self)
