import 'package:flutter/material.dart';
import '../models/client_profile.dart';
import '../widgets/illustrated_avatar.dart';

class ClientsTab extends StatelessWidget {
  final List<ClientProfile> clients;
  final Future<void> Function(ClientProfile) onViewClient;
  final Future<void> Function(ClientProfile) onEditClient;
  final Future<void> Function(ClientProfile) onDeleteClient;
  final Future<void> Function(String username, String name, String password)
  onAddClient;

  const ClientsTab({
    super.key,
    required this.clients,
    required this.onViewClient,
    required this.onEditClient,
    required this.onDeleteClient,
    required this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Add Client'),
                onPressed: () async {
                  final result = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (context) {
                      final usernameController = TextEditingController();
                      final nameController = TextEditingController();
                      final passwordController = TextEditingController();
                      return AlertDialog(
                        title: const Text('Add New Client'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(labelText: 'Username'),
                            ),
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(labelText: 'Name'),
                            ),
                            TextField(
                              controller: passwordController,
                              decoration: const InputDecoration(labelText: 'Password'),
                              obscureText: true,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop({
                                'username': usernameController.text.trim(),
                                'name': nameController.text.trim(),
                                'password': passwordController.text.trim(),
                              });
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                  if (result != null && result['username']!.isNotEmpty && result['name']!.isNotEmpty && result['password']!.isNotEmpty) {
                    await onAddClient(result['username']!, result['name']!, result['password']!);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: clients.isEmpty
              ? const Center(child: Text('No clients found.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: clients.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDBEAFE),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: ProfileAvatar(
                            imageValue: client.profilePictureUrl,
                            seed: client.username,
                            size: 44,
                          ),
                        ),
                      ),
                      title: Text(client.name.isNotEmpty ? client.name : client.username),
                      subtitle: Text(client.email),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'view') {
                            await onViewClient(client);
                          } else if (value == 'edit') {
                            await onEditClient(client);
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Client'),
                                content: const Text('Are you sure you want to delete this client? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await onDeleteClient(client);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () => onViewClient(client),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
