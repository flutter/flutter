#!/usr/bin/python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Downloads, builds (with instrumentation) and installs shared libraries."""

import argparse
import os
import platform
import re
import shlex
import shutil
import subprocess
import sys

SCRIPT_ABSOLUTE_PATH = os.path.dirname(os.path.abspath(__file__))

def unescape_flags(s):
  """Un-escapes build flags received from GYP.

  GYP escapes build flags as if they are to be inserted directly into a command
  line, wrapping each flag in double quotes. When flags are passed via
  CFLAGS/LDFLAGS instead, double quotes must be dropped.
  """
  return ' '.join(shlex.split(s))


def real_path(path_relative_to_gyp):
  """Returns the absolute path to a file.

  GYP generates paths relative to the location of the .gyp file, which is one
  level above the location of this script. This function converts them to
  absolute paths.
  """
  return os.path.realpath(os.path.join(SCRIPT_ABSOLUTE_PATH, '..',
                                       path_relative_to_gyp))


class InstrumentedPackageBuilder(object):
  """Checks out and builds a single instrumented package."""
  def __init__(self, args, clobber):
    self._cc = args.cc
    self._cxx = args.cxx
    self._extra_configure_flags = args.extra_configure_flags
    self._jobs = args.jobs
    self._libdir = args.libdir
    self._package = args.package
    self._patch = real_path(args.patch) if args.patch else None
    self._pre_build = \
        real_path(args.pre_build) if args.pre_build else None
    self._sanitizer = args.sanitizer
    self._verbose = args.verbose
    self._clobber = clobber
    self._working_dir = os.path.join(
        real_path(args.intermediate_dir), self._package, '')

    product_dir = real_path(args.product_dir)
    self._destdir = os.path.join(
        product_dir, 'instrumented_libraries', self._sanitizer)
    self._source_archives_dir = os.path.join(
        product_dir, 'instrumented_libraries', 'sources', self._package)

    self._cflags = unescape_flags(args.cflags)
    if args.sanitizer_blacklist:
      blacklist_file = real_path(args.sanitizer_blacklist)
      self._cflags += ' -fsanitize-blacklist=%s' % blacklist_file

    self._ldflags = unescape_flags(args.ldflags)

    self.init_build_env()

    # Initialized later.
    self._source_dir = None
    self._source_archives = None

  def init_build_env(self):
    self._build_env = os.environ.copy()

    self._build_env['CC'] = self._cc
    self._build_env['CXX'] = self._cxx

    self._build_env['CFLAGS'] = self._cflags
    self._build_env['CXXFLAGS'] = self._cflags
    self._build_env['LDFLAGS'] = self._ldflags

    if self._sanitizer == 'asan':
      # Do not report leaks during the build process.
      self._build_env['ASAN_OPTIONS'] = \
          '%s:detect_leaks=0' % self._build_env.get('ASAN_OPTIONS', '')

    # libappindicator1 needs this.
    self._build_env['CSC'] = '/usr/bin/mono-csc'

  def shell_call(self, command, env=None, cwd=None):
    """Wrapper around subprocess.Popen().

    Calls command with specific environment and verbosity using
    subprocess.Popen().
    """
    child = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        env=env, shell=True, cwd=cwd)
    stdout, stderr = child.communicate()
    if self._verbose or child.returncode:
      print stdout
    if child.returncode:
      raise Exception('Failed to run: %s' % command)

  def maybe_download_source(self):
    """Checks out the source code (if needed).

    Checks out the source code for the package, if required (i.e. unless running
    in no-clobber mode). Initializes self._source_dir and self._source_archives.
    """
    get_fresh_source = self._clobber or not os.path.exists(self._working_dir)
    if get_fresh_source:
      self.shell_call('rm -rf %s' % self._working_dir)
      os.makedirs(self._working_dir)
      self.shell_call('apt-get source %s' % self._package,
                      cwd=self._working_dir)

    (dirpath, dirnames, filenames) = os.walk(self._working_dir).next()

    if len(dirnames) != 1:
      raise Exception(
          '`apt-get source %s\' must create exactly one subdirectory.'
              % self._package)
    self._source_dir = os.path.join(dirpath, dirnames[0], '')

    if len(filenames) == 0:
      raise Exception('Can\'t find source archives after `apt-get source %s\'.'
         % self._package)
    self._source_archives = \
        [os.path.join(dirpath, filename) for filename in filenames]

    return get_fresh_source

  def patch_source(self):
    if self._patch:
      self.shell_call('patch -p1 -i %s' % self._patch, cwd=self._source_dir)
    if self._pre_build:
      self.shell_call(self._pre_build, cwd=self._source_dir)

  def copy_source_archives(self):
    """Copies the downloaded source archives to the output dir.

    For license compliance purposes, every Chromium build that includes
    instrumented libraries must include their full source code.
    """
    self.shell_call('rm -rf %s' % self._source_archives_dir)
    os.makedirs(self._source_archives_dir)
    for filename in self._source_archives:
      shutil.copy(filename, self._source_archives_dir)
    if self._patch:
      shutil.copy(self._patch, self._source_archives_dir)

  def download_build_install(self):
    got_fresh_source = self.maybe_download_source()
    if got_fresh_source:
      self.patch_source()
      self.copy_source_archives()

    self.shell_call('mkdir -p %s' % self.dest_libdir())

    try:
      self.build_and_install()
    except Exception as exception:
      print 'ERROR: Failed to build package %s. Have you run ' \
            'src/third_party/instrumented_libraries/scripts/' \
            'install-build-deps.sh?' % \
            self._package
      print
      raise

    # Touch a text file to indicate package is installed.
    stamp_file = os.path.join(self._destdir, '%s.txt' % self._package)
    open(stamp_file, 'w').close()

    # Remove downloaded package and generated temporary build files. Failed
    # builds intentionally skip this step to help debug build failures.
    if self._clobber:
      self.shell_call('rm -rf %s' % self._working_dir)

  def fix_rpaths(self, directory):
    # TODO(earthdok): reimplement fix_rpaths.sh in Python.
    script = real_path('scripts/fix_rpaths.sh')
    self.shell_call("%s %s" % (script, directory))

  def temp_dir(self):
    """Returns the directory which will be passed to `make install'."""
    return os.path.join(self._source_dir, 'debian', 'instrumented_build')

  def temp_libdir(self):
    """Returns the directory under temp_dir() containing the DSOs."""
    return os.path.join(self.temp_dir(), self._libdir)

  def dest_libdir(self):
    """Returns the final location of the DSOs."""
    return os.path.join(self._destdir, self._libdir)

  def cleanup_after_install(self):
    """Removes unneeded files in self.temp_libdir()."""
    # .la files are not needed, nuke them.
    # In case --no-static is not supported, nuke any static libraries we built.
    self.shell_call(
        'find %s -name *.la -or -name *.a | xargs rm -f' % self.temp_libdir())
    # .pc files are not needed.
    self.shell_call('rm %s/pkgconfig -rf' % self.temp_libdir())

  def make(self, args, jobs=None, env=None, cwd=None):
    """Invokes `make'.

    Invokes `make' with the specified args, using self._build_env and
    self._source_dir by default.
    """
    if jobs is None:
      jobs = self._jobs
    if cwd is None:
      cwd = self._source_dir
    if env is None:
      env = self._build_env
    cmd = ['make', '-j%s' % jobs] + args
    self.shell_call(' '.join(cmd), env=env, cwd=cwd)

  def make_install(self, args, **kwargs):
    """Invokes `make install'."""
    self.make(['install'] + args, **kwargs)

  def build_and_install(self):
    """Builds and installs the DSOs.

    Builds the package with ./configure + make, installs it to a temporary
    location, then moves the relevant files to their permanent location. 
    """
    configure_cmd = './configure --libdir=/%s/ %s' % (
        self._libdir, self._extra_configure_flags)
    self.shell_call(configure_cmd, env=self._build_env, cwd=self._source_dir)

    # Some makefiles use BUILDROOT or INSTALL_ROOT instead of DESTDIR.
    args = ['DESTDIR', 'BUILDROOT', 'INSTALL_ROOT']
    make_args = ['%s=%s' % (name, self.temp_dir()) for name in args]
    self.make(make_args)

    # Some packages don't support parallel install. Use -j1 always.
    self.make_install(make_args, jobs=1)

    self.cleanup_after_install()

    self.fix_rpaths(self.temp_libdir())

    # Now move the contents of the temporary destdir to their final place.
    # We only care for the contents of LIBDIR.
    self.shell_call('cp %s/* %s/ -rdf' % (self.temp_libdir(),
                                          self.dest_libdir()))


