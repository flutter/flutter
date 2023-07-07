// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

import 'src/button_configuration_column.dart';

// The instance of the plugin is automatically created by Flutter before calling
// our main code, let's grab it directly from the Platform interface of the plugin.
final GoogleSignInPlugin _plugin =
    GoogleSignInPlatform.instance as GoogleSignInPlugin;

Future<void> main() async {
  await _plugin.initWithParams(const SignInInitParameters(
    clientId: 'your-client_id.apps.googleusercontent.com',
  ));
  runApp(
    const MaterialApp(
      title: 'Sign in with Google button Tester',
      home: ButtonConfiguratorDemo(),
    ),
  );
}

/// The home widget of this app.
class ButtonConfiguratorDemo extends StatefulWidget {
  /// A const constructor for the Widget.
  const ButtonConfiguratorDemo({super.key});

  @override
  State createState() => _ButtonConfiguratorState();
}

class _ButtonConfiguratorState extends State<ButtonConfiguratorDemo> {
  GoogleSignInUserData? _userData; // sign-in information?
  GSIButtonConfiguration? _buttonConfiguration; // button configuration

  @override
  void initState() {
    super.initState();
    _plugin.userDataEvents?.listen((GoogleSignInUserData? userData) {
      setState(() {
        _userData = userData;
      });
    });
  }

  void _handleSignOut() {
    _plugin.signOut();
    setState(() {
      // signOut does not broadcast through the userDataEvents, so we fake it.
      _userData = null;
    });
  }

  void _handleNewWebButtonConfiguration(GSIButtonConfiguration newConfig) {
    setState(() {
      _buttonConfiguration = newConfig;
    });
  }

  Widget _buildBody() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_userData == null)
                _plugin.renderButton(configuration: _buttonConfiguration),
              if (_userData != null) ...<Widget>[
                Text('Hello, ${_userData!.displayName}!'),
                ElevatedButton(
                  onPressed: _handleSignOut,
                  child: const Text('SIGN OUT'),
                ),
              ]
            ],
          ),
        ),
        renderWebButtonConfiguration(
          _buttonConfiguration,
          onChange: _userData == null ? _handleNewWebButtonConfiguration : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Sign in with Google button Tester'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
