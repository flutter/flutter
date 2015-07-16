# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'chromium_code': 1,
  },
  'targets': [
    {
      # GN version: //tools/android/forwarder2
      'target_name': 'forwarder2',
      'type': 'none',
      'dependencies': [
        'device_forwarder',
        'host_forwarder#host',
      ],
      # For the component build, ensure dependent shared libraries are stripped
      # and put alongside forwarder to simplify pushing to the device.
      'variables': {
         'output_dir': '<(PRODUCT_DIR)/forwarder_dist/',
         'native_binary': '<(PRODUCT_DIR)/device_forwarder',
      },
      'includes': ['../../../build/android/native_app_dependencies.gypi'],
    },
    {
      # GN version: //tools/android/forwarder2:device_forwarder
      'target_name': 'device_forwarder',
      'type': 'executable',
      'toolsets': ['target'],
      'dependencies': [
        '../../../base/base.gyp:base',
        '../../../build/android/pylib/device/commands/commands.gyp:chromium_commands',
        '../common/common.gyp:android_tools_common',
      ],
      'include_dirs': [
        '../../..',
      ],
      'sources': [
        'command.cc',
        'common.cc',
        'daemon.cc',
        'device_controller.cc',
        'device_forwarder_main.cc',
        'device_listener.cc',
        'forwarder.cc',
        'forwarders_manager.cc',
        'pipe_notifier.cc',
        'socket.cc',
      ],
    },
    {
      # GN version: //tools/android/forwarder2:host_forwarder
      'target_name': 'host_forwarder',
      'type': 'executable',
      'toolsets': ['host'],
      'dependencies': [
        '../../../base/base.gyp:base',
        '../common/common.gyp:android_tools_common',
      ],
      'include_dirs': [
        '../../..',
      ],
      'sources': [
        'command.cc',
        'common.cc',
        'daemon.cc',
        'forwarder.cc',
        'forwarders_manager.cc',
        'host_controller.cc',
        'host_forwarder_main.cc',
        'pipe_notifier.cc',
        'socket.cc',
      ],
    },
  ],
}
