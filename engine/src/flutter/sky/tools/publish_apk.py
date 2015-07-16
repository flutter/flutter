#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Modeled on examples from:
# https://github.com/googlesamples/android-play-publisher-api/tree/master/v2/python

import argparse
import httplib2
import logging
import os
import sys

from apiclient.discovery import build
from oauth2client import client


SERVICE_ACCOUNT_EMAIL = (
    '69268379666-mu02g6delkg25t856t773fkdt9p90lpd@developer.gserviceaccount.com')
KEY_FILE_PATH = os.path.expanduser('~/sky_publish_key.p12')
API_AUTH_SCOPE = 'https://www.googleapis.com/auth/androidpublisher'
DEFAULT_TRACK = 'production'


def read_binary_file(path):
  with file(path, 'rb') as f:
    return f.read()


def read_text_file(path):
  with file(path, 'r') as f:
    return f.read()


def publish_apk(service, package_name, apk_path, changes_text, track):
    edit_request = service.edits().insert(body={}, packageName=package_name)
    result = edit_request.execute()
    edit_id = result['id']

    apk_response = service.edits().apks().upload(
        editId=edit_id,
        packageName=package_name,
        media_body=apk_path).execute()

    print 'Version code %d has been uploaded' % apk_response['versionCode']

    track_response = service.edits().tracks().update(
        editId=edit_id,
        track=track,
        packageName=package_name,
        body={u'versionCodes': [apk_response['versionCode']]}).execute()

    print 'Track %s is set for version code(s) %s' % (
        track_response['track'], str(track_response['versionCodes']))

    listing_response = service.edits().apklistings().update(
        editId=edit_id, packageName=package_name, language='en-US',
        apkVersionCode=apk_response['versionCode'],
        body={'recentChanges': changes_text}).execute()

    print ('Listing for language %s was updated.'
           % listing_response['language'])

    commit_request = service.edits().commit(
        editId=edit_id, packageName=package_name).execute()

    print 'Edit "%s" has been committed' % (commit_request['id'])


def connect_to_service(email, key_file, auth_scope):
  credentials = client.SignedJwtAssertionCredentials(
      email,
      read_binary_file(key_file),
      scope=auth_scope)
  http = httplib2.Http()
  http = credentials.authorize(http)

  return build('androidpublisher', 'v2', http=http)


def main(argv):
  logging.basicConfig()

  parser = argparse.ArgumentParser()
  parser.add_argument('package_name', help='Package (e.g. com.android.sample)')
  parser.add_argument('apk_path', help='Path to the APK file to upload.')
  parser.add_argument('changes_file',
      help='Path to file containing "What\'s new in this version?" text.')
  parser.add_argument('--track', default=DEFAULT_TRACK,
      choices=['alpha', 'beta', 'production', 'rollout'])
  args = parser.parse_args()

  changes_text = read_text_file(args.changes_file)

  service = connect_to_service(SERVICE_ACCOUNT_EMAIL, KEY_FILE_PATH,
    API_AUTH_SCOPE)

  try:
    publish_apk(service, args.package_name, args.apk_path, changes_text,
        args.track)
  except client.AccessTokenRefreshError:
    print ('The credentials have been revoked or expired, please re-run the '
           'application to re-authorize')


if __name__ == '__main__':
  main(sys.argv)
