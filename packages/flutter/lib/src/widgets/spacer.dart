// All components of the Spacer Widget are Copyright 2016 The Chromium Authors.
// All rights reserved. The Spacer Widget itself was created by Scott Stoll.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'container.dart';

/// Spacer:
/// A widget that creates an adjustable, empty
/// spacer that can be used to tune the alignment of
/// the UI. It was created to allow developers to 
/// accomplish this in ten characters, rather than
/// four lines of code.
/// 
/// It uses an empty Container, wrapped
/// with an Expanded. The Spacer takes an optional
/// parameter that is used as the flex value of the
/// Expanded. It defaults to 1.
///
/// Basic usage:
/// Spacer(); (Expanded's flex = 1)
/// Spacer(5); (Expanded's flex = 5)

class Spacer extends StatelessWidget {

  final int flexFactor;
  Spacer([int this.flexFactor = 1]);

  @override
  Widget build(BuildContext context) {
    return new Expanded(
      child: new Container(),
      flex: flexFactor,
    );
  }
}

