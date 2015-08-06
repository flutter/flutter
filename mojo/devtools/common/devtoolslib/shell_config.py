# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Configuration for the shell abstraction.

This module declares ShellConfig and knows how to compute it from command-line
arguments, applying any default paths inferred from the checkout, configuration
file, etc.
"""

import ast

from devtoolslib import paths


class ShellConfigurationException(Exception):
  """Represents an error preventing creating a functional shell abstraction."""
  pass


class ShellConfig(object):
  """Configuration for the shell abstraction."""

  def __init__(self):
    self.android = None
    self.shell_path = None
    self.origin = None
    self.map_url_list = []
    self.map_origin_list = []
    self.dev_servers = []
    self.sky = None
    self.verbose = None

    # Android-only.
    self.adb_path = None
    self.target_device = None
    self.logcat_tags = None

    # Desktop-only.
    self.use_osmesa = None


class DevServerConfig(object):
  """Configuration for a development server running on a host and available to
  the shell.
  """
  def __init__(self):
    self.host = None
    self.mappings = None


def add_shell_arguments(parser):
  """Adds argparse arguments allowing to configure shell abstraction using
  configure_shell() below.
  """
  # Arguments configuring the shell run.
  parser.add_argument('--android', help='Run on Android',
                      action='store_true')
  parser.add_argument('--shell-path', help='Path of the Mojo shell binary.')
  parser.add_argument('--origin', help='Origin for mojo: URLs. This can be a '
                      'web url or a local directory path.')
  parser.add_argument('--map-url', action='append',
                      help='Define a mapping for a url in the format '
                      '<url>=<url-or-local-file-path>')
  parser.add_argument('--map-origin', action='append',
                      help='Define a mapping for a url origin in the format '
                      '<origin>=<url-or-local-file-path>')
  parser.add_argument('--sky', action='store_true',
                      help='Maps mojo:sky_viewer as the content handler for '
                           'dart apps.')
  parser.add_argument('-v', '--verbose', action="store_true",
                      help="Increase output verbosity")

  android_group = parser.add_argument_group('Android-only',
      'These arguments apply only when --android is passed.')
  android_group.add_argument('--adb-path', help='Path of the adb binary.')
  android_group.add_argument('--target-device', help='Device to run on.')
  android_group.add_argument('--logcat-tags', help='Comma-separated list of '
                             'additional logcat tags to display.')

  desktop_group = parser.add_argument_group('Desktop-only',
      'These arguments apply only when running on desktop.')
  desktop_group.add_argument('--use-osmesa', action='store_true',
                             help='Configure the native viewport service '
                             'for off-screen rendering.')

  config_file_group = parser.add_argument_group('Configuration file',
      'These arguments allow to modify the behavior regarding the mojoconfig '
      'file.')
  config_file_group.add_argument('--config-file', type=file,
                                 help='Path of the configuration file to use.')
  config_file_group.add_argument('--no-config-file', action='store_true',
                                 help='Pass to skip automatic discovery of the '
                                 'mojoconfig file.')

  # Arguments allowing to indicate the build directory we are targeting when
  # running within a Chromium-like checkout (e.g. Mojo checkout). These will go
  # away once we have devtools config files, see
  # https://github.com/domokit/devtools/issues/28.
  chromium_checkout_group = parser.add_argument_group(
      'Chromium-like checkout configuration',
      'These arguments allow to infer paths to tools and build results '
      'when running within a Chromium-like checkout')
  debug_group = chromium_checkout_group.add_mutually_exclusive_group()
  debug_group.add_argument('--debug', help='Debug build (default)',
                           default=True, action='store_true')
  debug_group.add_argument('--release', help='Release build', default=False,
                           dest='debug', action='store_false')
  chromium_checkout_group.add_argument('--target-cpu',
                                     help='CPU architecture to run for.',
                                     choices=['x64', 'x86', 'arm'])


def _discover_config_file():
  config_file_path = paths.find_within_ancestors('mojoconfig')
  if not config_file_path:
    return None
  return open(config_file_path, 'r')


def _read_config_file(config_file, aliases):
  spec = config_file.read()
  for alias_pattern, alias_value in aliases:
    spec = spec.replace(alias_pattern, alias_value)
  return ast.literal_eval(spec)


def get_shell_config(script_args):
  """Processes command-line options defined in add_shell_arguments(), applying
  any inferred default paths and produces an instance of ShellConfig.

  Returns:
    An instance of ShellConfig.
  """
  # Infer paths based on the Chromium configuration options
  # (--debug/--release, etc.), if running within a Chromium-like checkout.
  inferred_paths = paths.infer_paths(script_args.android, script_args.debug,
                                     script_args.target_cpu)
  shell_config = ShellConfig()

  shell_config.android = script_args.android
  shell_config.shell_path = (script_args.shell_path or
                             inferred_paths['shell_path'])
  shell_config.origin = script_args.origin
  shell_config.map_url_list = script_args.map_url
  shell_config.map_origin_list = script_args.map_origin
  shell_config.sky = script_args.sky
  shell_config.verbose = script_args.verbose

  # Android-only.
  shell_config.adb_path = (script_args.adb_path or inferred_paths['adb_path'])
  shell_config.target_device = script_args.target_device
  shell_config.logcat_tags = script_args.logcat_tags

  # Desktop-only.
  shell_config.use_osmesa = script_args.use_osmesa

  if (shell_config.android and not shell_config.origin and
      inferred_paths['build_dir_path']):
    shell_config.origin = inferred_paths['build_dir_path']

  # Read the mojoconfig file.
  config_file = script_args.config_file
  if not script_args.no_config_file:
    config_file = config_file or _discover_config_file()

  if config_file:
    with config_file:
      config_file_aliases = []
      if inferred_paths['build_dir_path']:
        config_file_aliases.append(('@{BUILD_DIR}',
                                    inferred_paths['build_dir_path']))

      config = None
      try:
        if script_args.verbose:
          print 'Reading config file from: ' + config_file.name
        config = _read_config_file(config_file, config_file_aliases)
      except SyntaxError:
        raise ShellConfigurationException('Failed to parse the mojoconfig '
                                          'file.')

    if 'dev_servers' in config:
      try:
        for dev_server_spec in config['dev_servers']:
          dev_server_config = DevServerConfig()
          dev_server_config.host = dev_server_spec['host']
          dev_server_config.mappings = []
          for prefix, path in dev_server_spec['mappings']:
            dev_server_config.mappings.append((prefix, path))
          shell_config.dev_servers.append(dev_server_config)
      except (ValueError, KeyError):
        raise ShellConfigurationException('Failed to parse dev_servers in '
                                          'the mojoconfig file.')
  return shell_config