class LibcapBuilder(InstrumentedPackageBuilder):
  def build_and_install(self):
    # libcap2 doesn't have a configure script
    build_args = ['CC', 'CXX', 'CFLAGS', 'CXXFLAGS', 'LDFLAGS']
    make_args = [
        '%s="%s"' % (name, self._build_env[name]) for name in build_args
    ]
    self.make(make_args)

    install_args = [
        'DESTDIR=%s' % self.temp_dir(),
        'lib=%s' % self._libdir,
        # Skip a step that requires sudo.
        'RAISE_SETFCAP=no'
    ]
    self.make_install(install_args)

    self.cleanup_after_install()

    self.fix_rpaths(self.temp_libdir())

    # Now move the contents of the temporary destdir to their final place.
    # We only care for the contents of LIBDIR.
    self.shell_call('cp %s/* %s/ -rdf' % (self.temp_libdir(),
                                          self.dest_libdir()))


class Libpci3Builder(InstrumentedPackageBuilder):
  def package_version(self):
    """Guesses libpci3 version from source directory name."""
    dir_name = os.path.split(os.path.normpath(self._source_dir))[-1]
    match = re.match('pciutils-(\d+\.\d+\.\d+)', dir_name)
    if match is None:
      raise Exception(
          'Unable to guess libpci3 version from directory name: %s' %  dir_name)
    return match.group(1)

  def temp_libdir(self):
    # DSOs have to be picked up from <source_dir>/lib, since `make install'
    # doesn't actualy install them anywhere.
    return os.path.join(self._source_dir, 'lib')

  def build_and_install(self):
    # pciutils doesn't have a configure script
    # This build process follows debian/rules.
    self.shell_call('mkdir -p %s-udeb/usr/bin' % self.temp_dir())

    build_args = ['CC', 'CXX', 'CFLAGS', 'CXXFLAGS', 'LDFLAGS']
    make_args = [
        '%s="%s"' % (name, self._build_env[name]) for name in build_args
    ]
    make_args += [
        'LIBDIR=/%s/' % self._libdir,
        'PREFIX=/usr',
        'SBINDIR=/usr/bin',
        'IDSDIR=/usr/share/misc',
        'SHARED=yes',
        # pciutils-3.2.1 (Trusty) fails to build due to unresolved libkmod
        # symbols. The binary package has no dependencies on libkmod, so it
        # looks like it was actually built without libkmod support.
       'LIBKMOD=no',
    ]
    self.make(make_args)

    # `make install' is not needed.
    self.fix_rpaths(self.temp_libdir())

    # Now install the DSOs to their final place.
    self.shell_call(
        'install -m 644 %s/libpci.so* %s' % (self.temp_libdir(),
                                             self.dest_libdir()))
    self.shell_call(
        'ln -sf libpci.so.%s %s/libpci.so.3' % (self.package_version(),
                                                self.dest_libdir()))


