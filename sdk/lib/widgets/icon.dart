// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../mojo/asset_bundle.dart';
import 'basic.dart';

const String _kAssetBase = '/packages/sky/assets/material-design-icons/';
final AssetBundle _iconBundle = new NetworkAssetBundle(Uri.base.resolve(_kAssetBase));

class Icon extends Component {
  Icon({ String key, this.size, this.type: '' }) : super(key: key);

  final int size;
  final String type;

  Widget build() {
    String category = '';
    String subtype = '';
    List<String> parts = type.split('/');
    if (parts.length == 2) {
      category = parts[0];
      subtype = parts[1];
    }
    // TODO(eseidel): This clearly isn't correct.  Not sure what would be.
    // Should we use the ios images on ios?
    String density = 'drawable-xxhdpi';
    return new AssetImage(
      bundle: _iconBundle,
      name: '${category}/${density}/ic_${subtype}_${size}dp.png',
      size: new Size(size.toDouble(), size.toDouble())
    );
  }
}
