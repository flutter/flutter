// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

const String _kMarkdownData = """# Markdown Example
Markdown allows you to easily include formatted text, images, and even formatted Dart code in your app.

## Styling
Style text as _italic_, __bold__, or `inline code`.

- Use bulleted lists
- To better clarify
- Your points

## Links
You can use [hyperlinks](hyperlink) in markdown

## Code blocks
Formatted Dart code looks really pretty too. This is an example of how to create your own Markdown widget:

    new Markdown(data: 'Hello _world_!');

Enjoy!
""";

void main() {
  runApp(new MaterialApp(
    title: "Markdown Demo",
    home: new Scaffold(
      appBar: new AppBar(title: const Text('Markdown Demo')),
      body: const Markdown(data: _kMarkdownData)
    )
  ));
}
