// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [TextFormField].

void main() => runApp(const TextFormFieldExampleApp());

class TextFormFieldExampleApp extends StatelessWidget {
  const TextFormFieldExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TextFormFieldExample(),
    );
  }
}

class TextFormFieldExample extends StatefulWidget {
  const TextFormFieldExample({super.key});

  @override
  State<TextFormFieldExample> createState() => _TextFormFieldExampleState();
}

class _TextFormFieldExampleState extends State<TextFormFieldExample> {
  late final TextEditingController controller;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? forcedErrorText;
  bool isLoading = false;
  // username as a key, error text as value.
  final Map<String, String> cachedServerErrors = <String, String>{};

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  forceErrorText: forcedErrorText,
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Please write a username',
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    if (value.length != value.replaceAll(' ', '').length) {
                      return 'Username must not contains any spaces';
                    }
                    if (int.tryParse(value[0]) != null) {
                      return 'username must not start with a number';
                    }
                    if (value.length <= 2) {
                      return 'username should be at least 3 characters long';
                    }
                    return null;
                  },
                  onChanged: (String value) {
                    if (forcedErrorText != null && !cachedServerErrors.containsKey(value)) {
                      setState(() {
                        forcedErrorText = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 40),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  TextButton(
                    child: const Text('Save'),
                    onPressed: () async {
                      final String usernameToCheck = controller.text;
                      final bool isCheckedBefore = cachedServerErrors.containsKey(usernameToCheck);
                      if (isCheckedBefore) {
                        setState(() {
                          forcedErrorText = cachedServerErrors[usernameToCheck];
                        });
                        return;
                      }

                      final bool isValid = formKey.currentState?.validate() ?? true;
                      if (!isValid) {
                        return;
                      }

                      setState(() => isLoading = true);
                      final String? errorText = await validateUsernameFromServer(usernameToCheck);
                      setState(() => isLoading = false);

                      if (errorText != null) {
                        setState(() {
                          cachedServerErrors[usernameToCheck] = errorText;
                          forcedErrorText = errorText;
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> validateUsernameFromServer(String username) async {
  final Set<String> takenUsernames = <String>{'jack', 'alex'};

  // Simulate an http request.
  await Future<void>.delayed(const Duration(seconds: 3));

  final bool isValid = !takenUsernames.contains(username);
  if (isValid) {
    return null;
  }

  return 'Username $username is already taken';
}
