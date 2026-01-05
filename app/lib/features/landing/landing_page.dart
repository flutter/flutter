import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/app_state.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/roles');
      });
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scholesa', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.primary)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Login'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Education 2.0 for Future Skills, Leadership, and Impact.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text(
                'Plan, learn, and evidence growth across our three pillars. Built for learners, educators, parents, sites, partners, and HQ.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _PillarChip(label: 'Future Skills'),
                  _PillarChip(label: 'Leadership & Agency'),
                  _PillarChip(label: 'Impact & Innovation'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('Get started'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('I already have an account'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
    );
  }
}
