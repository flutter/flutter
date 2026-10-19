// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for [DropdownMenuFormField] demonstrating leading icon support and validation.

const List<String> roles = <String>['Admin', 'Editor', 'Viewer'];

void main() => runApp(const DropdownMenuFormFieldApp());

class DropdownMenuFormFieldApp extends StatelessWidget {
  const DropdownMenuFormFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('DropdownMenuFormField Sample')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: DropdownMenuFormFieldExample(),
          ),
        ),
      ),
    );
  }
}

class DropdownMenuFormFieldExample extends StatefulWidget {
  const DropdownMenuFormFieldExample({super.key});

  @override
  State<DropdownMenuFormFieldExample> createState() =>
      _DropdownMenuFormFieldExampleState();
}

typedef RoleEntry = DropdownMenuEntry<String>;

class _DropdownMenuFormFieldExampleState
    extends State<DropdownMenuFormFieldExample> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static final List<RoleEntry> _roleEntries = UnmodifiableListView<RoleEntry>(
    roles.map<RoleEntry>((String role) => RoleEntry(value: role, label: role)),
  );
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownMenuFormField<String>(
            leadingIcon: const Icon(Icons.person),
            label: const Text('User Role'),
            dropdownMenuEntries: _roleEntries,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please select a role';
              }
              return null;
            },
            onSelected: (String? role) {
              setState(() {
                _selectedRole = role;
              });
            },
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected role: $_selectedRole')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
