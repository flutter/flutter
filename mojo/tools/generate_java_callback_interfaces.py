"""Generate the org.chromium.mojo.bindings.Callbacks interface"""

import argparse
import sys

CALLBACK_TEMPLATE = ("""
    /**
     * A generic %d-argument callback.
     *
     * %s
     */
    interface Callback%d<%s> {
        /**
         * Call the callback.
         */
        public void call(%s);
    }
""")

INTERFACE_TEMPLATE = (
"""// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file was generated using
//     mojo/tools/generate_java_callback_interfaces.py

package org.chromium.mojo.bindings;

/**
 * Contains a generic interface for callbacks.
 */
public interface Callbacks {

    /**
     * A generic callback.
     */
    interface Callback0 {
        /**
         * Call the callback.
         */
        public void call();
    }
%s
}""")

def GenerateCallback(nb_args):
  params = '\n      * '.join(
      ['@param <T%d> the type of argument %d.' % (i+1, i+1)
       for i in xrange(nb_args)])
  template_parameters = ', '.join(['T%d' % (i+1) for i in xrange(nb_args)])
  callback_parameters = ', '.join(['T%d arg%d' % ((i+1), (i+1))
                                   for i in xrange(nb_args)])
  return CALLBACK_TEMPLATE % (nb_args, params, nb_args, template_parameters,
                              callback_parameters)

def main():
  parser = argparse.ArgumentParser(
      description="Generate org.chromium.mojo.bindings.Callbacks")
  parser.add_argument("max_args", nargs=1, type=int,
      help="maximal number of arguments to generate callbacks for")
  args = parser.parse_args()
  max_args = args.max_args[0]
  print INTERFACE_TEMPLATE % ''.join([GenerateCallback(i+1)
                                      for i in xrange(max_args)])
  return 0

if __name__ == "__main__":
  sys.exit(main())
