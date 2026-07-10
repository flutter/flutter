import 'package:flutter/material.dart';
import '../models/client_profile.dart';

class IllnessDayScreen extends StatefulWidget {
  final ClientProfile profile;
  final Function(ClientProfile) onProfileUpdated;

  const IllnessDayScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<IllnessDayScreen> createState() => _IllnessDayScreenState();
}

class _IllnessDayScreenState extends State<IllnessDayScreen> {
  late List<DateTime> _illnessDays;

  @override
  void initState() {
    super.initState();
    _illnessDays = List.from(widget.profile.illnessDays);
  }

  Future<void> _addIllnessDay() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Illness Day',
    );

    if (pickedDate != null) {
      // Normalize to midnight to avoid time comparison issues
      final normalizedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );

      // Check if date already exists
      final alreadyExists = _illnessDays.any(
        (date) =>
            date.year == normalizedDate.year &&
            date.month == normalizedDate.month &&
            date.day == normalizedDate.day,
      );

      if (alreadyExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This date is already marked as illness day'),
            ),
          );
        }
        return;
      }

      setState(() {
        _illnessDays.add(normalizedDate);
        _illnessDays.sort((a, b) => b.compareTo(a)); // Sort most recent first
      });
      _saveProfile();
    }
  }

  void _removeIllnessDay(DateTime date) {
    setState(() {
      _illnessDays.removeWhere(
        (d) =>
            d.year == date.year && d.month == date.month && d.day == date.day,
      );
    });
    _saveProfile();
  }

  void _saveProfile() {
    final updatedProfile = widget.profile.copyWith(illnessDays: _illnessDays);
    widget.onProfileUpdated(updatedProfile);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Illness Days'),
        elevation: 0,
      ),
      body: _illnessDays.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No illness days recorded',
                    style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a day when you were ill',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _illnessDays.length,
              itemBuilder: (context, index) {
                final date = _illnessDays[index];
                final isRecent = DateTime.now().difference(date).inDays < 7;

                return Card(
                  color: const Color(0xFF374151),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isRecent
                            ? Colors.red.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sick,
                        color: isRecent ? Colors.red[300] : Colors.grey[400],
                      ),
                    ),
                    title: Text(
                      _formatDate(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${DateTime.now().difference(date).inDays} days ago',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(date),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIllnessDay,
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF374151),
        title: const Text(
          'Remove Illness Day',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${_formatDate(date)} from your illness days?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _removeIllnessDay(date);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
