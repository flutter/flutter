import 'package:flutter/material.dart';

class Myforms1 extends StatefulWidget {
  const Myforms1({super.key});

  @override
  State<Myforms1> createState() => _Myforms1State();
}

class _Myforms1State extends State<Myforms1> {
  final _formkey = GlobalKey<FormState>();
  String fname = '';
  String lname = '';
  String email = '';
  String pass = '';
  trysubmit() {
    final _isvalid = _formkey.currentState!.validate();
    if (_isvalid) {
      _formkey.currentState!.save();
      submitform();
    } else {
      print("Error");
    }
  }

  submitform() {
    print(fname);
    print(lname);
    print(email);
    print(pass);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("My forms"),
          backgroundColor: Colors.blue,
        ),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            children: const [
              DrawerHeader(
                child: Card(
                  margin: EdgeInsets.all(0),
                  color: Colors.blue,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRIdoay7VbsVZzZ1bZkX4k0T77hp5sb_ciXdQ&s'),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Shobhit Mhase",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "CSE",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Form(
          key: _formkey,
          child: Container(
            child: ListView(
              children: [
                TextFormField(
                  key: ValueKey('fname'),
                  decoration: InputDecoration(
                      hintText: "Enter First name",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  validator: (value) {
                    if (value.toString().isEmpty) {
                      return 'This field is mandatory';
                    } else {
                      return null;
                    }
                  },
                  onSaved: (value) {
                    fname = value.toString();
                  },
                ),
                TextFormField(
                  key: ValueKey('lname'),
                  decoration: InputDecoration(
                      hintText: "Enter Last name",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  validator: (value) {
                    if (value.toString().isEmpty) {
                      return 'This field is mandatory';
                    } else {
                      return null;
                    }
                  },
                  onSaved: (value) {
                    lname = value.toString();
                  },
                ),
                TextFormField(
                  key: ValueKey('email'),
                  decoration: InputDecoration(
                      hintText: "Enter email",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  validator: (value) {
                    if (value.toString().isEmpty) {
                      return 'This field is mandatory';
                    } else if (value.toString().length < 7) {
                      return 'password lenght shoild be of 7 charachters';
                    } else {
                      return null;
                    }
                  },
                  onSaved: (value) {
                    email = value.toString();
                  },
                ),
                TextFormField(
                  key: ValueKey('pass'),
                  decoration: InputDecoration(
                      hintText: "Enter password",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  validator: (value) {
                    if (value.toString().isEmpty) {
                      return 'This field is mandatory';
                    } else {
                      return null;
                    }
                  },
                  onSaved: (value) {
                    pass = value.toString();
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      trysubmit();
                    },
                    child: Text("Submit"))
              ],
            ),
          ),
        ));
  }
}
