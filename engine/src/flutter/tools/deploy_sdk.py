#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
from datetime import datetime
import logging
import os
import shutil
import subprocess
import sys

# Generates the sky_sdk from the template at sky/sdk.

# This script has a split personality of both making our deployment sdk
# as well as being a required part of developing locally, since all
# of our framework assumes it's working from the SDK.

SKY_TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
SKY_DIR = os.path.dirname(SKY_TOOLS_DIR)
SRC_ROOT = os.path.dirname(SKY_DIR)

DEFAULT_REL_BUILD_DIR = os.path.join('out', 'android_Release')

def git_revision():
    return subprocess.check_output(['git', 'rev-parse', 'HEAD']).strip()


def gen_filter(path):
    if os.path.isdir(path):
        return True
    _, ext = os.path.splitext(path)
    # Don't include all .dart, just .mojom.dart.
    return path.endswith('.mojom.dart')


def dart_filter(path):
    if os.path.isdir(path):
        return True
    _, ext = os.path.splitext(path)
    # .dart includes '.mojom.dart'
    return ext == '.dart'


def ensure_dir_exists(path):
    if not os.path.exists(path):
        os.makedirs(path)


def copy(from_root, to_root, filter_func=None):
    assert os.path.exists(from_root), "%s does not exist!" % from_root
    if os.path.isfile(from_root):
        ensure_dir_exists(os.path.dirname(to_root))
        shutil.copy(from_root, to_root)
        return

    ensure_dir_exists(to_root)

    for root, dirs, files in os.walk(from_root):
        # filter_func expects paths not names, so wrap it to make them absolute.
        wrapped_filter = None
        if filter_func:
            wrapped_filter = lambda name: filter_func(os.path.join(root, name))

        for name in filter(wrapped_filter, files):
            from_path = os.path.join(root, name)
            root_rel_path = os.path.relpath(from_path, from_root)
            to_path = os.path.join(to_root, root_rel_path)
            to_dir = os.path.dirname(to_path)
            if not os.path.exists(to_dir):
                os.makedirs(to_dir)
            shutil.copy(from_path, to_path)

        dirs[:] = filter(wrapped_filter, dirs)


def link(from_root, to_root, filter_func=None):
    ensure_dir_exists(os.path.dirname(to_root))
    os.symlink(from_root, to_root)


def make_relative_symlink(source, link_name):
    rel_source = os.path.relpath(source, os.path.dirname(link_name))
    os.symlink(rel_source, link_name)


def confirm(prompt):
    response = raw_input('%s [N]|y: ' % prompt)
    return response and response.lower() == 'y'


def delete_all_non_hidden_files_in_directory(root, non_interactive=False):
    to_delete = [os.path.join(root, p)
        for p in os.listdir(root) if not p.startswith('.')]
    if not to_delete:
        return
    if not non_interactive:
        prompt = 'This will delete everything in %s:\n%s\nAre you sure?' % (
            root, '\n'.join(to_delete))
        if not confirm(prompt):
            print 'User aborted.'
            sys.exit(2)

    for path in to_delete:
        if os.path.isdir(path) and not os.path.islink(path):
            shutil.rmtree(path)
        else:
            os.remove(path)


