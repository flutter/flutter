# <img src="https://flutter.io/images/flutter-mark-square-100.png" alt="Flutter" width="40" height="40" /> Flutter [![Join Gitter Chat Channel -](https://badges.gitter.im/flutter/flutter.svg)](https://gitter.im/flutter/flutter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status - Travis](https://travis-ci.org/flutter/flutter.svg?branch=master)](https://travis-ci.org/flutter/flutter) [![Build Status - AppVeyor](https://ci.appveyor.com/api/projects/status/meyi9evcny64a2mg/branch/master?svg=true)](https://ci.appveyor.com/project/flutter/flutter/branch/master) [![Coverage Status -](https://coveralls.io/repos/github/flutter/flutter/badge.svg?branch=master)](https://coveralls.io/github/flutter/flutter?branch=master)

一套全新的用来帮助开发者和设计师们构建最新 iOS 和 Android 应用的移动应用 SDK。Flutter 目前是一个处于 alpha 测试阶段的开源项目。

> 语言切换：[English](https://github.com/flutter/flutter/blob/master/README.md)。

### 文档

* **主页: [flutter.io][]**
* [安装](https://flutter.io/setup/)
* [上手](https://flutter.io/getting-started/)
* [贡献](CONTRIBUTING.md)

## 快速开发

Flutter 的 <em>hot reload</em> 功能可以帮助您更快地进行试验、构建 UI、添加特性或者修改 Bug。在 iOS 或 Android 仿真器、模拟器和真机上体验次秒级别的重加载时间。

<img src="https://user-images.githubusercontent.com/919717/28131204-0f8c3cda-66ee-11e7-9428-6a0513eac75d.gif" alt="Make a change in your code, and your app is changed instantly.">

## 传神，美观的 UI

让您的用户沉浸于 Flutter 美观的内建原质化设计和 iOS 风格的部件、丰富的动作 API、平滑自然的滚动和平台意识。

<img src="https://flutter.io/images/homepage/screenshot-1.png" width="270" height="480" alt="Brand-first shopping design" align="left">
<img src="https://flutter.io/images/homepage/screenshot-2.png" width="270" height="480" alt="Fitness app design">

<img src="https://flutter.io/images/homepage/screenshot-3.png" width="270" height="480" alt="Contact app design" align="left">
<img src="https://flutter.io/images/homepage/ios-friendlychat.png" width="270" height="480" alt="iOS chat app design">

浏览<a href="https://flutter.io/widgets/">部件目录</a>。

## 现代，响应式的框架

利用 Flutter 现代的函数响应式框架和丰富的平台、布局和基础部件可以轻松地构建 UI。依靠强大灵活的 2D、动画、手势、特效等 API 解决您在 UI 构建过程中遇到的各种挑战。

```dart
class CounterState extends State<Counter> {
  int counter = 0;

  void increment() {
    // 告知 Flutter 框架 state 发生了改变，从而使框架执行 build() 并且更新显示。
    setState(() {
      counter++;
    });
  }

  Widget build(BuildContext context) {
    // 本方法会在每次 setState 被调用时重新执行。Flutter 框架已经为重新执行方法
    // 做了优化，这样您就可以重建任何需要更新的东西，而不是单独更改小部件的实例。
    return new Row(
      children: <Widget>[
        new RaisedButton(
          onPressed: increment,
          child: new Text('Increment'),
        ),
        new Text('Count: $counter'),
      ],
    );
  }
}
```

浏览<a href="https://flutter.io/widgets/">部件目录</a>并且了解更多和<a href="https://flutter.io/widgets-intro/">函数响应式框架</a>有关的信息。

## 访问原生功能和 SDK

利用平台 API、第三方 SDK 和原生代码打造您的移动应用，Flutter 让您能够重用您现有的 Java、Swift 和 ObjC 代码，并且能够访问 iOS 和 Android 的原生功能和 SDK。

访问平台功能很容易。这是我们和原生交互的<a href="https://github.com/flutter/flutter/tree/master/examples/platform_channel">互操作示例</a>的部分代码：

```dart
Future<Null> getBatteryLevel() async {
  var batteryLevel = 'unknown';
  try {
    int result = await methodChannel.invokeMethod('getBatteryLevel');
    batteryLevel = 'Battery level: $result%';
  } on PlatformException {
    batteryLevel = 'Failed to get battery level.';
  }
  setState(() {
    _batteryLevel = batteryLevel;
  });
}
```

了解如何通过使用<a href="https://flutter.io/using-packages/">软件包</a>或写<a href="https://flutter.io/platform-channels/">平台通道</a>的方式来访问原生代码，API 和 SDK。

## 统一的应用开发

Flutter 拥有能够帮助您轻松地在 iOS 和 Android 上实现您的想法的工具和库。如果您没有任何移动开发经验，Flutter 是一种构建精美移动应用的轻松、快捷的方式。如果您是一位经验丰富的 iOS 或 Android 开发人员，您可以使用 Flutter 来构建您的新视图，充分利用您现有的 Java／ObjC／Swift 使用经验。

### 构建

* **美观的应用 UI**
  * 丰富的 2D GPU 加速 API
  * 响应式框架
  * 动画／动作 API
  * 原质化设计和 iOS 风格部件
* **流式编码体验**
  * 次秒级，可维持状态的热重加载
  * IntelliJ：重构、代码补全等
  * Dart 语言和核心库
  * 包管理
* **全功能移动应用**
  * 与手机操作系统 API & SDK 进行交互
  * Maven／Java
  * Cocoapods／ObjC／Swift

### 优化

* **测试**
  * 单元测试
  * 集成测试
  * 设备测试
* **调试**
  * IDE 调试器
  * 基于 Web 的调试器
  * 异步/等待识别
  * 表达式计算器
* **概况**
  * 时间表
  * CPU 和内存
  * 应用内性能图表

### 发布

* **编译**
  * 原生 ARM 代码
  * 死码消除
* **分发**
  * App Store
  * Play Store

查看<a href="https://flutter.io/technical-overview/">技术概述</a>了解 Flutter 的更多特点。

来我们的 [Gitter 聊天室](https://gitter.im/flutter/flutter)加入我们或者加入我们的公共邮件列表 [flutter-dev@googlegroups.com](https://groups.google.com/forum/#!forum/flutter-dev)。

[flutter.io]: https://flutter.io/
