// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/layout/adaptive.dart';
import 'package:gallery/studies/shrine/expanding_bottom_sheet.dart';
import 'package:gallery/studies/shrine/model/app_state_model.dart';
import 'package:gallery/studies/shrine/supplemental/asymmetric_view.dart';
import 'package:scoped_model/scoped_model.dart';

const _ordinalSortKeyName = 'home';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);

    return ScopedModelDescendant<AppStateModel>(
        builder: (context, child, model) {
      return isDesktop
          ? DesktopAsymmetricView(products: model.getProducts())
          : MobileAsymmetricView(products: model.getProducts());
    });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    this.expandingBottomSheet,
    this.scrim,
    this.backdrop,
    super.key,
  });

  final ExpandingBottomSheet? expandingBottomSheet;
  final Widget? scrim;
  final Widget? backdrop;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);

    // Use sort keys to make sure the cart button is always on the top.
    // This way, a11y users do not have to scroll through the entire list to
    // find the cart, and can easily get to the cart from anywhere on the page.
    return ApplyTextOptions(
      child: Stack(
        children: [
          Semantics(
            container: true,
            sortKey: const OrdinalSortKey(1, name: _ordinalSortKeyName),
            child: backdrop,
          ),
          ExcludeSemantics(child: scrim),
          Align(
            alignment: isDesktop
                ? AlignmentDirectional.topEnd
                : AlignmentDirectional.bottomEnd,
            child: Semantics(
              container: true,
              sortKey: const OrdinalSortKey(0, name: _ordinalSortKeyName),
              child: expandingBottomSheet,
            ),
          ),
        ],
      ),
    );
  }
}
