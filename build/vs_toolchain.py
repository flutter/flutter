#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import glob
import json
import os
import pipes
import platform
import shutil
import stat
import subprocess
import sys


script_dir = os.path.dirname(os.path.realpath(__file__))
chrome_src = os.path.abspath(os.path.join(script_dir, os.pardir))
SRC_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(1, os.path.join(chrome_src, 'tools'))
sys.path.insert(0, os.path.join(chrome_src, 'third_party', 'gyp', 'pylib'))
json_data_file = os.path.join(script_dir, 'win_toolchain.json')


import gyp


# Use MSVS2015 as the default toolchain.
CURRENT_DEFAULT_TOOLCHAIN_VERSION = '2015'


def SetEnvironmentAndGetRuntimeDllDirs():
  """Sets up os.environ to use the depot_tools VS toolchain with gyp, and
  returns the location of the VS runtime DLLs so they can be copied into
  the output directory after gyp generation.
  Return value is [x64path, x86path] or None
  """
  vs_runtime_dll_dirs = None
  depot_tools_win_toolchain = \
      bool(int(os.environ.get('DEPOT_TOOLS_WIN_TOOLCHAIN', '1')))
  # When running on a non-Windows host, only do this if the SDK has explicitly
  # been downloaded before (in which case json_data_file will exist).
  if ((sys.platform in ('win32', 'cygwin') or os.path.exists(json_data_file))
      and depot_tools_win_toolchain):
    if ShouldUpdateToolchain():
      Update()
    with open(json_data_file, 'r') as tempf:
      toolchain_data = json.load(tempf)

    toolchain = toolchain_data['path']
    version = toolchain_data['version']
    win_sdk = toolchain_data.get('win_sdk')
    if not win_sdk:
      win_sdk = toolchain_data['win8sdk']
    wdk = toolchain_data['wdk']
    # TODO(scottmg): The order unfortunately matters in these. They should be
    # split into separate keys for x86 and x64. (See CopyVsRuntimeDlls call
    # below). http://crbug.com/345992
    vs_runtime_dll_dirs = toolchain_data['runtime_dirs']

    os.environ['GYP_MSVS_OVERRIDE_PATH'] = toolchain
    os.environ['GYP_MSVS_VERSION'] = version
    # We need to make sure windows_sdk_path is set to the automated
    # toolchain values in GYP_DEFINES, but don't want to override any
    # otheroptions.express
    # values there.
    gyp_defines_dict = gyp.NameValueListToDict(gyp.ShlexEnv('GYP_DEFINES'))
    gyp_defines_dict['windows_sdk_path'] = win_sdk
    os.environ['GYP_DEFINES'] = ' '.join('%s=%s' % (k, pipes.quote(str(v)))
        for k, v in gyp_defines_dict.iteritems())
    os.environ['WINDOWSSDKDIR'] = win_sdk
    os.environ['WDK_DIR'] = wdk
    # Include the VS runtime in the PATH in case it's not machine-installed.
    runtime_path = os.path.pathsep.join(vs_runtime_dll_dirs)
    os.environ['PATH'] = runtime_path + os.path.pathsep + os.environ['PATH']
  elif sys.platform == 'win32' and not depot_tools_win_toolchain:
    if not 'GYP_MSVS_OVERRIDE_PATH' in os.environ:
      os.environ['GYP_MSVS_OVERRIDE_PATH'] = DetectVisualStudioPath()
    if not 'GYP_MSVS_VERSION' in os.environ:
      os.environ['GYP_MSVS_VERSION'] = GetVisualStudioVersion()

    # When using an installed toolchain these files aren't needed in the output
    # directory in order to run binaries locally, but they are needed in order
    # to create isolates or the mini_installer. Copying them to the output
    # directory ensures that they are available when needed.
    bitness = platform.architecture()[0]
    # When running 64-bit python the x64 DLLs will be in System32
    x64_path = 'System32' if bitness == '64bit' else 'Sysnative'
    x64_path = os.path.join(r'C:\Windows', x64_path)
    vs_runtime_dll_dirs = [x64_path, r'C:\Windows\SysWOW64']

  return vs_runtime_dll_dirs


