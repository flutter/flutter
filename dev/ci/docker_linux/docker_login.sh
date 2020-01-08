#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [[ -n "$CIRRUS_CI" && -n "$GCLOUD_CREDENTIALS" ]]; then
  echo "$GCLOUD_CREDENTIALS" | base64 --decode | docker login -u _json_key --password-stdin https://gcr.io
else
  gcloud auth print-access-token | sudo docker login -u oauth2accesstoken --password-stdin https://gcr.io
fi
