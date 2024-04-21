import 'package:flutter/material.dart';

class Myform extends StatefulWidget {
  const Myform({super.key});

  @override
  State<Myform> createState() => _MyformState();
}

class _MyformState extends State<Myform> {
  final _formkey = GlobalKey<FormState>();
  String firstname = '';
  String lastname = '';
  String email = '';
  String password = '';
  trysubmit() {
    final _isvalid = _formkey.currentState!.validate();
    if (_isvalid) {
      _formkey.currentState!.save();
      submitform();
    } else
      print('Error');
  }

  submitform() {
    print(firstname);
    print(lastname);
    print(email);
    print(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('My Form'),
          leading: Icon(Icons.person),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Container(
            margin: EdgeInsets.all(10),
            child: Form(
              key: _formkey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Firstname',
                    ),
                    key: ValueKey('firstname'),
                    validator: (value) {
                      if (value.toString().isEmpty) {
                        return 'This field is mandatory';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      firstname = value.toString();
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Lastname',
                    ),
                    key: ValueKey('lastname'),
                    validator: (value) {
                      if (value.toString().isEmpty) {
                        return 'This field is mandatory';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      lastname = value.toString();
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Email',
                    ),
                    key: ValueKey('email'),
                    validator: (value) {
                      if (value.toString().isEmpty) {
                        return 'This field is mandatory';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      email = value.toString();
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Password',
                    ),
                    key: ValueKey('password'),
                    validator: (value) {
                      if (value.toString().isEmpty) {
                        return 'This field is mandatory';
                      } else if (value.toString().length < 7) {
                        return 'Too short password';
                      } else {
                        return null;
                      }
                    },
                    onSaved: (value) {
                      password = value.toString();
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        trysubmit();
                      },
                      child: Text('Sign up'))
                ],
              ),
            ),
          ),
        ));
  }
}
