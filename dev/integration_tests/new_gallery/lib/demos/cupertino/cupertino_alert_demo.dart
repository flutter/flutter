// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/demos/cupertino/demo_types.dart';

// BEGIN cupertinoAlertDemo

class CupertinoAlertDemo extends StatefulWidget {
  const CupertinoAlertDemo({
    super.key,
    required this.type,
  });

  final AlertDemoType type;

  @override
  State<CupertinoAlertDemo> createState() => _CupertinoAlertDemoState();
}

class _CupertinoAlertDemoState extends State<CupertinoAlertDemo>
    with RestorationMixin {
  RestorableStringN lastSelectedValue = RestorableStringN(null);
  late RestorableRouteFuture<String> _alertDialogRoute;
  late RestorableRouteFuture<String> _alertWithTitleDialogRoute;
  late RestorableRouteFuture<String> _alertWithButtonsDialogRoute;
  late RestorableRouteFuture<String> _alertWithButtonsOnlyDialogRoute;
  late RestorableRouteFuture<String> _modalPopupRoute;

  @override
  String get restorationId => 'cupertino_alert_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(
      lastSelectedValue,
      'last_selected_value',
    );
    registerForRestoration(
      _alertDialogRoute,
      'alert_demo_dialog_route',
    );
    registerForRestoration(
      _alertWithTitleDialogRoute,
      'alert_with_title_press_demo_dialog_route',
    );
    registerForRestoration(
      _alertWithButtonsDialogRoute,
      'alert_with_title_press_demo_dialog_route',
    );
    registerForRestoration(
      _alertWithButtonsOnlyDialogRoute,
      'alert_with_title_press_demo_dialog_route',
    );
    registerForRestoration(
      _modalPopupRoute,
      'modal_popup_route',
    );
  }

  void _setSelectedValue(String value) {
    setState(() {
      lastSelectedValue.value = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _alertDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertDemoDialog);
      },
      onComplete: _setSelectedValue,
    );
    _alertWithTitleDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertWithTitleDialog);
      },
      onComplete: _setSelectedValue,
    );
    _alertWithButtonsDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertWithButtonsDialog);
      },
      onComplete: _setSelectedValue,
    );
    _alertWithButtonsOnlyDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertWithButtonsOnlyDialog);
      },
      onComplete: _setSelectedValue,
    );
    _modalPopupRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_modalRoute);
      },
      onComplete: _setSelectedValue,
    );
  }

  String _title(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    switch (widget.type) {
      case AlertDemoType.alert:
        return localizations.demoCupertinoAlertTitle;
      case AlertDemoType.alertTitle:
        return localizations.demoCupertinoAlertWithTitleTitle;
      case AlertDemoType.alertButtons:
        return localizations.demoCupertinoAlertButtonsTitle;
      case AlertDemoType.alertButtonsOnly:
        return localizations.demoCupertinoAlertButtonsOnlyTitle;
      case AlertDemoType.actionSheet:
        return localizations.demoCupertinoActionSheetTitle;
    }
  }

  static Route<String> _alertDemoDialog(
    BuildContext context,
    Object? arguments,
  ) {
    final localizations = GalleryLocalizations.of(context)!;
    return CupertinoDialogRoute<String>(
      context: context,
      builder: (context) => ApplyTextOptions(
        child: CupertinoAlertDialog(
          title: Text(localizations.dialogDiscardTitle),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(localizations.cupertinoAlertDiscard);
              },
              child: Text(
                localizations.cupertinoAlertDiscard,
              ),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(
                context,
              ).pop(
                localizations.cupertinoAlertCancel,
              ),
              child: Text(
                localizations.cupertinoAlertCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Route<String> _alertWithTitleDialog(
    BuildContext context,
    Object? arguments,
  ) {
    final localizations = GalleryLocalizations.of(context)!;
    return CupertinoDialogRoute<String>(
      context: context,
      builder: (context) => ApplyTextOptions(
        child: CupertinoAlertDialog(
          title: Text(
            localizations.cupertinoAlertLocationTitle,
          ),
          content: Text(
            localizations.cupertinoAlertLocationDescription,
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(
                context,
              ).pop(
                localizations.cupertinoAlertDontAllow,
              ),
              child: Text(
                localizations.cupertinoAlertDontAllow,
              ),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(
                context,
              ).pop(
                localizations.cupertinoAlertAllow,
              ),
              child: Text(
                localizations.cupertinoAlertAllow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Route<String> _alertWithButtonsDialog(
    BuildContext context,
    Object? arguments,
  ) {
    final localizations = GalleryLocalizations.of(context)!;
    return CupertinoDialogRoute<String>(
      context: context,
      builder: (context) => ApplyTextOptions(
        child: CupertinoDessertDialog(
          title: Text(
            localizations.cupertinoAlertFavoriteDessert,
          ),
          content: Text(
            localizations.cupertinoAlertDessertDescription,
          ),
        ),
      ),
    );
  }

  static Route<String> _alertWithButtonsOnlyDialog(
    BuildContext context,
    Object? arguments,
  ) {
    return CupertinoDialogRoute<String>(
      context: context,
      builder: (context) => const ApplyTextOptions(
        child: CupertinoDessertDialog(),
      ),
    );
  }

  static Route<String> _modalRoute(
    BuildContext context,
    Object? arguments,
  ) {
    final localizations = GalleryLocalizations.of(context)!;
    return CupertinoModalPopupRoute<String>(
      builder: (context) => ApplyTextOptions(
        child: CupertinoActionSheet(
          title: Text(
            localizations.cupertinoAlertFavoriteDessert,
          ),
          message: Text(
            localizations.cupertinoAlertDessertDescription,
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(
                context,
              ).pop(
                localizations.cupertinoAlertCheesecake,
              ),
              child: Text(
                localizations.cupertinoAlertCheesecake,
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(
                context,
              ).pop(
                localizations.cupertinoAlertTiramisu,
              ),
              child: Text(
                localizations.cupertinoAlertTiramisu,
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(
                context,
              ).pop(
                localizations.cupertinoAlertApplePie,
              ),
              child: Text(
                localizations.cupertinoAlertApplePie,
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(
              context,
            ).pop(
              localizations.cupertinoAlertCancel,
            ),
            child: Text(
              localizations.cupertinoAlertCancel,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: Text(_title(context)),
      ),
      child: Builder(
        builder: (context) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: CupertinoButton.filled(
                    onPressed: () {
                      switch (widget.type) {
                        case AlertDemoType.alert:
                          _alertDialogRoute.present();
                          break;
                        case AlertDemoType.alertTitle:
                          _alertWithTitleDialogRoute.present();
                          break;
                        case AlertDemoType.alertButtons:
                          _alertWithButtonsDialogRoute.present();
                          break;
                        case AlertDemoType.alertButtonsOnly:
                          _alertWithButtonsOnlyDialogRoute.present();
                          break;
                        case AlertDemoType.actionSheet:
                          _modalPopupRoute.present();
                          break;
                      }
                    },
                    child: Text(
                      GalleryLocalizations.of(context)!.cupertinoShowAlert,
                    ),
                  ),
                ),
              ),
              if (lastSelectedValue.value != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    GalleryLocalizations.of(context)!
                        .dialogSelectedOption(lastSelectedValue.value!),
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class CupertinoDessertDialog extends StatelessWidget {
  const CupertinoDessertDialog({
    super.key,
    this.title,
    this.content,
  });

  final Widget? title;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return CupertinoAlertDialog(
      title: title,
      content: content,
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(
              localizations.cupertinoAlertCheesecake,
            );
          },
          child: Text(
            localizations.cupertinoAlertCheesecake,
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(
              localizations.cupertinoAlertTiramisu,
            );
          },
          child: Text(
            localizations.cupertinoAlertTiramisu,
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(
              localizations.cupertinoAlertApplePie,
            );
          },
          child: Text(
            localizations.cupertinoAlertApplePie,
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(
              localizations.cupertinoAlertChocolateBrownie,
            );
          },
          child: Text(
            localizations.cupertinoAlertChocolateBrownie,
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(
              context,
            ).pop(
              localizations.cupertinoAlertCancel,
            );
          },
          child: Text(
            localizations.cupertinoAlertCancel,
          ),
        ),
      ],
    );
  }
}

// END
