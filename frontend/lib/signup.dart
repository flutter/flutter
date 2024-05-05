import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parkngo/models/usermodel.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';

  Future<void> signUp(BuildContext context) async {
  try {
    // Prepare the user data to send to the backend
    Map<String, dynamic> userData = {
      'username': usernameController.text,
      'email': emailController.text,
      'password': passwordController.text,
    };

    // Make an HTTP POST request to create the user
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/user/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(userData),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      // User created successfully
      print('User signed up successfully');
    } else {
      // User creation failed
      setState(() {
        errorMessage = 'Failed to create user. Please try again.';
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'An error occurred while signing up. Please try again.';
    });
    print('Error signing up: $e');
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                signUp(context);
              },
              child: Text('Sign Up'),
            ),
            SizedBox(height: 10),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
