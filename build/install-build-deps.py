#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import operator
import os
import platform
import re
import subprocess
import sys


SUPPORTED_UBUNTU_VERSIONS = (
  {'number': '12.04', 'codename': 'precise'},
  {'number': '14.04', 'codename': 'trusty'},
  {'number': '14.10', 'codename': 'utopic'},
  {'number': '15.04', 'codename': 'vivid'},
)


# Packages needed for chromeos only.
_packages_chromeos_dev = (
  'libbluetooth-dev',
  'libxkbcommon-dev',
  'realpath',
)


# Packages needed for development.
_packages_dev = (
  'apache2.2-bin',
  'bison',
  'cdbs',
  'curl',
  'devscripts',
  'dpkg-dev',
  'elfutils',
  'fakeroot',
  'flex',
  'fonts-thai-tlwg',
  'g++',
  'git-core',
  'git-svn',
  'gperf',
  'language-pack-da',
  'language-pack-fr',
  'language-pack-he',
  'language-pack-zh-hant',
  'libapache2-mod-php5',
  'libasound2-dev',
  'libav-tools',
  'libbrlapi-dev',
  'libbz2-dev',
  'libcairo2-dev',
  'libcap-dev',
  'libcups2-dev',
  'libcurl4-gnutls-dev',
  'libdrm-dev',
  'libelf-dev',
  'libexif-dev',
  'libgconf2-dev',
  'libglib2.0-dev',
  'libglu1-mesa-dev',
  'libgnome-keyring-dev',
  'libgtk2.0-dev',
  'libkrb5-dev',
  'libnspr4-dev',
  'libnss3-dev',
  'libpam0g-dev',
  'libpci-dev',
  'libpulse-dev',
  'libsctp-dev',
  'libspeechd-dev',
  'libsqlite3-dev',
  'libssl-dev',
  'libudev-dev',
  'libwww-perl',
  'libxslt1-dev',
  'libxss-dev',
  'libxt-dev',
  'libxtst-dev',
  'openbox',
  'patch',
  'perl',
  'php5-cgi',
  'pkg-config',
  'python',
  'python-cherrypy3',
  'python-crypto',
  'python-dev',
  'python-numpy',
  'python-opencv',
  'python-openssl',
  'python-psutil',
  'python-yaml',
  'rpm',
  'ruby',
  'subversion',
  'ttf-dejavu-core',
  'ttf-indic-fonts',
  'ttf-kochi-gothic',
  'ttf-kochi-mincho',
  'wdiff',
  'xfonts-mathml',
  'zip',
)


# Run-time libraries required by chromeos only.
_packages_chromeos_lib = (
  'libbz2-1.0',
  'libpulse0',
)


# Full list of required run-time libraries.
_packages_lib = (
  'libasound2',
  'libatk1.0-0',
  'libc6',
  'libcairo2',
  'libcap2',
  'libcups2',
  'libexif12',
  'libexpat1',
  'libfontconfig1',
  'libfreetype6',
  'libglib2.0-0',
  'libgnome-keyring0',
  'libgtk2.0-0',
  'libpam0g',
  'libpango1.0-0',
  'libpci3',
  'libpcre3',
  'libpixman-1-0',
  'libpng12-0',
  'libspeechd2',
  'libsqlite3-0',
  'libstdc++6',
  'libx11-6',
  'libxau6',
  'libxcb1',
  'libxcomposite1',
  'libxcursor1',
  'libxdamage1',
  'libxdmcp6',
  'libxext6',
  'libxfixes3',
  'libxi6',
  'libxinerama1',
  'libxrandr2',
  'libxrender1',
  'libxtst6',
  'zlib1g',
)


# Debugging symbols for all of the run-time libraries.
_packages_dbg = (
  'libatk1.0-dbg',
  'libc6-dbg',
  'libcairo2-dbg',
  'libfontconfig1-dbg',
  'libglib2.0-0-dbg',
  'libgtk2.0-0-dbg',
  'libpango1.0-0-dbg',
  'libpcre3-dbg',
  'libpixman-1-0-dbg',
  'libsqlite3-0-dbg',
  'libx11-6-dbg',
  'libxau6-dbg',
  'libxcb1-dbg',
  'libxcomposite1-dbg',
  'libxcursor1-dbg',
  'libxdamage1-dbg',
  'libxdmcp6-dbg',
  'libxext6-dbg',
  'libxfixes3-dbg',
  'libxi6-dbg',
  'libxinerama1-dbg',
  'libxrandr2-dbg',
  'libxrender1-dbg',
  'libxtst6-dbg',
  'zlib1g-dbg',
)


