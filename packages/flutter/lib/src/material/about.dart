// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' show Timeline, Flow;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' hide Flow;

import 'app_bar.dart';
import 'back_button.dart';
import 'card.dart';
import 'constants.dart';
import 'debug.dart';
import 'dialog.dart';
import 'divider.dart';
import 'floating_action_button.dart';
import 'floating_action_button_location.dart';
import 'ink_decoration.dart';
import 'list_tile.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'page.dart';
import 'page_transitions_theme.dart';
import 'progress_indicator.dart';
import 'scaffold.dart';
import 'scrollbar.dart';
import 'text_button.dart';
import 'text_theme.dart';
import 'theme.dart';

/// A [ListTile] that shows an about box.
///
/// This widget is often added to an app's [Drawer]. When tapped it shows
/// an about box dialog with [showAboutDialog].
///
/// The about box will include a button that shows licenses for software used by
/// the application. The licenses shown are those returned by the
/// [LicenseRegistry] API, which can be used to add more licenses to the list.
///
/// If your application does not have a [Drawer], you should provide an
/// affordance to call [showAboutDialog] or (at least) [showLicensePage].
///
/// {@tool dartpad --template=stateless_widget_material}
///
/// This sample shows two ways to open [AboutDialog]. The first one
/// uses an [AboutListTile], and the second uses the [showAboutDialog] function.
///
/// ```dart
///  Widget build(BuildContext context) {
///    final TextStyle textStyle = Theme.of(context).textTheme.bodyText2!;
///    final List<Widget> aboutBoxChildren = <Widget>[
///      SizedBox(height: 24),
///      RichText(
///        text: TextSpan(
///          children: <TextSpan>[
///            TextSpan(
///              style: textStyle,
///              text: "Flutter is Google's UI toolkit for building beautiful, "
///              'natively compiled applications for mobile, web, and desktop '
///              'from a single codebase. Learn more about Flutter at '
///            ),
///            TextSpan(
///              style: textStyle.copyWith(color: Theme.of(context).accentColor),
///              text: 'https://flutter.dev'
///            ),
///            TextSpan(
///              style: textStyle,
///              text: '.'
///            ),
///          ],
///        ),
///      ),
///    ];
///
///    return Scaffold(
///      appBar: AppBar(
///        title: Text('Show About Example'),
///      ),
///      drawer: Drawer(
///        child: SingleChildScrollView(
///          child: SafeArea(
///            child: AboutListTile(
///              icon: Icon(Icons.info),
///              applicationIcon: FlutterLogo(),
///              applicationName: 'Show About Example',
///              applicationVersion: 'August 2019',
///              applicationLegalese: '\u{a9} 2014 The Flutter Authors',
///              aboutBoxChildren: aboutBoxChildren,
///            ),
///          ),
///        ),
///      ),
///      body: Center(
///        child: ElevatedButton(
///          child: Text('Show About Example'),
///          onPressed: () {
///            showAboutDialog(
///              context: context,
///              applicationIcon: FlutterLogo(),
///              applicationName: 'Show About Example',
///              applicationVersion: 'August 2019',
///              applicationLegalese: '\u{a9} 2014 The Flutter Authors',
///              children: aboutBoxChildren,
///            );
///          },
///        ),
///      ),
///    );
/// }
/// ```
/// {@end-tool}
class AboutListTile extends StatelessWidget {
  /// Creates a list tile for showing an about box.
  ///
  /// The arguments are all optional. The application name, if omitted, will be
  /// derived from the nearest [Title] widget. The version, icon, and legalese
  /// values default to the empty string.
  const AboutListTile({
    Key? key,
    this.icon,
    this.child,
    this.applicationName,
    this.applicationVersion,
    this.applicationIcon,
    this.applicationLegalese,
    this.aboutBoxChildren,
    this.dense,
  }) : super(key: key);

  /// The icon to show for this drawer item.
  ///
  /// By default no icon is shown.
  ///
  /// This is not necessarily the same as the image shown in the dialog box
  /// itself; which is controlled by the [applicationIcon] property.
  final Widget? icon;

  /// The label to show on this drawer item.
  ///
  /// Defaults to a text widget that says "About Foo" where "Foo" is the
  /// application name specified by [applicationName].
  final Widget? child;

  /// The name of the application.
  ///
  /// This string is used in the default label for this drawer item (see
  /// [child]) and as the caption of the [AboutDialog] that is shown.
  ///
  /// Defaults to the value of [Title.title], if a [Title] widget can be found.
  /// Otherwise, defaults to [Platform.resolvedExecutable].
  final String? applicationName;

  /// The version of this build of the application.
  ///
  /// This string is shown under the application name in the [AboutDialog].
  ///
  /// Defaults to the empty string.
  final String? applicationVersion;

  /// The icon to show next to the application name in the [AboutDialog].
  ///
  /// By default no icon is shown.
  ///
  /// Typically this will be an [ImageIcon] widget. It should honor the
  /// [IconTheme]'s [IconThemeData.size].
  ///
  /// This is not necessarily the same as the icon shown on the drawer item
  /// itself, which is controlled by the [icon] property.
  final Widget? applicationIcon;

  /// A string to show in small print in the [AboutDialog].
  ///
  /// Typically this is a copyright notice.
  ///
  /// Defaults to the empty string.
  final String? applicationLegalese;

  /// Widgets to add to the [AboutDialog] after the name, version, and legalese.
  ///
  /// This could include a link to a Web site, some descriptive text, credits,
  /// or other information to show in the about box.
  ///
  /// Defaults to nothing.
  final List<Widget>? aboutBoxChildren;

