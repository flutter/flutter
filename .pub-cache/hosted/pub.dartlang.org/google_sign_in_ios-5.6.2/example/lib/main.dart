// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs, avoid_print

import 'dart:async';
import 'dart:convert' show json;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(
      title: 'Google Sign In',
      home: SignInDemo(),
    ),
  );
}

class SignInDemo extends StatefulWidget {
  const SignInDemo({super.key});

  @override
  State createState() => SignInDemoState();
}

class SignInDemoState extends State<SignInDemo> {
  GoogleSignInUserData? _currentUser;
  String _contactText = '';
  // Future that completes when `initWithParams` has completed on the sign in
  // instance.
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _ensureInitialized() {
    return _initialization ??=
        GoogleSignInPlatform.instance.initWithParams(const SignInInitParameters(
      scopes: <String>[
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    ))
          ..catchError((dynamic _) {
            _initialization = null;
          });
  }

  void _setUser(GoogleSignInUserData? user) {
    setState(() {
      _currentUser = user;
      if (user != null) {
        _handleGetContact(user);
      }
    });
  }

  Future<void> _signIn() async {
    await _ensureInitialized();
    final GoogleSignInUserData? newUser =
        await GoogleSignInPlatform.instance.signInSilently();
    _setUser(newUser);
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final GoogleSignInUserData? user = _currentUser;
    if (user == null) {
      throw StateError('No user signed in');
    }

    final GoogleSignInTokenData response =
        await GoogleSignInPlatform.instance.getTokens(
      email: user.email,
      shouldRecoverAuth: true,
    );

    return <String, String>{
      'Authorization': 'Bearer ${response.accessToken}',
      // TODO(kevmoo): Use the correct value once it's available.
      // See https://github.com/flutter/flutter/issues/80905
      'X-Goog-AuthUser': '0',
    };
  }

  Future<void> _handleGetContact(GoogleSignInUserData user) async {
    setState(() {
      _contactText = 'Loading contact info...';
    });
    final http.Response response = await http.get(
      Uri.parse('https://people.googleapis.com/v1/people/me/connections'
          '?requestMask.includeField=person.names'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode != 200) {
      setState(() {
        _contactText = 'People API gave a ${response.statusCode} '
            'response. Check logs for details.';
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final int contactCount =
        (data['connections'] as List<dynamic>?)?.length ?? 0;
    setState(() {
      _contactText = '$contactCount contacts found';
    });
  }

  Future<void> _handleSignIn() async {
    try {
      await _ensureInitialized();
      _setUser(await GoogleSignInPlatform.instance.signIn());
    } catch (error) {
      final bool canceled =
          error is PlatformException && error.code == 'sign_in_canceled';
      if (!canceled) {
        print(error);
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _ensureInitialized();
    await GoogleSignInPlatform.instance.disconnect();
  }

  Widget _buildBody() {
    final GoogleSignInUserData? user = _currentUser;
    if (user != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            title: Text(user.displayName ?? ''),
            subtitle: Text(user.email),
          ),
          const Text('Signed in successfully.'),
          Text(_contactText),
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('SIGN OUT'),
          ),
          ElevatedButton(
            child: const Text('REFRESH'),
            onPressed: () => _handleGetContact(user),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text('You are not currently signed in.'),
          ElevatedButton(
            onPressed: _handleSignIn,
            child: const Text('SIGN IN'),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
