// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

enum StockMode { optimistic, pessimistic }
enum BackupMode { enabled, disabled }

class StockConfiguration {
  StockConfiguration({
    this.stockMode,
    this.backupMode,
    this.showGrid
  }) {
    assert(stockMode != null);
    assert(backupMode != null);
    assert(showGrid != null);
  }

  final StockMode stockMode;
  final BackupMode backupMode;
  final bool showGrid;

  StockConfiguration copyWith({
    StockMode stockMode,
    BackupMode backupMode,
    bool showGrid
  }) {
    return new StockConfiguration(
      stockMode: stockMode ?? this.stockMode,
      backupMode: backupMode ?? this.backupMode,
      showGrid: showGrid ?? this.showGrid
    );
  }
}