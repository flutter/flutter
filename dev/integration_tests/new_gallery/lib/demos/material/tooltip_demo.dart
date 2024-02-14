// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

// BEGIN tooltipDemo

class TooltipDemo extends StatelessWidget {
  const TooltipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.demoTooltipTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.demoTooltipInstructions,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Tooltip(
                message: localizations.starterAppTooltipSearch,
                child: IconButton(
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END
