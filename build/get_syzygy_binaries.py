#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A utility script for downloading versioned Syzygy binaries."""

import cStringIO
import hashlib
import errno
import json
import logging
import optparse
import os
import re
import shutil
import stat
import sys
import subprocess
import urllib2
import zipfile


_LOGGER = logging.getLogger(os.path.basename(__file__))

# The URL where official builds are archived.
_SYZYGY_ARCHIVE_URL = ('https://syzygy-archive.commondatastorage.googleapis.com'
    '/builds/official/%(revision)s')

# A JSON file containing the state of the download directory. If this file and
# directory state do not agree, then the binaries will be downloaded and
# installed again.
_STATE = '.state'

# This matches an integer (an SVN revision number) or a SHA1 value (a GIT hash).
# The archive exclusively uses lowercase GIT hashes.
_REVISION_RE = re.compile('^(?:\d+|[a-f0-9]{40})$')

# This matches an MD5 hash.
_MD5_RE = re.compile('^[a-f0-9]{32}$')

# List of reources to be downloaded and installed. These are tuples with the
# following format:
# (basename, logging name, relative installation path, extraction filter)
_RESOURCES = [
  ('benchmark.zip', 'benchmark', '', None),
  ('binaries.zip', 'binaries', 'exe', None),
  ('symbols.zip', 'symbols', 'exe',
      lambda x: x.filename.endswith('.dll.pdb'))]


def _Shell(*cmd, **kw):
  """Runs |cmd|, returns the results from Popen(cmd).communicate()."""
  _LOGGER.debug('Executing %s.', cmd)
  prog = subprocess.Popen(cmd, shell=True, **kw)

  stdout, stderr = prog.communicate()
  if prog.returncode != 0:
    raise RuntimeError('Command "%s" returned %d.' % (cmd, prog.returncode))
  return (stdout, stderr)


def _LoadState(output_dir):
  """Loads the contents of the state file for a given |output_dir|, returning
  None if it doesn't exist.
  """
  path = os.path.join(output_dir, _STATE)
  if not os.path.exists(path):
    _LOGGER.debug('No state file found.')
    return None
  with open(path, 'rb') as f:
    _LOGGER.debug('Reading state file: %s', path)
    try:
      return json.load(f)
    except ValueError:
      _LOGGER.debug('Invalid state file.')
      return None


def _SaveState(output_dir, state, dry_run=False):
  """Saves the |state| dictionary to the given |output_dir| as a JSON file."""
  path = os.path.join(output_dir, _STATE)
  _LOGGER.debug('Writing state file: %s', path)
  if dry_run:
    return
  with open(path, 'wb') as f:
    f.write(json.dumps(state, sort_keys=True, indent=2))


def _Md5(path):
  """Returns the MD5 hash of the file at |path|, which must exist."""
  return hashlib.md5(open(path, 'rb').read()).hexdigest()


def _StateIsValid(state):
  """Returns true if the given state structure is valid."""
  if not isinstance(state, dict):
    _LOGGER.debug('State must be a dict.')
    return False
  r = state.get('revision', None)
  if not isinstance(r, basestring) or not _REVISION_RE.match(r):
    _LOGGER.debug('State contains an invalid revision.')
    return False
  c = state.get('contents', None)
  if not isinstance(c, dict):
    _LOGGER.debug('State must contain a contents dict.')
    return False
  for (relpath, md5) in c.iteritems():
    if not isinstance(relpath, basestring) or len(relpath) == 0:
      _LOGGER.debug('State contents dict contains an invalid path.')
      return False
    if not isinstance(md5, basestring) or not _MD5_RE.match(md5):
      _LOGGER.debug('State contents dict contains an invalid MD5 digest.')
      return False
  return True


def _BuildActualState(stored, revision, output_dir):
  """Builds the actual state using the provided |stored| state as a template.
  Only examines files listed in the stored state, causing the script to ignore
  files that have been added to the directories locally. |stored| must be a
  valid state dictionary.
  """
  contents = {}
  state = { 'revision': revision, 'contents': contents }
  for relpath, md5 in stored['contents'].iteritems():
    abspath = os.path.abspath(os.path.join(output_dir, relpath))
    if os.path.isfile(abspath):
      m = _Md5(abspath)
      contents[relpath] = m

  return state


