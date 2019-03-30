import 'package:flutter/material.dart';

class LoginScreenApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(title: 'Login Screen'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const FlutterLogo(
                size: 30.0,
              ),
              const Text('Login2'),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration.collapsed(hintText: 'username'),
                autofocus: true,
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration.collapsed(hintText: 'password'),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}