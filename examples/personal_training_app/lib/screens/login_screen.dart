import 'package:flutter/material.dart';
import 'instructor_bio_screen.dart';
import 'package:personal_training_app/utils/firebase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:personal_training_app/utils/storage_helper.dart';
import 'package:personal_training_app/utils/security_helper.dart';

class LoginScreen extends StatefulWidget {
  final Function(String)?
  onClientLogin; // Called with email when client logs in
  final Function(String) onRoleSelected;

  const LoginScreen({
    super.key,
    required this.onRoleSelected,
    this.onClientLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _defaultLoginQuote =
      '"The hardest part of any workout is turning up"';
  static const String _loginQuoteStorageKey = 'login_quote_text';

  double _quoteOpacity = 0.0;
  double _quoteScale = 0.98;
  String _loginQuote = _defaultLoginQuote;
  final _clientUsernameController = TextEditingController();
  final _clientPasswordController = TextEditingController();
  final _instructorEmailController = TextEditingController();
  final _instructorPasswordController = TextEditingController();
  bool _obscureClientPassword = true;
  bool _obscureInstructorPassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadLoginQuote();

    // Animate the quote in after a short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _quoteOpacity = 1.0;
          _quoteScale = 1.04;
        });
        // Settle scale back to normal after pop
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _quoteScale = 1.0;
            });
          }
        });
      }
    });
  }

  Future<void> _loadSavedCredentials() async {
    final rememberMe = await StorageHelper.getString('rememberMe') == 'true';

    if (rememberMe) {
      final username = await StorageHelper.getString('clientUsername') ?? '';
      setState(() {
        _rememberMe = true;
        _clientUsernameController.text = username;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await StorageHelper.setString('rememberMe', 'true');
      await StorageHelper.setString(
        'clientUsername',
        _clientUsernameController.text,
      );
    } else {
      await StorageHelper.remove('rememberMe');
      await StorageHelper.remove('clientUsername');
    }
  }

  Future<void> _loadLoginQuote() async {
    final cachedQuote = await StorageHelper.getString(_loginQuoteStorageKey);
    if (cachedQuote != null && cachedQuote.trim().isNotEmpty && mounted) {
      setState(() {
        _loginQuote = cachedQuote.trim();
      });
    }

    await _refreshLoginQuoteFromFirebase();
  }

  Future<void> _refreshLoginQuoteFromFirebase() async {
    final remoteQuote = await FirebaseService.getLoginQuote();
    if (remoteQuote == null || remoteQuote.trim().isEmpty) return;

    final trimmedQuote = remoteQuote.trim();
    await StorageHelper.setString(_loginQuoteStorageKey, trimmedQuote);

    if (trimmedQuote != _loginQuote) {
      if (!mounted) return;
      setState(() {
        _loginQuote = trimmedQuote;
      });
    }
  }

  @override
  void dispose() {
    _clientUsernameController.dispose();
    _clientPasswordController.dispose();
    _instructorEmailController.dispose();
    _instructorPasswordController.dispose();
    super.dispose();
  }

  Future<void> _clientLogin() async {
    final username = _clientUsernameController.text.trim();
    final password = _clientPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    final authSignedIn = await FirebaseService.signInOrCreateClientAuth(
      username,
      password,
    );
    if (!authSignedIn) {
      if (!mounted) return;
      final authError = FirebaseService.lastAuthError;
      final errorMessage = authError == 'operation-not-allowed'
          ? 'Email/Password sign-in is disabled in Firebase Auth. Enable it and try again.'
          : (authError == 'firebase-not-initialized'
            ? 'Firebase is not initialized on this build. Please reinstall the latest app build.'
            : (authError == null
              ? 'Invalid username or password.'
              : 'Unable to start secure session: $authError'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      return;
    }

    // After auth, verify this username is provisioned in app data.
    final storedPassword = await FirebaseService.getUser(username);
    final profile = await FirebaseService.getClientProfile(username);
    final isProvisioned = storedPassword != null || profile != null;
    if (!isProvisioned) {
      await FirebaseService.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account not found. Contact your instructor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _refreshLoginQuoteFromFirebase();
    _saveCredentials();

    // Check if this is first login
    var firstLoginFlag = await StorageHelper.getString('first_login_$username');
    final isFirstLogin = firstLoginFlag != 'false';

    if (isFirstLogin) {
      // Show password change dialog for first login
      _showFirstLoginPasswordChange(username);
    } else {
      widget.onClientLogin?.call(username);
      widget.onRoleSelected('client');
      // Save FCM token after client login
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseService.saveUserToken(username, token);
      }
    }
  }

  void _showFirstLoginPasswordChange(String username) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('First Login - Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please set a new password for your account.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureNew = !obscureNew;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureConfirm = !obscureConfirm;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both passwords'),
                    ),
                  );
                  return;
                }

                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                // Update password and mark first login as complete.
                final hashedPassword = SecurityHelper.hashPassword(
                  newPassword,
                  username,
                );
                await FirebaseService.saveUser(username, hashedPassword);
                await FirebaseService.updateCurrentAuthPassword(newPassword);
                await StorageHelper.setString('first_login_$username', 'false');
                await _refreshLoginQuoteFromFirebase();

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );

                widget.onClientLogin?.call(username);
                widget.onRoleSelected('client');
                // Save FCM token after first login password change
                final tokenFuture = FirebaseMessaging.instance.getToken();
                tokenFuture.then((token) async {
                  if (token != null) {
                    await FirebaseService.saveUserToken(username, token);
                  }
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _instructorLogin() async {
    const instructorEmail = 'merianstephen@sim.com';

    if (_instructorEmailController.text.isEmpty ||
        _instructorPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final enteredEmail = _instructorEmailController.text.trim();
    final enteredPassword = _instructorPasswordController.text;

    if (enteredEmail == instructorEmail) {
      final authSignedIn = await FirebaseService.signInInstructorAuth(
        enteredEmail,
        enteredPassword,
      );
      if (!authSignedIn) {
        if (!mounted) return;
        final authError = FirebaseService.lastAuthError;
        final errorMessage = authError == 'operation-not-allowed'
            ? 'Email/Password sign-in is disabled in Firebase Auth. Enable it and try again.'
          : (authError == 'firebase-not-initialized'
            ? 'Firebase is not initialized on this build. Please reinstall the latest app build.'
            : (authError == null
              ? 'Unable to start secure session. Try again.'
              : 'Unable to start secure session: $authError'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
        return;
      }

      await _refreshLoginQuoteFromFirebase();
      widget.onRoleSelected('instructor');
      // Save FCM token after instructor login
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseService.saveUserToken(enteredEmail, token);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid instructor credentials'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            // Header
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 152,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Smart Training Platform',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Removed instructor forgot password button
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: _quoteOpacity,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    child: AnimatedScale(
                      scale: _quoteScale,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2563EB).withValues(alpha: 0.13),
                              const Color(0xFF7C3AED).withValues(alpha: 0.13),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          _loginQuote,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // CLIENT LOGIN SECTION
            Text(
              'Client Login',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),

            // Username Field
            TextField(
              controller: _clientUsernameController,
              decoration: const InputDecoration(
                hintText: 'Username',
                prefixIcon: Icon(Icons.person, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _clientPasswordController,
              obscureText: _obscureClientPassword,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF6B7280)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureClientPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureClientPassword = !_obscureClientPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field (only in signup mode)
            // Remember Me Checkbox
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF2563EB),
                ),
                Text(
                  'Remember me',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Client Login Button
            FilledButton(
              onPressed: _clientLogin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Login as Client',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            // Meet Your Trainer button
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Meet Your Trainer'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InstructorBioScreen(),
                    ),
                  );
                },
              ),
            ),

            // DIVIDER
            const Divider(thickness: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 32),

            // INSTRUCTOR LOGIN SECTION
            Text(
              'Instructor Login',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 12),

            // Instructor Email
            TextField(
              controller: _instructorEmailController,
              decoration: InputDecoration(
                hintText: 'Instructor email',
                prefixIcon: Icon(Icons.email, color: Color(0xFF6B7280)),
                isDense: true,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),

            // Instructor Password
            TextField(
              controller: _instructorPasswordController,
              obscureText: _obscureInstructorPassword,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock, color: Color(0xFF6B7280)),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureInstructorPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Color(0xFF6B7280),
                  ),
                  iconSize: 20,
                  onPressed: () {
                    setState(() {
                      _obscureInstructorPassword = !_obscureInstructorPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 12),

            // Instructor Login Button
            FilledButton(
              onPressed: _instructorLogin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: EdgeInsets.symmetric(vertical: 11),
              ),
              child: Text(
                'Login as Instructor',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
