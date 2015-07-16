#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
lastchange.py -- Chromium revision fetching utility.
"""

import re
import optparse
import os
import subprocess
import sys

_GIT_SVN_ID_REGEX = re.compile(r'.*git-svn-id:\s*([^@]*)@([0-9]+)', re.DOTALL)

class VersionInfo(object):
  def __init__(self, url, revision):
    self.url = url
    self.revision = revision


def FetchSVNRevision(directory, svn_url_regex):
  """
  Fetch the Subversion branch and revision for a given directory.

  Errors are swallowed.

  Returns:
    A VersionInfo object or None on error.
  """
  try:
    proc = subprocess.Popen(['svn', 'info'],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            cwd=directory,
                            shell=(sys.platform=='win32'))
  except OSError:
    # command is apparently either not installed or not executable.
    return None
  if not proc:
    return None

  attrs = {}
  for line in proc.stdout:
    line = line.strip()
    if not line:
      continue
    key, val = line.split(': ', 1)
    attrs[key] = val

  try:
    match = svn_url_regex.search(attrs['URL'])
    if match:
      url = match.group(2)
    else:
      url = ''
    revision = attrs['Revision']
  except KeyError:
    return None

  return VersionInfo(url, revision)


def RunGitCommand(directory, command):
  """
  Launches git subcommand.

  Errors are swallowed.

  Returns:
    A process object or None.
  """
  command = ['git'] + command
  # Force shell usage under cygwin. This is a workaround for
  # mysterious loss of cwd while invoking cygwin's git.
  # We can't just pass shell=True to Popen, as under win32 this will
  # cause CMD to be used, while we explicitly want a cygwin shell.
  if sys.platform == 'cygwin':
    command = ['sh', '-c', ' '.join(command)]
  try:
    proc = subprocess.Popen(command,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            cwd=directory,
                            shell=(sys.platform=='win32'))
    return proc
  except OSError:
    return None


def FetchGitRevision(directory):
  """
  Fetch the Git hash for a given directory.

  Errors are swallowed.

  Returns:
    A VersionInfo object or None on error.
  """
  hsh = ''
  proc = RunGitCommand(directory, ['rev-parse', 'HEAD'])
  if proc:
    output = proc.communicate()[0].strip()
    if proc.returncode == 0 and output:
      hsh = output
  if not hsh:
    return None
  pos = ''
  proc = RunGitCommand(directory, ['cat-file', 'commit', 'HEAD'])
  if proc:
    output = proc.communicate()[0]
    if proc.returncode == 0 and output:
      for line in reversed(output.splitlines()):
        if line.startswith('Cr-Commit-Position:'):
          pos = line.rsplit()[-1].strip()
          break
  if not pos:
    return VersionInfo('git', hsh)
  return VersionInfo('git', '%s-%s' % (hsh, pos))


def FetchGitSVNURLAndRevision(directory, svn_url_regex):
  """
  Fetch the Subversion URL and revision through Git.

  Errors are swallowed.

  Returns:
    A tuple containing the Subversion URL and revision.
  """
  proc = RunGitCommand(directory, ['log', '-1', '--format=%b'])
  if proc:
    output = proc.communicate()[0].strip()
    if proc.returncode == 0 and output:
      # Extract the latest SVN revision and the SVN URL.
      # The target line is the last "git-svn-id: ..." line like this:
      # git-svn-id: svn://svn.chromium.org/chrome/trunk/src@85528 0039d316....
      match = _GIT_SVN_ID_REGEX.search(output)
      if match:
        revision = match.group(2)
        url_match = svn_url_regex.search(match.group(1))
        if url_match:
          url = url_match.group(2)
        else:
          url = ''
        return url, revision
  return None, None


def FetchGitSVNRevision(directory, svn_url_regex):
  """
  Fetch the Git-SVN identifier for the local tree.

  Errors are swallowed.
  """
  url, revision = FetchGitSVNURLAndRevision(directory, svn_url_regex)
  if url and revision:
    return VersionInfo(url, revision)
  return None


def FetchVersionInfo(default_lastchange, directory=None,
                     directory_regex_prior_to_src_url='chrome|blink|svn'):
  """
  Returns the last change (in the form of a branch, revision tuple),
  from some appropriate revision control system.
  """
  svn_url_regex = re.compile(
      r'.*/(' + directory_regex_prior_to_src_url + r')(/.*)')

  version_info = (FetchSVNRevision(directory, svn_url_regex) or
                  FetchGitSVNRevision(directory, svn_url_regex) or
                  FetchGitRevision(directory))
  if not version_info:
    if default_lastchange and os.path.exists(default_lastchange):
      revision = open(default_lastchange, 'r').read().strip()
      version_info = VersionInfo(None, revision)
    else:
      version_info = VersionInfo(None, None)
  return version_info

def GetHeaderGuard(path):
  """
  Returns the header #define guard for the given file path.
  This treats everything after the last instance of "src/" as being a
  relevant part of the guard. If there is no "src/", then the entire path
  is used.
  """
  src_index = path.rfind('src/')
  if src_index != -1:
    guard = path[src_index + 4:]
  else:
    guard = path
  guard = guard.upper()
  return guard.replace('/', '_').replace('.', '_').replace('\\', '_') + '_'

def GetHeaderContents(path, define, version):
  """
  Returns what the contents of the header file should be that indicate the given
  revision. Note that the #define is specified as a string, even though it's
  currently always a SVN revision number, in case we need to move to git hashes.
  """
  header_guard = GetHeaderGuard(path)

  header_contents = """/* Generated by lastchange.py, do not edit.*/

