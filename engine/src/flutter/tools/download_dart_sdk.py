#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# When the environment variable in FLUTTER_PREBUILTS_ENV_VAR below is defined
# and is not '0' or 'false', this script downloads the Dart SDK that matches the
# version in the source tree and puts it in prebuilts/.
#
# The return code of this script will always be 0, even if there is an error,
# unless the --fail-loudly flag is passed.

# TODO(zra): Eliminate this script and download through the DEPS file if/when
# the Dart SDKs pulled by this script are uploaded to cipd.

import argparse
import os
import multiprocessing
import platform
import re
import shutil
import subprocess
import sys
import zipfile


SRC_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FLUTTER_DIR = os.path.join(SRC_ROOT, 'flutter')
FLUTTER_PREBUILTS_DIR = os.path.join(FLUTTER_DIR, 'prebuilts')
DART_DIR = os.path.join(SRC_ROOT, 'third_party', 'dart')
DART_VERSION = os.path.join(DART_DIR, 'tools', 'VERSION')
FLUTTER_PREBUILTS_ENV_VAR = 'FLUTTER_PREBUILT_DART_SDK'


# The Dart SDK script is the source of truth about the sematic version.
sys.path.append(os.path.join(DART_DIR, 'tools'))
import utils


# Prints to stderr.
def eprint(*args, **kwargs):
  print(*args, file=sys.stderr, **kwargs)


# Try to guess the host operating system.
def GuessOS():
  os_name = utils.GuessOS()
  if os_name == 'win32':
    os_name = 'windows'
  if os_name not in ['linux', 'macos', 'windows']:
    eprint('Could not determine the OS: "%s"' % os_name)
    return None
  return os_name


# For os `os_name` return a list of architectures for which prebuilts are
# supported. Kepp in sync with `can_use_prebuilt_dart` in //flutter/tools/gn.
def ArchitecturesForOS(os_name):
  if os_name == 'linux':
    return ['x64', 'arm64']
  elif os_name == 'macos':
    return ['x64', 'arm64']
  elif os_name =='windows':
    return ['x64']

  eprint('Could not determine architectures for os "%s"' % os_name)
  return None


# Downloads a Dart SDK to //flutter/prebuilts.
def DownloadDartSDK(channel, version, os_name, arch, verbose):
  file = 'dartsdk-{}-{}-release.zip'.format(os_name, arch)
  url = 'https://storage.googleapis.com/dart-archive/channels/{}/raw/{}/sdk/{}'.format(
    channel, version, file,
  )
  dest = os.path.join(FLUTTER_PREBUILTS_DIR, file)

  if verbose:
    print('Dart SDK url: "%s"' % url)
    print('Dart SDK destination path: "%s"' % dest)

  stamp_file = '{}.stamp'.format(dest)
  version_stamp = None
  try:
    with open(stamp_file) as fd:
      version_stamp = fd.read()
  except:
    version_stamp = 'none'

  if verbose:
    print('Dart SDK version stamp = "%s"' % version_stamp)

  if version == version_stamp:
    # The prebuilt Dart SDK is already up-to-date. Indicate that the download
    # should be skipped by returning the empty string.
    if verbose:
      print('Dart SDK stamp files match. Skipping download.')
    return ''

  if os.path.isfile(dest):
    os.unlink(dest)

  curl_command = [
    'curl',
    '--retry', '3',
    '--continue-at', '-', '--location',
    '--output', dest,
    url,
  ]
  if verbose:
    print('Running: "%s"' % (' '.join(curl_command)))
  curl_result = subprocess.run(
    curl_command,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    universal_newlines=True,
  )
  if curl_result.returncode == 0 and verbose:
    print('curl output:stdout:\n{}\nstderr:\n{}'.format(
      curl_result.stdout, curl_result.stderr,
    ))
  elif curl_result.returncode != 0:
    eprint('Failed to download: stdout:\n{}\nstderr:\n{}'.format(
      curl_result.stdout, curl_result.stderr,
    ))
    return None

  return dest


# A custom ZipFile class that preserves file permissions.
class ZipFileWithPermissions(zipfile.ZipFile):
  def _extract_member(self, member, targetpath, pwd):
    if not isinstance(member, zipfile.ZipInfo):
      member = self.getinfo(member)

    targetpath = super()._extract_member(member, targetpath, pwd)

    attr = member.external_attr >> 16
    if attr != 0:
      os.chmod(targetpath, attr)
    return targetpath


def OnErrorRmTree(func, path, exc_info):
  """
  Error handler for ``shutil.rmtree``.

  If the error is due to an access error (read only file)
  it attempts to add write permission and then retries.
  If the error is for another reason it re-raises the error.

  Usage : ``shutil.rmtree(path, onerror=onerror)``
  """
  import stat
  # Is the error an access error?
  if not os.access(path, os.W_OK):
    os.chmod(path, stat.S_IWUSR)
    func(path)
  else:
    raise