# 32-bit libraries needed e.g. to compile V8 snapshot for Android or armhf.
_packages_lib32 = (
  'linux-libc-dev:i386',
)


# arm cross toolchain packages needed to build chrome on armhf.
_packages_arm = (
  'g++-arm-linux-gnueabihf',
  'libc6-dev-armhf-cross',
  'linux-libc-dev-armhf-cross',
)


# Packages to build NaCl, its toolchains, and its ports.
_packages_naclports = (
  'ant',
  'autoconf',
  'bison',
  'cmake',
  'gawk',
  'intltool',
  'xsltproc',
  'xutils-dev',
)
_packages_nacl = (
  'g++-mingw-w64-i686',
  'lib32ncurses5-dev',
  'lib32z1-dev',
  'libasound2:i386',
  'libcap2:i386',
  'libelf-dev:i386',
  'libexif12:i386',
  'libfontconfig1:i386',
  'libgconf-2-4:i386',
  'libglib2.0-0:i386',
  'libgpm2:i386',
  'libgtk2.0-0:i386',
  'libncurses5:i386',
  'libnss3:i386',
  'libpango1.0-0:i386',
  'libssl1.0.0:i386',
  'libtinfo-dev',
  'libtinfo-dev:i386',
  'libtool',
  'libxcomposite1:i386',
  'libxcursor1:i386',
  'libxdamage1:i386',
  'libxi6:i386',
  'libxrandr2:i386',
  'libxss1:i386',
  'libxtst6:i386',
  'texinfo',
  'xvfb',
)


def is_userland_64_bit():
  return platform.architecture()[0] == '64bit'


def package_exists(pkg):
  return pkg in subprocess.check_output(['apt-cache', 'pkgnames']).splitlines()


def lsb_release_short_codename():
  return subprocess.check_output(
      ['lsb_release', '--codename', '--short']).strip()


def write_error(message):
  sys.stderr.write('ERROR: %s\n' % message)
  sys.stderr.flush()


def nonfatal_get_output(*popenargs, **kwargs):
  process = subprocess.Popen(
      stdout=subprocess.PIPE, stderr=subprocess.PIPE, *popenargs, **kwargs)
  stdout, stderr = process.communicate()
  retcode = process.poll()
  return retcode, stdout, stderr


