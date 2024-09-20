#!/usr/bin/env python3
# Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""_macros package presubmit python script.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

PRESUBMIT_VERSION = '2.0.0'
USE_PYTHON3 = True


# Ensures that the pubspec of `package_name` has been altered.
#
# Returns a list of errors if not.
#
# TODO(jakemac): Ensure the version was bumped as well.
def EnsurePubspecAndChangelogAltered(input_api, package_name):
    errors = []
    package_path = 'pkg/%s' % package_name
    pubspec_path = '%s/pubspec.yaml' % package_path
    pubspec_changed = any(file.LocalPath() == pubspec_path
                          for file in input_api.change.AffectedFiles())
    if not pubspec_changed:
        errors.append(
            ('The pkg/_macros/lib dir was altered but the version of %s was '
             'not bumped. See pkg/_macros/CONTRIBUTING.md' % package_path))

    changelog_path = '%s/CHANGELOG.md' % package_path
    changelog_changed = any(file.LocalPath() == changelog_path
                            for file in input_api.change.AffectedFiles())
    if not changelog_changed:
        errors.append(
            ('The pkg/_macros/lib dir was altered but the CHANGELOG.md of %s '
             'was not edited. See pkg/_macros/CONTRIBUTING.md' % package_path))
    return errors

# Invoked on upload and commit.
def CheckChange(input_api, output_api):
    errors = []

    # If the `lib` dir is altered, we also require a change to the pubspec.yaml
    # of both this package and the `macros` package.
    lib_changed = any(file.LocalPath().startswith('pkg/_macros/lib')
                      for file in input_api.AffectedFiles())
    if lib_changed:
        errors += EnsurePubspecAndChangelogAltered(input_api, '_macros')
        errors += EnsurePubspecAndChangelogAltered(input_api, 'macros')

    if errors:
        return [
            output_api.PresubmitError(
                'pkg/_macros presubmit/PRESUBMIT.py failure(s):',
                long_text='\n\n'.join(errors))
        ]

    return []
