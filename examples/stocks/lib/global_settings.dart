// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

enum OptimismMode { optimistic, pessimistic }
enum BackupMode { enabled, disabled }

class GlobalSettings {
  GlobalSettings({
    OptimismMode optimism: OptimismMode.optimistic,
    BackupMode backup: BackupMode.disabled,
    VoidCallback onChanged
  }) : _optimism = optimism,
       _backup = backup,
       _onChanged = onChanged;

  OptimismMode get optimism => _optimism;
  OptimismMode _optimism;
  void set optimism(OptimismMode value) {
    if (_optimism == value)
      return;
    _optimism = value;
    _onChanged();
  }

  BackupMode get backup => _backup;
  BackupMode _backup;
  void set backup(BackupMode value) {
    if (_backup == value)
      return;
    _backup = value;
    _onChanged();
  }

  VoidCallback _onChanged;
}
