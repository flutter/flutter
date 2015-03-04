// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fn;

class Style {
  final String _className;
  static final Map<String, Style> _cache = new HashMap<String, Style>();

  static int nextStyleId = 1;

  static String nextClassName(String styles) {
    assert(sky.document != null);
    String className = "style$nextStyleId";
    nextStyleId++;

    sky.Element styleNode = sky.document.createElement('style');
    styleNode.setChild(new sky.Text(".$className { $styles }"));
    sky.document.appendChild(styleNode);

    return className;
  }

  factory Style(String styles) {
    return _cache.putIfAbsent(styles, () {
      return new Style._internal(nextClassName(styles));
    });
  }

  Style._internal(this._className);
}
