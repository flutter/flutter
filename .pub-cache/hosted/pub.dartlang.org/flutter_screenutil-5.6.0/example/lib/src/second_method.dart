import 'package:example/src/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Note that you still can use [Theme] to theme your widget, but if you want
/// to theme MaterialApp you must use ScreenUtil.init in builder method and
/// wrap child with Theme, and remove theme and home properties from MaterialApp.
/// See [MyThemedApp].
///
/// example
/// ```dart
/// Theme(
///   data: ThemeData(...),
///   child: widget,
/// )
/// ```
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In first method you only need to wrap [MaterialApp] with [ScreenUtilInit] and that's it
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Second Method',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Second Method'),
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
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return HomePageScaffold(title: widget.title);
  }
}

class MyThemedApp extends StatelessWidget {
  const MyThemedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'First Method (Themed)',
      builder: (ctx, child) {
        ScreenUtil.init(ctx);
        return Theme(
          data: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: TextTheme(bodyText2: TextStyle(fontSize: 30.sp)),
          ),
          child: HomePage(title: 'FlutterScreenUtil Demo'),
        );
      },
    );
  }
}
