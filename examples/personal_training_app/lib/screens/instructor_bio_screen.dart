import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/firebase_service.dart';

/// Public read-only view of the instructor's "About Me" profile.
/// Accessible from the login screen without logging in.
class InstructorBioScreen extends StatefulWidget {
  const InstructorBioScreen({super.key});

  @override
  State<InstructorBioScreen> createState() => _InstructorBioScreenState();
}

class _InstructorBioScreenState extends State<InstructorBioScreen> {
  Map<String, dynamic>? _bio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  Future<void> _loadBio() async {
    final bio = await FirebaseService.getInstructorBio();
    if (mounted) {
      setState(() {
        _bio = bio;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Your Trainer'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_bio == null || (_bio!['name'] as String? ?? '').isEmpty)
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Trainer profile coming soon!',
                      style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final name = _bio!['name'] as String? ?? '';
    final title = _bio!['title'] as String? ?? '';
    final email = _bio!['email'] as String? ?? '';
    final bio = _bio!['bio'] as String? ?? '';
    final specialties = _bio!['specialties'] as String? ?? '';
    final certifications = _bio!['certifications'] as String? ?? '';
    final picUrl = _bio!['profilePictureUrl'] as String? ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header with photo
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                _buildAvatar(picUrl, 56),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bio.isNotEmpty) ...[
                  _sectionCard(
                    icon: Icons.info_outline,
                    title: 'About',
                    content: bio,
                  ),
                  const SizedBox(height: 16),
                ],
                if (email.isNotEmpty) ...[
                  _sectionCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    content: email,
                  ),
                  const SizedBox(height: 16),
                ],
                if (specialties.isNotEmpty) ...[
                  _sectionCard(
                    icon: Icons.star_outline,
                    title: 'Specialties',
                    content: specialties,
                  ),
                  const SizedBox(height: 16),
                ],
                if (certifications.isNotEmpty) ...[
                  _sectionCard(
                    icon: Icons.verified_outlined,
                    title: 'Certifications',
                    content: certifications,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String picUrl, double radius) {
    if (picUrl.startsWith('data:')) {
      try {
        final bytes = base64Decode(picUrl.split(',').last);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: Colors.white24,
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person, size: radius * 0.9, color: Colors.white70),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
