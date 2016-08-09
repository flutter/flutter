#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Installs deps for using SDK emulator for testing.

The script will download the SDK and system images, if they are not present, and
install and enable KVM, if virtualization has been enabled in the BIOS.
"""


import logging
import optparse
import os
import re
import shutil
import sys

from pylib import cmd_helper
from pylib import constants
from pylib import pexpect
from pylib.utils import run_tests_helper

# Android API level
DEFAULT_ANDROID_API_LEVEL = constants.ANDROID_SDK_VERSION

# From the Android Developer's website.
# Keep this up to date; the user can install older API levels as necessary.
SDK_BASE_URL = 'http://dl.google.com/android/adt'
SDK_ZIP = 'adt-bundle-linux-x86_64-20131030.zip'

# pylint: disable=line-too-long
# Android x86 system image from the Intel website:
# http://software.intel.com/en-us/articles/intel-eula-x86-android-4-2-jelly-bean-bin
# These don't exist prior to Android-15.
# As of 08 Nov 2013, Android-19 is not yet available either.
X86_IMG_URLS = {
  15: 'https://software.intel.com/sites/landingpage/android/sysimg_x86-15_r01.zip',
  16: 'https://software.intel.com/sites/landingpage/android/sysimg_x86-16_r01.zip',
  17: 'https://software.intel.com/sites/landingpage/android/sysimg_x86-17_r01.zip',
  18: 'https://software.intel.com/sites/landingpage/android/sysimg_x86-18_r01.zip',
  19: 'https://software.intel.com/sites/landingpage/android/sysimg_x86-19_r01.zip'}
#pylint: enable=line-too-long

def CheckSDK():
  """Check if SDK is already installed.

  Returns:
    True if the emulator SDK directory (src/android_emulator_sdk/) exists.
  """
  return os.path.exists(constants.EMULATOR_SDK_ROOT)


def CheckSDKPlatform(api_level=DEFAULT_ANDROID_API_LEVEL):
  """Check if the "SDK Platform" for the specified API level is installed.
     This is necessary in order for the emulator to run when the target
     is specified.

  Args:
    api_level: the Android API level to check; defaults to the latest API.

  Returns:
    True if the platform is already installed.
  """
  android_binary = os.path.join(constants.EMULATOR_SDK_ROOT,
                                'sdk', 'tools', 'android')
  pattern = re.compile('id: [0-9]+ or "android-%d"' % api_level)
  try:
    exit_code, stdout = cmd_helper.GetCmdStatusAndOutput(
        [android_binary, 'list'])
    if exit_code != 0:
      raise Exception('\'android list\' command failed')
    for line in stdout.split('\n'):
      if pattern.match(line):
        return True
    return False
  except OSError:
    logging.exception('Unable to execute \'android list\'')
    return False


def CheckX86Image(api_level=DEFAULT_ANDROID_API_LEVEL):
  """Check if Android system images have been installed.

  Args:
    api_level: the Android API level to check for; defaults to the latest API.

  Returns:
    True if sdk/system-images/android-<api_level>/x86 exists inside
    EMULATOR_SDK_ROOT.
  """
  api_target = 'android-%d' % api_level
  return os.path.exists(os.path.join(constants.EMULATOR_SDK_ROOT,
                                     'sdk', 'system-images',
                                     api_target, 'x86'))


def CheckKVM():
  """Quickly check whether KVM is enabled.

  Returns:
    True iff /dev/kvm exists (Linux only).
  """
  return os.path.exists('/dev/kvm')


def RunKvmOk():
  """Run kvm-ok as root to check that KVM is properly enabled after installation
     of the required packages.

  Returns:
    True iff KVM is enabled (/dev/kvm exists). On failure, returns False
    but also print detailed information explaining why KVM isn't enabled
    (e.g. CPU doesn't support it, or BIOS disabled it).
  """
  try:
    # Note: kvm-ok is in /usr/sbin, so always use 'sudo' to run it.
    return not cmd_helper.RunCmd(['sudo', 'kvm-ok'])
  except OSError:
    logging.info('kvm-ok not installed')
    return False


def GetSDK():
  """Download the SDK and unzip it into EMULATOR_SDK_ROOT."""
  logging.info('Download Android SDK.')
  sdk_url = '%s/%s' % (SDK_BASE_URL, SDK_ZIP)
  try:
    cmd_helper.RunCmd(['curl', '-o', '/tmp/sdk.zip', sdk_url])
    print 'curled unzipping...'
    rc = cmd_helper.RunCmd(['unzip', '-o', '/tmp/sdk.zip', '-d', '/tmp/'])
    if rc:
      raise Exception('ERROR: could not download/unzip Android SDK.')
    # Get the name of the sub-directory that everything will be extracted to.
    dirname, _ = os.path.splitext(SDK_ZIP)
    zip_dir = '/tmp/%s' % dirname
    # Move the extracted directory to EMULATOR_SDK_ROOT
    shutil.move(zip_dir, constants.EMULATOR_SDK_ROOT)
  finally:
    os.unlink('/tmp/sdk.zip')


def InstallKVM():
  """Installs KVM packages."""
  rc = cmd_helper.RunCmd(['sudo', 'apt-get', 'install', 'kvm'])
  if rc:
    logging.critical('ERROR: Did not install KVM. Make sure hardware '
                     'virtualization is enabled in BIOS (i.e. Intel VT-x or '
                     'AMD SVM).')
  # TODO(navabi): Use modprobe kvm-amd on AMD processors.
  rc = cmd_helper.RunCmd(['sudo', 'modprobe', 'kvm-intel'])
  if rc:
    logging.critical('ERROR: Did not add KVM module to Linux Kernel. Make sure '
                     'hardware virtualization is enabled in BIOS.')
  # Now check to ensure KVM acceleration can be used.
  if not RunKvmOk():
    logging.critical('ERROR: Can not use KVM acceleration. Make sure hardware '
                     'virtualization is enabled in BIOS (i.e. Intel VT-x or '
                     'AMD SVM).')


def GetX86Image(api_level=DEFAULT_ANDROID_API_LEVEL):
  """Download x86 system image from Intel's website.

  Args:
    api_level: the Android API level to download for.
  """
  logging.info('Download x86 system image directory into sdk directory.')
  # TODO(andrewhayden): Use python tempfile lib instead
  temp_file = '/tmp/x86_img_android-%d.zip' % api_level
  if api_level not in X86_IMG_URLS:
    raise Exception('ERROR: no URL known for x86 image for android-%s' %
                    api_level)
  try:
    cmd_helper.RunCmd(['curl', '-o', temp_file, X86_IMG_URLS[api_level]])
    rc = cmd_helper.RunCmd(['unzip', '-o', temp_file, '-d', '/tmp/'])
    if rc:
      raise Exception('ERROR: Could not download/unzip image zip.')
    api_target = 'android-%d' % api_level
    sys_imgs = os.path.join(constants.EMULATOR_SDK_ROOT, 'sdk',
                            'system-images', api_target, 'x86')
    logging.info('Deploying system image to %s' % sys_imgs)
    shutil.move('/tmp/x86', sys_imgs)
  finally:
    os.unlink(temp_file)


def GetSDKPlatform(api_level=DEFAULT_ANDROID_API_LEVEL):
  """Update the SDK to include the platform specified.

  Args:
    api_level: the Android API level to download
  """
  android_binary = os.path.join(constants.EMULATOR_SDK_ROOT,
                                'sdk', 'tools', 'android')
  pattern = re.compile(
      r'\s*([0-9]+)- SDK Platform Android [\.,0-9]+, API %d.*' % api_level)
  # Example:
  #   2- SDK Platform Android 4.3, API 18, revision 2
  exit_code, stdout = cmd_helper.GetCmdStatusAndOutput(
      [android_binary, 'list', 'sdk'])
  if exit_code != 0:
    raise Exception('\'android list sdk\' command return %d' % exit_code)
  for line in stdout.split('\n'):
    match = pattern.match(line)
    if match:
      index = match.group(1)
      print 'package %s corresponds to platform level %d' % (index, api_level)
      # update sdk --no-ui --filter $INDEX
      update_command = [android_binary,
                        'update', 'sdk', '--no-ui', '--filter', index]
      update_command_str = ' '.join(update_command)
      logging.info('running update command: %s' % update_command_str)
      update_process = pexpect.spawn(update_command_str)
      # TODO(andrewhayden): Do we need to bug the user about this?
      if update_process.expect('Do you accept the license') != 0:
        raise Exception('License agreement check failed')
      update_process.sendline('y')
      if update_process.expect('Done. 1 package installed.') == 0:
        print 'Successfully installed platform for API level %d' % api_level
        return
      else:
        raise Exception('Failed to install platform update')
  raise Exception('Could not find android-%d update for the SDK!' % api_level)


def main(argv):
  opt_parser = optparse.OptionParser(
      description='Install dependencies for running the Android emulator')
  opt_parser.add_option('--api-level', dest='api_level',
      help='The API level (e.g., 19 for Android 4.4) to ensure is available',
      type='int', default=DEFAULT_ANDROID_API_LEVEL)
  opt_parser.add_option('-v', dest='verbose', action='store_true',
      help='enable verbose logging')
  options, _ = opt_parser.parse_args(argv[1:])

  # run_tests_helper will set logging to INFO or DEBUG
  # We achieve verbose output by configuring it with 2 (==DEBUG)
  verbosity = 1
  if options.verbose:
    verbosity = 2
  logging.basicConfig(level=logging.INFO,
                      format='# %(asctime)-15s: %(message)s')
  run_tests_helper.SetLogLevel(verbose_count=verbosity)

  # Calls below will download emulator SDK and/or system images only if needed.
  if CheckSDK():
    logging.info('android_emulator_sdk/ already exists, skipping download.')
  else:
    GetSDK()

  # Check target. The target has to be installed in order to run the emulator.
  if CheckSDKPlatform(options.api_level):
    logging.info('SDK platform android-%d already present, skipping.' %
                 options.api_level)
  else:
    logging.info('SDK platform android-%d not present, installing.' %
                 options.api_level)
    GetSDKPlatform(options.api_level)

  # Download the x86 system image only if needed.
  if CheckX86Image(options.api_level):
    logging.info('x86 image for android-%d already present, skipping.' %
                 options.api_level)
  else:
    GetX86Image(options.api_level)

  # Make sure KVM packages are installed and enabled.
  if CheckKVM():
    logging.info('KVM already installed and enabled.')
  else:
    InstallKVM()


if __name__ == '__main__':
  sys.exit(main(sys.argv))