def main():
    logging.basicConfig(level=logging.WARN)
    parser = argparse.ArgumentParser(description='Deploy a new sky_sdk.')
    parser.add_argument('sdk_root', type=str)
    parser.add_argument('--build-dir', action='store', type=str,
        default=os.path.join(SRC_ROOT, DEFAULT_REL_BUILD_DIR))
    parser.add_argument('--extra-mojom-dir', action='append',
                        type=str,
                        dest='extra_mojom_dirs',
                        metavar='EXTRA_MOJOM_DIR',
                        help='Extra root directory for mojom packages. '
                             'Can be specified multiple times.',
                        default=[])
    parser.add_argument('--non-interactive', action='store_true')
    parser.add_argument('--dev-environment', action='store_true')
    parser.add_argument('--commit', action='store_true')
    parser.add_argument('--fake-pub-get-into', action='store', type=str)
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)
    sdk_root = os.path.abspath(args.sdk_root)

    print 'Building SDK from %s into %s' % (build_dir, sdk_root)
    start_time = datetime.now()

    # These are separate ideas but don't need a separate flag yet.
    use_links = args.dev_environment
    skip_apks = args.dev_environment
    should_commit = args.commit
    generate_licenses = not args.dev_environment

    # We save a bunch of time in --dev-environment mode by symlinking whole
    # directories when possible.  Any names which conflict with generated
    # directories can't be symlinked and must be copied.
    copy_or_link = link if use_links else copy

    def sdk_path(rel_path):
        return os.path.join(sdk_root, rel_path)

    def src_path(rel_path):
        return os.path.join(SRC_ROOT, rel_path)

    ensure_dir_exists(sdk_root)
    delete_all_non_hidden_files_in_directory(sdk_root, args.non_interactive)

    # Manually clear sdk_root above to avoid deleting dot-files.
    copy(src_path('sky/sdk'), sdk_root)

    copy_or_link(src_path('sky/examples'), sdk_path('examples'))

    # Sky package
    copy_or_link(src_path('sky/framework'), sdk_path('packages/sky/lib/framework'))
    copy_or_link(src_path('sky/assets'), sdk_path('packages/sky/lib/assets'))

    # Sky SDK additions:
    copy_or_link(src_path('sky/engine/bindings/builtin.dart'),
        sdk_path('packages/sky/sdk_additions/dart_sky_builtins.dart'))
    bindings_path = os.path.join(build_dir, 'gen/sky/bindings')
    # dart_sky.dart has many supporting files:
    copy(bindings_path, sdk_path('packages/sky/sdk_additions'),
        dart_filter)

    # Mojo package, lots of overlap with gen, must be copied:
    copy(src_path('mojo/public'), sdk_path('packages/mojo/lib/public'),
        dart_filter)

    # By convention the generated .mojom.dart files in a pub package
    # go under $PACKAGE/lib/mojom.
    # The mojo package owns all the .mojom.dart files that are not in the 'sky'
    # mojom module.
    def non_sky_gen_filter(path):
        if os.path.isdir(path) and path.endswith('sky'):
            return False
        return gen_filter(path)
    mojo_package_mojom_dir = sdk_path('packages/mojo/lib/mojom')
    copy(os.path.join(build_dir, 'gen/dart-gen/mojom'), mojo_package_mojom_dir,
         non_sky_gen_filter)

    # The Sky package owns the .mojom.dart files in the 'sky' mojom module.
    def sky_gen_filter(path):
        if os.path.isfile(path) and not os.path.dirname(path).endswith('sky'):
            return False
        return gen_filter(path)
    sky_package_mojom_dir = sdk_path('packages/sky/lib/mojom')
    copy(os.path.join(build_dir, 'gen/dart-gen/mojom'), sky_package_mojom_dir,
         sky_gen_filter)

    # Mojo SDK additions:
    copy_or_link(src_path('mojo/public/dart/bindings.dart'),
        sdk_path('packages/mojo/sdk_additions/dart_mojo_bindings.dart'))
    copy_or_link(src_path('mojo/public/dart/core.dart'),
        sdk_path('packages/mojo/sdk_additions/dart_mojo_core.dart'))

    if not skip_apks:
        ensure_dir_exists(sdk_path('packages/sky/apks'))
        shutil.copy(os.path.join(build_dir, 'apks', 'SkyDemo.apk'),
            sdk_path('packages/sky/apks'))

    if generate_licenses:
        with open(sdk_path('LICENSES.sky'), 'w') as license_file:
            subprocess.check_call([src_path('tools/licenses.py'), 'credits'],
                stdout=license_file)

        copy_or_link(src_path('AUTHORS'), sdk_path('packages/mojo/AUTHORS'))
        copy_or_link(src_path('LICENSE'), sdk_path('packages/mojo/LICENSE'))
        copy_or_link(src_path('AUTHORS'), sdk_path('packages/sky/AUTHORS'))
        copy_or_link(src_path('LICENSE'), sdk_path('packages/sky/LICENSE'))

    if args.fake_pub_get_into:
        packages_dir = os.path.abspath(args.fake_pub_get_into)
        ensure_dir_exists(packages_dir)
        make_relative_symlink(sdk_path('packages/mojo/lib'),
            os.path.join(packages_dir, 'mojo'))
        make_relative_symlink(sdk_path('packages/sky/lib'),
            os.path.join(packages_dir, 'sky'))

        mojom_dirs = [ mojo_package_mojom_dir, sky_package_mojom_dir ]
        mojom_dirs += args.extra_mojom_dirs
        for mojom_dir in mojom_dirs:
          copy(mojom_dir, os.path.join(packages_dir, 'mojom'), gen_filter)

    if should_commit:
        # Kinda a hack to make a prettier build dir for the commit:
        script_path = os.path.relpath(os.path.abspath(__file__), SRC_ROOT)
        rel_build_dir = os.path.relpath(build_dir, SRC_ROOT)
        revision = git_revision()
        commit_url = "https://github.com/domokit/mojo/commit/%s" % revision
        pattern = """Autogenerated from %s
Using %s and build output from %s.
"""
        commit_message = pattern % (commit_url, script_path, rel_build_dir)
        subprocess.check_call(['git', 'add', '.'], cwd=sdk_root)
        subprocess.check_call([
            'git', 'commit',
            '-m', commit_message
            ], cwd=sdk_root)

    time_delta = datetime.now() - start_time
    print 'SDK built at %s in %ss' % (sdk_root, time_delta.total_seconds())


if __name__ == '__main__':
    main()