  /// Whether this list tile is part of a vertically dense list.
  ///
  /// If this property is null, then its value is based on [ListTileTheme.dense].
  ///
  /// Dense list tiles default to a smaller height.
  final bool? dense;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    return ListTile(
      leading: icon,
      title: child ?? Text(MaterialLocalizations.of(context).aboutListTileTitle(
        applicationName ?? _defaultApplicationName(context),
      )),
      dense: dense,
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: applicationName,
          applicationVersion: applicationVersion,
          applicationIcon: applicationIcon,
          applicationLegalese: applicationLegalese,
          children: aboutBoxChildren,
        );
      },
    );
  }
}

/// Displays an [AboutDialog], which describes the application and provides a
/// button to show licenses for software used by the application.
///
/// The arguments correspond to the properties on [AboutDialog].
///
/// If the application has a [Drawer], consider using [AboutListTile] instead
/// of calling this directly.
///
/// If you do not need an about box in your application, you should at least
/// provide an affordance to call [showLicensePage].
///
/// The licenses shown on the [LicensePage] are those returned by the
/// [LicenseRegistry] API, which can be used to add more licenses to the list.
///
/// The [context], [useRootNavigator] and [routeSettings] arguments are passed to
/// [showDialog], the documentation for which discusses how it is used.
void showAboutDialog({
  required BuildContext context,
  String? applicationName,
  String? applicationVersion,
  Widget? applicationIcon,
  String? applicationLegalese,
  List<Widget>? children,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  assert(context != null);
  assert(useRootNavigator != null);
  showDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext context) {
      return AboutDialog(
        applicationName: applicationName,
        applicationVersion: applicationVersion,
        applicationIcon: applicationIcon,
        applicationLegalese: applicationLegalese,
        children: children,
      );
    },
    routeSettings: routeSettings,
  );
}

/// Displays a [LicensePage], which shows licenses for software used by the
/// application.
///
/// The application arguments correspond to the properties on [LicensePage].
///
/// The `context` argument is used to look up the [Navigator] for the page.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// page to the [Navigator] furthest from or nearest to the given `context`. It
/// is `false` by default.
///
/// If the application has a [Drawer], consider using [AboutListTile] instead
/// of calling this directly.
///
/// The [AboutDialog] shown by [showAboutDialog] includes a button that calls
/// [showLicensePage].
///
/// The licenses shown on the [LicensePage] are those returned by the
/// [LicenseRegistry] API, which can be used to add more licenses to the list.
void showLicensePage({
  required BuildContext context,
  String? applicationName,
  String? applicationVersion,
  Widget? applicationIcon,
  String? applicationLegalese,
  bool useRootNavigator = false,
}) {
  assert(context != null);
  assert(useRootNavigator != null);
  Navigator.of(context, rootNavigator: useRootNavigator).push(MaterialPageRoute<void>(
    builder: (BuildContext context) => LicensePage(
      applicationName: applicationName,
      applicationVersion: applicationVersion,
      applicationIcon: applicationIcon,
      applicationLegalese: applicationLegalese,
    ),
  ));
}

/// The amount of vertical space to separate chunks of text.
const double _textVerticalSeparation = 18.0;

/// An about box. This is a dialog box with the application's icon, name,
/// version number, and copyright, plus a button to show licenses for software
/// used by the application.
///
/// To show an [AboutDialog], use [showAboutDialog].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=YFCSODyFxbE}
///
/// If the application has a [Drawer], the [AboutListTile] widget can make the
/// process of showing an about dialog simpler.
///
/// The [AboutDialog] shown by [showAboutDialog] includes a button that calls
/// [showLicensePage].
///
/// The licenses shown on the [LicensePage] are those returned by the
/// [LicenseRegistry] API, which can be used to add more licenses to the list.
class AboutDialog extends StatelessWidget {
  /// Creates an about box.
  ///
  /// The arguments are all optional. The application name, if omitted, will be
  /// derived from the nearest [Title] widget. The version, icon, and legalese
  /// values default to the empty string.
  const AboutDialog({
    Key? key,
    this.applicationName,
    this.applicationVersion,
    this.applicationIcon,
    this.applicationLegalese,
    this.children,
  }) : super(key: key);

  /// The name of the application.
  ///
  /// Defaults to the value of [Title.title], if a [Title] widget can be found.
  /// Otherwise, defaults to [Platform.resolvedExecutable].
  final String? applicationName;

  /// The version of this build of the application.
  ///
  /// This string is shown under the application name.
  ///
  /// Defaults to the empty string.
  final String? applicationVersion;

  /// The icon to show next to the application name.
  ///
  /// By default no icon is shown.
  ///
  /// Typically this will be an [ImageIcon] widget. It should honor the
  /// [IconTheme]'s [IconThemeData.size].
  final Widget? applicationIcon;

  /// A string to show in small print.
  ///
  /// Typically this is a copyright notice.
  ///
  /// Defaults to the empty string.
  final String? applicationLegalese;

