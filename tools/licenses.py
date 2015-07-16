#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility for checking and processing licensing information in third_party
directories.

Usage: licenses.py <command>

Commands:
  scan     scan third_party directories, verifying that we have licensing info
  credits  generate about:credits on stdout

(You can also import this as a module.)
"""

import cgi
import os
import sys

# Paths from the root of the tree to directories to skip.
PRUNE_PATHS = set([
    # Same module occurs in crypto/third_party/nss and net/third_party/nss, so
    # skip this one.
    os.path.join('third_party','nss'),

    # Placeholder directory only, not third-party code.
    os.path.join('third_party','adobe'),

    # Build files only, not third-party code.
    os.path.join('third_party','widevine'),

    # Only binaries, used during development.
    os.path.join('third_party','valgrind'),

    # Used for development and test, not in the shipping product.
    os.path.join('build','secondary'),
    os.path.join('third_party','bison'),
    os.path.join('third_party','blanketjs'),
    os.path.join('third_party','gnu_binutils'),
    os.path.join('third_party','gold'),
    os.path.join('third_party','gperf'),
    os.path.join('third_party','lighttpd'),
    os.path.join('third_party','llvm'),
    os.path.join('third_party','llvm-build'),
    os.path.join('third_party','nacl_sdk_binaries'),
    os.path.join('third_party','pefile'),
    os.path.join('third_party','perl'),
    os.path.join('third_party','pylib'),
    os.path.join('third_party','pywebsocket'),
    os.path.join('third_party','qunit'),
    os.path.join('third_party','sinonjs'),
    os.path.join('third_party','syzygy'),
    os.path.join('tools', 'profile_chrome', 'third_party'),

    # Chromium code in third_party.
    os.path.join('third_party','fuzzymatch'),
    os.path.join('tools', 'swarming_client'),

    # Stuff pulled in from chrome-internal for official builds/tools.
    os.path.join('third_party', 'clear_cache'),
    os.path.join('third_party', 'gnu'),
    os.path.join('third_party', 'googlemac'),
    os.path.join('third_party', 'pcre'),
    os.path.join('third_party', 'psutils'),
    os.path.join('third_party', 'sawbuck'),
])

# Directories we don't scan through.
VCS_METADATA_DIRS = ('.svn', '.git')
PRUNE_DIRS = (VCS_METADATA_DIRS +
              ('out', 'Debug', 'Release',  # build files
               'tests'))            # lots of subdirs, not shipped.

ADDITIONAL_PATHS = (
    os.path.join('breakpad'),
    os.path.join('chrome', 'common', 'extensions', 'docs', 'examples'),
    os.path.join('chrome', 'test', 'chromeos', 'autotest'),
    os.path.join('chrome', 'test', 'data'),
    os.path.join('native_client'),
    os.path.join('net', 'tools', 'spdyshark'),
    os.path.join('sdch', 'open-vcdiff'),
    os.path.join('testing', 'gmock'),
    os.path.join('testing', 'gtest'),
    os.path.join('tools', 'grit'),
    os.path.join('tools', 'gyp'),
    os.path.join('tools', 'page_cycler', 'acid3'),
    os.path.join('url', 'third_party', 'mozilla'),
    os.path.join('v8'),
    # Fake directory so we can include the strongtalk license.
    os.path.join('v8', 'strongtalk'),
    os.path.join('v8', 'third_party', 'fdlibm'),
)


# Directories where we check out directly from upstream, and therefore
# can't provide a README.chromium.  Please prefer a README.chromium
# wherever possible.
SPECIAL_CASES = {
    os.path.join('native_client'): {
        "Name": "native client",
        "URL": "http://code.google.com/p/nativeclient",
        "License": "BSD",
    },
    os.path.join('sdch', 'open-vcdiff'): {
        "Name": "open-vcdiff",
        "URL": "http://code.google.com/p/open-vcdiff",
        "License": "Apache 2.0, MIT, GPL v2 and custom licenses",
        "License Android Compatible": "yes",
    },
    os.path.join('testing', 'gmock'): {
        "Name": "gmock",
        "URL": "http://code.google.com/p/googlemock",
        "License": "BSD",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('testing', 'gtest'): {
        "Name": "gtest",
        "URL": "http://code.google.com/p/googletest",
        "License": "BSD",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('third_party', 'angle'): {
        "Name": "Almost Native Graphics Layer Engine",
        "URL": "http://code.google.com/p/angleproject/",
        "License": "BSD",
    },
    os.path.join('third_party', 'cros_system_api'): {
        "Name": "Chromium OS system API",
        "URL": "http://www.chromium.org/chromium-os",
        "License": "BSD",
        # Absolute path here is resolved as relative to the source root.
        "License File": "/LICENSE.chromium_os",
    },
    os.path.join('third_party', 'lss'): {
        "Name": "linux-syscall-support",
        "URL": "http://code.google.com/p/linux-syscall-support/",
        "License": "BSD",
        "License File": "/LICENSE",
    },
    os.path.join('third_party', 'ots'): {
        "Name": "OTS (OpenType Sanitizer)",
        "URL": "http://code.google.com/p/ots/",
        "License": "BSD",
    },
    os.path.join('third_party', 'pdfium'): {
        "Name": "PDFium",
        "URL": "http://code.google.com/p/pdfium/",
        "License": "BSD",
    },
    os.path.join('third_party', 'pdfsqueeze'): {
        "Name": "pdfsqueeze",
        "URL": "http://code.google.com/p/pdfsqueeze/",
        "License": "Apache 2.0",
        "License File": "COPYING",
    },
    os.path.join('third_party', 'ppapi'): {
        "Name": "ppapi",
        "URL": "http://code.google.com/p/ppapi/",
    },
    os.path.join('third_party', 'scons-2.0.1'): {
        "Name": "scons-2.0.1",
        "URL": "http://www.scons.org",
        "License": "MIT",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('third_party', 'trace-viewer'): {
        "Name": "trace-viewer",
        "URL": "http://code.google.com/p/trace-viewer",
        "License": "BSD",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('third_party', 'v8-i18n'): {
        "Name": "Internationalization Library for v8",
        "URL": "http://code.google.com/p/v8-i18n/",
        "License": "Apache 2.0",
    },
    os.path.join('third_party', 'WebKit'): {
        "Name": "WebKit",
        "URL": "http://webkit.org/",
        "License": "BSD and GPL v2",
        # Absolute path here is resolved as relative to the source root.
        "License File": "/webkit/LICENSE",
    },
    os.path.join('third_party', 'webpagereplay'): {
        "Name": "webpagereplay",
        "URL": "http://code.google.com/p/web-page-replay",
        "License": "Apache 2.0",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('tools', 'grit'): {
        "Name": "grit",
        "URL": "http://code.google.com/p/grit-i18n",
        "License": "BSD",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('tools', 'gyp'): {
        "Name": "gyp",
        "URL": "http://code.google.com/p/gyp",
        "License": "BSD",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('v8'): {
        "Name": "V8 JavaScript Engine",
        "URL": "http://code.google.com/p/v8",
        "License": "BSD",
    },
    os.path.join('v8', 'strongtalk'): {
        "Name": "Strongtalk",
        "URL": "http://www.strongtalk.org/",
        "License": "BSD",
        # Absolute path here is resolved as relative to the source root.
        "License File": "/v8/LICENSE.strongtalk",
    },
    os.path.join('v8', 'third_party', 'fdlibm'): {
        "Name": "fdlibm",
        "URL": "http://www.netlib.org/fdlibm/",
        "License": "Freely Distributable",
        # Absolute path here is resolved as relative to the source root.
        "License File" : "/v8/third_party/fdlibm/LICENSE",
        "License Android Compatible" : "yes",
    },
    os.path.join('third_party', 'khronos_glcts'): {
        # These sources are not shipped, are not public, and it isn't
        # clear why they're tripping the license check.
        "Name": "khronos_glcts",
        "URL": "http://no-public-url",
        "License": "Khronos",
        "License File": "NOT_SHIPPED",
    },
    os.path.join('tools', 'telemetry', 'third_party', 'gsutil'): {
        "Name": "gsutil",
        "URL": "https://cloud.google.com/storage/docs/gsutil",
        "License": "Apache 2.0",
        "License File": "NOT_SHIPPED",
    },
}

# Special value for 'License File' field used to indicate that the license file
# should not be used in about:credits.
NOT_SHIPPED = "NOT_SHIPPED"


class LicenseError(Exception):
    """We raise this exception when a directory's licensing info isn't
    fully filled out."""
    pass

def AbsolutePath(path, filename, root):
    """Convert a path in README.chromium to be absolute based on the source
    root."""
    if filename.startswith('/'):
        # Absolute-looking paths are relative to the source root
        # (which is the directory we're run from).
        absolute_path = os.path.join(root, filename[1:])
    else:
        absolute_path = os.path.join(root, path, filename)
    if os.path.exists(absolute_path):
        return absolute_path
    return None

def ParseDir(path, root, require_license_file=True, optional_keys=None):
    """Examine a third_party/foo component and extract its metadata."""

    # Parse metadata fields out of README.chromium.
    # We examine "LICENSE" for the license file by default.
    metadata = {
        "License File": "LICENSE",  # Relative path to license text.
        "Name": None,               # Short name (for header on about:credits).
        "URL": None,                # Project home page.
        "License": None,            # Software license.
        }

    if optional_keys is None:
        optional_keys = []

    if path in SPECIAL_CASES:
        metadata.update(SPECIAL_CASES[path])
    else:
        # Try to find README.chromium.
        readme_path = os.path.join(root, path, 'README.chromium')
        if not os.path.exists(readme_path):
            raise LicenseError("missing README.chromium or licenses.py "
                               "SPECIAL_CASES entry")

        for line in open(readme_path):
            line = line.strip()
            if not line:
                break
            for key in metadata.keys() + optional_keys:
                field = key + ": "
                if line.startswith(field):
                    metadata[key] = line[len(field):]

    # Check that all expected metadata is present.
    for key, value in metadata.iteritems():
        if not value:
            raise LicenseError("couldn't find '" + key + "' line "
                               "in README.chromium or licences.py "
                               "SPECIAL_CASES")

    # Special-case modules that aren't in the shipping product, so don't need
    # their license in about:credits.
    if metadata["License File"] != NOT_SHIPPED:
        # Check that the license file exists.
        for filename in (metadata["License File"], "COPYING"):
            license_path = AbsolutePath(path, filename, root)
            if license_path is not None:
                break

        if require_license_file and not license_path:
            raise LicenseError("License file not found. "
                               "Either add a file named LICENSE, "
                               "import upstream's COPYING if available, "
                               "or add a 'License File:' line to "
                               "README.chromium with the appropriate path.")
        metadata["License File"] = license_path

    return metadata


def ContainsFiles(path, root):
    """Determines whether any files exist in a directory or in any of its
    subdirectories."""
    for _, dirs, files in os.walk(os.path.join(root, path)):
        if files:
            return True
        for vcs_metadata in VCS_METADATA_DIRS:
            if vcs_metadata in dirs:
                dirs.remove(vcs_metadata)
    return False


def FilterDirsWithFiles(dirs_list, root):
    # If a directory contains no files, assume it's a DEPS directory for a
    # project not used by our current configuration and skip it.
    return [x for x in dirs_list if ContainsFiles(x, root)]


def FindThirdPartyDirs(prune_paths, root):
    """Find all third_party directories underneath the source root."""
    third_party_dirs = set()
    for path, dirs, files in os.walk(root):
        path = path[len(root)+1:]  # Pretty up the path.

        if path in prune_paths:
            dirs[:] = []
            continue

        # Prune out directories we want to skip.
        # (Note that we loop over PRUNE_DIRS so we're not iterating over a
        # list that we're simultaneously mutating.)
        for skip in PRUNE_DIRS:
            if skip in dirs:
                dirs.remove(skip)

        if os.path.basename(path) == 'third_party':
            # Add all subdirectories that are not marked for skipping.
            for dir in dirs:
                dirpath = os.path.join(path, dir)
                if dirpath not in prune_paths:
                    third_party_dirs.add(dirpath)

            # Don't recurse into any subdirs from here.
            dirs[:] = []
            continue

        # Don't recurse into paths in ADDITIONAL_PATHS, like we do with regular
        # third_party/foo paths.
        if path in ADDITIONAL_PATHS:
            dirs[:] = []

    for dir in ADDITIONAL_PATHS:
        if dir not in prune_paths:
            third_party_dirs.add(dir)

    return third_party_dirs


def ScanThirdPartyDirs(root=None):
    """Scan a list of directories and report on any problems we find."""
    if root is None:
      root = os.getcwd()
    third_party_dirs = FindThirdPartyDirs(PRUNE_PATHS, root)
    third_party_dirs = FilterDirsWithFiles(third_party_dirs, root)

    errors = []
    for path in sorted(third_party_dirs):
        try:
            metadata = ParseDir(path, root)
        except LicenseError, e:
            errors.append((path, e.args[0]))
            continue

    for path, error in sorted(errors):
        print path + ": " + error

    return len(errors) == 0


def GenerateCredits():
    """Generate about:credits."""

    if len(sys.argv) not in (2, 3):
      print 'usage: licenses.py credits [output_file]'
      return False

    def EvaluateTemplate(template, env, escape=True):
        """Expand a template with variables like {{foo}} using a
        dictionary of expansions."""
        for key, val in env.items():
            if escape:
                val = cgi.escape(val)
            template = template.replace('{{%s}}' % key, val)
        return template

    root = os.path.join(os.path.dirname(__file__), '..')
    third_party_dirs = FindThirdPartyDirs(PRUNE_PATHS, root)
    templates_dir = os.path.join(os.path.dirname(__file__), 'resources')

    entry_template = open(os.path.join(templates_dir,
                                       'about_credits_entry.tmpl'), 'rb').read()
    entries = []
    for path in sorted(third_party_dirs):
        try:
            metadata = ParseDir(path, root)
        except LicenseError:
            # TODO(phajdan.jr): Convert to fatal error (http://crbug.com/39240).
            continue
        if metadata['License File'] == NOT_SHIPPED:
            continue
        env = {
            'name': metadata['Name'],
            'url': metadata['URL'],
            'license': open(metadata['License File'], 'rb').read(),
        }
        entries.append(EvaluateTemplate(entry_template, env))

    file_template = open(os.path.join(templates_dir,
                                      'about_credits.tmpl'), 'rb').read()
    template_contents = EvaluateTemplate(file_template,
                                          {'entries': '\n'.join(entries)},
                                          escape=False)

    if len(sys.argv) == 3:
      with open(sys.argv[2], 'w') as output_file:
        output_file.write(template_contents)
    elif len(sys.argv) == 2:
      print template_contents

    return True


def main():
    command = 'help'
    if len(sys.argv) > 1:
        command = sys.argv[1]

    if command == 'scan':
        if not ScanThirdPartyDirs():
            return 1
    elif command == 'credits':
        if not GenerateCredits():
            return 1
    else:
        print __doc__
        return 1


if __name__ == '__main__':
  sys.exit(main())