def _StatesAreConsistent(stored, actual):
  """Validates whether two state dictionaries are consistent. Both must be valid
  state dictionaries. Additional entries in |actual| are ignored.
  """
  if stored['revision'] != actual['revision']:
    _LOGGER.debug('Mismatched revision number.')
    return False
  cont_stored = stored['contents']
  cont_actual = actual['contents']
  for relpath, md5 in cont_stored.iteritems():
    if relpath not in cont_actual:
      _LOGGER.debug('Missing content: %s', relpath)
      return False
    if md5 != cont_actual[relpath]:
      _LOGGER.debug('Modified content: %s', relpath)
      return False
  return True


def _GetCurrentState(revision, output_dir):
  """Loads the current state and checks to see if it is consistent. Returns
  a tuple (state, bool). The returned state will always be valid, even if an
  invalid state is present on disk.
  """
  stored = _LoadState(output_dir)
  if not _StateIsValid(stored):
    _LOGGER.debug('State is invalid.')
    # Return a valid but empty state.
    return ({'revision': '0', 'contents': {}}, False)
  actual = _BuildActualState(stored, revision, output_dir)
  # If the script has been modified consider the state invalid.
  path = os.path.join(output_dir, _STATE)
  if os.path.getmtime(__file__) > os.path.getmtime(path):
    return (stored, False)
  # Otherwise, explicitly validate the state.
  if not _StatesAreConsistent(stored, actual):
    return (stored, False)
  return (stored, True)


def _DirIsEmpty(path):
  """Returns true if the given directory is empty, false otherwise."""
  for root, dirs, files in os.walk(path):
    return not dirs and not files