  /// Widgets to add to the dialog box after the name, version, and legalese.
  ///
  /// This could include a link to a Web site, some descriptive text, credits,
  /// or other information to show in the about box.
  ///
  /// Defaults to nothing.
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final String name = applicationName ?? _defaultApplicationName(context);
    final String version = applicationVersion ?? _defaultApplicationVersion(context);
    final Widget? icon = applicationIcon ?? _defaultApplicationIcon(context);
    return AlertDialog(
      content: ListBody(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (icon != null) IconTheme(data: Theme.of(context).iconTheme, child: icon),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ListBody(
                    children: <Widget>[
                      Text(name, style: Theme.of(context).textTheme.headline5),
                      Text(version, style: Theme.of(context).textTheme.bodyText2),
                      const SizedBox(height: _textVerticalSeparation),
                      Text(applicationLegalese ?? '', style: Theme.of(context).textTheme.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ...?children,
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text(MaterialLocalizations.of(context).viewLicensesButtonLabel),
          onPressed: () {
            showLicensePage(
              context: context,
              applicationName: applicationName,
              applicationVersion: applicationVersion,
              applicationIcon: applicationIcon,
              applicationLegalese: applicationLegalese,
            );
          },
        ),
        TextButton(
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
      scrollable: true,
    );
  }
}

/// A page that shows licenses for software used by the application.
///
/// To show a [LicensePage], use [showLicensePage].
///
/// The [AboutDialog] shown by [showAboutDialog] and [AboutListTile] includes
/// a button that calls [showLicensePage].
///
/// The licenses shown on the [LicensePage] are those returned by the
/// [LicenseRegistry] API, which can be used to add more licenses to the list.
class LicensePage extends StatefulWidget {
  /// Creates a page that shows licenses for software used by the application.
  ///
  /// The arguments are all optional. The application name, if omitted, will be
  /// derived from the nearest [Title] widget. The version and legalese values
  /// default to the empty string.
  ///
  /// The licenses shown on the [LicensePage] are those returned by the
  /// [LicenseRegistry] API, which can be used to add more licenses to the list.
  const LicensePage({
    Key? key,
    this.applicationName,
    this.applicationVersion,
    this.applicationIcon,
    this.applicationLegalese,
  }) : super(key: key);

  /// The name of the application.
  ///
  /// Defaults to the value of [Title.title], if a [Title] widget can be found.
  /// Otherwise, defaults to [Platform.resolvedExecutable].
  final String? applicationName;

  /// The version of this build of the application.
  ///
  /// This string is shown under the application name.
  ///
  /// Defaults to the empty string.
  final String? applicationVersion;

  /// The icon to show below the application name.
  ///
  /// By default no icon is shown.
  ///
  /// Typically this will be an [ImageIcon] widget. It should honor the
  /// [IconTheme]'s [IconThemeData.size].
  final Widget? applicationIcon;

  /// A string to show in small print.
  ///
  /// Typically this is a copyright notice.
  ///
  /// Defaults to the empty string.
  final String? applicationLegalese;

  @override
  _LicensePageState createState() => _LicensePageState();
}

class _LicensePageState extends State<LicensePage> {
  final ValueNotifier<int?> selectedId = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    return _MasterDetailFlow(
      detailPageFABlessGutterWidth: _getGutterSize(context),
      title: Text(MaterialLocalizations.of(context).licensesPageTitle),
      detailPageBuilder: _packageLicensePage,
      masterViewBuilder: _packagesView,
    );
  }

  Widget _packageLicensePage(BuildContext _, Object? args, ScrollController? scrollController) {
    assert(args is _DetailArguments);
    final _DetailArguments detailArguments = args! as _DetailArguments;
    return _PackageLicensePage(
      packageName: detailArguments.packageName,
      licenseEntries: detailArguments.licenseEntries,
      scrollController: scrollController,
    );
  }

  Widget _packagesView(final BuildContext _, final bool isLateral) {
    final Widget about = _AboutProgram(
        name: widget.applicationName ?? _defaultApplicationName(context),
        icon: widget.applicationIcon ?? _defaultApplicationIcon(context),
        version: widget.applicationVersion ?? _defaultApplicationVersion(context),
        legalese: widget.applicationLegalese,
      );
    return _PackagesView(
      about: about,
      isLateral: isLateral,
      selectedId: selectedId,
    );
  }
}

class _AboutProgram extends StatelessWidget {
  const _AboutProgram({
    Key? key,
    required this.name,
    required this.version,
    this.icon,
    this.legalese,
  })  : assert(name != null),
        assert(version != null),
        super(key: key);

  final String name;
  final String version;
  final Widget? icon;
  final String? legalese;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getGutterSize(context),
        vertical: 24.0,
      ),
      child: Column(
        children: <Widget>[
          Text(
            name,
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
          if (icon != null)
            IconTheme(data: Theme.of(context).iconTheme, child: icon!),
          Text(
            version,
            style: Theme.of(context).textTheme.bodyText2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _textVerticalSeparation),
          Text(
            legalese ?? '',
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _textVerticalSeparation),
          Text(
            'Powered by Flutter',
            style: Theme.of(context).textTheme.bodyText2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PackagesView extends StatefulWidget {
  const _PackagesView({
    Key? key,
    required this.about,
    required this.isLateral,
    required this.selectedId,
  })  : assert(about != null),
        assert(isLateral != null),
        super(key: key);

  final Widget about;
  final bool isLateral;
  final ValueNotifier<int?> selectedId;

  @override
  _PackagesViewState createState() => _PackagesViewState();
}

class _PackagesViewState extends State<_PackagesView> {
  final Future<_LicenseData> licenses = LicenseRegistry.licenses
      .fold<_LicenseData>(
        _LicenseData(),
        (_LicenseData prev, LicenseEntry license) => prev..addLicense(license),
      )
      .then((_LicenseData licenseData) => licenseData..sortPackages());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LicenseData>(
      future: licenses,
      builder: (BuildContext context, AsyncSnapshot<_LicenseData> snapshot) {
        return LayoutBuilder(
          key: ValueKey<ConnectionState>(snapshot.connectionState),
          builder: (BuildContext context, BoxConstraints constraints) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                _initDefaultDetailPage(snapshot.data!, context);
                return ValueListenableBuilder<int?>(
                  valueListenable: widget.selectedId,
                  builder: (BuildContext context, int? selectedId, Widget? _) {
                    return Center(
                      child: Material(
                        color: Theme.of(context).cardColor,
                        elevation: 4.0,
                        child: Container(
                          constraints: BoxConstraints.loose(const Size.fromWidth(600.0)),
                          child: _packagesList(context, selectedId, snapshot.data!, widget.isLateral),
                        ),
                      ),
                    );
                  },
                );
              default:
                return Material(
                    color: Theme.of(context).cardColor,
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      widget.about,
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                );
            }
          },
        );
      },
    );
  }

  void _initDefaultDetailPage(_LicenseData data, BuildContext context) {
    if (data.packages.isEmpty) {
      return;
    }
    final String packageName = data.packages[widget.selectedId.value ?? 0];
    final List<int> bindings = data.packageLicenseBindings[packageName]!;
    _MasterDetailFlow.of(context)!.setInitialDetailPage(
      _DetailArguments(
        packageName,
        bindings.map((int i) => data.licenses[i]).toList(growable: false),
      ),
    );
  }

  Widget _packagesList(
    final BuildContext context,
    final int? selectedId,
    final _LicenseData data,
    final bool drawSelection,
  ) {
    return ListView(
      children: <Widget>[
        widget.about,
        ...data.packages
            .asMap()
            .entries
            .map<Widget>((MapEntry<int, String> entry) {
          final String packageName = entry.value;
          final int index = entry.key;
          final List<int> bindings = data.packageLicenseBindings[packageName]!;
          return _PackageListTile(
            packageName: packageName,
            index: index,
            isSelected: drawSelection && entry.key == (selectedId ?? 0),
            numberLicenses: bindings.length,
            onTap: () {
              widget.selectedId.value = index;
              _MasterDetailFlow.of(context)!.openDetailPage(_DetailArguments(
                packageName,
                bindings.map((int i) => data.licenses[i]).toList(growable: false),
              ));
            },
          );
        }),
      ],
    );
  }
}

class _PackageListTile extends StatelessWidget {
  const _PackageListTile({
    Key? key,
    required this.packageName,
    this.index,
    required this.isSelected,
    required this.numberLicenses,
    this.onTap,
}) : super(key:key);

  final String packageName;
  final int? index;
  final bool isSelected;
  final int numberLicenses;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Ink(
      color: isSelected ? Theme.of(context).highlightColor : Theme.of(context).cardColor,
      child: ListTile(
        title: Text(packageName),
        subtitle: Text(MaterialLocalizations.of(context).licensesPackageDetailText(numberLicenses)),
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }
}

/// This is a collection of licenses and the packages to which they apply.
/// [packageLicenseBindings] records the m+:n+ relationship between the license
/// and packages as a map of package names to license indexes.
class _LicenseData {
  final List<LicenseEntry> licenses = <LicenseEntry>[];
  final Map<String, List<int>> packageLicenseBindings = <String, List<int>>{};
  final List<String> packages = <String>[];

  // Special treatment for the first package since it should be the package
  // for delivered application.
  String? firstPackage;

  void addLicense(LicenseEntry entry) {
    // Before the license can be added, we must first record the packages to
    // which it belongs.
    for (final String package in entry.packages) {
      _addPackage(package);
      // Bind this license to the package using the next index value. This
      // creates a contract that this license must be inserted at this same
      // index value.
      packageLicenseBindings[package]!.add(licenses.length);
    }
    licenses.add(entry); // Completion of the contract above.
  }

  /// Add a package and initialize package license binding. This is a no-op if
  /// the package has been seen before.
  void _addPackage(String package) {
    if (!packageLicenseBindings.containsKey(package)) {
      packageLicenseBindings[package] = <int>[];
      firstPackage ??= package;
      packages.add(package);
    }
  }

  /// Sort the packages using some comparison method, or by the default manner,
  /// which is to put the application package first, followed by every other
  /// package in case-insensitive alphabetical order.
  void sortPackages([int Function(String a, String b)? compare]) {
    packages.sort(compare ?? (String a, String b) {
      // Based on how LicenseRegistry currently behaves, the first package
      // returned is the end user application license. This should be
      // presented first in the list. So here we make sure that first package
      // remains at the front regardless of alphabetical sorting.
      if (a == firstPackage) {
        return -1;
      }
      if (b == firstPackage) {
        return 1;
      }
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  }
}

@immutable
class _DetailArguments {
  const _DetailArguments(this.packageName, this.licenseEntries);

  final String packageName;
  final List<LicenseEntry> licenseEntries;

  @override
  bool operator ==(final dynamic other) {
    if (other is _DetailArguments) {
      return other.packageName == packageName;
    }
    return other == this;
  }

  @override
  int get hashCode => packageName.hashCode; // Good enough.
}

class _PackageLicensePage extends StatefulWidget {
  const _PackageLicensePage({
    Key? key,
    required this.packageName,
    required this.licenseEntries,
    required this.scrollController,
  }) : super(key: key);

  final String packageName;
  final List<LicenseEntry> licenseEntries;
  final ScrollController? scrollController;

  @override
  _PackageLicensePageState createState() => _PackageLicensePageState();
}

class _PackageLicensePageState extends State<_PackageLicensePage> {
  @override
  void initState() {
    super.initState();
    _initLicenses();
  }

  final List<Widget> _licenses = <Widget>[];
  bool _loaded = false;

  Future<void> _initLicenses() async {
    int debugFlowId = -1;
    assert(() {
      final Flow flow = Flow.begin();
      Timeline.timeSync('_initLicenses()', () { }, flow: flow);
      debugFlowId = flow.id;
      return true;
    }());
    for (final LicenseEntry license in widget.licenseEntries) {
      if (!mounted) {
        return;
      }
      assert(() {
        Timeline.timeSync('_initLicenses()', () { }, flow: Flow.step(debugFlowId));
        return true;
      }());
      final List<LicenseParagraph> paragraphs =
        await SchedulerBinding.instance!.scheduleTask<List<LicenseParagraph>>(
          license.paragraphs.toList,
          Priority.animation,
          debugLabel: 'License',
        );
      if (!mounted) {
        return;
      }
      setState(() {
        _licenses.add(const Padding(
          padding: EdgeInsets.all(18.0),
          child: Divider(),
        ));
        for (final LicenseParagraph paragraph in paragraphs) {
          if (paragraph.indent == LicenseParagraph.centeredIndent) {
            _licenses.add(Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                paragraph.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ));
          } else {
            assert(paragraph.indent >= 0);
            _licenses.add(Padding(
              padding: EdgeInsetsDirectional.only(top: 8.0, start: 16.0 * paragraph.indent),
              child: Text(paragraph.text),
            ));
          }
        }
      });
    }
    setState(() {
      _loaded = true;
    });
    assert(() {
      Timeline.timeSync('Build scheduled', () { }, flow: Flow.end(debugFlowId));
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String title = widget.packageName;
    final String subtitle = localizations.licensesPackageDetailText(widget.licenseEntries.length);
    final double pad = _getGutterSize(context);
    final EdgeInsets padding = EdgeInsets.only(left: pad, right: pad, bottom: pad);
    final List<Widget> listWidgets = <Widget>[
      ..._licenses,
      if (!_loaded)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ];

    final Widget page;
    if (widget.scrollController == null) {
      page = Scaffold(
        appBar: AppBar(
          title: _PackageLicensePageTitle(
            title,
            subtitle,
            theme.appBarTheme.textTheme ?? theme.primaryTextTheme,
          ),
        ),
        body: Center(
          child: Material(
            color: theme.cardColor,
            elevation: 4.0,
            child: Container(
              constraints: BoxConstraints.loose(const Size.fromWidth(600.0)),
              child: Localizations.override(
                locale: const Locale('en', 'US'),
                context: context,
                child: Scrollbar(
                  child: ListView(padding: padding, children: listWidgets),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      page = CustomScrollView(
        controller: widget.scrollController,
        slivers: <Widget>[
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: theme.cardColor,
            title: _PackageLicensePageTitle(title, subtitle, theme.textTheme),
          ),
          SliverPadding(
            padding: padding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Localizations.override(
                  locale: const Locale('en', 'US'),
                  context: context,
                  child: listWidgets[index],
                ),
                childCount: listWidgets.length,
              ),
            ),
          ),
        ],
      );
    }
    return DefaultTextStyle(
      style: theme.textTheme.caption!,
      child: page,
    );
  }
}

class _PackageLicensePageTitle extends StatelessWidget {
  const _PackageLicensePageTitle(
    this.title,
    this.subtitle,
    this.theme, {
    Key? key,
  }) : super(key: key);

  final String title;
  final String subtitle;
  final TextTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.headline6),
        Text(subtitle, style: theme.subtitle2),
      ],
    );
  }
}

String _defaultApplicationName(BuildContext context) {
  // This doesn't handle the case of the application's title dynamically
  // changing. In theory, we should make Title expose the current application
  // title using an InheritedWidget, and so forth. However, in practice, if
  // someone really wants their application title to change dynamically, they
  // can provide an explicit applicationName to the widgets defined in this
  // file, instead of relying on the default.
  final Title? ancestorTitle = context.findAncestorWidgetOfExactType<Title>();
  return ancestorTitle?.title ?? Platform.resolvedExecutable.split(Platform.pathSeparator).last;
}

String _defaultApplicationVersion(BuildContext context) {
  // TODO(ianh): Get this from the embedder somehow.
  return '';
}

Widget? _defaultApplicationIcon(BuildContext context) {
  // TODO(ianh): Get this from the embedder somehow.
  return null;
}

const int _materialGutterThreshold = 720;
const double _wideGutterSize = 24.0;
const double _narrowGutterSize = 12.0;

double _getGutterSize(BuildContext context) =>
    MediaQuery.of(context).size.width >= _materialGutterThreshold ? _wideGutterSize : _narrowGutterSize;

/// Signature for the builder callback used by [_MasterDetailFlow].
typedef _MasterViewBuilder = Widget Function(BuildContext context, bool isLateralUI);

/// Signature for the builder callback used by [_MasterDetailFlow.detailPageBuilder].
///
/// scrollController is provided when the page destination is the draggable
/// sheet in the lateral UI. Otherwise, it is null.
typedef _DetailPageBuilder = Widget Function(BuildContext context, Object? arguments, ScrollController? scrollController);

/// Signature for the builder callback used by [_MasterDetailFlow.actionBuilder].
///
/// Builds the actions that go in the app bars constructed for the master and
/// lateral UI pages. actionLevel indicates the intended destination of the
/// return actions.
typedef _ActionBuilder = List<Widget> Function(BuildContext context, _ActionLevel actionLevel);

/// Describes which type of app bar the actions are intended for.
enum _ActionLevel {
  /// Indicates the top app bar in the lateral UI.
  top,

  /// Indicates the master view app bar in the lateral UI.
  view,

  /// Indicates the master page app bar in the nested UI.
  composite,
}

/// Describes which layout will be used by [_MasterDetailFlow].
enum _LayoutMode {
  /// Use a nested or lateral layout depending on available screen width.
  auto,

  /// Always use a lateral layout.
  lateral,

  /// Always use a nested layout.
  nested,
}

const String _navMaster = 'master';
const String _navDetail = 'detail';
enum _Focus { master, detail }

/// A Master Detail Flow widget. Depending on screen width it builds either a
/// lateral or nested navigation flow between a master view and a detail page.
/// bloc pattern.
///
/// If focus is on detail view, then switching to nested navigation will
/// populate the navigation history with the master page and the detail page on
/// top. Otherwise the focus is on the master view and just the master page
/// is shown.
class _MasterDetailFlow extends StatefulWidget {
  /// Creates a master detail navigation flow which is either nested or
  /// lateral depending on screen width.
  const _MasterDetailFlow({
    Key? key,
    required this.detailPageBuilder,
    required this.masterViewBuilder,
    this.actionBuilder,
    this.automaticallyImplyLeading = true,
    this.breakpoint,
    this.centerTitle,
    this.detailPageFABGutterWidth,
    this.detailPageFABlessGutterWidth,
    this.displayMode = _LayoutMode.auto,
    this.flexibleSpace,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonMasterPageLocation,
    this.leading,
    this.masterPageBuilder,
    this.masterViewWidth,
    this.title,
  })  : assert(masterViewBuilder != null),
        assert(automaticallyImplyLeading != null),
        assert(detailPageBuilder != null),
        assert(displayMode != null),
        super(key: key);

  /// Builder for the master view for lateral navigation.
  ///
  /// If [masterPageBuilder] is not supplied the master page required for nested navigation, also
  /// builds the master view inside a [Scaffold] with an [AppBar].
  final _MasterViewBuilder masterViewBuilder;

  /// Builder for the master page for nested navigation.
  ///
  /// This builder is usually a wrapper around the [masterViewBuilder] builder to provide the
  /// extra UI required to make a page. However, this builder is optional, and the master page
  /// can be built using the master view builder and the configuration for the lateral UI's app bar.
  final _MasterViewBuilder? masterPageBuilder;

  /// Builder for the detail page.
  ///
  /// If scrollController == null, the page is intended for nested navigation. The lateral detail
  /// page is inside a [DraggableScrollableSheet] and should have a scrollable element that uses
  /// the [ScrollController] provided. In fact, it is strongly recommended the entire lateral
  /// page is scrollable.
  final _DetailPageBuilder detailPageBuilder;

  /// Override the width of the master view in the lateral UI.
  final double? masterViewWidth;

  /// Override the width of the floating action button gutter in the lateral UI.
  final double? detailPageFABGutterWidth;

  /// Override the width of the gutter when there is no floating action button.
  final double? detailPageFABlessGutterWidth;

  /// Add a floating action button to the lateral UI. If no [masterPageBuilder] is supplied, this
  /// floating action button is also used on the nested master page.
  ///
  /// See [Scaffold.floatingActionButton].
  final FloatingActionButton? floatingActionButton;

  /// The title for the lateral UI [AppBar].
  ///
  /// See [AppBar.title].
  final Widget? title;

  /// A widget to display before the title for the lateral UI [AppBar].
  ///
  /// See [AppBar.leading].
  final Widget? leading;

  /// Override the framework from determining whether to show a leading widget or not.
  ///
  /// See [AppBar.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// Override the framework from determining whether to display the title in the center of the
  /// app bar or not.
  ///
  /// See [AppBar.centerTitle].
  final bool? centerTitle;

  /// See [AppBar.flexibleSpace].
  final Widget? flexibleSpace;

  /// Build actions for the lateral UI, and potentially the master page in the nested UI.
  ///
  /// If level is [_ActionLevel.top] then the actions are for
  /// the entire lateral UI page. If level is [_ActionLevel.view] the actions
  /// are for the master
  /// view toolbar. Finally, if the [AppBar] for the master page for the nested UI is being built
  /// by [_MasterDetailFlow], then [_ActionLevel.composite] indicates the
  /// actions are for the
  /// nested master page.
  final _ActionBuilder? actionBuilder;

  /// Determine where the floating action button will go.
  ///
  /// If null, [FloatingActionButtonLocation.endTop] is used.
  ///
  /// Also see [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Determine where the floating action button will go on the master page.
  ///
  /// See [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation? floatingActionButtonMasterPageLocation;

  /// Forces display mode and style.
  final _LayoutMode displayMode;

  /// Width at which layout changes from nested to lateral.
  final double? breakpoint;

  @override
  _MasterDetailFlowState createState() => _MasterDetailFlowState();

  /// The master detail flow proxy from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// _MasterDetailFlow.of(context).openDetailPage(arguments);
  /// ```
  static _MasterDetailFlowProxy? of(BuildContext context) {
    _PageOpener? pageOpener = context.findAncestorStateOfType<_MasterDetailScaffoldState>();
    pageOpener ??= context.findAncestorStateOfType<_MasterDetailFlowState>();
    assert(() {
      if (pageOpener == null) {
        throw FlutterError(
          'Master Detail operation requested with a context that does not include a Master Detail '
          'Flow.\nThe context used to open a detail page from the Master Detail Flow must be '
          'that of a widget that is a descendant of a Master Detail Flow widget.'
        );
      }
      return true;
    }());
    return pageOpener != null ? _MasterDetailFlowProxy._(pageOpener) : null;
  }
}

/// Interface for interacting with the [_MasterDetailFlow].
class _MasterDetailFlowProxy implements _PageOpener {
  _MasterDetailFlowProxy._(this._pageOpener);

  final _PageOpener _pageOpener;

  /// Open detail page with arguments.
  @override
  void openDetailPage(Object arguments) =>
      _pageOpener.openDetailPage(arguments);

  /// Set the initial page to be open for the lateral layout. This can be set at any time, but
  /// will have no effect after any calls to openDetailPage.
  @override
  void setInitialDetailPage(Object arguments) =>
      _pageOpener.setInitialDetailPage(arguments);
}

abstract class _PageOpener {
  void openDetailPage(Object arguments);

  void setInitialDetailPage(Object arguments);
}

const int _materialWideDisplayThreshold = 840;

class _MasterDetailFlowState extends State<_MasterDetailFlow> implements _PageOpener {
  /// Tracks whether focus is on the detail or master views. Determines behavior when switching
  /// from lateral to nested navigation.
  _Focus focus = _Focus.master;

  /// Cache of arguments passed when opening a detail page. Used when rebuilding.
  Object? _cachedDetailArguments;

  /// Record of the layout that was built.
  _LayoutMode? _builtLayout;

  /// Key to access navigator in the nested layout.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void openDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
    if (_builtLayout == _LayoutMode.nested) {
      _navigatorKey.currentState!.pushNamed(_navDetail, arguments: arguments);
    } else {
      focus = _Focus.detail;
    }
  }

  @override
  void setInitialDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayMode) {
      case _LayoutMode.nested:
        return _nestedUI(context);
      case _LayoutMode.lateral:
        return _lateralUI(context);
      case _LayoutMode.auto:
        return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double availableWidth = constraints.maxWidth;
              if (availableWidth >= (widget.breakpoint ?? _materialWideDisplayThreshold)) {
                return _lateralUI(context);
              } else {
                return _nestedUI(context);
              }
            });
    }
  }

  Widget _nestedUI(BuildContext context) {
    _builtLayout = _LayoutMode.nested;
    final MaterialPageRoute<void> masterPageRoute = _masterPageRoute(context);

    return WillPopScope(
      // Push pop check into nested navigator.
      onWillPop: () async => !(await _navigatorKey.currentState!.maybePop()),
      child: Navigator(
        key: _navigatorKey,
        initialRoute: 'initial',
        onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
          switch (focus) {
            case _Focus.master:
              return <Route<void>>[masterPageRoute];
            case _Focus.detail:
              return <Route<void>>[
                masterPageRoute,
                _detailPageRoute(_cachedDetailArguments)
              ];
          }
        },
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case _navMaster:
              // Matching state to navigation event.
              focus = _Focus.master;
              return masterPageRoute;
            case _navDetail:
              // Matching state to navigation event.
              focus = _Focus.detail;
              // Cache detail page settings.
              _cachedDetailArguments = settings.arguments;
              return _detailPageRoute(_cachedDetailArguments);
            default:
              throw Exception('Unknown route ${settings.name}');
          }
        },
      ),
    );
  }

  MaterialPageRoute<void> _masterPageRoute(BuildContext context) {
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext c) => BlockSemantics(
        child: widget.masterPageBuilder != null
            ? widget.masterPageBuilder!(c, false)
            : _MasterPage(
                leading: widget.leading ??
                    (widget.automaticallyImplyLeading && Navigator.of(context).canPop()
                        ? BackButton(onPressed: () => Navigator.of(context).pop())
                        : null),
                title: widget.title,
                centerTitle: widget.centerTitle,
                flexibleSpace: widget.flexibleSpace,
                automaticallyImplyLeading: widget.automaticallyImplyLeading,
                floatingActionButton: widget.floatingActionButton,
                floatingActionButtonLocation: widget.floatingActionButtonMasterPageLocation,
                masterViewBuilder: widget.masterViewBuilder,
                actionBuilder: widget.actionBuilder,
              ),
      ),
    );
  }

  MaterialPageRoute<void> _detailPageRoute(Object? arguments) {
    return MaterialPageRoute<dynamic>(builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          // No need for setState() as rebuild happens on navigation pop.
          focus = _Focus.master;
          Navigator.of(context).pop();
          return false;
        },
        child: BlockSemantics(child: widget.detailPageBuilder(context, arguments, null)),
      );
    });
  }

  Widget _lateralUI(BuildContext context) {
    _builtLayout = _LayoutMode.lateral;
    return _MasterDetailScaffold(
      actionBuilder: widget.actionBuilder ?? (_, __) => const<Widget>[],
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      centerTitle: widget.centerTitle,
      detailPageBuilder: (BuildContext context, Object? args, ScrollController? scrollController) =>
          widget.detailPageBuilder(context, args ?? _cachedDetailArguments, scrollController),
      floatingActionButton: widget.floatingActionButton,
      detailPageFABlessGutterWidth: widget.detailPageFABlessGutterWidth,
      detailPageFABGutterWidth: widget.detailPageFABGutterWidth,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      initialArguments: _cachedDetailArguments,
      leading: widget.leading,
      masterViewBuilder: (BuildContext context, bool isLateral) => widget.masterViewBuilder(context, isLateral),
      masterViewWidth: widget.masterViewWidth,
      title: widget.title,
    );
  }
}

