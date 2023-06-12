import 'dart:core';

import 'package:flutter/material.dart';

import '../plugin_example/basic_content.dart';
import '../plugin_example/grid_content.dart';
import '../plugin_example/list_content.dart';
import 'info_page.dart';

/// The name of the plugin, which will be displayed throughout the example App.
const String pluginName = 'CachedNetworkImage';

/// Returns Github URL, which is shown in the [InfoPage].
const String githubURL =
    'https://github.com/Baseflow/flutter_cached_network_image';

/// Returns Baseflow URL, which is shown in the [InfoPage].
const String baseflowURL = 'https://baseflow.com';

/// Returns pub.dev URL, which is shown in the [InfoPage].
const String pubDevURL = 'https://pub.dev/packages/cached_network_image';

/// [EdgeInsets] to define horizontal padding throughout the application.
const EdgeInsets defaultHorizontalPadding =
    EdgeInsets.symmetric(horizontal: 24);

/// [EdgeInsets] to define vertical padding throughout the application.
const EdgeInsets defaultVerticalPadding = EdgeInsets.symmetric(vertical: 24);

/// Returns a [List] with [IconData] to show in the [AppHome] [AppBar].
final List<IconData> icons = [
  Icons.image,
  Icons.list,
  Icons.grid_on,
  Icons.info_outline,
];

/// Returns a [List] with [Widget]s to construct pages in the [AppBar].
final List<Widget> pages = [
  BasicContent(),
  ListContent(),
  GridContent(),
  InfoPage(),
];
