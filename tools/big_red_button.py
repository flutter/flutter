# Roll versions script:
# /src/mojo/src/sky/apk/demo/AndroidManifest.xml version and string.
# Update versions of pub packages:

# Make a commit, upload it, land it.

# Useful links:
# http://stackoverflow.com/questions/14665518/api-to-automatically-upload-apk-to-google-play
# https://developers.google.com/resources/api-libraries/documentation/androidpublisher/v2/python/latest/androidpublisher_v2.edits.apks.html

import argparse
import os
import subprocess
import sys

DEFAULT_MOJO_ROOT = '/src/mojo/src'
DEFAULT_SKY_SDK_ROOT = '/src/sky_sdk'
DEFAULT_DEMO_SITE_ROOT = '/src/domokit.github.io'

def run(cwd, args):
    print 'RUNNING:', ' '.join(args), 'IN:', cwd
    subprocess.check_call(args, cwd=cwd)


def main():
    parser = argparse.ArgumentParser(description='Deploy!')
    parser.add_argument('--mojo-root',
                        action='store',
                        type=str,
                        metavar='mojo_root',
                        help='Path to mojo/src',
                        default=DEFAULT_MOJO_ROOT)
    parser.add_argument('--sky-sdk-root',
                        action='store',
                        type=str,
                        metavar='sky_sdk_root',
                        help='Path to sky_sdk',
                        default=DEFAULT_SKY_SDK_ROOT)
    parser.add_argument('--demo-site-root',
                        action='store',
                        type=str,
                        metavar='demo_site_root',
                        help='Path to domokit.github.io',
                        default=DEFAULT_DEMO_SITE_ROOT)
    args = parser.parse_args()

    mojo_root = os.path.abspath(os.path.expanduser(args.mojo_root))
    sky_sdk_root = os.path.abspath(os.path.expanduser(args.sky_sdk_root))
    demo_site_root = os.path.abspath(os.path.expanduser(args.demo_site_root))

    # Derived paths:
    dart_sdk_root = os.path.join(mojo_root, 'third_party/dart-sdk/dart-sdk')
    pub_path = os.path.join(dart_sdk_root, 'bin/pub')
    packages_root = os.path.join(sky_sdk_root, 'packages')

    run(mojo_root, ['git', 'pull', '--rebase'])
    run(mojo_root, ['gclient', 'sync'])
    run(mojo_root, ['mojo/tools/mojob.py', 'gn', '--android', '--release'])
    run(mojo_root, ['mojo/tools/mojob.py', 'build', '--android', '--release'])
    # Run tests?

    run(sky_sdk_root, ['git', 'reset', '--hard', 'origin/master'])
    run(mojo_root, [
        'sky/tools/deploy_sdk.py',
        '--non-interactive',
        '--commit',
        sky_sdk_root
    ])
    # tag for version?

    run(demo_site_root, ['git', 'reset', '--hard', 'origin/master'])
    run(mojo_root, ['mojo/tools/deploy_domokit_site.py', demo_site_root])
    # tag for version?

    for package in os.listdir(packages_root):
        package_path = os.path.join(packages_root, package)
        if not os.path.isdir(package_path):
            continue
        run(package_path, [pub_path, 'publish', '--force'])

    run(sky_sdk_root, ['git', 'push'])
    run(demo_site_root, ['git', 'push'])


if __name__ == '__main__':
    sys.exit(main())