class _MasterPage extends StatelessWidget {
  const _MasterPage({
    Key? key,
    this.leading,
    this.title,
    this.actionBuilder,
    this.centerTitle,
    this.flexibleSpace,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.masterViewBuilder,
    required this.automaticallyImplyLeading,
  }) : super(key: key);

  final _MasterViewBuilder? masterViewBuilder;
  final Widget? title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final Widget? flexibleSpace;
  final _ActionBuilder? actionBuilder;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: title,
          leading: leading,
          actions: actionBuilder == null
              ? const <Widget>[]
              : actionBuilder!(context, _ActionLevel.composite),
          centerTitle: centerTitle,
          flexibleSpace: flexibleSpace,
          automaticallyImplyLeading: automaticallyImplyLeading,
        ),
        body: masterViewBuilder!(context, false),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
  }

}

const double _kCardElevation = 4.0;
const double _kMasterViewWidth = 320.0;
const double _kDetailPageFABlessGutterWidth = 40.0;
const double _kDetailPageFABGutterWidth = 84.0;

class _MasterDetailScaffold extends StatefulWidget {
  const _MasterDetailScaffold({
    Key? key,
    required this.detailPageBuilder,
    required this.masterViewBuilder,
    this.actionBuilder,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.initialArguments,
    this.leading,
    this.title,
    required this.automaticallyImplyLeading,
    this.centerTitle,
    this.detailPageFABlessGutterWidth,
    this.detailPageFABGutterWidth,
    this.masterViewWidth,
  })  : assert(detailPageBuilder != null),
        assert(masterViewBuilder != null),
        super(key: key);

