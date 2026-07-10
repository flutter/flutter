
import 'package:flutter/material.dart';
import '../utils/firebase_service.dart';
import '../models/client_profile.dart';


class NotificationTab extends StatefulWidget {
  final List<ClientProfile> clients;
  const NotificationTab({super.key, required this.clients});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  final TextEditingController notificationController = TextEditingController();
  bool celebration = false;
  String? _selectedClient;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Client dropdown at the top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Client',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                initialValue: _selectedClient,
                items: widget.clients.map((client) {
                  return DropdownMenuItem<String>(
                    value: client.username,
                    child: Text(client.name.isNotEmpty ? client.name : client.username),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClient = value;
                  });
                },
              ),
            ),
            if (_selectedClient != null) ...[
              const SizedBox(height: 24),
              // Message box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send Notification to Client:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notificationController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notification Message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Confetti box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: celebration,
                        onChanged: (val) {
                          setState(() => celebration = val ?? false);
                        },
                      ),
                      const Text('Show confetti (celebration)', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.notifications),
                label: const Text('Send Notification'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final msg = notificationController.text.trim();
                  if (msg.isNotEmpty) {
                    await FirebaseService.sendNotification(
                      _selectedClient!,
                      msg,
                      celebration: celebration,
                    );
                    notificationController.clear();
                    // Show a prominent dialog with a checkmark
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 56),
                              const SizedBox(height: 18),
                              const Text('Notification sent!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}