def _RmTreeHandleReadOnly(func, path, exc):
  """An error handling function for use with shutil.rmtree. This will
  detect failures to remove read-only files, and will change their properties
  prior to removing them. This is necessary on Windows as os.remove will return
  an access error for read-only files, and git repos contain read-only
  pack/index files.
  """
  excvalue = exc[1]
  if func in (os.rmdir, os.remove) and excvalue.errno == errno.EACCES:
    _LOGGER.debug('Removing read-only path: %s', path)
    os.chmod(path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
    func(path)
  else:
    raise


def _RmTree(path):
  """A wrapper of shutil.rmtree that handles read-only files."""
  shutil.rmtree(path, ignore_errors=False, onerror=_RmTreeHandleReadOnly)


def _CleanState(output_dir, state, dry_run=False):
  """Cleans up files/directories in |output_dir| that are referenced by
  the given |state|. Raises an error if there are local changes. Returns a
  dictionary of files that were deleted.
  """
  _LOGGER.debug('Deleting files from previous installation.')
  deleted = {}

  # Generate a list of files to delete, relative to |output_dir|.
  contents = state['contents']
  files = sorted(contents.keys())

  # Try to delete the files. Keep track of directories to delete as well.
  dirs = {}
  for relpath in files:
    fullpath = os.path.join(output_dir, relpath)
    fulldir = os.path.dirname(fullpath)
    dirs[fulldir] = True
    if os.path.exists(fullpath):
      # If somehow the file has become a directory complain about it.
      if os.path.isdir(fullpath):
        raise Exception('Directory exists where file expected: %s' % fullpath)

      # Double check that the file doesn't have local changes. If it does
      # then refuse to delete it.
      if relpath in contents:
        stored_md5 = contents[relpath]
        actual_md5 = _Md5(fullpath)
        if actual_md5 != stored_md5:
          raise Exception('File has local changes: %s' % fullpath)

      # The file is unchanged so it can safely be deleted.
      _LOGGER.debug('Deleting file "%s".', fullpath)
      deleted[relpath] = True
      if not dry_run:
        os.unlink(fullpath)

  # Sort directories from longest name to shortest. This lets us remove empty
  # directories from the most nested paths first.
  dirs = sorted(dirs.keys(), key=lambda x: len(x), reverse=True)
  for p in dirs:
    if os.path.exists(p) and _DirIsEmpty(p):
      _LOGGER.debug('Deleting empty directory "%s".', p)
      if not dry_run:
        _RmTree(p)

  return deleted


def _Download(url):
  """Downloads the given URL and returns the contents as a string."""
  response = urllib2.urlopen(url)
  if response.code != 200:
    raise RuntimeError('Failed to download "%s".' % url)
  return response.read()


def _InstallBinaries(options, deleted={}):
  """Installs Syzygy binaries. This assumes that the output directory has
  already been cleaned, as it will refuse to overwrite existing files."""
  contents = {}
  state = { 'revision': options.revision, 'contents': contents }
  archive_url = _SYZYGY_ARCHIVE_URL % { 'revision': options.revision }
  if options.resources:
    resources = [(resource, resource, '', None)
                 for resource in options.resources]
  else:
    resources = _RESOURCES
  for (base, name, subdir, filt) in resources:
    # Create the output directory if it doesn't exist.
    fulldir = os.path.join(options.output_dir, subdir)
    if os.path.isfile(fulldir):
      raise Exception('File exists where a directory needs to be created: %s' %
                      fulldir)
    if not os.path.exists(fulldir):
      _LOGGER.debug('Creating directory: %s', fulldir)
      if not options.dry_run:
        os.makedirs(fulldir)

    # Download the archive.
    url = archive_url + '/' + base
    _LOGGER.debug('Retrieving %s archive at "%s".', name, url)
    data = _Download(url)

    _LOGGER.debug('Unzipping %s archive.', name)
    archive = zipfile.ZipFile(cStringIO.StringIO(data))
    for entry in archive.infolist():
      if not filt or filt(entry):
        fullpath = os.path.normpath(os.path.join(fulldir, entry.filename))
        relpath = os.path.relpath(fullpath, options.output_dir)
        if os.path.exists(fullpath):
          # If in a dry-run take into account the fact that the file *would*
          # have been deleted.
          if options.dry_run and relpath in deleted:
            pass
          else:
            raise Exception('Path already exists: %s' % fullpath)

        # Extract the file and update the state dictionary.
        _LOGGER.debug('Extracting "%s".', fullpath)
        if not options.dry_run:
          archive.extract(entry.filename, fulldir)
          md5 = _Md5(fullpath)
          contents[relpath] = md5
          if sys.platform == 'cygwin':
            os.chmod(fullpath, os.stat(fullpath).st_mode | stat.S_IXUSR)

  return state


def _ParseCommandLine():
  """Parses the command-line and returns an options structure."""
  option_parser = optparse.OptionParser()
  option_parser.add_option('--dry-run', action='store_true', default=False,
      help='If true then will simply list actions that would be performed.')
  option_parser.add_option('--force', action='store_true', default=False,
      help='Force an installation even if the binaries are up to date.')
  option_parser.add_option('--output-dir', type='string',
      help='The path where the binaries will be replaced. Existing binaries '
           'will only be overwritten if not up to date.')
  option_parser.add_option('--overwrite', action='store_true', default=False,
      help='If specified then the installation will happily delete and rewrite '
           'the entire output directory, blasting any local changes.')
  option_parser.add_option('--revision', type='string',
      help='The SVN revision or GIT hash associated with the required version.')
  option_parser.add_option('--revision-file', type='string',
      help='A text file containing an SVN revision or GIT hash.')
  option_parser.add_option('--resource', type='string', action='append',
      dest='resources', help='A resource to be downloaded.')
  option_parser.add_option('--verbose', dest='log_level', action='store_const',
      default=logging.INFO, const=logging.DEBUG,
      help='Enables verbose logging.')
  option_parser.add_option('--quiet', dest='log_level', action='store_const',
      default=logging.INFO, const=logging.ERROR,
      help='Disables all output except for errors.')
  options, args = option_parser.parse_args()
  if args:
    option_parser.error('Unexpected arguments: %s' % args)
  if not options.output_dir:
    option_parser.error('Must specify --output-dir.')
  if not options.revision and not options.revision_file:
    option_parser.error('Must specify one of --revision or --revision-file.')
  if options.revision and options.revision_file:
    option_parser.error('Must not specify both --revision and --revision-file.')

  # Configure logging.
  logging.basicConfig(level=options.log_level)

  # If a revision file has been specified then read it.
  if options.revision_file:
    options.revision = open(options.revision_file, 'rb').read().strip()
    _LOGGER.debug('Parsed revision "%s" from file "%s".',
                 options.revision, options.revision_file)

  # Ensure that the specified SVN revision or GIT hash is valid.
  if not _REVISION_RE.match(options.revision):
    option_parser.error('Must specify a valid SVN or GIT revision.')

  # This just makes output prettier to read.
  options.output_dir = os.path.normpath(options.output_dir)

  return options


def _RemoveOrphanedFiles(options):
  """This is run on non-Windows systems to remove orphaned files that may have
  been downloaded by a previous version of this script.
  """
  # Reconfigure logging to output info messages. This will allow inspection of
  # cleanup status on non-Windows buildbots.
  _LOGGER.setLevel(logging.INFO)

  output_dir = os.path.abspath(options.output_dir)

  # We only want to clean up the folder in 'src/third_party/syzygy', and we
  # expect to be called with that as an output directory. This is an attempt to
  # not start deleting random things if the script is run from an alternate
  # location, or not called from the gclient hooks.
  expected_syzygy_dir = os.path.abspath(os.path.join(
      os.path.dirname(__file__), '..', 'third_party', 'syzygy'))
  expected_output_dir = os.path.join(expected_syzygy_dir, 'binaries')
  if expected_output_dir != output_dir:
    _LOGGER.info('Unexpected output directory, skipping cleanup.')
    return

  if not os.path.isdir(expected_syzygy_dir):
    _LOGGER.info('Output directory does not exist, skipping cleanup.')
    return

  def OnError(function, path, excinfo):
    """Logs error encountered by shutil.rmtree."""
    _LOGGER.error('Error when running %s(%s)', function, path, exc_info=excinfo)

  _LOGGER.info('Removing orphaned files from %s', expected_syzygy_dir)
  if not options.dry_run:
    shutil.rmtree(expected_syzygy_dir, True, OnError)


def main():
  options = _ParseCommandLine()

  if options.dry_run:
    _LOGGER.debug('Performing a dry-run.')

  # We only care about Windows platforms, as the Syzygy binaries aren't used
  # elsewhere. However, there was a short period of time where this script
  # wasn't gated on OS types, and those OSes downloaded and installed binaries.
  # This will cleanup orphaned files on those operating systems.
  if sys.platform not in ('win32', 'cygwin'):
    return _RemoveOrphanedFiles(options)

  # Load the current installation state, and validate it against the
  # requested installation.
  state, is_consistent = _GetCurrentState(options.revision, options.output_dir)

  # Decide whether or not an install is necessary.
  if options.force:
    _LOGGER.debug('Forcing reinstall of binaries.')
  elif is_consistent:
    # Avoid doing any work if the contents of the directory are consistent.
    _LOGGER.debug('State unchanged, no reinstall necessary.')
    return

  # Under normal logging this is the only only message that will be reported.
  _LOGGER.info('Installing revision %s Syzygy binaries.',
               options.revision[0:12])

  # Clean up the old state to begin with.
  deleted = []
  if options.overwrite:
    if os.path.exists(options.output_dir):
      # If overwrite was specified then take a heavy-handed approach.
      _LOGGER.debug('Deleting entire installation directory.')
      if not options.dry_run:
        _RmTree(options.output_dir)
  else:
    # Otherwise only delete things that the previous installation put in place,
    # and take care to preserve any local changes.
    deleted = _CleanState(options.output_dir, state, options.dry_run)

  # Install the new binaries. In a dry-run this will actually download the
  # archives, but it won't write anything to disk.
  state = _InstallBinaries(options, deleted)

  # Build and save the state for the directory.
  _SaveState(options.output_dir, state, options.dry_run)


if __name__ == '__main__':
  main()
