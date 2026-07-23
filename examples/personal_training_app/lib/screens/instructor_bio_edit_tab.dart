import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/firebase_service.dart';

/// Instructor-only tab for editing the public "About Me" bio profile.
class InstructorBioEditTab extends StatefulWidget {
  const InstructorBioEditTab({super.key});

  @override
  State<InstructorBioEditTab> createState() => _InstructorBioEditTabState();
}

class _InstructorBioEditTabState extends State<InstructorBioEditTab> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _certificationsController = TextEditingController();
  String _profilePictureUrl = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _specialtiesController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  Future<void> _loadBio() async {
    final bio = await FirebaseService.getInstructorBio();
    if (!mounted) return;
    if (bio != null) {
      _nameController.text = bio['name'] as String? ?? '';
      _titleController.text = bio['title'] as String? ?? '';
      _emailController.text = bio['email'] as String? ?? '';
      _bioController.text = bio['bio'] as String? ?? '';
      _specialtiesController.text = bio['specialties'] as String? ?? '';
      _certificationsController.text = bio['certifications'] as String? ?? '';
      _profilePictureUrl = bio['profilePictureUrl'] as String? ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _pickProfilePicture() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;
      final mimeType = picked.mimeType ?? 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      setState(() => _profilePictureUrl = dataUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseService.saveInstructorBio({
      'name': _nameController.text.trim(),
      'title': _titleController.text.trim(),
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim(),
      'specialties': _specialtiesController.text.trim(),
      'certifications': _certificationsController.text.trim(),
      'profilePictureUrl': _profilePictureUrl,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_profilePictureUrl.startsWith('data:')) {
      try {
        final bytes = base64Decode(_profilePictureUrl.split(',').last);
        return CircleAvatar(
          radius: 52,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }
    return const CircleAvatar(
      radius: 52,
      backgroundColor: Color(0xFFEDE9FE),
      child: Icon(Icons.person, size: 52, color: Color(0xFF7C3AED)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'My Public Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'This is what clients see before logging in.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Avatar with camera button
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _pickProfilePicture,
              icon: const Icon(Icons.photo_library, size: 16),
              label: const Text('Change Photo'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _field(_nameController, 'Display Name', Icons.badge),
          const SizedBox(height: 14),
          _field(_titleController, 'Title / Role', Icons.work_outline),
          const SizedBox(height: 14),
          _field(
            _emailController,
            'Contact Email',
            Icons.email_outlined,
            hint: 'e.g. coach@fitpro.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _field(
            _bioController,
            'About Me',
            Icons.info_outline,
            maxLines: 5,
            hint: 'Tell your clients about your background and approach...',
          ),
          const SizedBox(height: 14),
          _field(
            _specialtiesController,
            'Specialties',
            Icons.star_outline,
            maxLines: 3,
            hint: 'e.g. Weight Loss, Strength Training, HIIT...',
          ),
          const SizedBox(height: 14),
          _field(
            _certificationsController,
            'Certifications',
            Icons.verified_outlined,
            maxLines: 3,
            hint: 'e.g. NASM-CPT, CrossFit Level 2...',
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving…' : 'Save Profile'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
