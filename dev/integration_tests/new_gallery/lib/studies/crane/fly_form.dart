// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/studies/crane/backlayer.dart';
import 'package:gallery/studies/crane/header_form.dart';

class FlyForm extends BackLayerItem {
  const FlyForm({super.key}) : super(index: 0);

  @override
  State<FlyForm> createState() => _FlyFormState();
}

class _FlyFormState extends State<FlyForm> with RestorationMixin {
  final travelerController = RestorableTextEditingController();
  final countryDestinationController = RestorableTextEditingController();
  final destinationController = RestorableTextEditingController();
  final dateController = RestorableTextEditingController();

  @override
  String get restorationId => 'fly_form';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(travelerController, 'diner_controller');
    registerForRestoration(countryDestinationController, 'date_controller');
    registerForRestoration(destinationController, 'time_controller');
    registerForRestoration(dateController, 'location_controller');
  }

  @override
  void dispose() {
    travelerController.dispose();
    countryDestinationController.dispose();
    destinationController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return HeaderForm(
      fields: <HeaderFormField>[
        HeaderFormField(
          index: 0,
          iconData: Icons.person,
          title: localizations.craneFormTravelers,
          textController: travelerController.value,
        ),
        HeaderFormField(
          index: 1,
          iconData: Icons.place,
          title: localizations.craneFormOrigin,
          textController: countryDestinationController.value,
        ),
        HeaderFormField(
          index: 2,
          iconData: Icons.airplanemode_active,
          title: localizations.craneFormDestination,
          textController: destinationController.value,
        ),
        HeaderFormField(
          index: 3,
          iconData: Icons.date_range,
          title: localizations.craneFormDates,
          textController: dateController.value,
        ),
      ],
    );
  }
}