def _RegistryGetValueUsingWinReg(key, value):
  """Use the _winreg module to obtain the value of a registry key.
  Args:
    key: The registry key.
    value: The particular registry value to read.
  Return:
    contents of the registry key's value, or None on failure.  Throws
    ImportError if _winreg is unavailable.
  """
  import _winreg
  try:
    root, subkey = key.split('\\', 1)
    assert root == 'HKLM'  # Only need HKLM for now.
    with _winreg.OpenKey(_winreg.HKEY_LOCAL_MACHINE, subkey) as hkey:
      return _winreg.QueryValueEx(hkey, value)[0]
  except WindowsError:
    return None


def _RegistryGetValue(key, value):
  try:
    return _RegistryGetValueUsingWinReg(key, value)
  except ImportError:
    raise Exception('The python library _winreg not found.')


def GetVisualStudioVersion():
  """Return GYP_MSVS_VERSION of Visual Studio.
  """
  return os.environ.get('GYP_MSVS_VERSION', CURRENT_DEFAULT_TOOLCHAIN_VERSION)


def DetectVisualStudioPath():
  """Return path to the GYP_MSVS_VERSION of Visual Studio.
  """

  # Note that this code is used from
  # build/toolchain/win/setup_toolchain.py as well.
  version_as_year = GetVisualStudioVersion()
  year_to_version = {
      '2013': '12.0',
      '2015': '14.0',
  }
  if version_as_year not in year_to_version:
    raise Exception(('Visual Studio version %s (from GYP_MSVS_VERSION)'
                     ' not supported. Supported versions are: %s') % (
                       version_as_year, ', '.join(year_to_version.keys())))
  version = year_to_version[version_as_year]
  keys = [r'HKLM\Software\Microsoft\VisualStudio\%s' % version,
          r'HKLM\Software\Wow6432Node\Microsoft\VisualStudio\%s' % version]
  for key in keys:
    path = _RegistryGetValue(key, 'InstallDir')
    if not path:
      continue
    path = os.path.normpath(os.path.join(path, '..', '..'))
    return path

  raise Exception(('Visual Studio Version %s (from GYP_MSVS_VERSION)'
                   ' not found.') % (version_as_year))


def _VersionNumber():
  """Gets the standard version number ('120', '140', etc.) based on
  GYP_MSVS_VERSION."""
  vs_version = GetVisualStudioVersion()
  if vs_version == '2013':
    return '120'
  elif vs_version == '2015':
    return '140'
  else:
    raise ValueError('Unexpected GYP_MSVS_VERSION')


def _CopyRuntimeImpl(target, source, verbose=True):
  """Copy |source| to |target| if it doesn't already exist or if it needs to be
  updated (comparing last modified time as an approximate float match as for
  some reason the values tend to differ by ~1e-07 despite being copies of the
  same file... https://crbug.com/603603).
  """
  if (os.path.isdir(os.path.dirname(target)) and
      (not os.path.isfile(target) or
       abs(os.stat(target).st_mtime - os.stat(source).st_mtime) >= 0.01)):
    if verbose:
      print 'Copying %s to %s...' % (source, target)
    if os.path.exists(target):
      # Make the file writable so that we can delete it now.
      os.chmod(target, stat.S_IWRITE)
      os.unlink(target)
    shutil.copy2(source, target)
    # Make the file writable so that we can overwrite or delete it later.
    os.chmod(target, stat.S_IWRITE)


def _CopyRuntime2013(target_dir, source_dir, dll_pattern):
  """Copy both the msvcr and msvcp runtime DLLs, only if the target doesn't
  exist, but the target directory does exist."""
  for file_part in ('p', 'r'):
    dll = dll_pattern % file_part
    target = os.path.join(target_dir, dll)
    source = os.path.join(source_dir, dll)
    _CopyRuntimeImpl(target, source)


