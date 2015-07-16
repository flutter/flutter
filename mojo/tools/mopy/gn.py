# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
GN-related configuration functions, e.g., to produce a Config object from a GN
args.gn file).
"""


import ast
import os.path
import re

from .config import Config


def BuildDirectoryForConfig(config, src_root):
  """
  Returns the build directory for the given configuration.
  """
  subdir = ""
  if config.target_os == Config.OS_ANDROID:
    subdir += "android_"
    if config.target_cpu != Config.ARCH_ARM:
      subdir += config.target_cpu + "_"
  elif config.target_os == Config.OS_IOS:
    subdir += "ios_"
  if config.is_simulator:
    subdir += "sim_"
  if config.is_official_build:
    subdir += "Official"
  elif config.is_debug:
    subdir += "Debug"
  else:
    subdir += "Release"
  if config.sanitizer == Config.SANITIZER_ASAN:
    subdir += "_asan"
  if not(config.is_debug) and config.dcheck_always_on:
    subdir += "_dcheck"
  return os.path.join(src_root, "out", subdir)


def GNArgsForConfig(config):
  """
  Return the arguments for gn for the given configuration. This function returns
  a dictionary with boolean values as boolean.
  """
  gn_args = {}

  gn_args["is_debug"] = bool(config.is_debug)
  gn_args["is_official_build"] = bool(config.is_official_build)
  gn_args["is_asan"] = config.sanitizer == Config.SANITIZER_ASAN

  if config.is_clang is not None:
    gn_args["is_clang"] = bool(config.is_clang)
  else:
    gn_args["is_clang"] = config.target_os not in (Config.OS_ANDROID,
                                                   Config.OS_WINDOWS)

  if config.values.get("use_goma"):
    gn_args["use_goma"] = True
    gn_args["goma_dir"] = config.values["goma_dir"]
  else:
    gn_args["use_goma"] = False

  gn_args["dcheck_always_on"] = config.dcheck_always_on

  if config.target_os == Config.OS_ANDROID:
    gn_args["target_os"] = "android"
  elif config.target_os == Config.OS_IOS:
    gn_args["target_os"] = "ios"
    gn_args["ios_deployment_target"] = "7.0"
    gn_args["clang_use_chrome_plugins"] = False
    if config.is_simulator:
      gn_args["use_libjpeg_turbo"] = False
    gn_args["use_ios_simulator"] = config.is_simulator
  elif config.target_os == Config.OS_LINUX:
    gn_args["use_aura"] = False
    gn_args["use_glib"] = False
    gn_args["use_system_harfbuzz"] = False

  gn_args["target_cpu"] = config.target_cpu

  if "use_nacl" in config.values:
    gn_args["mojo_use_nacl"] = config.values.get("use_nacl", False)

  if "mojo_use_go" in config.values:
    gn_args["mojo_use_go"] = config.values.get("mojo_use_go", False)
    if gn_args["mojo_use_go"]:
      gn_args["go_build_tool"] = config.values.get("go_build_tool")

  extra_args = config.values.get("gn_args")
  if extra_args:
    for arg in extra_args.split():
      (name, val) = arg.split('=')
      gn_args[name] = val

  return gn_args


def CommandLineForGNArgs(gn_args):
  """
  Returns the list of gn arguments to use with the gn command line.
  """
  def _ToCommandLine(key, value):
    if type(value) is bool:
      return "%s=%s" % (key, "true" if value else "false")
    return "%s=\"%s\"" % (key, value)
  return [_ToCommandLine(x, y) for x, y in gn_args.iteritems()]


def ConfigForGNArgs(args):
  """
  Return the Config object for the given gn arguments. This function takes a
  dictionary with boolean values as boolean.
  """
  config_args = {}
  config_args["is_debug"] = args.get("is_debug", True)
  config_args["is_official_build"] = args.get("is_official_build", False)
  config_args["sanitizer"] = (
      Config.SANITIZER_ASAN if args.get("is_asan") else None)
  config_args["is_clang"] = args.get("is_clang", False)
  config_args["use_goma"] = args.get("use_goma", False)
  if config_args["use_goma"]:
    config_args["goma_dir"] = args.get("goma_dir")
  config_args["use_nacl"] = args.get("mojo_use_nacl", False)
  config_args["mojo_use_go"] = args.get("mojo_use_go", False)
  if config_args["mojo_use_go"]:
    config_args["go_build_tool"] = args.get("go_build_tool")
  config_args["target_os"] = args.get("target_os")
  config_args["target_cpu"] = args.get("target_cpu")
  config_args["dcheck_always_on"] = args.get("dcheck_always_on")
  config_args["is_simulator"] = args.get("use_ios_simulator", False)
  return Config(**config_args)


def ParseGNConfig(build_dir):
  """
  Parse the gn config file present in |build_dir|. This function returns a
  dictionary with boolean values as boolean.
  """
  TRANSLATIONS = {
      "true": "True",
      "false": "False",
  }
  gn_file = os.path.join(build_dir, "args.gn")
  values = {}
  with open(gn_file, "r") as f:
    for line in f.readlines():
      line = re.sub("\s*#.*", "", line)
      result = re.match("^\s*(\w+)\s*=\s*(.*)\s*$", line)
      if result:
        key = result.group(1)
        value = result.group(2)
        values[key] = ast.literal_eval(TRANSLATIONS.get(value, value))
  return values
