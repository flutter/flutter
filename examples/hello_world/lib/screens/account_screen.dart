import 'package:flutter/material.dart';

import '../app_build_info.dart';
import '../models/user_profile.dart';
import '../services/app_controller.dart';
import '../services/training_service.dart';
import '../widgets/section_header.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    required this.controller,
    required this.service,
    super.key,
  });

  final AppController controller;
  final TrainingService service;

  @override
  Widget build(BuildContext context) {
    final UserProfile user = service.getUserProfile();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        const SectionHeader(title: 'Konto'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                const CircleAvatar(
                  radius: 36,
                  child: Icon(Icons.person, size: 34),
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('${user.goal} • ${user.experience}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoChip(label: 'Alder', value: '${user.age}'),
                    _InfoChip(label: 'Vægt', value: '${user.weightKg.toStringAsFixed(1)} kg'),
                    _InfoChip(label: 'Højde', value: '${user.heightCm} cm'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Rediger profil'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Indstillinger'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                title: const Text('Notifikationer'),
                value: controller.notificationsEnabled,
                onChanged: controller.toggleNotifications,
              ),
              ListTile(
                title: const Text('Enhed / format'),
                subtitle: Text(controller.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'),
                trailing: SegmentedButton<WeightUnit>(
                  segments: const <ButtonSegment<WeightUnit>>[
                    ButtonSegment<WeightUnit>(value: WeightUnit.kg, label: Text('kg')),
                    ButtonSegment<WeightUnit>(value: WeightUnit.lbs, label: Text('lbs')),
                  ],
                  selected: <WeightUnit>{controller.weightUnit},
                  onSelectionChanged: (Set<WeightUnit> value) {
                    controller.setWeightUnit(value.first);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Mere'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: const <Widget>[
              ListTile(
                title: Text('Privatliv / data'),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 0),
              ListTile(
                title: Text('Apple Health / Google Fit'),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 0),
              ListTile(
                title: Text('Hjælp og support'),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 0),
              ListTile(
                title: Text('Abonnement'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            title: const Text('App version'),
            subtitle: const Text('Brug denne til at bekræfte ny build i simulatoren'),
            trailing: Text(
              appVersion,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () {},
          icon: const Icon(Icons.logout),
          label: const Text('Log ud'),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}
