import 'package:flutter/cupertino.dart';
import 'package:parkngo/homepage.dart';
import 'package:parkngo/signup.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Login'),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 150,
              ),
              SizedBox(height: 20),
              CupertinoTextField(
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              CupertinoTextField(
                placeholder: 'Password',
                obscureText: true,
              ),
              SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: () {
                  // Implement login functionality
                },
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  // Implement navigation to contributor sign up page
                },
                child: Text(
                  'Do you want to sign up as a contributor?',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 14, // Smaller font size
                    decoration: TextDecoration.none, // Remove underline
                  ),
                ),
              ),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to SignUpPage
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => SignUpPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 14, // Smaller font size
                          decoration: TextDecoration.none, // Remove underline
                          color:
                              CupertinoColors.activeBlue, // Change text color
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        // Navigate to homepage
                        Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => HomePage(),
                          ),
                        );
                      },
                      child: Icon(
                        CupertinoIcons.arrow_right,
                        color: CupertinoColors.activeBlue,
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
  }
}
