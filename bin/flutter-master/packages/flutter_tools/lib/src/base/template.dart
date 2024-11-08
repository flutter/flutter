// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An indirection around our mustache templating system to avoid a
/// dependency on mustache..
abstract class TemplateRenderer {
  const TemplateRenderer();

  String renderString(String template, dynamic context, {bool htmlEscapeValues = false});
}
