// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library generate_vm_service_common;

import 'package:markdown/markdown.dart';
import 'package:pub_semver/pub_semver.dart';

import 'src_gen_common.dart';

/// [ApiParseUtil] contains top level parsing utilities.
class ApiParseUtil {
  /// Extract the current VM Service version number as a String.
  static String parseVersionString(List<Node> nodes) =>
      parseVersionSemVer(nodes).toString();

  static Version parseVersionSemVer(List<Node> nodes) {
    final RegExp regex = RegExp(r'[\d.]+');

    // Extract version from header: `# Dart VM Service Protocol 2.0`.
    Element node = nodes.firstWhere((n) => isH1(n)) as Element;
    Text text = node.children![0] as Text;
    Match? match = regex.firstMatch(text.text);
    if (match == null) throw 'Unable to locate service protocol version';

    // Append a `.0`.
    return Version.parse('${match.group(0)}.0');
  }
}
