import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_layout.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.painter;
  
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = false;

      if (_isRegistering) {
        // Handle registration with Supabase Auth
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'full_name': _nameController.text.trim(),
            'role': _selectedRole.name,
          },
        );

        if (response.user != null) {
          // Create user profile in database
          await Supabase.instance.client.from('profiles').insert({
            'id': response.user!.id,
            'full_name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': _selectedRole.name,
            'is_active': true,
          });
          success = true;
        }
      } else {
        // Check for admin credentials first
        if (_emailController.text.trim() == 'admin' && _passwordController.text == 'hwrp123') {
          success = await authProvider.loginWithCredentials(
            'admin',
            'hwrp123',
            UserRole.ceo,
          );
        } else {
          // Handle login with Supabase Auth
          final response = await Supabase.instance.client.auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (response.user != null) {
            // Get user profile from database
            final profileResponse = await Supabase.instance.client
                .from('profiles')
                .select()
                .eq('id', response.user!.id)
                .single();

            final user = UserModel(
              id: response.user!.id,
              fullName: profileResponse['full_name'] ?? '',
              email: profileResponse['email'] ?? '',
              role: UserRole.values.firstWhere(
                (role) => role.name == (profileResponse['role'] ?? 'painter'),
                orElse: () => UserRole.painter,
              ),
              isActive: profileResponse['is_active'] ?? true,
            );

            authProvider.setCurrentUser(user);
            success = true;
          }
        }
      }

      if (!success) {
        setState(() {
          _errorMessage = _isRegistering 
              ? 'Failed to create account. Please try again.'
              : 'Invalid email or password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        if (e is AuthException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = _isRegistering 
              ? 'Failed to create account. Please try again.'
              : 'Login failed. Please check your credentials.';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF37474F),
              Color(0xFF263238),
              Color(0xFF1C2329),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveLayout.getPadding(context),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
                    _buildHeader(),
                    SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
                    _buildAuthToggle(),
                    SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
                    _buildAuthForm(),
                    SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
                    _buildSubmitButton(),
                    if (_errorMessage != null) ...[
                      SizedBox(height: ResponsiveLayout.getSpacing(context)),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF37474F), Color(0xFF263238)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.business,
              size: ResponsiveLayout.getIconSize(context, base: 48),
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          Text(
            'PaintOps',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 32),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Operational Intelligence Platform',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
              color: const Color(0xFFB0BEC5),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Sign In', !_isRegistering),
          _buildToggleButton('Register', _isRegistering),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRegistering = text == 'Register';
          _errorMessage = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? const Color(0xFF37474F) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_isRegistering) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: ResponsiveLayout.getSpacing(context)),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _isRegistering ? 'Email Address' : 'Email or Username',
                hintText: _isRegistering ? 'Enter your email' : 'Enter your email or username',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your ${_isRegistering ? 'email' : 'email or username'}';
                }
                if (_isRegistering && !value.contains('@') && value != 'admin') {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            SizedBox(height: ResponsiveLayout.getSpacing(context)),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (_isRegistering && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            if (_isRegistering) ...[
              SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
              _buildRoleSelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Role',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 12),
          ...UserRole.values.map((role) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedRole = role),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedRole == role 
                        ? const Color(0xFF37474F).withOpacity(0.1) 
                        : Colors.transparent,
                    border: Border.all(
                      color: _selectedRole == role 
                          ? const Color(0xFF37474F) 
                          : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Radio<UserRole>(
                        value: role,
                        groupValue: _selectedRole,
                        onChanged: (value) => setState(() => _selectedRole = value!),
                        activeColor: const Color(0xFF37474F),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.displayName,
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF37474F),
                              ),
                            ),
                            Text(
                              role.description,
                              style: TextStyle(
                                fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                                color: const Color(0xFFB0BEC5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: ResponsiveLayout.getButtonHeight(context),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF263238)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF37474F).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleSubmit,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRegistering ? Icons.person_add : Icons.login, 
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRegistering ? 'Create Account' : 'Sign In',
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 18),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
