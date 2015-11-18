// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

enum Orientation { portrait, landscape }

class MediaQueryData {

  const MediaQueryData({ this.size });

  final Size size;

  Orientation get orientation {
    return size.width > size.height ? Orientation.landscape : Orientation.portrait;
  }

  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    MediaQueryData typedOther = other;
    return typedOther.size == size;
  }

  int get hashCode => size.hashCode;

  String toString() => '$runtimeType($size, $orientation)';
}

class MediaQuery extends InheritedWidget {
  MediaQuery({
    Key key,
    this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
    assert(data != null);
  }

  final MediaQueryData data;

  static MediaQueryData of(BuildContext context) {
    MediaQuery query = context.inheritFromWidgetOfType(MediaQuery);
    return query == null ? null : query.data;
  }

  bool updateShouldNotify(MediaQuery old) => data != old.data;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}
