# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Functions that configure the shell before it is run manipulating its argument
list.
"""

import os.path
import sys
import urlparse

from devtoolslib.android_shell import AndroidShell
from devtoolslib.linux_shell import LinuxShell

# When spinning up servers for local origins, we want to use predictable ports
# so that caching works between subsequent runs with the same command line.
_LOCAL_ORIGIN_PORT = 31840
_MAPPINGS_BASE_PORT = 31841
_SKY_SERVER_PORT = 9998


def _is_web_url(dest):
  return True if urlparse.urlparse(dest).scheme else False


def _host_local_url_destination(shell, dest_file, port):
  """Starts a local server to host |dest_file|.

  Returns:
    Url of the hosted file.
  """
  directory = os.path.dirname(dest_file)
  if not os.path.exists(directory):
    raise ValueError('local path passed as --map-url destination '
                     'does not exist')
  server_url = shell.ServeLocalDirectory(directory, port)
  return server_url + os.path.relpath(dest_file, directory)


def _host_local_origin_destination(shell, dest_dir, port):
  """Starts a local server to host |dest_dir|.

  Returns:
    Url of the hosted directory.
  """
  return shell.ServeLocalDirectory(dest_dir, port)


def _rewrite(mapping, host_destination_functon, shell, port):
  """Takes a mapping given as <src>=<dest> and rewrites the <dest> part to be
  hosted locally using the given function if <dest> is not a web url.
  """
  parts = mapping.split('=')
  if len(parts) != 2:
    raise ValueError('each mapping value should be in format '
                     '"<url>=<url-or-local-path>"')
  if _is_web_url(parts[1]):
    # The destination is a web url, do nothing.
    return mapping

  src = parts[0]
  dest = host_destination_functon(shell, parts[1], port)
  return src + '=' + dest


def _apply_mappings(shell, original_arguments, map_urls, map_origins):
  """Applies mappings for specified urls and origins. For each local path
  specified as destination a local server will be spawned and the mapping will
  be rewritten accordingly.

  Args:
    shell: The shell that is being configured.
    original_arguments: Current list of shell arguments.
    map_urls: List of url mappings, each in the form of
      <url>=<url-or-local-path>.
    map_origins: List of origin mappings, each in the form of
        <origin>=<url-or-local-path>.

  Returns:
    The updated argument list.
  """
  next_port = _MAPPINGS_BASE_PORT
  args = original_arguments
  if map_urls:
    # Sort the mappings to preserve caching regardless of argument order.
    for map_url in sorted(map_urls):
      mapping = _rewrite(map_url, _host_local_url_destination, shell, next_port)
      next_port += 1
      # All url mappings need to be coalesced into one shell argument.
      args = append_to_argument(args, '--url-mappings=', mapping)

  if map_origins:
    for map_origin in sorted(map_origins):
      mapping = _rewrite(map_origin, _host_local_origin_destination, shell,
                         next_port)
      next_port += 1
      # Origin mappings are specified as separate, repeated shell arguments.
      args.append('--map-origin=' + mapping)
  return args


def _configure_sky(shell, root_path, sky_packages_path, sky_target):
  """Configures additional mappings and a server needed to run the given Sky
  app.

  Args:
    root_path: Local path to the root from which Sky apps will be served.
    sky_packages_path: Local path to the root from which Sky packages will be
        served.
    sky_target: Path to the Sky app to be run, relative to |root_path|.

  Returns:
    Arguments that need to be appended to the shell argument list.
  """
  # Configure a server to serve the checkout root at / (so that Sky examples
  # are accessible using a root-relative path) and Sky packages at /packages.
  # This is independent from the server that potentially serves the origin
  # directory containing the mojo: apps.
  additional_mappings = [
      ('packages/', sky_packages_path),
  ]
  server_url = shell.ServeLocalDirectory(root_path, port=_SKY_SERVER_PORT,
      additional_mappings=additional_mappings)

  args = []
  # Configure the content type mappings for the sky_viewer. This is needed
  # only for the Sky apps that do not declare mojo:sky_viewer in a shebang,
  # and it is unfortunate as it configures the shell to map all items of the
  # application/dart content-type as Sky apps.
  # TODO(ppi): drop this part once we can rely on the Sky files declaring
  # correct shebang.
  args = append_to_argument(args, '--content-handlers=',
                                            'text/sky,mojo:sky_viewer')
  args = append_to_argument(args, '--content-handlers=',
                                            'application/dart,mojo:sky_viewer')

  # Configure the window manager to embed the sky_viewer.
  sky_url = server_url + sky_target
  args.append('mojo:window_manager %s' % sky_url)
  return args


def configure_local_origin(shell, local_dir, fixed_port=True):
  """Sets up a local http server to serve files in |local_dir| along with
  device port forwarding if needed.

  Returns:
    The list of arguments to be appended to the shell argument list.
  """

  origin_url = shell.ServeLocalDirectory(
      local_dir, _LOCAL_ORIGIN_PORT if fixed_port else 0)
  return ["--origin=" + origin_url]


def append_to_argument(arguments, key, value, delimiter=","):
  """Looks for an argument of the form "key=val1,val2" within |arguments| and
  appends |value| to it.

  If the argument is not present in |arguments| it is added.

  Args:
    arguments: List of arguments for the shell.
    key: Identifier of the argument, including the equal sign, eg.
        "--content-handlers=".
    value: The value to be appended, after |delimeter|, to the argument.
    delimiter: The string used to separate values within the argument.

  Returns:
    The updated argument list.
  """
  assert key and key.endswith('=')
  assert value

  for i, argument in enumerate(arguments):
    if not argument.startswith(key):
      continue
    arguments[i] = argument + delimiter + value
    break
  else:
    arguments.append(key + value)

  return arguments


def add_shell_arguments(parser):
  """Adds argparse arguments allowing to configure shell abstraction using
  configure_shell() below.
  """
  # Arguments configuring the shell run.
  parser.add_argument('--shell-path', help='Path of the Mojo shell binary.')
  parser.add_argument('--android', help='Run on Android',
                      action='store_true')
  parser.add_argument('--origin', help='Origin for mojo: URLs. This can be a '
                      'web url or a local directory path.')
  parser.add_argument('--map-url', action='append',
                      help='Define a mapping for a url in the format '
                      '<url>=<url-or-local-file-path>')
  parser.add_argument('--map-origin', action='append',
                      help='Define a mapping for a url origin in the format '
                      '<origin>=<url-or-local-file-path>')
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


class ShellConfigurationException(Exception):
  """Represents an error preventing creating a functional shell abstraction."""
  pass


def configure_shell(config_args, shell_args):
  """
  Produces a shell abstraction configured using the parsed arguments defined in
  add_shell_arguments().

  Args:
    config_args: Parsed arguments added using add_shell_arguments().
    shell_args: Additional raw shell arguments to be passed to the shell. We
        need to take these into account as some parameters need to appear only
        once on the argument list (e.g. url-mappings) so we need to coalesce any
        overrides and the existing value into just one argument.

  Returns:
    A tuple of (shell, shell_args).

  Throws:
    ShellConfigurationException if shell abstraction could not be configured.
  """
  if config_args.android:
    verbose_pipe = sys.stdout if config_args.verbose else None

    shell = AndroidShell(config_args.adb_path, config_args.target_device,
                         logcat_tags=config_args.logcat_tags,
                         verbose_pipe=verbose_pipe)
    device_status, error = shell.CheckDevice()
    if not device_status:
      raise ShellConfigurationException('Device check failed: ' + error)
    if config_args.shell_path:
      shell.InstallApk(config_args.shell_path)
  else:
    if not config_args.shell_path:
      raise ShellConfigurationException('Can not run without a shell binary. '
                                        'Please pass --shell-path.')
    shell = LinuxShell(config_args.shell_path)
    if config_args.use_osmesa:
      shell_args.append('--args-for=mojo:native_viewport_service --use-osmesa')

  shell_args = _apply_mappings(shell, shell_args, config_args.map_url,
                               config_args.map_origin)

  if config_args.origin:
    if _is_web_url(config_args.origin):
      shell_args.append('--origin=' + config_args.origin)
    else:
      shell_args.extend(configure_local_origin(shell, config_args.origin,
                                             fixed_port=True))

  return shell, shell_args