def _CopyRuntime2015(target_dir, source_dir, dll_pattern, suffix):
  """Copy both the msvcp and vccorlib runtime DLLs, only if the target doesn't
  exist, but the target directory does exist."""
  for file_part in ('msvcp', 'vccorlib', 'vcruntime'):
    dll = dll_pattern % file_part
    target = os.path.join(target_dir, dll)
    source = os.path.join(source_dir, dll)
    _CopyRuntimeImpl(target, source)
  # OS installs of Visual Studio (and all installs of Windows 10) put the
  # universal CRT files in c:\Windows\System32\downlevel - look for them there
  # to support DEPOT_TOOLS_WIN_TOOLCHAIN=0.
  if os.path.exists(os.path.join(source_dir, 'downlevel')):
    ucrt_src_glob = os.path.join(source_dir, 'downlevel', 'api-ms-win-*.dll')
  else:
    ucrt_src_glob = os.path.join(source_dir, 'api-ms-win-*.dll')
  ucrt_files = glob.glob(ucrt_src_glob)
  assert len(ucrt_files) > 0
  for ucrt_src_file in ucrt_files:
    file_part = os.path.basename(ucrt_src_file)
    ucrt_dst_file = os.path.join(target_dir, file_part)
    _CopyRuntimeImpl(ucrt_dst_file, ucrt_src_file, False)
  _CopyRuntimeImpl(os.path.join(target_dir, 'ucrtbase' + suffix),
                    os.path.join(source_dir, 'ucrtbase' + suffix))


def _CopyRuntime(target_dir, source_dir, target_cpu, debug):
  """Copy the VS runtime DLLs, only if the target doesn't exist, but the target
  directory does exist. Handles VS 2013 and VS 2015."""
  suffix = "d.dll" if debug else ".dll"
  if GetVisualStudioVersion() == '2015':
    _CopyRuntime2015(target_dir, source_dir, '%s140' + suffix, suffix)
  else:
    _CopyRuntime2013(target_dir, source_dir, 'msvc%s120' + suffix)

  # Copy the PGO runtime library to the release directories.
  if not debug and os.environ.get('GYP_MSVS_OVERRIDE_PATH'):
    pgo_x86_runtime_dir = os.path.join(os.environ.get('GYP_MSVS_OVERRIDE_PATH'),
                                        'VC', 'bin')
    pgo_x64_runtime_dir = os.path.join(pgo_x86_runtime_dir, 'amd64')
    pgo_runtime_dll = 'pgort' + _VersionNumber() + '.dll'
    if target_cpu == "x86":
      source_x86 = os.path.join(pgo_x86_runtime_dir, pgo_runtime_dll)
      if os.path.exists(source_x86):
        _CopyRuntimeImpl(os.path.join(target_dir, pgo_runtime_dll), source_x86)
    elif target_cpu == "x64":
      source_x64 = os.path.join(pgo_x64_runtime_dir, pgo_runtime_dll)
      if os.path.exists(source_x64):
        _CopyRuntimeImpl(os.path.join(target_dir, pgo_runtime_dll),
                          source_x64)
    else:
      raise NotImplementedError("Unexpected target_cpu value:" + target_cpu)


def CopyVsRuntimeDlls(output_dir, runtime_dirs):
  """Copies the VS runtime DLLs from the given |runtime_dirs| to the output
  directory so that even if not system-installed, built binaries are likely to
  be able to run.
  This needs to be run after gyp has been run so that the expected target
  output directories are already created.
  This is used for the GYP build and gclient runhooks.
  """
  x86, x64 = runtime_dirs
  out_debug = os.path.join(output_dir, 'Debug')
  out_debug_nacl64 = os.path.join(output_dir, 'Debug', 'x64')
  out_release = os.path.join(output_dir, 'Release')
  out_release_nacl64 = os.path.join(output_dir, 'Release', 'x64')
  out_debug_x64 = os.path.join(output_dir, 'Debug_x64')
  out_release_x64 = os.path.join(output_dir, 'Release_x64')

  if os.path.exists(out_debug) and not os.path.exists(out_debug_nacl64):
    os.makedirs(out_debug_nacl64)
  if os.path.exists(out_release) and not os.path.exists(out_release_nacl64):
    os.makedirs(out_release_nacl64)
  _CopyRuntime(out_debug,          x86, "x86", debug=True)
  _CopyRuntime(out_release,        x86, "x86", debug=False)
  _CopyRuntime(out_debug_x64,      x64, "x64", debug=True)
  _CopyRuntime(out_release_x64,    x64, "x64", debug=False)
  _CopyRuntime(out_debug_nacl64,   x64, "x64", debug=True)
  _CopyRuntime(out_release_nacl64, x64, "x64", debug=False)


