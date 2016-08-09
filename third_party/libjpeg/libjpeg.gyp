# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  # This file handles building both with our local libjpeg and with the system
  # libjpeg.
  'conditions': [
    ['use_system_libjpeg==0', {
      'targets': [
        {
          'target_name': 'libjpeg',
          'type': 'static_library',
          'defines': [
            'NO_GETENV',  # getenv() is not thread-safe.
          ],
          'sources': [
            'jcapimin.c',
            'jcapistd.c',
            'jccoefct.c',
            'jccolor.c',
            'jcdctmgr.c',
            'jchuff.c',
            'jchuff.h',
            'jcinit.c',
            'jcmainct.c',
            'jcmarker.c',
            'jcmaster.c',
            'jcomapi.c',
            'jconfig.h',
            'jcparam.c',
            'jcphuff.c',
            'jcprepct.c',
            'jcsample.c',
            'jdapimin.c',
            'jdapistd.c',
            'jdatadst.c',
            'jdatasrc.c',
            'jdcoefct.c',
            'jdcolor.c',
            'jdct.h',
            'jddctmgr.c',
            'jdhuff.c',
            'jdhuff.h',
            'jdinput.c',
            'jdmainct.c',
            'jdmarker.c',
            'jdmaster.c',
            'jdmerge.c',
            'jdphuff.c',
            'jdpostct.c',
            'jdsample.c',
            'jerror.c',
            'jerror.h',
            'jfdctflt.c',
            'jfdctfst.c',
            'jfdctint.c',
            'jidctflt.c',
            'jidctfst.c',
            'jidctint.c',
            'jinclude.h',
            'jmemmgr.c',
            'jmemnobs.c',
            'jmemsys.h',
            'jmorecfg.h',
            'jpegint.h',
            'jpeglib.h',
            'jquant1.c',
            'jquant2.c',
            'jutils.c',
            'jversion.h',
          ],
          'direct_dependent_settings': {
            'include_dirs': [
              '.',
            ],
          },
          'conditions': [
            ['OS!="win"', {'product_name': 'jpeg'}],
          ],
        },
      ],
    }, {
      'targets': [
        {
          'target_name': 'libjpeg',
          'type': 'none',
          'direct_dependent_settings': {
            'defines': [
              'USE_SYSTEM_LIBJPEG',
            ],
            'conditions': [
              ['os_bsd==1', {
                'include_dirs': [
                  '/usr/local/include',
                ],
              }],
            ],
          },
          'link_settings': {
            'libraries': [
              '-ljpeg',
            ],
          },
        }
      ],
    }],
  ],
}
