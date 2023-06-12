[English](https://github.com/rrousselGit/provider/blob/master/README.md)| [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) <a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

এটি [InheritedWidget] এর চারপাশে একটি মোড়ক যা ব্যবহার করে
আপনি এগুলাকে আরো সহজ এবং পুনঃব্যবহারযোগ্য করতে পারবেন।

ম্যানুয়ালি [InheritedWidget] লেখার পরিবর্তে `provider` ব্যবহার করে, আপনি পাবেন:

- সরলীকৃতভাবে রিসোর্স নিষ্পত্তি/ডিস্পোস
- লেজি-লোডিং
- প্রতিবার একটি নতুন ক্লাস তৈরি করার জন্য একটি ব্যাপকভাবে হ্রাস করা বয়লারপ্লেট
- devtool-এর সাথে বন্ধুত্বপূর্ণ - প্রভাইডার ব্যবহার করে, আপনার এপ্লিকেশন এর স্টেট Flutter devtool-এ দৃশ্যমান হবে
- এই [InheritedWidget]গুলি ব্যবহার করার একটি সাধারণ উপায় (দেখুন [Provider.of]/[Consumer]/[Selector])
- লিসেনিং পদ্ধতির সাথে ক্লাসের জন্য বর্ধিত মাপযোগ্যতা যা জটিলতায় দ্রুত বৃদ্ধি পায় (যেমন [ChangeNotifier], যা নোটিফিকেশন পাঠানোর জন্য O(N)।

একটি `প্রভাইডার' সম্পর্কে আরও পড়তে, এটির [ডকুমেন্টেশন](https://pub.dev/documentation/provider/latest/provider/provider-library.html) দেখুন।

আর দেখুনঃ

- [অফিসিয়াল Flutter এর স্টেট ম্যানেজম্যান্ট ডকুমেন্টশন](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple), এটি দেখায় কিভাবে `provider` ব্যবহার করতে হয়, আর সাথে [ChangeNotifier]।
- [Flutter আর্কিটেকচার স্যাম্পল](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider), যেটিতে `provider` + [ChangeNotifier] কে ব্যবহার করে একটি এ্যাপ ইমপ্লিমেন্ট করা হয়েছে।
- [flutter_bloc](https://github.com/felangel/bloc) এবং [Mobx](https://github.com/mobxjs/mobx.dart), যারা তাদের আর্কিটেকচার এ `provider` ব্যবহার করে।

## 4.x.x থেকে 5.0.0-nullsafety-এ মাইগ্রেশন

- `FutureProvider` এবং `StreamProvider` উভয়ের জন্য `initialData` এখন প্রয়োজন।

মাইগ্রেট করতে, আগে যা হতোঃ

```dart
FutureProvider<int>(
  create: (context) => Future.value(42),
  child: MyApp(),
)

Widget build(BuildContext context) {
  final value = context.watch<int>();
  return Text('$value');
}
```

আর এখনঃ

```dart
FutureProvider<int?>(
  initialValue: null,
  create: (context) => Future.value(42),
  child: MyApp(),
)

Widget build(BuildContext context) {
  // খেয়াল রাখবেন যেন "?" দেওয়া হয়, যেমনঃ context.watch<int?>();
  return Text('$value');
}
```

- `ValueListenableProvider` রিমোভ করে দেওয়া হয়েছে

  মাইগ্রেট করতে, আপনি `Provider` ব্যবহার করতে পারেন `ValueListenableBuilder` এর সাথে যোগ করেঃ

  ```dart
  ValueListenableBuilder<int>(
    valueListenable: myValueListenable,
    builder: (context, value, _) {
      return Provider<int>.value(
        value: value,
        child: MyApp(),
      );
    }
  )
  ```

## ব্যবহার

### একটি ভ্যালু এক্সপোস করা

#### একটি নতুন অবজেক্ট এর ইন্সট্যান্স এক্সপোস করা

প্রভাইডাররা আপনাকে শুধুমাত্র একটি ভ্যালু প্রকাশ করতে দেয় না, বরং এটি তৈরি করতে, শুনতে এবং নিষ্পত্তি করতে দেয়।

একটি নতুন তৈরি অবজেক্ট এক্সপোস করতে, একটি প্রভাইডারের ডিফল্ট কনস্ট্রাক্টর ব্যবহার করুন।

আপনি যদি কোনো অবজেক্ট **তৈরি** করতে চান তাহলে `.value` কনস্ট্রাক্টর ব্যবহার _করবেন না_, অথবা অন্যথায় আপনার অযাচিত পার্শ্বপ্রতিক্রিয়া হতে পারে।

[এই StackOverflow উত্তরটি](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build) দেখুন যা ব্যাখ্যা করে কেন ভ্যালু তৈরি করতে `.value` কনস্ট্রাক্টর ব্যবহার করা অনাকাঙ্ক্ষিত

- `create` এর মধ্যে অবজেক্ট তৈরি **করুনঃ**

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- অবজেক্ট তৈরিতে `Provider.value` কখনোই ব্যবহার **করবেন না।**

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- সময়ের সাথে পরিবর্তন হতে পারে এমন ভেরিয়েবল থেকে আপনার অবজেক্ট তৈরি **করবেন না।**

  এমন পরিস্থিতিতে, ভ্যালু পরিবর্তন হলে আপনার অবজেক্ট কখনই আপডেট হবে না।

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

আপনি যদি ভেরিয়েবলগুলি পাস করতে চান যা সময়ের সাথে সাথে আপনার অবজেক্টে পরিবর্তন করতে পারে,
`ProxyProvider` ব্যবহার করে বিবেচনা করুনঃ

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**নোটঃ**

একটি প্রভাইডারের `create`/`update` কলব্যাক ব্যবহার করার সময়, এটি লক্ষণীয় যে এই কলব্যাকটিকে ডিফল্টরূপে লেজি/অলসভাবে কল করা হয়।

এর মানে হল অন্তত একবার ভ্যালু অনুরোধ না করা পর্যন্ত, `create`/`update` কলব্যাক কল করা হবে না।

আপনি যদি `lazy` প্যারামিটার ব্যবহার করে কিছু যুক্তি প্রাক-গণনা করতে চান তবে এই আচরণটি অক্ষম করা যেতে পারেঃ

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### একটি বিদ্যমান বস্তুর ইন্সট্যান্স পুনরায় ব্যবহার করা হচ্ছেঃ

আপনার যদি ইতিমধ্যেই একটি বস্তুর ইন্সট্যান্স থাকে এবং আপনি এটি প্রকাশ করতে চান, তাহলে একটি প্রদানকারীর `.value` কনস্ট্রাক্টর ব্যবহার করা ভাল হবে৷

এটি করতে ব্যর্থ হলে আপনার অবজেক্টকে `dispose` পদ্ধতি কল হতে পারে যখন এটি এখনও ব্যবহার করা হয়।

- একটি বিদ্যমান [ChangeNotifier] প্রদান করতে `ChangeNotifierProvider.value` ব্যবহার **করুন।**

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- ডিফল্ট কনস্ট্রাক্টর ব্যবহার করে একটি বিদ্যমান [ChangeNotifier] পুনরায় ব্যবহার **করবেন না**

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### একটি ভ্যালু রিড করা

একটি ভ্যালু রিড করার সবচেয়ে সহজ উপায় হল [BuildContext] এ এক্সটেনশন পদ্ধতি ব্যবহার করেঃ

- `context.watch<T>()`,যা উইজেট পরিবর্তনগুলি রিড করতে সাহায্য করে `T` এর মধ্যে
- `context.read<T>()`, যেটি `T` রিটার্ন করে লিসেন করা ছাড়া
- `context.select<T, R>(R cb(T value))`, যা একটি উইজেটকে `T` এর একটি ছোট অংশ লিসেন করতে দেয়।

অনেকে স্ট্যাটিক পদ্ধতি ব্যবহার করতে পারে `Provider.of<T>(context)`, যা `watch` এর মতোই আচরণ করবে। যখন `listen` প্যারামিটার `false` তে সেট করা হয় (যেমন `Provider.of<T>(context, listen: false)`), তখন এটি `read` এর মতোই আচরণ করবে।

এটা লক্ষণীয় যে `context.read<T>()` কোনো উইজেট পুনর্নির্মাণ করবে না যখন ভ্যালু পরিবর্তন হবে এবং এটিকে `StatelessWidget.build`/`State.build`-এর মধ্যে কল করা যাবে না। অন্যদিকে, এটিকে এই মেথডগুলির বাইরে অবাধে কল করা যেতে পারে।

এই মেথডগুলি `BuildContext` পাস করা উইজেট থেকে শুরু করে উইজেট ট্রিতে দেখাবে এবং পাওয়া `T` প্রকারের নিকটতম ভেরিয়েবল রিটার্ন দেবে (অথবা কিছু না পাওয়া গেলে throw দেওয়া হবে)।

এই অপারেশন হল O(1)। এটি উইজেট ট্রিতে নড়াচড়ার সাথে জড়িত নয়।

[একটি ভ্যালু প্রকাশ করা](#এক্সপোজিং-এ-মান) এর প্রথম উদাহরণের সাথে মিলিত হয়ে, এই উইজেটটি একটি উন্মুক্ত `String` রিড করবে এবং "Hello World." রেন্ডার করবে।

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // আপনি `watch` প্রাপ্ত করতে চান অবজেক্ট টাইপ
      // পাস করতে ভুলবেন না!
      context.watch<String>(),
    );
  }
}
```

বিকল্পভাবে, এই পদ্ধতিগুলি ব্যবহার করার পরিবর্তে, আমরা [Consumer] এবং [Selector] ব্যবহার করতে পারি।

এগুলি পারফরমেন্স অপ্টিমাইজেশানের জন্য বা যখন প্রভাইডারের একটি `BuildContext` উত্তরসূরি পাওয়া কঠিন হয় তার জন্য উপযোগী হতে পারে।

[সচারাচর জিজ্ঞাসা](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) দেখুন
অথবা [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html) এর ডকুমেন্টেশন
এবং [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
আরও তথ্যের জন্য.

### ঐচ্ছিকভাবে একটি প্রভাইডারের উপর নির্ভর করা

কখনও কখনও, আমরা এমন ক্ষেত্র সমর্থন করতে চাই যেখানে কোনও প্রভাইডার নেই। একটি উদাহরণ হল পুনঃব্যবহারযোগ্য উইজেটগুলির জন্য যা একটি প্রভাইডারের বাইরে সহ বিভিন্ন স্থানে ব্যবহার করা যেতে পারে।

এটি করতে, `context.watch`/`context.read` কল করার সময়, জেনেরিক টাইপটিকে বাতিলযোগ্য করুন। এর পরিবর্তে যেমনঃ

```dart
context.watch<Model>()
```

যেটি একটি `ProviderNotFoundException` নিক্ষেপ করবে যদি কোনো মিল প্রভাইডার পাওয়া না যায়, তাহলে এটি করুনঃ

```dart
context.watch<Model?>()
```

যা একটি ম্যাচিং প্রভাইডার প্রাপ্ত করার চেষ্টা করবে. কিন্তু কোনোটি না পাওয়া গেলে, নিক্ষেপের পরিবর্তে `null` ফেরত দেওয়া হবে।

### MultiProvider || একাধিক প্রভাইডার

বড় অ্যাপ্লিকেশনগুলিতে অনেকগুলি ভ্যালু ইনজেকশন করার সময়, `Provider` দ্রুত সুন্দরভাবে নেস্টেড হয়ে উঠতে পারেঃ

```dart
Provider<Something>(
  create: (_) => Something(),
  child: Provider<SomethingElse>(
    create: (_) => SomethingElse(),
    child: Provider<AnotherThing>(
      create: (_) => AnotherThing(),
      child: someWidget,
    ),
  ),
),
```

এর পরিবর্তেঃ

```dart
MultiProvider(
  providers: [
    Provider<Something>(create: (_) => Something()),
    Provider<SomethingElse>(create: (_) => SomethingElse()),
    Provider<AnotherThing>(create: (_) => AnotherThing()),
  ],
  child: someWidget,
)
```

উভয় উদাহরণের আচরণ কঠোরভাবে একই। `MultiProvider` শুধুমাত্র কোডের লুক পরিবর্তন করে।

### ProxyProvider

3.0.0 থেকে, একটি নতুন ধরনের প্রভাইডার আছেঃ `ProxyProvider`।

`ProxyProvider` হল একটি প্রভাইডার যেটি অন্যান্য প্রভাইডারদের থেকে একাধিক ভ্যালুকে একটি নতুন অবজেক্টে একত্রিত করে এবং ফলাফলটি `Provider`-এ পাঠায়।

সেই নতুন অবজেক্টটি আপডেট করা হবে যখনই আমরা যে প্রভাইডারের উপর নির্ভরশীল তাদের একজন আপডেট করা হবে।

নিচের উদাহরণটি অন্য প্রভাইডার থেকে আসা কাউন্টারের উপর ভিত্তি করে অনুবাদ তৈরি করতে `ProxyProvider` ব্যবহার করে।

```dart
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => Counter()),
      ProxyProvider<Counter, Translations>(
        update: (_, counter, __) => Translations(counter.value),
      ),
    ],
    child: Foo(),
  );
}

class Translations {
  const Translations(this._value);

  final int _value;

  String get title => 'You clicked $_value times';
}
```

এটি একাধিক বৈচিত্রের অধীনে আসে, যেমনঃ

- `ProxyProvider` বনাম `ProxyProvider2` বনাম `ProxyProvider3`, ...

  ক্লাসের নামের পরে সেই সংখ্যা হল অন্যান্য প্রভাইডারের সংখ্যা যার উপর `ProxyProvider` নির্ভর করে।

- `ProxyProvider` বনাম `ChangeNotifierProxyProvider` বনাম `ListenableProxyProvider`, ...

  তারা সবাই একইভাবে কাজ করে, কিন্তু একটি `Provider`-এ ফলাফল পাঠানোর পরিবর্তে, একটি `ChangeNotifierProxyProvider` এর ভ্যালু `ChangeNotifierProvider`-এ পাঠাবে।

### সচারচর জিজ্ঞাসা

#### আমি কি আমার অবজেক্টের বিষয়বস্তু ইন্সপেক্ট করতে পারি?

ফ্লটার একটি [ডেভটুল](https://github.com/flutter/devtools) এর সাথে আসে যা দেখায় যে একটি নির্দিষ্ট মুহূর্তে উইজেট ট্রি কিরকম আছে।

যেহেতু প্রভাইডাররা উইজেট, তাই তারা সেই devtool-এও দৃশ্যমানঃ

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

সেখান থেকে, আপনি যদি একটি প্রভাইডারে ক্লিক করেন, তাহলে আপনি এটি এক্সপোস করে এমন ভ্যালু দেখতে সক্ষম হবেনঃ

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(`example` ফোল্ডার ব্যবহার করে devtool-এর স্ক্রিনশট)

#### devtool শুধুমাত্র"Instance of MyClass" দেখায়। আমি কি করতে পারি?

ডিফল্টরূপে, devtool `toString`-এর উপর নির্ভর করে, যা ডিফল্ট হয় "Instance of MyClass"।

আরো দরকারী কিছু পেতে, আপনার দুটি সমাধান আছেঃ

- Flutter থেকে [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) API ব্যবহার করুন।

  বেশিরভাগ ক্ষেত্রে, আমি আপনার অবজেক্টে [DiagnosticableTreeMixin] ব্যবহার করব, তারপরে [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html) এর একটি কাস্টম ইমপ্লিমেন্টশন হবে।

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    void debugFillProperties(DiagnosticPropertiesBuilder properties) {
      super.debugFillProperties(properties);
      // এখানে আপনার ক্লাসের সমস্ত প্রপার্টিগুলো তালিকাভুক্ত করুন।
      // আরো তথ্যের জন্য debugFillProperties এর ডকুমেন্টেশন দেখুন।
      properties.add(IntProperty('a', a));
      properties.add(StringProperty('b', b));
    }
  }
  ```

- `toString` ওভাররাইড করা।

  আপনি যদি [DiagnosticableTreeMixin] ব্যবহার করতে না পারেন (যেমন যদি আপনার ক্লাস এমন একটি প্যাকেজে থাকে যা Flutter এর উপর নির্ভর করে না), তাহলে আপনি `toString` ওভাররাইড করতে পারেন।

  এটি [DiagnosticableTreeMixin] ব্যবহার করার চেয়ে সহজ কিন্তু কম শক্তিশালীঃ

  আপনি আপনার অব্জকটের বিশদ বিবরণ প্রসারিত/সঙ্কুচিত করতে সক্ষম হবেন না।

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    String toString() {
      return '$runtimeType(a: $a, b: $b)';
    }
  }
  ```

#### `initState`-এর মধ্যে প্রোভাইডার পাওয়ার সময় আমার একটি এক্সেপশন আসে, আমি কি করতে পারি?

এই এক্সেপশনটি ঘটছে কারণ আপনি একটি লাইফ-সাইকেল থেকে এমন একটি প্রভাইডার লিসেনের চেষ্টা করছেন যা আর কখনও কল করা হবে না।

এর অর্থ হল আপনার হয় অন্য লাইফ-সাইকেলে (`build`) ব্যবহার করা উচিত, অথবা স্পষ্টভাবে উল্লেখ করা উচিত যে আপনি আপডেটের বিষয়ে চিন্তা করেন না।

যেমন, পরিবর্তেঃ

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

আপনি করতে পারেনঃ

```dart
Value value;

Widget build(BuildContext context) {
  final value = context.watch<Foo>().value;
  if (value != this.value) {
    this.value = value;
    print(value);
  }
}
```

যা `value` প্রিন্ট করবে যখনই এটি পরিবর্তিত হয় (এবং শুধুমাত্র যখন এটি পরিবর্তিত হয়)।

বিকল্পভাবে, আপনি করতে পারেনঃ

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

যা একবার `value` প্রিন্ট করবে _এবং আপডেট উপেক্ষা করবে।_

#### আমার অবজেক্টে হট-রিলোড কীভাবে পরিচালনা করবেন?

আপনি আপনার প্রদত্ত অবজেক্টকে `ReassembleHandler` ইমপ্লিমেন্ট করতে পারেনঃ

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

তারপর সাধারণত `provider` এর সাথে ব্যবহার করা হয়ঃ

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### আমি [ChangeNotifier] ব্যবহার করি এবং এটি আপডেট করার সময় আমার একটি এক্সেপশন আসে। কি ঘটেছে?

এটি সম্ভবত ঘটতে পারে কারণ আপনি [ChangeNotifier] এর কোনো একটি বংশধর থেকে পরিবর্তন করছেন _যখন উইজেট ট্রি তৈরি হচ্ছে_।

একটি সাধারণ পরিস্থিতি যেখানে এটি ঘটে যখন একটি http রিকুয়েস্ট শুরু করা হয়, যেখানে ফিউচার নটিফায়ার এর ভিতরে সংরক্ষণ করা হয়ঃ

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

এটি অনুমোদিত নয় কারণ স্টেট আপডেট সিঙ্ক্রোনাস।

এর মানে হল মিউটেশন হওয়ার _আগে_ কিছু উইজেট তৈরি হতে পারে (পুরোনো ভ্যালু পাওয়া), অন্য উইজেটগুলি মিউটেশন সম্পূর্ণ হওয়ার _পরে_ তৈরি হবে (একটি নতুন মান পাওয়া)। এটি আপনার UI তে অসঙ্গতি সৃষ্টি করতে পারে এবং তাই এটি অনুমোদিত নয়৷

পরিবর্তে, আপনার সেই মিউটেশনটি এমন জায়গায় করা উচিত যা পুরো ট্রিকে সমানভাবে প্রভাবিত করবেঃ

- সরাসরি আপনার মডেলের আপনার প্রদানকারী/নির্মাতার `create`-এর ভিতরেঃ

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  যখন কোন "বাহ্যিক প্যারামিটার" নেই তখন এটি কার্যকর।

- ফ্রেমের শেষে অ্যাসিঙ্ক্রোনাসঃ

  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>().fetchSomething(someValue);
    );
  }
  ```

  এটি সামান্য কম আদর্শ, কিন্তু মিউটেশনে প্যারমিটার পাস করার অনুমতি দেয়।

#### জটিল স্টেটের জন্য আমাকে কি [ChangeNotifier] ব্যবহার করতে হবে?

না।

আপনি আপনার স্টেট প্রতিনিধিত্ব করার জন্য যে কোনো অবজেক্ট ব্যবহার করতে পারেন. উদাহরণ স্বরূপ, একটি বিকল্প আর্কিটেকচার হল `StatefulWidget` এর সাথে মিলিত `Provider.value()` ব্যবহার করা।

এই ধরনের আর্কিটেকচার ব্যবহার করে এখানে একটি কাউন্টারের উদাহরণ রয়েছে:

```dart
class Example extends StatefulWidget {
  const Example({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  ExampleState createState() => ExampleState();
}

class ExampleState extends State<Example> {
  int _count;

  void increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _count,
      child: Provider.value(
        value: this,
        child: widget.child,
      ),
    );
  }
}
```

যেখানে আমরা এটি করে স্টেট রিড করতে পারিঃ

```dart
return Text(context.watch<int>().toString());
```

এবং স্টেটকে মডিফাই করতে পারিঃ

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

বিকল্পভাবে, আপনি আপনার নিজস্ব প্রভাইডার তৈরি করতে পারেন।

#### আমি কি আমার প্রভাইডার তৈরি করতে পারি?

হ্যাঁ. `provider` সমস্ত ছোট উপাদানগুলিকে উন্মোচিত করে যা একটি সম্পূর্ণরূপে প্রভাইডারকে তৈরি করে৷

এটা অন্তর্ভুক্তঃ

- `SingleChildStateless Widget`, যেকোনো উইজেটকে `MultiProvider`-এর সাথে কাজ করতে
  এই ইন্টারফেসটি এক্সপোস হয় একটি `package:provider/single_child_widget` এর অংশ হিসেবে।

- [InheritedProvider], জেনেরিক `InheritedWidget` যা `context.watch` করার সময় প্রাপ্ত হয়।

এখানে 'ValueNotifier' ষ্টেট হিসাবে ব্যবহার করার জন্য একটি কাস্টম প্রভাইডারের একটি উদাহরণ রয়েছে:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### আমার উইজেট প্রায়ই রিবিল্ট হয়। আমি কি করতে পারি?

`context.watch` এর পরিবর্তে, আপনি শুধুমাত্র প্রাপ্ত অবজেক্টের প্রপারটিগুলোর নির্দিষ্ট সেট শুনতে `context.select` ব্যবহার করতে পারেন।

উদাহরণস্বরূপ, যখন আপনি লিখতে পারেনঃ

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

যদি `name` ব্যতীত অন্য কিছু পরিবর্তন হয় তাহলে এটি উইজেটটিকে পুনর্নির্মাণ করতে পারে।

পরিবর্তে, আপনি শুধুমাত্র `name` প্রপারটি শুনতে `context.select` ব্যবহার করতে পারেনঃ

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

এইভাবে, `name` ছাড়া অন্য কিছু পরিবর্তন হলে উইজেটটি অপ্রয়োজনীয়ভাবে পুনর্নির্মাণ করবে না।

একইভাবে, আপনি [Consumer]/[Selector] ব্যবহার করতে পারেন। তাদের ঐচ্ছিক `child` লজিক উইজেট ট্রির শুধুমাত্র একটি নির্দিষ্ট অংশ পুনর্নির্মাণের অনুমতি দেয়:

```dart
Foo(
  child: Consumer<A>(
    builder: (_, a, child) {
      return Bar(a: a, child: child);
    },
    child: Baz(),
  ),
)
```

এই উদাহরণে, `A` আপডেট হলে শুধুমাত্র `Bar` পুনরায় তৈরি হবে। `Foo` এবং `Baz` অপ্রয়োজনীয়ভাবে পুনর্নির্মাণ হবে না।

#### আমি কি একই ধরনের টাইপ ব্যবহার করে দুটি ভিন্ন প্রভাইডার পেতে পারি?

না। আপনার কাছে একই ধরনের একাধিক প্রভাইডার শেয়ার করার সময়, একটি উইজেট তাদের মধ্যে শুধুমাত্র একটি পেতে সক্ষম হবে: যে নিকটতম।

পরিবর্তে, আপনি যদি স্পষ্টভাবে উভয় প্রভাইডারকে একটি ভিন্ন ধরনের টাইপ দেন তবে এটি সাহায্য করবে।

এর পরিবর্তেঃ

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

এরকম করুনঃ

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### আমি কি একটি ইন্টারফেস কনসিউম করতে পারি এবং একটি ইমপ্লিমেন্টশন প্রদান করতে পারি?

হ্যাঁ, কম্পাইলারকে একটি টাইপ ইঙ্গিত দিতে হবে যাতে বোঝা যায় যে ইন্টারফেসটি ব্যবহার করা হবে, তৈরিতে দেওয়া ইমপ্লিমেন্টশনের সাথে।

```dart
abstract class ProviderInterface with ChangeNotifier {
  ...
}

class ProviderImplementation with ChangeNotifier implements ProviderInterface {
  ...
}

class Foo extends StatelessWidget {
  @override
  build(context) {
    final provider = Provider.of<ProviderInterface>(context);
    return ...
  }
}

ChangeNotifierProvider<ProviderInterface>(
  create: (_) => ProviderImplementation(),
  child: Foo(),
),
```

### বিদ্যমান প্রভাইডার

`provider` বিভিন্ন ধরনের অবজেক্টের জন্য কয়েকটি ভিন্ন ধরনের `provider` প্রকাশ করে।

উপলব্ধ সমস্ত অবজেক্টের সম্পূর্ণ তালিকা [এখানে](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| নাম                                                                                                                           | ব্যাখ্যা                                                                                                                                                                         |
| ----------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | প্রভাইডারের সবচেয়ে মৌলিক ফর্ম. এটি একটি ভ্যালু/মান নেয় এবং এটি প্রকাশ করে, তা যাই হোক না কেন।                                                                                  |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | লিসেনেবল অবজেক্টের জন্য একটি নির্দিষ্ট প্রভাইডার। ListenableProvider অবেজক্টটি লিসেন করবে এবং যখনই শ্রোতাকে ডাকা হবে তখনই এটির উপর নির্ভরশীল উইজেটগুলিকে পুনর্নির্মাণ করতে বলবে। |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | ChangeNotifier-এর জন্য ListenableProvider-এর একটি স্পেসিফিকেশন। প্রয়োজনে এটি স্বয়ংক্রিয়ভাবে `ChangeNotifier.dispose` কল করবে।                                                 |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | একটি ValueListenable লিসেন করুন এবং শুধুমাত্র `ValueListenable.value` প্রকাশ করুন।                                                                                               |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | একটি স্ট্রিম লিসেন করুন এবং নির্গত সর্বশেষ মান/ভ্যালু প্রকাশ করুন।                                                                                                               |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | একটি `Future` নেয় এবং `Future` সম্পূর্ণ হলে নির্ভরশীলদের আপডেট করে।                                                                                                             |

### আমার অ্যাপ্লিকেশন একটি StackOverflowError নিক্ষেপ করে কারণ আমার অনেক প্রভাইডার আছে, আমি কি করতে পারি?

আপনার যদি অনেক বেশি সংখ্যক প্রভাইডার থাকে (150+), তাহলে এটা সম্ভব যে কিছু ডিভাইস একটি `StackOverflowError` নিক্ষেপ করবে কারণ আপনি একবারে অনেকগুলি উইজেট তৈরি করেন।

এই পরিস্থিতিতে, আপনার কয়েকটি সমাধান আছেঃ

- আপনার অ্যাপ্লিকেশানে যদি স্প্ল্যাশ-স্ক্রিন থাকে, তবে একবারে সব না করে সময়ের সাথে সাথে আপনার প্রভাইডারদের মাউন্ট করার চেষ্টা করুন।

  আপনি করতে পারেনঃ

  ```dart
  MultiProvider(
    providers: [
      if (step1) ...[
        <lots of providers>,
      ],
      if (step2) ...[
        <some more providers>
      ]
    ],
  )
  ```

  যেখানে আপনার স্প্ল্যাশ স্ক্রিন অ্যানিমেশনের সময়, আপনি করবেনঃ

  ```dart
  bool step1 = false;
  bool step2 = false;
  @override
  initState() {
    super.initState();
    Future(() {
      setState(() => step1 = true);
      Future(() {
        setState(() => step2 = true);
      });
    });
  }
  ```

- `MultiProvider` ব্যবহার করা থেকে অপ্ট আউট করার কথা বিবেচনা করুন। `MultiProvider` প্রতিটি প্রভাইডারের মধ্যে একটি উইজেট যোগ করে কাজ করে। `MultiProvider` ব্যবহার না করলে `StackOverflowError` এর লিমিট বাড়তে পারে।

[provider.of]: https://pub.dev/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.dev/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.dev/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html
