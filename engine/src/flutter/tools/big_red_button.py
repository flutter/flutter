# Roll versions script:
# /src/mojo/src/sky/apk/demo/AndroidManifest.xml version and string.
# Update versions of pub packages:

# Make a commit, upload it, land it.

import os
import subprocess

def run(cwd, args):
    print 'RUNNING:', ' '.join(args), 'IN:', cwd
    subprocess.check_call(args, cwd=cwd)

# Input paths:
# FIXME: These could be args?
MOJO_ROOT = '/src/mojo/src'
SKY_SDK_ROOT = '/src/sky_sdk'
DEMO_SITE_ROOT = '/src/domokit.github.io'

# Derived paths:
DART_SDK_ROOT = os.path.join(MOJO_ROOT, 'third_party/dart-sdk/dart-sdk')
PUB_PATH = os.path.join(DART_SDK_ROOT, 'bin/pub')
PACKAGES_ROOT = os.path.join(SKY_SDK_ROOT, 'packages')


run(MOJO_ROOT, ['git', 'pull', '--rebase'])
run(MOJO_ROOT, ['gclient', 'sync'])
run(MOJO_ROOT, ['mojo/tools/mojob.py', 'gn', '--android', '--release'])
run(MOJO_ROOT, ['mojo/tools/mojob.py', 'build', '--android', '--release'])
# Run tests?

run(SKY_SDK_ROOT, ['git', 'reset', '--hard', 'origin/master'])
run(MOJO_ROOT, [
    'sky/tools/deploy_sdk.py',
    '--non-interactive',
    '--commit',
    SKY_SDK_ROOT
])
# tag for version?

run(DEMO_SITE_ROOT, ['git', 'reset', '--hard', 'origin/master'])
run(MOJO_ROOT, ['mojo/tools/deploy_domokit_site.py', DEMO_SITE_ROOT])
# tag for version?

for package in os.listdir(PACKAGES_ROOT):
    package_path = os.path.join(PACKAGES_ROOT, package)
    if not os.path.isdir(package_path):
        continue
    run(package_path, [PUB_PATH, 'publish', '--force'])

run(SKY_SDK_ROOT, ['git', 'push'])
run(DEMO_SITE_ROOT, ['git', 'push'])

# http://stackoverflow.com/questions/14665518/api-to-automatically-upload-apk-to-google-play
# https://developers.google.com/resources/api-libraries/documentation/androidpublisher/v2/python/latest/androidpublisher_v2.edits.apks.html