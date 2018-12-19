// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

class CupertinoTextFieldDemo extends StatefulWidget {
  static const String routeName = '/cupertino/text_fields';

  @override
  _CupertinoTextFieldDemoState createState() {
    return _CupertinoTextFieldDemoState();
  }
}

class _CupertinoTextFieldDemoState extends State<CupertinoTextFieldDemo> {
  TextEditingController _chatTextController;
  TextEditingController _locationTextController;

  @override
  void initState() {
    super.initState();
    _chatTextController = TextEditingController();
    _locationTextController = TextEditingController(text: 'Montreal, Canada');
  }

  Widget _buildChatTextField() {
    return CupertinoTextField(
      controller: _chatTextController,
      textCapitalization: TextCapitalization.sentences,
      placeholder: 'Text Message',
      decoration: BoxDecoration(
        border: Border.all(
          width: 0,
          color: CupertinoColors.inactiveGray,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      maxLines: null,
      keyboardType: TextInputType.multiline,
      prefix: const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      suffix: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: CupertinoButton(
          color: CupertinoColors.activeGreen,
          minSize: 0,
          child: const Icon(
            CupertinoIcons.up_arrow,
            size: 21,
            color: CupertinoColors.white,
          ),
          padding: const EdgeInsets.all(2),
          borderRadius: BorderRadius.circular(15),
          onPressed: ()=> setState(()=> _chatTextController.clear()),
        ),
      ),
      autofocus: true,
      suffixMode: OverlayVisibilityMode.editing,
      onSubmitted: (String text)=> setState(()=> _chatTextController.clear()),
    );
  }

  Widget _buildNameField() {
    return const CupertinoTextField(
      prefix: Icon(
        CupertinoIcons.person_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      clearButtonMode: OverlayVisibilityMode.editing,
      textCapitalization: TextCapitalization.words,
      autocorrect: false,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Name',
    );
  }

  Widget _buildEmailField() {
    return const CupertinoTextField(
      prefix: Icon(
        CupertinoIcons.mail_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      clearButtonMode: OverlayVisibilityMode.editing,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Email',
    );
  }

  Widget _buildLocationField() {
    return CupertinoTextField(
      controller: _locationTextController,
      prefix: const Icon(
        CupertinoIcons.location_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      clearButtonMode: OverlayVisibilityMode.editing,
      textCapitalization: TextCapitalization.words,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Location',
    );
  }

  Widget _buildPinField() {
    return const CupertinoTextField(
      prefix: Icon(
        CupertinoIcons.padlock_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      clearButtonMode: OverlayVisibilityMode.editing,
      keyboardType: TextInputType.number,
      autocorrect: false,
      obscureText: true,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Create a PIN',
    );
  }

  Widget _buildTagsField() {
    return CupertinoTextField(
      controller: TextEditingController(text: 'colleague, reading club'),
      prefix: const Icon(
        CupertinoIcons.tags_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28,
      ),
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 0, color: CupertinoColors.inactiveGray)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: '.SF UI Text',
        inherit: false,
        fontSize: 17,
        color: CupertinoColors.black,
      ),
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          // We're specifying a back label here because the previous page is a
          // Material page. CupertinoPageRoutes could auto-populate these back
          // labels.
          previousPageTitle: 'Cupertino',
          middle: Text('Text Fields'),
        ),
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: <Widget>[
                  _buildNameField(),
                  _buildEmailField(),
                  _buildLocationField(),
                  _buildPinField(),
                  _buildTagsField(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: _buildChatTextField(),
            ),
          ],
        ),
      ),
    );
  }
}
