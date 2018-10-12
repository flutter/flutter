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

  @override
  void initState() {
    super.initState();
    _chatTextController = TextEditingController();
  }

  Widget _buildChatTextField() {
    return CupertinoTextField(
      controller: _chatTextController,
      textCapitalization: TextCapitalization.sentences,
      placeholder: 'Text Message',
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.0,
          color: CupertinoColors.inactiveGray,
        ),
        borderRadius: BorderRadius.circular(15.0),
      ),
      maxLines: null,
      keyboardType: TextInputType.multiline,
      leading: const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
      trailing: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: CupertinoButton(
          color: CupertinoColors.activeGreen,
          minSize: 0.0,
          child: const Icon(
            CupertinoIcons.up_arrow,
            size: 21.0,
            color: CupertinoColors.white,
          ),
          padding: const EdgeInsets.all(2.0),
          borderRadius: BorderRadius.circular(15.0),
          onPressed: ()=> setState(()=> _chatTextController.clear()),
        ),
      ),
      autofocus: true,
      trailingMode: OverlayVisibilityMode.editing,
      onSubmitted: (String text)=> setState(()=> _chatTextController.clear()),
    );
  }

  Widget _buildNameField() {
    return const CupertinoTextField(
      leading: Icon(
        CupertinoIcons.person_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28.0,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      clearButtonMode: OverlayVisibilityMode.editing,
      textCapitalization: TextCapitalization.words,
      autocorrect: false,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Name',
    );
  }

  Widget _buildEmailField() {
    return const CupertinoTextField(
      leading: Icon(
        CupertinoIcons.mail_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28.0,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      clearButtonMode: OverlayVisibilityMode.editing,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Email',
    );
  }

  Widget _buildLocationField() {
    return CupertinoTextField(
      controller: TextEditingController(text: 'Montreal, Canada'),
      leading: const Icon(
        CupertinoIcons.location_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      clearButtonMode: OverlayVisibilityMode.editing,
      textCapitalization: TextCapitalization.words,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Location',
    );
  }

  Widget _buildPinField() {
    return const CupertinoTextField(
      leading: Icon(
        CupertinoIcons.padlock_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28.0,
      ),
      padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      clearButtonMode: OverlayVisibilityMode.editing,
      autocorrect: false,
      obscureText: true,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.0, color: CupertinoColors.inactiveGray)),
      ),
      placeholder: 'Create a PIN',
    );
  }

  Widget _buildTagsField() {
    return CupertinoTextField(
      controller: TextEditingController(text: 'colleague, reading club'),
      leading: const Icon(
        CupertinoIcons.tags_solid,
        color: CupertinoColors.lightBackgroundGray,
        size: 28.0,
      ),
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.0, color: CupertinoColors.inactiveGray)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      // We don't want a new navigator but we want the CupertinoApp's defaults.
      builder: (BuildContext context, Widget navigator) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            previousPageTitle: 'Cupertino',
            middle: Text('Text Fields'),
          ),
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
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
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                child: _buildChatTextField(),
              ),
            ],
          ),
        );
      },
    );
  }
}