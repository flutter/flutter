import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/app_state.dart';

const Map<String, String> roles = <String, String>{
  'learner': 'Learner',
  'educator': 'Educator',
  'parent': 'Parent',
  'site': 'Site Lead',
  'partner': 'Partner',
  'hq': 'HQ',
};

class RoleSelectorPage extends StatefulWidget {
  const RoleSelectorPage({super.key});

  @override
  State<RoleSelectorPage> createState() => _RoleSelectorPageState();
}

class _RoleSelectorPageState extends State<RoleSelectorPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose role')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: roles.entries
            .map(
              (MapEntry<String, String> entry) => Card(
                child: ListTile(
                  title: Text(entry.value),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.read<AppState>().setRole(entry.key);
                    Navigator.pushNamed(context, '/dashboard/${entry.key}');
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