def CopyDlls(target_dir, configuration, target_cpu):
  """Copy the VS runtime DLLs into the requested directory as needed.
  configuration is one of 'Debug' or 'Release'.
  target_cpu is one of 'x86' or 'x64'.
  The debug configuration gets both the debug and release DLLs; the
  release config only the latter.
  This is used for the GN build.
  """
  vs_runtime_dll_dirs = SetEnvironmentAndGetRuntimeDllDirs()
  if not vs_runtime_dll_dirs:
    return

  x64_runtime, x86_runtime = vs_runtime_dll_dirs
  runtime_dir = x64_runtime if target_cpu == 'x64' else x86_runtime
  _CopyRuntime(target_dir, runtime_dir, target_cpu, debug=False)
  if configuration == 'Debug':
    _CopyRuntime(target_dir, runtime_dir, target_cpu, debug=True)


def _GetDesiredVsToolchainHashes():
  """Load a list of SHA1s corresponding to the toolchains that we want installed
  to build with."""
  if GetVisualStudioVersion() == '2015':
    # Update 3 final with patches with 10.0.10586.0 SDK.
    return ['d5dc33b15d1b2c086f2f6632e2fd15882f80dbd3']
  else:
    return ['03a4e939cd325d6bc5216af41b92d02dda1366a6']


def ShouldUpdateToolchain():
  """Check if the toolchain should be upgraded."""
  if not os.path.exists(json_data_file):
    return True
  with open(json_data_file, 'r') as tempf:
    toolchain_data = json.load(tempf)
  version = toolchain_data['version']
  env_version = GetVisualStudioVersion()
  # If there's a mismatch between the version set in the environment and the one
  # in the json file then the toolchain should be updated.
  return version != env_version


def Update(force=False):
  """Requests an update of the toolchain to the specific hashes we have at
  this revision. The update outputs a .json of the various configuration
  information required to pass to gyp which we use in |GetToolchainDir()|.
  """
  if force != False and force != '--force':
    print >>sys.stderr, 'Unknown parameter "%s"' % force
    return 1
  if force == '--force' or os.path.exists(json_data_file):
    force = True

  depot_tools_win_toolchain = \
      bool(int(os.environ.get('DEPOT_TOOLS_WIN_TOOLCHAIN', '1')))
  if ((sys.platform in ('win32', 'cygwin') or force) and
        depot_tools_win_toolchain):
    import find_depot_tools
    depot_tools_path = find_depot_tools.add_depot_tools_to_path()
    # Necessary so that get_toolchain_if_necessary.py will put the VS toolkit
    # in the correct directory.
    os.environ['GYP_MSVS_VERSION'] = GetVisualStudioVersion()
    get_toolchain_args = [
        sys.executable,
        os.path.join(depot_tools_path,
                    'win_toolchain',
                    'get_toolchain_if_necessary.py'),
        '--output-json', json_data_file,
      ] + _GetDesiredVsToolchainHashes()
    if force:
      get_toolchain_args.append('--force')
    subprocess.check_call(get_toolchain_args)

  return 0


def NormalizePath(path):
  while path.endswith("\\"):
    path = path[:-1]
  return path


def GetToolchainDir():
  """Gets location information about the current toolchain (must have been
  previously updated by 'update'). This is used for the GN build."""
  runtime_dll_dirs = SetEnvironmentAndGetRuntimeDllDirs()

  # If WINDOWSSDKDIR is not set, search the default SDK path and set it.
  if not 'WINDOWSSDKDIR' in os.environ:
    default_sdk_path = 'C:\\Program Files (x86)\\Windows Kits\\10'
    if os.path.isdir(default_sdk_path):
      os.environ['WINDOWSSDKDIR'] = default_sdk_path

  print '''vs_path = "%s"
sdk_path = "%s"
vs_version = "%s"
wdk_dir = "%s"
runtime_dirs = "%s"
''' % (
      NormalizePath(os.environ['GYP_MSVS_OVERRIDE_PATH']),
      NormalizePath(os.environ['WINDOWSSDKDIR']),
      GetVisualStudioVersion(),
      NormalizePath(os.environ.get('WDK_DIR', '')),
      os.path.pathsep.join(runtime_dll_dirs or ['None']))


def main():
  commands = {
      'update': Update,
      'get_toolchain_dir': GetToolchainDir,
      'copy_dlls': CopyDlls,
  }
  if len(sys.argv) < 2 or sys.argv[1] not in commands:
    print >>sys.stderr, 'Expected one of: %s' % ', '.join(commands)
    return 1
  return commands[sys.argv[1]](*sys.argv[2:])


if __name__ == '__main__':
  sys.exit(main())
  