# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Functions that configure the shell before it is run manipulating its argument
list.
"""

import os.path
import urlparse

# When spinning up servers for local origins, we want to use predictable ports
# so that caching works between subsequent runs with the same command line.
_LOCAL_ORIGIN_PORT = 31840
_MAPPINGS_BASE_PORT = 31841

# Port on which the mojo:debugger http server will be available on the host
# machine.
_MOJO_DEBUGGER_PORT = 7777

_SKY_SERVER_PORT = 9998


def _HostLocalUrlDestination(shell, dest_file, port):
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


def _HostLocalOriginDestination(shell, dest_dir, port):
  """Starts a local server to host |dest_dir|.

  Returns:
    Url of the hosted directory.
  """
  return shell.ServeLocalDirectory(dest_dir, port)


def _Rewrite(mapping, host_destination_functon, shell, port):
  """Takes a mapping given as <src>=<dest> and rewrites the <dest> part to be
  hosted locally using the given function if <dest> is not a web url.
  """
  parts = mapping.split('=')
  if len(parts) != 2:
    raise ValueError('each mapping value should be in format '
                     '"<url>=<url-or-local-path>"')
  if urlparse.urlparse(parts[1])[0]:
    # The destination is a web url, do nothing.
    return mapping

  src = parts[0]
  dest = host_destination_functon(shell, parts[1], port)
  return src + '=' + dest



def ApplyMappings(shell, original_arguments, map_urls, map_origins):
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
      mapping = _Rewrite(map_url, _HostLocalUrlDestination, shell, next_port)
      next_port += 1
      # All url mappings need to be coalesced into one shell argument.
      args = AppendToArgument(args, '--url-mappings=', mapping)

  if map_origins:
    for map_origin in sorted(map_origins):
      mapping = _Rewrite(map_origin, _HostLocalOriginDestination, shell,
                         next_port)
      next_port += 1
      # Origin mappings are specified as separate, repeated shell arguments.
      args.append('--map-origin=' + mapping)
  return args


def ConfigureDebugger(shell):
  """Configures mojo:debugger to run and sets up port forwarding for its http
  server if the shell is running on a device.

  Returns:
    Arguments that need to be appended to the shell argument list in order to
    run with the debugger.
  """
  shell.ForwardHostPortToShell(_MOJO_DEBUGGER_PORT)
  return ['mojo:debugger %d' % _MOJO_DEBUGGER_PORT]


def ConfigureSky(shell, root_path, sky_packages_path, sky_target):
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
  args = AppendToArgument(args, '--content-handlers=',
                          'text/sky,mojo:sky_viewer')
  args = AppendToArgument(args, '--content-handlers=',
                          'application/dart,mojo:sky_viewer')

  # Configure the window manager to embed the sky_viewer.
  sky_url = server_url + sky_target
  args.append('mojo:window_manager %s' % sky_url)
  return args


def ConfigureLocalOrigin(shell, local_dir, fixed_port=True):
  """Sets up a local http server to serve files in |local_dir| along with
  device port forwarding if needed.

  Returns:
    The list of arguments to be appended to the shell argument list.
  """

  origin_url = shell.ServeLocalDirectory(
      local_dir, _LOCAL_ORIGIN_PORT if fixed_port else 0)
  return ["--origin=" + origin_url]


def AppendToArgument(arguments, key, value, delimiter=","):
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