def compute_dynamic_package_lists():
  global _packages_arm
  global _packages_dbg
  global _packages_dev
  global _packages_lib
  global _packages_lib32
  global _packages_nacl

  if is_userland_64_bit():
    # 64-bit systems need a minimum set of 32-bit compat packages
    # for the pre-built NaCl binaries.
    _packages_dev += (
      'lib32gcc1',
      'lib32stdc++6',
      'libc6-i386',
    )

    # When cross building for arm/Android on 64-bit systems the host binaries
    # that are part of v8 need to be compiled with -m32 which means
    # that basic multilib support is needed.
    # gcc-multilib conflicts with the arm cross compiler (at least in trusty)
    # but g++-X.Y-multilib gives us the 32-bit support that we need. Find out
    # the appropriate value of X and Y by seeing what version the current
    # distribution's g++-multilib package depends on.
    output = subprocess.check_output(['apt-cache', 'depends', 'g++-multilib'])
    multilib_package = re.search(r'g\+\+-[0-9.]+-multilib', output).group()
    _packages_lib32 += (multilib_package,)

  lsb_codename = lsb_release_short_codename()

  # Find the proper version of libstdc++6-4.x-dbg.
  if lsb_codename == 'precise':
    _packages_dbg += ('libstdc++6-4.6-dbg',)
  elif lsb_codename == 'trusty':
    _packages_dbg += ('libstdc++6-4.8-dbg',)
  else:
    _packages_dbg += ('libstdc++6-4.9-dbg',)

  # Work around for dependency issue Ubuntu/Trusty: http://crbug.com/435056 .
  if lsb_codename == 'trusty':
    _packages_arm += (
      'g++-4.8-multilib-arm-linux-gnueabihf',
      'gcc-4.8-multilib-arm-linux-gnueabihf',
    )

  # Find the proper version of libgbm-dev. We can't just install libgbm-dev as
  # it depends on mesa, and only one version of mesa can exists on the system.
  # Hence we must match the same version or this entire script will fail.
  mesa_variant = ''
  for variant in ('-lts-trusty', '-lts-utopic'):
    rc, stdout, stderr = nonfatal_get_output(
        ['dpkg-query', '-Wf\'{Status}\'', 'libgl1-mesa-glx' + variant])
    if 'ok installed' in output:
      mesa_variant = variant
  _packages_dev += (
    'libgbm-dev' + mesa_variant,
    'libgl1-mesa-dev' + mesa_variant,
    'libgles2-mesa-dev' + mesa_variant,
    'mesa-common-dev' + mesa_variant,
  )

  if package_exists('ttf-mscorefonts-installer'):
    _packages_dev += ('ttf-mscorefonts-installer',)
  else:
    _packages_dev += ('msttcorefonts',)

  if package_exists('libnspr4-dbg'):
    _packages_dbg += ('libnspr4-dbg', 'libnss3-dbg')
    _packages_lib += ('libnspr4', 'libnss3')
  else:
    _packages_dbg += ('libnspr4-0d-dbg', 'libnss3-1d-dbg')
    _packages_lib += ('libnspr4-0d', 'libnss3-1d')

  if package_exists('libjpeg-dev'):
    _packages_dev += ('libjpeg-dev',)
  else:
    _packages_dev += ('libjpeg62-dev',)

  if package_exists('libudev1'):
    _packages_dev += ('libudev1',)
    _packages_nacl += ('libudev1:i386',)
  else:
    _packages_dev += ('libudev0',)
    _packages_nacl += ('libudev0:i386',)

  if package_exists('libbrlapi0.6'):
    _packages_dev += ('libbrlapi0.6',)
  else:
    _packages_dev += ('libbrlapi0.5',)

  # Some packages are only needed if the distribution actually supports
  # installing them.
  if package_exists('appmenu-gtk'):
    _packages_lib += ('appmenu-gtk',)

  _packages_dev += _packages_chromeos_dev
  _packages_lib += _packages_chromeos_lib
  _packages_nacl += _packages_naclports


def quick_check(packages):
  rc, stdout, stderr = nonfatal_get_output([
      'dpkg-query', '-W', '-f', '${PackageSpec}:${Status}\n'] + list(packages))
  if rc == 0 and not stderr:
    return 0
  print stderr
  return 1


def main(argv):
  parser = argparse.ArgumentParser()
  parser.add_argument('--quick-check', action='store_true',
                      help='quickly try to determine if dependencies are '
                           'installed (this avoids interactive prompts and '
                           'sudo commands so might not be 100% accurate)')
  parser.add_argument('--unsupported', action='store_true',
                      help='attempt installation even on unsupported systems')
  args = parser.parse_args(argv)

  lsb_codename = lsb_release_short_codename()
  if not args.unsupported and not args.quick_check:
    if lsb_codename not in map(
        operator.itemgetter('codename'), SUPPORTED_UBUNTU_VERSIONS):
      supported_ubuntus = ['%(number)s (%(codename)s)' % v
                           for v in SUPPORTED_UBUNTU_VERSIONS]
      write_error('Only Ubuntu %s are currently supported.' %
                  ', '.join(supported_ubuntus))
      return 1

    if platform.machine() not in ('i686', 'x86_64'):
      write_error('Only x86 architectures are currently supported.')
      return 1

  if os.geteuid() != 0 and not args.quick_check:
    print 'Running as non-root user.'
    print 'You might have to enter your password one or more times'
    print 'for \'sudo\'.'
    print

  compute_dynamic_package_lists()

  packages = (_packages_dev + _packages_lib + _packages_dbg + _packages_lib32 +
              _packages_arm + _packages_nacl)
  def packages_key(pkg):
    s = pkg.rsplit(':', 1)
    if len(s) == 1:
      return (s, '')
    return s
  packages = sorted(set(packages), key=packages_key)

  if args.quick_check:
    return quick_check(packages)

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
