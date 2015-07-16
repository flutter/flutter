#!/usr/bin/env python
# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# TODO: remove this script when GYP has for loops

import sys
import optparse

def main(argv):

  parser = optparse.OptionParser()
  usage = 'usage: %s [options ...] format_string locale_list'
  parser.set_usage(usage.replace('%s', '%prog'))
  parser.add_option('-d', dest='dash_to_underscore', action="store_true",
                    default=False,
                    help='map "en-US" to "en" and "-" to "_" in locales')

  (options, arglist) = parser.parse_args(argv)

  if len(arglist) < 3:
    print 'ERROR: need string and list of locales'
    return 1

  str_template = arglist[1]
  locales = arglist[2:]

  results = []
  for locale in locales:
    # For Cocoa to find the locale at runtime, it needs to use '_' instead
    # of '-' (http://crbug.com/20441).  Also, 'en-US' should be represented
    # simply as 'en' (http://crbug.com/19165, http://crbug.com/25578).
    if options.dash_to_underscore:
      if locale == 'en-US':
        locale = 'en'
      locale = locale.replace('-', '_')
    results.append(str_template.replace('ZZLOCALE', locale))

  # Quote each element so filename spaces don't mess up GYP's attempt to parse
  # it into a list.
  print ' '.join(["'%s'" % x for x in results])

if __name__ == '__main__':
  sys.exit(main(sys.argv))
