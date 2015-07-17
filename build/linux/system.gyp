# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    # If any of the linux_link_FOO below are set to 1, then the corresponding
    # target will be linked against the FOO library (either dynamically or
    # statically, depending on the pkg-config files), as opposed to loading the
    # FOO library dynamically with dlopen.
    'linux_link_libgps%': 0,
    'linux_link_libpci%': 0,
    'linux_link_libspeechd%': 0,
    'linux_link_libbrlapi%': 0,

    # Used below for the various libraries. In this scope for sharing with GN.
    'libbrlapi_functions': [
      'brlapi_getHandleSize',
      'brlapi_error_location',
      'brlapi_strerror',
      'brlapi__acceptKeys',
      'brlapi__openConnection',
      'brlapi__closeConnection',
      'brlapi__getDisplaySize',
      'brlapi__enterTtyModeWithPath',
      'brlapi__leaveTtyMode',
      'brlapi__writeDots',
      'brlapi__readKey',
    ],
    'libgio_functions': [
      'g_settings_new',
      'g_settings_get_child',
      'g_settings_get_string',
      'g_settings_get_boolean',
      'g_settings_get_int',
      'g_settings_get_strv',
      'g_settings_list_schemas',
    ],
    'libpci_functions': [
      'pci_alloc',
      'pci_init',
      'pci_cleanup',
      'pci_scan_bus',
      'pci_fill_info',
      'pci_lookup_name',
    ],
    'libudev_functions': [
      'udev_device_get_action',
      'udev_device_get_devnode',
      'udev_device_get_parent',
      'udev_device_get_parent_with_subsystem_devtype',
      'udev_device_get_property_value',
      'udev_device_get_subsystem',
      'udev_device_get_sysattr_value',
      'udev_device_get_sysname',
      'udev_device_get_syspath',
      'udev_device_new_from_devnum',
      'udev_device_new_from_subsystem_sysname',
      'udev_device_new_from_syspath',
      'udev_device_unref',
      'udev_enumerate_add_match_subsystem',
      'udev_enumerate_get_list_entry',
      'udev_enumerate_new',
      'udev_enumerate_scan_devices',
      'udev_enumerate_unref',
      'udev_list_entry_get_next',
      'udev_list_entry_get_name',
      'udev_monitor_enable_receiving',
      'udev_monitor_filter_add_match_subsystem_devtype',
      'udev_monitor_get_fd',
      'udev_monitor_new_from_netlink',
      'udev_monitor_receive_device',
      'udev_monitor_unref',
      'udev_new',
      'udev_set_log_fn',
      'udev_set_log_priority',
      'udev_unref',
    ],
  },
  'conditions': [
    [ 'chromeos==0 and use_ozone==0', {
      # Hide GTK and related dependencies for Chrome OS and Ozone, so they won't get
      # added back to Chrome OS and Ozone. Don't try to use GTK on Chrome OS and Ozone.
      'targets': [
        {
          'target_name': 'atk',
          'type': 'none',
          'conditions': [
            ['_toolset=="target"', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags atk)',
                ],
                'defines': [
                  'ATK_LIB_DIR="<!@(<(pkg-config) --variable=libdir atk)"',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other atk)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l atk)',
                ],
              },
            }],
          ],
        },
        {
          'target_name': 'gdk',
          'type': 'none',
          'conditions': [
            ['_toolset=="target"', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags gdk-2.0)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other gdk-2.0)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l gdk-2.0)',
                ],
              },
            }],
          ],
        },
        {
          'target_name': 'gtk',
          'type': 'none',
          'toolsets': ['host', 'target'],
          'variables': {
            # gtk requires gmodule, but it does not list it as a dependency
            # in some misconfigured systems.
            'gtk_packages': 'gmodule-2.0 gtk+-2.0 gthread-2.0',
          },
          'conditions': [
            ['_toolset=="target"', {
              'all_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags <(gtk_packages))',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other <(gtk_packages))',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l <(gtk_packages))',
                ],
              },
            }, {
              'all_dependent_settings': {
                'cflags': [
                  '<!@(pkg-config --cflags <(gtk_packages))',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(pkg-config --libs-only-L --libs-only-other <(gtk_packages))',
                ],
                'libraries': [
                  '<!@(pkg-config --libs-only-l <(gtk_packages))',
                ],
              },
            }],
          ],
        },
        {
          'target_name': 'gtkprint',
          'type': 'none',
          'conditions': [
            ['_toolset=="target"', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags gtk+-unix-print-2.0)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other gtk+-unix-print-2.0)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l gtk+-unix-print-2.0)',
                ],
              },
            }],
          ],
        },
      ],  # targets
    }],
    [ 'use_x11==1 or ozone_platform_ozonex==1', {
      # Hide X11 and related dependencies when use_x11=0
      'targets': [
        {
          'target_name': 'x11',
          'type': 'none',
          'toolsets': ['host', 'target'],
          'conditions': [
            ['_toolset=="target"', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags x11)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other x11 xi)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l x11 xi)',
                ],
              },
            }, {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(pkg-config --cflags x11)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(pkg-config --libs-only-L --libs-only-other x11 xi)',
                ],
                'libraries': [
                  '<!@(pkg-config --libs-only-l x11 xi)',
                ],
              },
            }],
          ],
        },
        {
          'target_name': 'xcursor',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xcursor)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xcursor)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xcursor)',
            ],
          },
        },
        {
          'target_name': 'xcomposite',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xcomposite)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xcomposite)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xcomposite)',
            ],
          },
        },
        {
          'target_name': 'xdamage',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xdamage)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xdamage)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xdamage)',
            ],
          },
        },
        {
          'target_name': 'xext',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xext)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xext)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xext)',
            ],
          },
        },
        {
          'target_name': 'xfixes',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xfixes)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xfixes)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xfixes)',
            ],
          },
        },
        {
          'target_name': 'xi',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xi)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xi)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xi)',
            ],
          },
        },
        {
          'target_name': 'xrandr',
          'type': 'none',
          'toolsets': ['host', 'target'],
          'conditions': [
            ['_toolset=="target"', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags xrandr)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other xrandr)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l xrandr)',
                ],
              },
            }, {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(pkg-config --cflags xrandr)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(pkg-config --libs-only-L --libs-only-other xrandr)',
                ],
                'libraries': [
                  '<!@(pkg-config --libs-only-l xrandr)',
                ],
              },
            }],
          ],
        },
        {
          'target_name': 'xrender',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xrender)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xrender)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xrender)',
            ],
          },
        },
        {
          'target_name': 'xtst',
          'type': 'none',
          'toolsets': ['host', 'target'],
          'conditions': [
            ['_toolset=="target"', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags xtst)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other xtst)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l xtst)',
                ],
              },
            }, {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(pkg-config --cflags xtst)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(pkg-config --libs-only-L --libs-only-other xtst)',
                ],
                'libraries': [
                  '<!@(pkg-config --libs-only-l xtst)',
                ],
              },
            }]
          ]
        }
      ],  # targets
    }],
    ['use_x11==1 and chromeos==0', {
      'targets': [
        {
          'target_name': 'xscrnsaver',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xscrnsaver)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xscrnsaver)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xscrnsaver)',
            ],
          },
        },
      ],  # targets
    }],
    ['use_evdev_gestures==1', {
      'targets': [
        {
          'target_name': 'libevdev-cros',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags libevdev-cros)'
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other libevdev-cros)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l libevdev-cros)',
            ],
          },
        },
        {
          'target_name': 'libgestures',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags libgestures)'
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other libgestures)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l libgestures)',
            ],
          },
        },
      ],
    }],
    ['use_xkbcommon==1', {
      'targets': [
        {
          'target_name': 'xkbcommon',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags xkbcommon)'
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other xkbcommon)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l xkbcommon)',
            ],
          },
        },
      ],
    }],
    ['ozone_platform_gbm==1', {
      'targets': [
        {
          'target_name': 'gbm',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags gbm)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other gbm)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l gbm)',
            ],
          },
        },
      ],
    }],
    ['ozone_platform_drm==1 or ozone_platform_gbm==1', {
      'targets': [
        {
          'target_name': 'libdrm',
          'type': 'none',
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags libdrm)',
            ],
          },
          'link_settings': {
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l libdrm)',
            ],
          },
        },
      ],
    }],
    ['use_udev==1', {
      'targets': [
        {
          'target_name': 'udev',
          'type': 'static_library',
          'conditions': [
            ['_toolset=="target"', {
              'include_dirs': [
                '../..',
              ],
              'hard_dependency': 1,
              'actions': [
                {
                  'variables': {
                    'output_h': '<(SHARED_INTERMEDIATE_DIR)/library_loaders/libudev0.h',
                    'output_cc': '<(INTERMEDIATE_DIR)/libudev0_loader.cc',
                    'generator': '../../tools/generate_library_loader/generate_library_loader.py',
                  },
                  'action_name': 'generate_libudev0_loader',
                  'inputs': [
                    '<(generator)',
                  ],
                  'outputs': [
                    '<(output_h)',
                    '<(output_cc)',
                  ],
                  'action': ['python',
                             '<(generator)',
                             '--name', 'LibUdev0Loader',
                             '--output-h', '<(output_h)',
                             '--output-cc', '<(output_cc)',
                             '--header', '"third_party/libudev/libudev0.h"',
                             '--link-directly=0',
                             '<@(libudev_functions)',
                  ],
                  'message': 'Generating libudev0 library loader',
                  'process_outputs_as_sources': 1,
                },
                {
                  'variables': {
                    'output_h': '<(SHARED_INTERMEDIATE_DIR)/library_loaders/libudev1.h',
                    'output_cc': '<(INTERMEDIATE_DIR)/libudev1_loader.cc',
                    'generator': '../../tools/generate_library_loader/generate_library_loader.py',
                  },
                  'action_name': 'generate_libudev1_loader',
                  'inputs': [
                    '<(generator)',
                  ],
                  'outputs': [
                    '<(output_h)',
                    '<(output_cc)',
                  ],
                  'action': ['python',
                             '<(generator)',
                             '--name', 'LibUdev1Loader',
                             '--output-h', '<(output_h)',
                             '--output-cc', '<(output_cc)',
                             '--header', '"third_party/libudev/libudev1.h"',
                             '--link-directly=0',
                             '<@(libudev_functions)',
                  ],
                  'message': 'Generating libudev1 library loader',
                  'process_outputs_as_sources': 1,
                },
              ],
            }],
          ],
        },
      ],
    }],
    ['use_libpci==1', {
      'targets': [
        {
          'target_name': 'libpci',
          'type': 'static_library',
          'cflags': [
            '<!@(<(pkg-config) --cflags libpci)',
          ],
          'direct_dependent_settings': {
            'include_dirs': [
              '<(SHARED_INTERMEDIATE_DIR)',
            ],
            'conditions': [
              ['linux_link_libpci==1', {
                'link_settings': {
                  'ldflags': [
                    '<!@(<(pkg-config) --libs-only-L --libs-only-other libpci)',
                  ],
                  'libraries': [
                    '<!@(<(pkg-config) --libs-only-l libpci)',
                  ],
                }
              }],
            ],
          },
          'include_dirs': [
            '../..',
          ],
          'hard_dependency': 1,
          'actions': [
            {
              'variables': {
                'output_h': '<(SHARED_INTERMEDIATE_DIR)/library_loaders/libpci.h',
                'output_cc': '<(INTERMEDIATE_DIR)/libpci_loader.cc',
                'generator': '../../tools/generate_library_loader/generate_library_loader.py',
              },
              'action_name': 'generate_libpci_loader',
              'inputs': [
                '<(generator)',
              ],
              'outputs': [
                '<(output_h)',
                '<(output_cc)',
              ],
              'action': ['python',
                         '<(generator)',
                         '--name', 'LibPciLoader',
                         '--output-h', '<(output_h)',
                         '--output-cc', '<(output_cc)',
                         '--header', '<pci/pci.h>',
                         # TODO(phajdan.jr): Report problem to pciutils project
                         # and get it fixed so that we don't need --use-extern-c.
                         '--use-extern-c',
                         '--link-directly=<(linux_link_libpci)',
                         '<@(libpci_functions)',
              ],
              'message': 'Generating libpci library loader',
              'process_outputs_as_sources': 1,
            },
          ],
        },
      ],
    }],
  ],  # conditions
  'targets': [
    {
      'target_name': 'dbus',
      'type': 'none',
      'direct_dependent_settings': {
        'cflags': [
          '<!@(<(pkg-config) --cflags dbus-1)',
        ],
      },
      'link_settings': {
        'ldflags': [
          '<!@(<(pkg-config) --libs-only-L --libs-only-other dbus-1)',
        ],
        'libraries': [
          '<!@(<(pkg-config) --libs-only-l dbus-1)',
        ],
      },
    },
    {
      'target_name': 'fontconfig',
      'type': 'none',
      'conditions': [
        ['_toolset=="target"', {
          'conditions': [
            ['use_system_fontconfig==1', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags fontconfig)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other fontconfig)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l fontconfig)',
                ],
              },
            }, {  # use_system_fontconfig==0
              'dependencies': [
                '../../third_party/fontconfig/fontconfig.gyp:fontconfig',
              ],
              'export_dependent_settings' : [
                '../../third_party/fontconfig/fontconfig.gyp:fontconfig',
              ],
            }],
          ],
        }],
      ],
    },
    {
      'target_name': 'freetype2',
      'type': 'none',
      'conditions': [
        ['_toolset=="target"', {
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags freetype2)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other freetype2)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l freetype2)',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'gconf',
      'type': 'none',
      'conditions': [
        ['use_gconf==1 and _toolset=="target"', {
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags gconf-2.0)',
            ],
            'defines': [
              'USE_GCONF',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other gconf-2.0)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l gconf-2.0)',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'gio',
      'type': 'static_library',
      'conditions': [
        ['use_gio==1 and _toolset=="target"', {
          'cflags': [
            '<!@(<(pkg-config) --cflags gio-2.0)',
          ],
          'variables': {
            'gio_warning_define': [
              # glib >=2.40 deprecate g_settings_list_schemas in favor of
              # g_settings_schema_source_list_schemas. This function is not
              # available on earlier versions that we still need to support
              # (specifically, 2.32), so disable the warning.
              # TODO(mgiuca): Remove this suppression (and variable) when we
              # drop support for Ubuntu 13.10 (saucy) and earlier. Update the
              # code to use g_settings_schema_source_list_schemas instead.
              'GLIB_DISABLE_DEPRECATION_WARNINGS',
            ],
          },
          'defines': [
            '<(gio_warning_define)',
          ],
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags gio-2.0)',
            ],
            'defines': [
              'USE_GIO',
              '<(gio_warning_define)',
            ],
            'include_dirs': [
              '<(SHARED_INTERMEDIATE_DIR)',
            ],
          },
          'include_dirs': [
            '../..',
          ],
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other gio-2.0)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l gio-2.0)',
            ],
            'conditions': [
              ['linux_link_gsettings==0 and OS=="linux"', {
                'libraries': [
                  '-ldl',
                ],
              }],
            ],
          },
          'hard_dependency': 1,
          'actions': [
            {
              'variables': {
                'output_h': '<(SHARED_INTERMEDIATE_DIR)/library_loaders/libgio.h',
                'output_cc': '<(INTERMEDIATE_DIR)/libgio_loader.cc',
                'generator': '../../tools/generate_library_loader/generate_library_loader.py',
              },
              'action_name': 'generate_libgio_loader',
              'inputs': [
                '<(generator)',
              ],
              'outputs': [
                '<(output_h)',
                '<(output_cc)',
              ],
              'action': ['python',
                         '<(generator)',
                         '--name', 'LibGioLoader',
                         '--output-h', '<(output_h)',
                         '--output-cc', '<(output_cc)',
                         '--header', '<gio/gio.h>',
                         '--link-directly=<(linux_link_gsettings)',
                         '<@(libgio_functions)',
              ],
              'message': 'Generating libgio library loader',
              'process_outputs_as_sources': 1,
            },
          ],
        }],
      ],
    },
    {
      'target_name': 'glib',
      'type': 'none',
      'toolsets': ['host', 'target'],
      'variables': {
        'glib_packages': 'glib-2.0 gmodule-2.0 gobject-2.0 gthread-2.0',
      },
      'conditions': [
        ['_toolset=="target"', {
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags <(glib_packages))',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other <(glib_packages))',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l <(glib_packages))',
            ],
          },
        }, {
          'direct_dependent_settings': {
            'cflags': [
              '<!@(pkg-config --cflags <(glib_packages))',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(pkg-config --libs-only-L --libs-only-other <(glib_packages))',
            ],
            'libraries': [
              '<!@(pkg-config --libs-only-l <(glib_packages))',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'gnome_keyring',
      'type': 'none',
      'conditions': [
        ['use_gnome_keyring==1', {
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags gnome-keyring-1)',
            ],
            'defines': [
              'USE_GNOME_KEYRING',
            ],
            'conditions': [
              ['linux_link_gnome_keyring==0', {
                'defines': ['DLOPEN_GNOME_KEYRING'],
              }],
            ],
          },
          'conditions': [
            ['linux_link_gnome_keyring!=0', {
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other gnome-keyring-1)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l gnome-keyring-1)',
                ],
              },
            }, {
              'conditions': [
                ['OS=="linux"', {
                 'link_settings': {
                   'libraries': [
                     '-ldl',
                   ],
                 },
                }],
              ],
            }],
          ],
        }],
      ],
    },
    {
      # The unit tests use a few convenience functions from the GNOME
      # Keyring library directly. We ignore linux_link_gnome_keyring and
      # link directly in this version of the target to allow this.
      # *** Do not use this target in the main binary! ***
      'target_name': 'gnome_keyring_direct',
      'type': 'none',
      'conditions': [
        ['use_gnome_keyring==1', {
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags gnome-keyring-1)',
            ],
            'defines': [
              'USE_GNOME_KEYRING',
            ],
            'conditions': [
              ['linux_link_gnome_keyring==0', {
                'defines': ['DLOPEN_GNOME_KEYRING'],
              }],
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other gnome-keyring-1)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l gnome-keyring-1)',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'libbrlapi',
      'type': 'static_library',
      'all_dependent_settings': {
        'include_dirs': [
          '<(SHARED_INTERMEDIATE_DIR)',
        ],
        'defines': [
          'USE_BRLAPI',
        ],
        'conditions': [
          ['linux_link_libbrlapi==1', {
            'link_settings': {
              'libraries': [
                '-lbrlapi',
              ],
            }
          }],
        ],
      },
      'include_dirs': [
        '../..',
      ],
      'hard_dependency': 1,
      'actions': [
        {
          'variables': {
            'output_h': '<(SHARED_INTERMEDIATE_DIR)/library_loaders/libbrlapi.h',
            'output_cc': '<(INTERMEDIATE_DIR)/libbrlapi_loader.cc',
            'generator': '../../tools/generate_library_loader/generate_library_loader.py',
          },
          'action_name': 'generate_brlapi_loader',
          'inputs': [
            '<(generator)',
          ],
          'outputs': [
            '<(output_h)',
            '<(output_cc)',
          ],
          'action': ['python',
                     '<(generator)',
                     '--name', 'LibBrlapiLoader',
                     '--output-h', '<(output_h)',
                     '--output-cc', '<(output_cc)',
                     '--header', '<brlapi.h>',
                     '--link-directly=<(linux_link_libbrlapi)',
                     '<@(libbrlapi_functions)',
          ],
          'message': 'Generating libbrlapi library loader',
          'process_outputs_as_sources': 1,
        },
      ],
    },
    {
      'target_name': 'libcap',
      'type': 'none',
      'link_settings': {
        'libraries': [
          '-lcap',
        ],
      },
    },
    {
      'target_name': 'libresolv',
      'type': 'none',
      'link_settings': {
        'libraries': [
          '-lresolv',
        ],
      },
    },
    {
      # GN version: //third_party/speech-dispatcher
      'target_name': 'libspeechd',
      'type': 'static_library',
      'direct_dependent_settings': {
        'include_dirs': [
          '<(SHARED_INTERMEDIATE_DIR)',
        ],
        'conditions': [
          ['linux_link_libspeechd==1', {
            'link_settings': {
              'libraries': [
                '-lspeechd',
              ],
            }
          }],
        ],
      },
      'include_dirs': [
        '../..',
      ],
      'hard_dependency': 1,
      'actions': [
        {
          'variables': {
            'output_h': '<(SHARED_INTERMEDIATE_DIR)/library_loaders/libspeechd.h',
            'output_cc': '<(INTERMEDIATE_DIR)/libspeechd_loader.cc',
            'generator': '../../tools/generate_library_loader/generate_library_loader.py',

            # speech-dispatcher >= 0.8 installs libspeechd.h into
            # speech-dispatcher/libspeechd.h, whereas speech-dispatcher < 0.8
            # puts libspeechd.h in the top-level include directory.
            # Since we need to support both cases for now, we ship a copy of
            # libspeechd.h in third_party/speech-dispatcher. If the user
            # prefers to link against the speech-dispatcher directly, the
            # `libspeechd_h_prefix' variable can be passed to gyp with a value
            # such as "speech-dispatcher/" that will be prepended to
            # "libspeechd.h" in the #include directive.
            # TODO(phaldan.jr): Once we do not need to support
            # speech-dispatcher < 0.8 we can get rid of all this (including
            # third_party/speech-dispatcher) and just include
            # speech-dispatcher/libspeechd.h unconditionally.
            'libspeechd_h_prefix%': '',
          },
          'action_name': 'generate_libspeechd_loader',
          'inputs': [
            '<(generator)',
          ],
          'outputs': [
            '<(output_h)',
            '<(output_cc)',
          ],
          'action': ['python',
                     '<(generator)',
                     '--name', 'LibSpeechdLoader',
                     '--output-h', '<(output_h)',
                     '--output-cc', '<(output_cc)',
                     '--header', '<<(libspeechd_h_prefix)libspeechd.h>',
                     '--bundled-header',
                     '"third_party/speech-dispatcher/libspeechd.h"',
                     '--link-directly=<(linux_link_libspeechd)',
                     'spd_open',
                     'spd_say',
                     'spd_stop',
                     'spd_close',
                     'spd_pause',
                     'spd_resume',
                     'spd_set_notification_on',
                     'spd_set_voice_rate',
                     'spd_set_voice_pitch',
                     'spd_list_synthesis_voices',
                     'spd_set_synthesis_voice',
                     'spd_list_modules',
                     'spd_set_output_module',
                     'spd_set_language',
          ],
          'message': 'Generating libspeechd library loader',
          'process_outputs_as_sources': 1,
        },
      ],
    },
    {
      'target_name': 'pangocairo',
      'type': 'none',
      'toolsets': ['host', 'target'],
      'conditions': [
        ['use_pango==1 and use_cairo==1', {
          'conditions': [
            ['_toolset=="target"', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags pangocairo pangoft2)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other pangocairo pangoft2)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l pangocairo pangoft2)',
                ],
              },
            }, {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(pkg-config --cflags pangocairo pangoft2)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(pkg-config --libs-only-L --libs-only-other pangocairo pangoft2)',
                ],
                'libraries': [
                  '<!@(pkg-config --libs-only-l pangocairo pangoft2)',
                ],
              },
            }],
          ],
        }],
      ],
    },
    {
      'target_name': 'ssl',
      'type': 'none',
      'conditions': [
        ['_toolset=="target"', {
          'conditions': [
            ['use_openssl==1', {
              'dependencies': [
                '../../third_party/boringssl/boringssl.gyp:boringssl',
              ],
            }, {
              'dependencies': [
                '../../net/third_party/nss/ssl.gyp:libssl',
              ],
              'direct_dependent_settings': {
                'include_dirs+': [
                  # We need for our local copies of the libssl3 headers to come
                  # before other includes, as we are shadowing system headers.
                  '<(DEPTH)/net/third_party/nss/ssl',
                ],
              },
            }],
            # Link in the system NSS if it is used for either the internal
            # crypto library (use_openssl==0) or platform certificate
            # library (use_nss_certs==1).
            ['use_openssl==0 or use_nss_certs==1', {
              'direct_dependent_settings': {
                'cflags': [
                  '<!@(<(pkg-config) --cflags nss)',
                ],
              },
              'link_settings': {
                'ldflags': [
                  '<!@(<(pkg-config) --libs-only-L --libs-only-other nss)',
                ],
                'libraries': [
                  '<!@(<(pkg-config) --libs-only-l nss | sed -e "s/-lssl3//")',
                ],
              },
              'conditions': [
                ['clang==1', {
                  'direct_dependent_settings': {
                    'cflags': [
                      # There is a broken header guard in /usr/include/nss/secmod.h:
                      # https://bugzilla.mozilla.org/show_bug.cgi?id=884072
                      '-Wno-header-guard',
                    ],
                  },
                }],
              ],
            }],
          ]
        }],
      ],
    },
  ],
}
