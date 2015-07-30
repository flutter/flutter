// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

patch class _ProcessUtils {
  /* patch */ static int _pid(Process p) {
    if (p != null) {
      throw new UnimplementedError('Process objects not currently supported.');
    }
    return _getPid();
  }
}

int _getPid() native "Process_Pid";