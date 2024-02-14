// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

// BEGIN snackbarsDemo

class SnackbarsDemo extends StatelessWidget {
  const SnackbarsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.demoSnackbarsTitle),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(localizations.demoSnackbarsText),
              action: SnackBarAction(
                label: localizations.demoSnackbarsActionButtonLabel,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                    localizations.demoSnackbarsAction,
                  )));
                },
              ),
            ));
          },
          child: Text(localizations.demoSnackbarsButtonLabel),
        ),
      ),
    );
  }
}

// END
