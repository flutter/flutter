import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyReservations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('My Reservations'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReservationCard(
              location: 'Parking Spot A',
              dateTime: 'April 15, 2024 - 10:00 AM',
              status: 'Confirmed',
            ),
            SizedBox(height: 16),
            ReservationCard(
              location: 'Parking Spot B',
              dateTime: 'April 16, 2024 - 11:30 AM',
              status: 'Confirmed',
            ),
            SizedBox(height: 16),
            ReservationCard(
              location: 'Parking Spot C',
              dateTime: 'April 18, 2024 - 09:15 AM',
              status: 'Confirmed',
            ),
            SizedBox(height: 16),
            ReservationCard(
              location: 'Parking Spot D',
              dateTime: 'April 20, 2024 - 02:45 PM',
              status: 'Confirmed',
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationCard extends StatelessWidget {
  final String location;
  final String dateTime;
  final String status;

  const ReservationCard({
    required this.location,
    required this.dateTime,
    required this.status,
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
              'Location: $location',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text('Date & Time: $dateTime'),
            SizedBox(height: 8),
            Text('Status: $status'),
          ],
        ),
      ),
    );
  }
}