# Extracts a Dart SDK in //fluter/prebuilts
def ExtractDartSDK(archive, os_name, arch, verbose):
  os_arch = '{}-{}'.format(os_name, arch)
  dart_sdk = os.path.join(FLUTTER_PREBUILTS_DIR, os_arch, 'dart-sdk')
  if os.path.isdir(dart_sdk):
    shutil.rmtree(dart_sdk, onerror=OnErrorRmTree)

  extract_dest = os.path.join(FLUTTER_PREBUILTS_DIR, os_arch, 'temp')
  if os.path.isdir(extract_dest):
    shutil.rmtree(extract_dest, onerror=OnErrorRmTree)
  os.makedirs(extract_dest, exist_ok=True)

  if verbose:
    print('Extracting "%s" to "%s"' % (archive, extract_dest))

  with ZipFileWithPermissions(archive, "r") as z:
    z.extractall(extract_dest)

  shutil.move(os.path.join(extract_dest, 'dart-sdk'), dart_sdk)


def PrintFileIfSmall(file):
  if not os.path.isfile(file):
    return
  size = os.path.getsize(file)
  if size < (1 << 14): # < 16KB
    with open(file) as f:
      contents = f.read()
      eprint(contents)


def DownloadAndExtract(channel, version, os_name, arch, verbose):
  archive = DownloadDartSDK(channel, version, os_name, arch, verbose)
  if archive == None:
    return 1
  if archive == '':
    return 0
  try:
    ExtractDartSDK(archive, os_name, arch, verbose)
  except Exception as e:
    eprint('Failed to extract Dart SDK archive:\n%s' % e)
    PrintFileIfSmall(archive)
    return 1
  try:
    stamp_file = '{}.stamp'.format(archive)
    with open(stamp_file, "w") as fd:
      fd.write(version)
  except Exception as e:
    eprint('Failed to write Dart SDK version stamp file:\n{}'.format(e))
    return 1
  return 0


def Main():
  parser = argparse.ArgumentParser()
  parser.add_argument(
    '--fail-loudly',
    action='store_true',
    default=False,
    help="Return an error code if a prebuilt couldn't be fetched and extracted")
  parser.add_argument(
    '--verbose',
    action='store_true',
    default='LUCI_CONTEXT' in os.environ,
    help='Emit verbose output')
  args = parser.parse_args()
  fail_loudly = 1 if args.fail_loudly else 0
  verbose = args.verbose

  prebuilt_enabled = os.environ.get(FLUTTER_PREBUILTS_ENV_VAR, 'true')
  if prebuilt_enabled == '0' or prebuilt_enabled.lower() == 'false':
    if verbose:
      print('Skipping prebuild Dart SDK download.')
    return 0

  os.makedirs(FLUTTER_PREBUILTS_DIR, exist_ok=True)

  # Read //third_party/dart/tools/VERSION to extract information about the
  # Dart SDK version.
  version = utils.ReadVersionFile()
  if version == None:
    eprint('Failed to read the Dart VERSION file.')
    return fail_loudly
  channel = version.channel
  if verbose:
    print('Dart SDK channel = "%s".' % channel)

  # A short Dart SDK version string used in the download url.
  if channel == 'be':
    dart_git_rev = utils.GetGitRevision()
    semantic_version = 'hash/{}'.format(dart_git_rev)
  else:
    semantic_version = utils.GetSemanticSDKVersion()
  if verbose:
    print('Semantic Dart SDK version = "%s".' % semantic_version)

  os_name = GuessOS()
  if os_name == None:
    return fail_loudly

  architectures = ArchitecturesForOS(os_name)
  if architectures == None:
    return fail_loudly

  # Work around a bug in Python.
  #
  # The multiprocessing package relies on the win32 WaitForMultipleObjects()
  # call, which supports waiting on a maximum of MAXIMUM_WAIT_OBJECTS (defined
  # by Windows to be 64) handles, processes in this case. To avoid hitting
  # this, we limit ourselves to 60 handles (since there are a couple extra
  # processes launched for the queue reader and thread wakeup reader).
  #
  # See: https://bugs.python.org/issue26903
  max_processes = os.cpu_count()
  if sys.platform.startswith(('cygwin', 'win')) and max_processes > 60:
    max_processes = 60

  # Download and extract variants in parallel
  pool = multiprocessing.Pool(processes=max_processes)
  tasks = [(channel, semantic_version, os_name, arch, verbose) for arch in architectures]
  async_results = [pool.apply_async(DownloadAndExtract, t) for t in tasks]
  success = True
  for async_result in async_results:
    result = async_result.get()
    success = success and (result == 0)

  return 0 if success else fail_loudly


if __name__ == '__main__':
  sys.exit(Main())
