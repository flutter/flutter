# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Produces configured shell abstractions.

This module knows how to produce a configured shell abstraction based on
shell_config.ShellConfig.
"""

import os.path
import sys
import urlparse

from devtoolslib.android_shell import AndroidShell
from devtoolslib.linux_shell import LinuxShell
from devtoolslib.shell_config import ShellConfigurationException

# When spinning up servers for local origins, we want to use predictable ports
# so that caching works between subsequent runs with the same command line.
_LOCAL_ORIGIN_PORT = 31840
_MAPPINGS_BASE_PORT = 31841


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
  server_url = shell.serve_local_directory(directory, port)
  return server_url + os.path.relpath(dest_file, directory)


def _host_local_origin_destination(shell, dest_dir, port):
  """Starts a local server to host |dest_dir|.

  Returns:
    Url of the hosted directory.
  """
  return shell.serve_local_directory(dest_dir, port)


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


def _configure_sky(shell_args):
  """Maps mojo:sky_viewer as a content handler for dart applications.
  app.

  Args:
    shell_args: Current list of shell arguments.

  Returns:
    Updated list of shell arguments.
  """
  # Configure the content type mappings for the sky_viewer. This is needed
  # only for the Sky apps that do not declare mojo:sky_viewer in a shebang.
  # TODO(ppi): drop this part once we can rely on the Sky files declaring
  # correct shebang.
  shell_args = append_to_argument(shell_args, '--content-handlers=',
                                            'text/sky,mojo:sky_viewer')
  shell_args = append_to_argument(shell_args, '--content-handlers=',
                                            'application/dart,mojo:sky_viewer')
  return shell_args


def configure_local_origin(shell, local_dir, fixed_port=True):
  """Sets up a local http server to serve files in |local_dir| along with
  device port forwarding if needed.

  Returns:
    The list of arguments to be appended to the shell argument list.
  """

  origin_url = shell.serve_local_directory(
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


def _configure_dev_server(shell, shell_args, dev_server_config):
  """Sets up a dev server on the host according to |dev_server_config|.

  Args:
    shell: The shell that is being configured.
    shell_arguments: Current list of shell arguments.
    dev_server_config: Instance of shell_config.DevServerConfig describing the
        dev server to be set up.

  Returns:
    The updated argument list.
  """
  server_url = shell.serve_local_directories(dev_server_config.mappings)
  shell_args.append('--map-origin=%s=%s' % (dev_server_config.host, server_url))
  print "Configured %s locally to serve:" % (dev_server_config.host)
  for mapping_prefix, mapping_path in dev_server_config.mappings:
    print "  /%s -> %s" % (mapping_prefix, mapping_path)
  return shell_args


def get_shell(shell_config, shell_args):
  """
  Produces a shell abstraction configured according to |shell_config|.

  Args:
    shell_config: Instance of shell_config.ShellConfig.
    shell_args: Additional raw shell arguments to be passed to the shell. We
        need to take these into account as some parameters need to appear only
        once on the argument list (e.g. url-mappings) so we need to coalesce any
        overrides and the existing value into just one argument.

  Returns:
    A tuple of (shell, shell_args). |shell| is the configured shell abstraction,
    |shell_args| is updated list of shell arguments.

  Throws:
    ShellConfigurationException if shell abstraction could not be configured.
  """
  if shell_config.android:
    verbose_pipe = sys.stdout if shell_config.verbose else None

    shell = AndroidShell(shell_config.adb_path, shell_config.target_device,
                         logcat_tags=shell_config.logcat_tags,
                         verbose_pipe=verbose_pipe)

    device_status, error = shell.check_device()
    if not device_status:
      raise ShellConfigurationException('Device check failed: ' + error)
    if shell_config.shell_path:
      shell.install_apk(shell_config.shell_path)
  else:
    if not shell_config.shell_path:
      raise ShellConfigurationException('Can not run without a shell binary. '
                                        'Please pass --shell-path.')
    shell = LinuxShell(shell_config.shell_path)
    if shell_config.use_osmesa:
      shell_args.append('--args-for=mojo:native_viewport_service --use-osmesa')

  shell_args = _apply_mappings(shell, shell_args, shell_config.map_url_list,
                               shell_config.map_origin_list)

  if shell_config.origin:
    if _is_web_url(shell_config.origin):
      shell_args.append('--origin=' + shell_config.origin)
    else:
      shell_args.extend(configure_local_origin(shell, shell_config.origin,
                                               fixed_port=True))

  if shell_config.sky:
    shell_args = _configure_sky(shell_args)

  for dev_server_config in shell_config.dev_servers:
    shell_args = _configure_dev_server(shell, shell_args, dev_server_config)

  return shell, shell_args