  final _MasterViewBuilder masterViewBuilder;

  /// Builder for the detail page.
  ///
  /// The detail page is inside a [DraggableScrollableSheet] and should have a scrollable element
  /// that uses the [ScrollController] provided. In fact, it is strongly recommended the entire
  /// lateral page is scrollable.
  final _DetailPageBuilder detailPageBuilder;
  final _ActionBuilder? actionBuilder;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Object? initialArguments;
  final Widget? leading;
  final Widget? title;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final double? detailPageFABlessGutterWidth;
  final double? detailPageFABGutterWidth;
  final double? masterViewWidth;

  @override
  _MasterDetailScaffoldState createState() => _MasterDetailScaffoldState();
}

class _MasterDetailScaffoldState extends State<_MasterDetailScaffold>
    implements _PageOpener {
  late FloatingActionButtonLocation floatingActionButtonLocation;
  late double detailPageFABGutterWidth;
  late double detailPageFABlessGutterWidth;
  late double masterViewWidth;

  final ValueNotifier<Object?> _detailArguments = ValueNotifier<Object?>(null);

  @override
  void initState() {
    super.initState();
    detailPageFABlessGutterWidth = widget.detailPageFABlessGutterWidth ?? _kDetailPageFABlessGutterWidth;
    detailPageFABGutterWidth = widget.detailPageFABGutterWidth ?? _kDetailPageFABGutterWidth;
    masterViewWidth = widget.masterViewWidth ?? _kMasterViewWidth;
    floatingActionButtonLocation = widget.floatingActionButtonLocation ?? FloatingActionButtonLocation.endTop;
  }

  @override
  void openDetailPage(Object arguments) {
    SchedulerBinding.instance!
        .addPostFrameCallback((_) => _detailArguments.value = arguments);
    _MasterDetailFlow.of(context)!.openDetailPage(arguments);
  }

  @override
  void setInitialDetailPage(Object arguments) {
    SchedulerBinding.instance!
        .addPostFrameCallback((_) => _detailArguments.value = arguments);
    _MasterDetailFlow.of(context)!.setInitialDetailPage(arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          floatingActionButtonLocation: floatingActionButtonLocation,
          appBar: AppBar(
            title: widget.title,
            actions: widget.actionBuilder!(context, _ActionLevel.top),
            leading: widget.leading,
            automaticallyImplyLeading: widget.automaticallyImplyLeading,
            centerTitle: widget.centerTitle,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: masterViewWidth),
                    child: IconTheme(
                      data: Theme.of(context).primaryIconTheme,
                      child: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsets.all(8),
                        child: OverflowBar(
                          spacing: 8,
                          overflowAlignment: OverflowBarAlignment.end,
                          children: widget.actionBuilder!(context, _ActionLevel.view),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          body: _masterPanel(context),
          floatingActionButton: widget.floatingActionButton,
        ),
        // Detail view stacked above main scaffold and master view.
        SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: masterViewWidth - _kCardElevation,
              end: widget.floatingActionButton == null
                  ? detailPageFABlessGutterWidth
                  : detailPageFABGutterWidth,
            ),
            child: ValueListenableBuilder<Object?>(
              valueListenable: _detailArguments,
              builder: (BuildContext context, Object? value, Widget? child) {
                return AnimatedSwitcher(
                  transitionBuilder:
                      (Widget child, Animation<double> animation) =>
                      const FadeUpwardsPageTransitionsBuilder()
                          .buildTransitions<void>(
                          null, null, animation, null, child),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    key: ValueKey<Object?>(value ?? widget.initialArguments),
                    constraints: const BoxConstraints.expand(),
                    child: _DetailView(
                      builder: widget.detailPageBuilder,
                      arguments: value ?? widget.initialArguments,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  ConstrainedBox _masterPanel(BuildContext context, {bool needsScaffold = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: masterViewWidth),
      child: needsScaffold
          ? Scaffold(
              appBar: AppBar(
                title: widget.title,
                actions: widget.actionBuilder!(context, _ActionLevel.top),
                leading: widget.leading,
                automaticallyImplyLeading: widget.automaticallyImplyLeading,
                centerTitle: widget.centerTitle,
              ),
              body: widget.masterViewBuilder(context, true),
            )
          : widget.masterViewBuilder(context, true),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    Key? key,
    required _DetailPageBuilder builder,
    Object? arguments,
  })  : assert(builder != null),
        _builder = builder,
        _arguments = arguments,
        super(key: key);

  final _DetailPageBuilder _builder;
  final Object? _arguments;

  @override
  Widget build(BuildContext context) {
    if (_arguments == null) {
      return Container();
    }
    final double screenHeight = MediaQuery.of(context).size.height;
    final double minHeight = (screenHeight - kToolbarHeight) / screenHeight;

    return DraggableScrollableSheet(
      initialChildSize: minHeight,
      minChildSize: minHeight,
      maxChildSize: 1,
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return MouseRegion(
          // TODO(TonicArtos): Remove MouseRegion workaround for pointer hover events passing through DraggableScrollableSheet once https://github.com/flutter/flutter/issues/59741 is resolved.
          child: Card(
            color: Theme.of(context).cardColor,
            elevation: _kCardElevation,
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.fromLTRB(
                _kCardElevation, 0.0, _kCardElevation, 0.0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(3.0), bottom: Radius.zero),
            ),
            child: _builder(
              context,
              _arguments,
              controller,
            ),
          ),
        );
      },
    );
  }
}
