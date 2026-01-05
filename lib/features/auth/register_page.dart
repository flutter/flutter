import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final AuthService _auth = AuthService();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (passwordController.text != confirmController.text) {
      setState(() => error = 'Passwords do not match');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    final bool ok = await _auth.register(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      context.read<AppState>().clearRole();
      Navigator.pushReplacementNamed(context, '/roles');
    } else {
      setState(() => error = 'Registration failed.');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <>[
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Account'),
            ),
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
