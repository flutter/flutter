# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

from .config import Config
from .gn import BuildDirectoryForConfig

class Paths(object):
  """Provides commonly used paths"""

  def __init__(self, config=None, build_dir=None):
    """Specify either a config or a build_dir to generate paths to binary
    artifacts."""
    self.src_root = os.path.abspath(os.path.join(__file__,
      os.pardir, os.pardir, os.pardir, os.pardir))
    self.mojo_dir = os.path.join(self.src_root, "mojo")
    self.adb_path = os.path.join(self.src_root, 'third_party', 'android_tools',
                                 'sdk', 'platform-tools', 'adb')

    if config:
      self.build_dir = BuildDirectoryForConfig(config, self.src_root)
    elif build_dir is not None:
      self.build_dir = os.path.abspath(build_dir)
    else:
      self.build_dir = None

    if self.build_dir is not None:
      self.mojo_shell_path = os.path.join(self.build_dir, "mojo_shell")
      self.sky_shell_path = os.path.join(self.build_dir, "sky_shell")
      # TODO(vtl): Use the host OS here, since |config| may not be available.
      # In any case, if the target is Windows, but the host isn't, using
      # |os.path| isn't correct....
      if Config.GetHostOS() == Config.OS_WINDOWS:
        self.mojo_shell_path += ".exe"
        self.sky_shell_path += ".exe"
      if config and config.target_os == Config.OS_ANDROID:
        self.target_mojo_shell_path = os.path.join(self.build_dir,
                                                   "apks",
                                                   "MojoShell.apk")
        self.target_sky_shell_path = os.path.join(self.build_dir,
                                                  "apks",
                                                  "SkyDemo.apk")
      else:
        self.target_mojo_shell_path = self.mojo_shell_path
        self.target_sky_shell_path = self.sky_shell_path
    else:
      self.mojo_shell_path = None
      self.sky_shell_path = None
      self.target_mojo_shell_path = None
      self.target_sky_shell_path = None

  def RelPath(self, path):
    """Returns the given path, relative to the current directory."""
    return os.path.relpath(path)

  def SrcRelPath(self, path):
    """Returns the given path, relative to self.src_root."""
    return os.path.relpath(path, self.src_root)

  def FileFromUrl(self, url):
    """Given an app URL (<scheme>:<appname>), return 'build_dir/appname.mojo'.
    If self.build_dir is None, just return appname.mojo
    """
    (_, name) = url.split(':')
    if self.build_dir:
      return os.path.join(self.build_dir, name + '.mojo')
    return name + '.mojo'

  @staticmethod
  def IsValidAppUrl(url):
    """Returns False if url is malformed, True otherwise."""
    try:
      return len(url.split(':')) == 2
    except ValueError:
      return False
