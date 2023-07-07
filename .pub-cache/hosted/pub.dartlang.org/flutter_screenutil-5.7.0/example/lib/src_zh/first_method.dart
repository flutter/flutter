import 'package:example/src_zh/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In first method you only need to wrap [MaterialApp] with [ScreenUtilInit] and that's it
    return ScreenUtilInit(
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '第一种方法',
          // You can use the library anywhere in the app even in theme
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: TextTheme(bodyText2: TextStyle(fontSize: 30.sp)),
          ),
          home: child,
        );
      },
      child: HomePage(title: '第一种方法'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) => HomePageScaffold(title: widget.title);
}