class NSSBuilder(InstrumentedPackageBuilder):
  def build_and_install(self):
    # NSS uses a build system that's different from configure/make/install. All
    # flags must be passed as arguments to make.
    make_args = [
        # Do an optimized build.
        'BUILD_OPT=1',
        # CFLAGS/CXXFLAGS should not be used, as doing so overrides the flags in
        # the makefile completely. The only way to append our flags is to tack
        # them onto CC/CXX.
        'CC="%s %s"' % (self._build_env['CC'], self._build_env['CFLAGS']),
        'CXX="%s %s"' % (self._build_env['CXX'], self._build_env['CXXFLAGS']),
        # We need to override ZDEFS_FLAG at least to avoid -Wl,-z,defs, which
        # is not compatible with sanitizers. We also need some way to pass
        # LDFLAGS without overriding the defaults. Conveniently, ZDEF_FLAG is
        # always appended to link flags when building NSS on Linux, so we can
        # just add our LDFLAGS here.
        'ZDEFS_FLAG="-Wl,-z,nodefs %s"' % self._build_env['LDFLAGS'],
        'NSPR_INCLUDE_DIR=/usr/include/nspr',
        'NSPR_LIB_DIR=%s' % self.dest_libdir(),
        'NSS_ENABLE_ECC=1'
    ]
    if platform.architecture()[0] == '64bit':
      make_args.append('USE_64=1')

    # Make sure we don't override the default flags in the makefile.
    for variable in ['CFLAGS', 'CXXFLAGS', 'LDFLAGS']:
      del self._build_env[variable]

    # Hardcoded paths.
    temp_dir = os.path.join(self._source_dir, 'nss')
    temp_libdir = os.path.join(temp_dir, 'lib')

    # Parallel build is not supported. Also, the build happens in
    # <source_dir>/nss.
    self.make(make_args, jobs=1, cwd=temp_dir)

    self.fix_rpaths(temp_libdir)

    # 'make install' is not supported. Copy the DSOs manually.
    for (dirpath, dirnames, filenames) in os.walk(temp_libdir):
      for filename in filenames:
        if filename.endswith('.so'):
          full_path = os.path.join(dirpath, filename)
          if self._verbose:
            print 'download_build_install.py: installing %s' % full_path
          shutil.copy(full_path, self.dest_libdir())


