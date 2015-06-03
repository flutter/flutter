// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../theme/shadows.dart';

class Material extends Component {
  // static final List<Style> _shadowStyle = [
  //   null,
  //   new Style('box-shadow: ${Shadow[1]}'),
  //   new Style('box-shadow: ${Shadow[2]}'),
  //   new Style('box-shadow: ${Shadow[3]}'),
  //   new Style('box-shadow: ${Shadow[4]}'),
  //   new Style('box-shadow: ${Shadow[5]}'),
  // ];

  UINode content;
  int level;

  Material({ Object key, this.content, this.level: 0 }) : super(key: key);

  UINode build() {
    // TODO(eseidel): Add a shadow.
    // return new StyleNode(content, _shadowStyle[level]);
    return content;
  }
}
