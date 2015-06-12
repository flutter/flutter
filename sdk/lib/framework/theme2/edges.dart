// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum MaterialEdge { canvas, card, circle }

const Map<MaterialEdge, double> edges = const {
  MaterialEdge.canvas: 0.0,
  MaterialEdge.card: 2.0,
  MaterialEdge.circle: null,
};
