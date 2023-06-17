import 'package:flutter/material.dart';

void main() {
  runApp(ProfilePage());
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/profile_picture.jpg'),
              ),
              SizedBox(height: 16.0),
              Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Software Engineer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16.0),
              ListTile(
                leading: Icon(Icons.email),
                title: Text('john.doe@example.com'),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('+1 123-456-7890'),
              ),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text('New York, USA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
