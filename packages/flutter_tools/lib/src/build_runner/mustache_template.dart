// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mustache_template/mustache_template.dart';

import '../base/template.dart';

/// An indirection around mustache use to allow google3 to use a different dependency.
class MustacheTemplateRenderer extends TemplateRenderer {
  const MustacheTemplateRenderer();

  @override
  String renderString(String template, dynamic context, {bool htmlEscapeValues = false}) {
    return Template(template, htmlEscapeValues: htmlEscapeValues).renderString(context);
  }
}
