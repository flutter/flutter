// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../gallery_localizations.dart';
import 'backlayer.dart';
import 'header_form.dart';

class EatForm extends BackLayerItem {
  const EatForm({super.key}) : super(index: 2);

  @override
  State<EatForm> createState() => _EatFormState();
}

class _EatFormState extends State<EatForm> with RestorationMixin {
  final RestorableTextEditingController dinerController = RestorableTextEditingController();
  final RestorableTextEditingController dateController = RestorableTextEditingController();
  final RestorableTextEditingController timeController = RestorableTextEditingController();
  final RestorableTextEditingController locationController = RestorableTextEditingController();

  @override
  String get restorationId => 'eat_form';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(dinerController, 'diner_controller');
    registerForRestoration(dateController, 'date_controller');
    registerForRestoration(timeController, 'time_controller');
    registerForRestoration(locationController, 'location_controller');
  }

  @override
  void dispose() {
    dinerController.dispose();
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GalleryLocalizations localizations = GalleryLocalizations.of(context)!;
    return HeaderForm(
      fields: <HeaderFormField>[
        HeaderFormField(
          index: 0,
          iconData: Icons.person,
          title: localizations.craneFormDiners,
          textController: dinerController.value,
        ),
        HeaderFormField(
          index: 1,
          iconData: Icons.date_range,
          title: localizations.craneFormDate,
          textController: dateController.value,
        ),
        HeaderFormField(
          index: 2,
          iconData: Icons.access_time,
          title: localizations.craneFormTime,
          textController: timeController.value,
        ),
        HeaderFormField(
          index: 3,
          iconData: Icons.restaurant_menu,
          title: localizations.craneFormLocation,
          textController: locationController.value,
        ),
      ],
    );
  }
}