#ifndef %(header_guard)s
#define %(header_guard)s

#define %(define)s "%(version)s"

#endif  // %(header_guard)s
"""
  header_contents = header_contents % { 'header_guard': header_guard,
                                        'define': define,
                                        'version': version }
  return header_contents

def WriteIfChanged(file_name, contents):
  """
  Writes the specified contents to the specified file_name
  iff the contents are different than the current contents.
  """
  try:
    old_contents = open(file_name, 'r').read()
  except EnvironmentError:
    pass
  else:
    if contents == old_contents:
      return
    os.unlink(file_name)
  open(file_name, 'w').write(contents)


def main(argv=None):
  if argv is None:
    argv = sys.argv

  parser = optparse.OptionParser(usage="lastchange.py [options]")
  parser.add_option("-d", "--default-lastchange", metavar="FILE",
                    help="Default last change input FILE.")
  parser.add_option("-m", "--version-macro",
                    help="Name of C #define when using --header. Defaults to " +
                    "LAST_CHANGE.",
                    default="LAST_CHANGE")
  parser.add_option("-o", "--output", metavar="FILE",
                    help="Write last change to FILE. " +
                    "Can be combined with --header to write both files.")
  parser.add_option("", "--header", metavar="FILE",
                    help="Write last change to FILE as a C/C++ header. " +
                    "Can be combined with --output to write both files.")
  parser.add_option("--revision-only", action='store_true',
                    help="Just print the SVN revision number. Overrides any " +
                    "file-output-related options.")
  parser.add_option("-s", "--source-dir", metavar="DIR",
                    help="Use repository in the given directory.")
  opts, args = parser.parse_args(argv[1:])

  out_file = opts.output
  header = opts.header

  while len(args) and out_file is None:
    if out_file is None:
      out_file = args.pop(0)
  if args:
    sys.stderr.write('Unexpected arguments: %r\n\n' % args)
    parser.print_help()
    sys.exit(2)

  if opts.source_dir:
    src_dir = opts.source_dir
  else:
    src_dir = os.path.dirname(os.path.abspath(__file__))

  version_info = FetchVersionInfo(opts.default_lastchange, src_dir)

  if version_info.revision == None:
    version_info.revision = '0'

  if opts.revision_only:
    print version_info.revision
  else:
    contents = "LASTCHANGE=%s\n" % version_info.revision
    if not out_file and not opts.header:
      sys.stdout.write(contents)
    else:
      if out_file:
        WriteIfChanged(out_file, contents)
      if header:
        WriteIfChanged(header,
                       GetHeaderContents(header, opts.version_macro,
                                         version_info.revision))

  return 0


if __name__ == '__main__':
  sys.exit(main())
