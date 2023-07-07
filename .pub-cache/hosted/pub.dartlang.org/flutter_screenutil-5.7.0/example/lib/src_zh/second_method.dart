import 'package:example/src_zh/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 请注意，您仍然可以使用 [Theme] 为您的小部件设置主题，但如果您想为 MaterialApp
/// 设置主题，您必须在 builder 方法中使用 ScreenUtil.init 并使用 Theme 包装子项
/// 并从 MaterialApp 中删除主题和主页属性。 请参阅 [MyThemedApp]。
///
/// 例子
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
      title: '第二种方法',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: '第二种方法'),
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
      title: '第二种方法（带主题）',
      builder: (ctx, child) {
        ScreenUtil.init(ctx);
        return Theme(
          data: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: TextTheme(bodyText2: TextStyle(fontSize: 30.sp)),
          ),
          child: HomePage(title: '第二种方法（带主题）'),
        );
      },
    );
  }
}
