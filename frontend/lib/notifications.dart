import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Notifications'),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NotificationCard(
              title: 'Reminder: Your parking session is about to expire',
              description:
                  'Your parking session at Parking Spot A is about to expire in 10 minutes.',
              timestamp: '10:45 AM',
            ),
            SizedBox(height: 16),
            NotificationCard(
              title: 'New Offer: 20% off on parking fees',
              description:
                  'Get 20% off on your next parking session at any parking spot. Limited time offer!',
              timestamp: 'Yesterday',
            ),
            SizedBox(height: 16),
            NotificationCard(
              title: 'Feedback Request',
              description:
                  'Please provide feedback on your recent parking experience. Your opinion matters!',
              timestamp: '2 days ago',
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String timestamp;

  const NotificationCard({super.key, 
    required this.title,
    required this.description,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            Text('Received at $timestamp',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Color.fromARGB(255, 46, 46, 220),
              ),
            ),
          ],
        ),
      ),
    );
  }
}