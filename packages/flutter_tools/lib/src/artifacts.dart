// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

enum Artifact {
  FlutterCompiler
}

class _ArtifactStore {
  _ArtifactStore._();

  Future<File> getPath(Artifact artifact) async {
    // TODO(abarth): Download artifacts from cloud storage.
    return new File('');
  }
}

final _ArtifactStore artifactStore = new _ArtifactStore._();