def main():
  parser = argparse.ArgumentParser(
      description='Download, build and install an instrumented package.')

  parser.add_argument('-j', '--jobs', type=int, default=1)
  parser.add_argument('-p', '--package', required=True)
  parser.add_argument(
      '-i', '--product-dir', default='.',
      help='Relative path to the directory with chrome binaries')
  parser.add_argument(
      '-m', '--intermediate-dir', default='.',
      help='Relative path to the directory for temporary build files')
  parser.add_argument('--extra-configure-flags', default='')
  parser.add_argument('--cflags', default='')
  parser.add_argument('--ldflags', default='')
  parser.add_argument('-s', '--sanitizer', required=True,
                               choices=['asan', 'msan', 'tsan'])
  parser.add_argument('-v', '--verbose', action='store_true')
  parser.add_argument('--cc')
  parser.add_argument('--cxx')
  parser.add_argument('--patch', default='')
  # This should be a shell script to run before building specific libraries.
  # This will be run after applying the patch above.
  parser.add_argument('--pre-build', default='')
  parser.add_argument('--build-method', default='destdir')
  parser.add_argument('--sanitizer-blacklist', default='')
  # The LIBDIR argument to configure/make.
  parser.add_argument('--libdir', default='lib')

  # Ignore all empty arguments because in several cases gyp passes them to the
  # script, but ArgumentParser treats them as positional arguments instead of
  # ignoring (and doesn't have such options).
  args = parser.parse_args([arg for arg in sys.argv[1:] if len(arg) != 0])

  # Clobber by default, unless the developer wants to hack on the package's
  # source code.
  clobber = \
        (os.environ.get('INSTRUMENTED_LIBRARIES_NO_CLOBBER', '') != '1')

  if args.build_method == 'destdir':
    builder = InstrumentedPackageBuilder(args, clobber)
  elif args.build_method == 'custom_nss':
    builder = NSSBuilder(args, clobber)
  elif args.build_method == 'custom_libcap':
    builder = LibcapBuilder(args, clobber)
  elif args.build_method == 'custom_libpci3':
    builder = Libpci3Builder(args, clobber)
  else:
    raise Exception('Unrecognized build method: %s' % args.build_method)

  builder.download_build_install()

if __name__ == '__main__':
  main()
