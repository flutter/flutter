# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This gypi file defines the patterns used for determining whether a
# file is excluded from the build on a given platform.  It is
# included by common.gypi for chromium_code.

{
  'target_conditions': [
    ['OS!="win" or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_win(_browsertest|_unittest)?\\.(h|cc)$'],
                    ['exclude', '(^|/)win/'],
                    ['exclude', '(^|/)win_[^/]*\\.(h|cc)$'] ],
    }],
    ['OS!="mac" or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_(cocoa|mac)(_unittest)?\\.(h|cc|mm?)$'],
                    ['exclude', '(^|/)(cocoa|mac)/'] ],
    }],
    ['OS!="ios" or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_ios(_unittest)?\\.(h|cc|mm?)$'],
                    ['exclude', '(^|/)ios/'] ],
    }],
    ['(OS!="mac" and OS!="ios") or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '\\.mm?$' ] ],
    }],
    # Do not exclude the linux files on *BSD since most of them can be
    # shared at this point.
    # In case a file is not needed, it is going to be excluded later on.
    # TODO(evan): the above is not correct; we shouldn't build _linux
    # files on non-linux.
    ['OS!="linux" and OS!="openbsd" and OS!="freebsd" or >(nacl_untrusted_build)==1', {
      'sources/': [
        ['exclude', '_linux(_unittest)?\\.(h|cc)$'],
        ['exclude', '(^|/)linux/'],
      ],
    }],
    ['OS!="android" or _toolset=="host" or >(nacl_untrusted_build)==1', {
      'sources/': [
        ['exclude', '_android(_unittest)?\\.(h|cc)$'],
        ['exclude', '(^|/)android/'],
      ],
    }],
    ['OS=="win" and >(nacl_untrusted_build)==0', {
      'sources/': [
        ['exclude', '_posix(_unittest)?\\.(h|cc)$'],
        ['exclude', '(^|/)posix/'],
      ],
    }],
    ['<(chromeos)!=1 or >(nacl_untrusted_build)==1', {
      'sources/': [
        ['exclude', '_chromeos(_unittest)?\\.(h|cc)$'],
        ['exclude', '(^|/)chromeos/'],
      ],
    }],
    ['>(nacl_untrusted_build)==0', {
      'sources/': [
        ['exclude', '_nacl(_unittest)?\\.(h|cc)$'],
      ],
    }],
    ['OS!="linux" and OS!="openbsd" and OS!="freebsd" or >(nacl_untrusted_build)==1', {
      'sources/': [
        ['exclude', '_xdg(_unittest)?\\.(h|cc)$'],
      ],
    }],
    ['<(use_x11)!=1 or >(nacl_untrusted_build)==1', {
      'sources/': [
        ['exclude', '_(x|x11)(_interactive_uitest|_unittest)?\\.(h|cc)$'],
        ['exclude', '(^|/)x11_[^/]*\\.(h|cc)$'],
        ['exclude', '(^|/)x11/'],
        ['exclude', '(^|/)x/'],
      ],
    }],
    ['<(toolkit_views)==0 or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_views(_browsertest|_unittest)?\\.(h|cc)$'] ]
    }],
    ['<(use_aura)==0 or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_aura(_browsertest|_unittest)?\\.(h|cc)$'],
                    ['exclude', '(^|/)aura/'],
      ]
    }],
    ['<(use_aura)==0 or <(use_x11)==0 or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_aurax11(_browsertest|_unittest)?\\.(h|cc)$'] ]
    }],
    ['<(use_aura)==0 or OS!="win" or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_aurawin\\.(h|cc)$'] ]
    }],
    ['<(use_aura)==0 or OS!="linux" or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_auralinux\\.(h|cc)$'] ]
    }],
    ['<(use_ash)==0 or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_ash(_browsertest|_unittest)?\\.(h|cc)$'],
                    ['exclude', '(^|/)ash/'],
      ]
    }],
    ['<(use_ash)==0 or OS!="win" or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_ashwin\\.(h|cc)$'] ]
    }],
    ['<(use_ozone)==0 or >(nacl_untrusted_build)==1', {
      'sources/': [ ['exclude', '_ozone(_browsertest|_unittest)?\\.(h|cc)$'] ]
    }],
    ['<(use_pango)==0', {
      'sources/': [ ['exclude', '(^|_)pango(_util|_browsertest|_unittest)?\\.(h|cc)$'], ],
    }],
  ]
}
