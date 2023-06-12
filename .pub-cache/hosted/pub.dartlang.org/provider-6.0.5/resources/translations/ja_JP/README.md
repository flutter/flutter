[English](https://github.com/rrousselGit/provider/blob/master/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) <a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

[InheritedWidget]をより使いやすく、より再利用しやすくするためのラッパーです。

[InheritedWidget]を直接使う代わりに `provider` を使うことで以下の利点が得られます。

- リソースの割り当てと破棄を簡略化することができます。
- 遅延読み込み。
- 毎回新しいクラスを作成するなどのボイラープレートが大幅に削減されます。
- devtool friendly - `provider` を使うと、アプリケーションの状態が Flutter の devtool を使用して確認できるようになります。
- [InheritedWidget] の仕組みを使用する一般的な方法があります。（[Provider.of]/[Consumer]/[Selector]を参照）
- 指数関数的に複雑化するリスニング機構を持つクラスのスケーラビリティを向上させました。（例えば、通知をディスパッチする際の計算時間が O(N)となる [ChangeNotifier] があります）

`provider`についてより多くの情報が必要な方はこのライブラリの[ドキュメント](<(https://pub.dev/documentation/provider/latest/provider/provider-library.html)>)を参照してください。

以下も必要に応じて参照してください:

- `provider` と [ChangeNotifier] の使用に関して例を公開している [Flutter 公式の状態管理ドキュメント](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)。
- `provider` と [ChangeNotifier] を使用したアプリの実装に関する例を公開している [flutter_architecture_samples](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider)。
- それらのアーキテクチャ上で `provider` を使用している [flutter_bloc](https://github.com/felangel/bloc) と [Mobx](https://github.com/mobxjs/mobx.dart)。

## 4.x.x から 5.0.0-nullsafety への移行について

- 現在は `FutureProvider` と `StreamProvider` における `initialData` は必須引数になっています。

  移行を行うためには以下のようにしてください。

  **_以前（修正前）:_**

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

  **_現在（修正後）:_**

  ```dart
  FutureProvider<int?>(
    initialValue: null,
    create: (context) => Future.value(42),
    child: MyApp(),
  )

  Widget build(BuildContext context) {
    // watch<int?>にある "?" を必ず指定してください
    final value = context.watch<int?>();
    return Text('$value');
  }
  ```

- `ValueListenableProvider` は削除されました

  `ValueListenableProvider` の代わりに `Provider` と `ValueListenableBuilder` を組み合わせて使用することができます。

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

## 使い方

### 値の公開

#### 新しいオブジェクトのインスタンスを公開

Provider は値を公開するだけでなくその値を作成、リスニング、破棄することができます。

新しく生成されたオブジェクトを公開するためには Provider のデフォルトコンストラクタを使用してください。

新しくオブジェクトを作成する場合は、`.value` コンストラクタを使用しないでください。新しいオブジェクトを生成する際に `.value` コンストラクタを使用した場合には、予期しない副作用が発生する可能性があります。

詳しくは、なぜ `.value` を使用した値の生成を避けるべきなのかについて説明した [StackOverflow の回答](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build) を参照してください。

- `create` の内部で新しいオブジェクトを生成 **_してください_**。

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- オブジェクトを生成する際に `Provider.value` を使用 **_しないでください_**。

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- 何度も変更される変数からオブジェクトを生成 **_しないでください_**。

  このような場合には、変数の値が変更された時でもオブジェクトの状態が更新されることはありません。

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

もしあなたが何度も変更される可能性のある変数を使用してオブジェクトを生成したい場合には `ProxyProvider` を使用することを検討してください。

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**NOTE**:

プロバイダの `create`/`update` コールバックを使用する場合、このコールバックはデフォルトで遅延的に呼び出されることに注意する必要があります。

つまり、値が少なくとも 1 回要求されるまでは `create`/`update` コールバックは呼び出されないということです。

この動作は、何らかのロジックを事前に計算したい場合に引数である `lazy` を使用することで無効化することができます。

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### 既存のオブジェクトインスタンスの再利用

もし、既にオブジェクトのインスタンスを持っていて、それを公開したい場合はプロバイダの `.value` コンストラクタを使用するのが最適でしょう。

既に存在するオブジェクトのインスタンスを再利用する際に `.value` コンストラクタを使用しなかった場合は、オブジェクトがまだ使用されているにもかかわらず `dispose` メソッドが呼び出される可能性があります。

- 既に存在する [ChangeNotifier] を再利用するためには `ChangeNotifierProvider.value` を使用 **_してください_**。

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- 既に存在する [ChangeNotifier] をデフォルトコンストラクタを使用して再利用 **_しないでください_**。

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### 値の読み込み

値を読み取る最も簡単な方法は [BuildContext] の拡張メソッドを使用することです。

- `context.watch<T>()`: ウィジェットが `T` 上の変更をリッスンできるようにします。
- `context.read<T>()`: リッスンせずに `T` を返却します。
- `context.select<T, R>(R cb(T value))`: ウィジェットが `T` の一部の変更を監視できるようにします。

また、`watch` と似たような動作をする静的メソッド `Provider.of<T>(context)` も利用することができます。引数である `listen` を `false` に設定する (`Provider.of<T>(context, listen: false)`) と `read` と同じような挙動になります。

注意すべきは、`context.read<T>()` は値が変更されてもウィジェットを再構築しないので、 `StatelessWidget.build`/`State.build` 内では呼び出すことができません。 一方、これらのメソッド以外では自由に呼び出すことができます。

これらのメソッドは渡された `BuildContext` に関連付けられたウィジェットからウィジェットツリーを検索し、見つかった `T` の型に最も近い変数を返します。この際に何も見つからなかった場合は例外をスローします。

この検索操作の計算量は O(1)であり、ウィジェットツリーを探索することを意味しません。

これらのメソッドと最初に [値の公開](#値の公開) で挙げた例を組み合わせると、以下のようにウィジェットは公開された `String` を読み込み "Hello World." をレンダリングすることできます。

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // 必ず `watch` メソッドのジェネリクスにあなたが取得したい値の型を指定してください！
      context.watch<String>(),
    );
  }
}
```

また、これらの方法の代わりに [Consumer] と [Selector] を使用することも可能です。

これらは、パフォーマンスの最適化や、プロバイダの `BuildContext` の子孫を取得するのが困難な場合に便利です。

[Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
と [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html) に関するより詳細なドキュメントは [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) を参照してください。

### プロバイダーが存在しない場合

プロバイダーが存在しないケースに対応したい場合もあります。例えば、プロバイダの外も含むさまざまな場面で使用できる再利用可能なウィジェットの場合です。

そのためには、`context.watch`/`context.read` を呼び出す際に、ジェネリクスの型で null を許容する必要があります。

**_対応前_**

```dart
context.watch<Model>()
```

上記の場合では合致するプロバイダーが存在しない場合には必ず `ProviderNotFoundException` がスローされます。

**_対応後_**

```dart
context.watch<Model?>()
```

対応を行った上記の場合はではもし合致するプロバイダーが存在しない場合でも `ProviderNotFoundException` がスローされる代わりに null が返却されます。

### MultiProvider

大きなアプリケーションで多くの値をインジェクションする場合には、以下の例のような複雑なネストが発生することが予想されます。

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

この問題を `MultiProvider` を使用することで以下のように簡単に解決することができます。

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

両者の例の動作は全く同じですが、 `MultiProvider` を使用することでより可読性の高いコードにすることができます。

### ProxyProvider

`3.0.0` から新しい種類のプロバイダーとして `ProxyProvider` が登場しました。

`ProxyProvider` は、他のプロバイダからの複数の値を組み合わせて新しいオブジェクトを生成し、その結果を `Provider` に送信するプロバイダーです。この生成された新しいオブジェクトは、私たちが依存しているプロバイダの 1 つが更新されるたびに更新されます。

次の例では、`ProxyProvider` を使って他のプロバイダーから連携された `Counter` をもとに `Translations` を構築しています。

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

これには以下のようなバリエーションがあります

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  クラス名の末尾に付けられた数字は `ProxyProvider` が依存する他のプロバイダーの数を示しています。

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  これらはすべて同じように動作しますが、 `Provider` に結果を送る代わりに `ChangeNotifierProxyProvider` はその値を `ChangeNotifierProvider` に送ります。

### FAQ

#### オブジェクトの中身を検査することはできますか？

Flutter にはある瞬間のウィジェットツリーの状態を表示する [devtool](https://github.com/flutter/devtools) が付属されています。

プロバイダはウィジェットなので、その devtool にも表示されます。

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

検査したい特定のプロバイダーをクリックすると、そのプロバイダーの管理下にある値を確認することができます。

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(上記の画像は `example` フォルダーを使用した devtools のスクリーンショットです)

#### devtool には "Instance of MyClass"としか表示されません。どうしたらいいでしょうか？

デフォルトでは devtool が出力できる値は出力対象のオブジェクトで実装された `toString` に依存し、`toString` が正しく実装できていない場合に "Instance of MyClass" が出力されます。

これを解決するためには以下の 2 つの方法があります。

- Flutter から提供された [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) API を使用する。

  プロバイダーに依存するオブジェクトクラスで [DiagnosticableTreeMixin] をミックスインして [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html) に出力が必要なプロパティを定義してください。

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    void debugFillProperties(DiagnosticPropertiesBuilder properties) {
      super.debugFillProperties(properties);
      // このクラスで定義した全フィールドを以下のように出力プロパティとして定義します。
      // 詳細は、debugFillPropertiesのドキュメントを参照してください。
      properties.add(IntProperty('a', a));
      properties.add(StringProperty('b', b));
    }
  }
  ```

- `toString` をオーバーライドする。

  あなたが開発しているプロジェクトが Flutter に依存していない等の理由で [DiagnosticableTreeMixin] を使用できない場合は `toString` をオーバーライドしてください。

  これは [DiagnosticableTreeMixin] を使用するよりも簡単ですが、オブジェクトの詳細を展開または折りたたむことができなくなります。

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

#### `initState` の中で Provider を取得すると例外が発生します。どうすればよいですか？

この例外は二度と呼び出されないライフサイクルからプロバイダーをリッスンすることを試みているために発生します。

この例外はプロバイダーをリッスンする際には `initState` のような一度しか呼び出されないライフサイクルではなく、何度も呼び出される `build` のようなライフサイクルで使用すべきであることを示しています。また、あなたがこのプロバイダーに関する更新を無視することを明示するべきことも示しています。

例えば以下の代わりに、

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

以下のようにすることができます。

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

上記の実装では値に更新がある度に `value` が出力されます。

代わりに値の更新を無視するように以下のように定義することもできます。

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

これは `initState` が呼び出される際に一度だけ `value` を出力し、`initState` 以降の処理で発生した **_更新は無視されます_**。

#### オブジェクトのホットリロードはどのように扱えばいいですか？

プロバイダーで生成するクラスで `ReassembleHandler` を実装することでホットリロード時のハンドリングが可能になります。

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

上記の実装が完了した後の使い方は先に紹介した `Provider` の実装と同じです。

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### [ChangeNotifier] を使っているのですが更新すると例外が発生します。何が起きたのでしょうか？

これは **_ウィジェットツリーが構築されている間に_** その子孫の 1 つから [ChangeNotifier] を変更したために起こったと思われます。

このようなことが起こる典型的な状況は http リクエストを開始するときで、notifier の内部に future オブジェクトが格納される場合が考えられます。

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

状態の更新は同期的であるためこのような非同期での更新は許可されません。

これはつまり、あるウィジェットが状態の更新が起こる前に古い値を取得してビルドを行い、他のウィジェットは更新が完了した後に新しい値を取得してビルドを行うということです。この操作は UI に矛盾をもたらす可能性があるため許可されません。

その代わりに、あなたはツリー全体に均等に影響を与えるような場所でその更新を行う必要があります。

- `create` で実行されるオブジェクトのコンストラクタ処理

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  この方法は外部から引数がない場合に使用できます。

- フレーム終了時の非同期処理

  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>().fetchSomething(someValue);
    );
  }
  ```

  あまり理想的ではありませんが、更新時に引数を渡すことができます。

#### 複雑な状態の場合 [ChangeNotifier] を使用しなければならないのでしょうか？

いいえ。

状態を表すオブジェクトは何でもよいです。例えば、別のアーキテクチャとして `Provider.value()` と `StatefulWidget` を組み合わせて使うこともできます。

このようなアーキテクチャを用いた反例を紹介します。

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

以下のコードで状態の値を読み取ることができます。

```dart
return Text(context.watch<int>().toString());
```

以下のコードで状態の更新を行うことができます。

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

代わりに、あなたは独自のプロバイダーを作成することができます。

#### 独自の Provider を作成できますか?

はい、できます。
`provider` は、完成されたプロバイダを構成するすべての小さなコンポーネントを公開します。

- `SingleChildStatelessWidget` は、任意のウィジェットを `MultiProvider` で動作させるためのものです。このインターフェースは `package:provider/single_child_widget` の一部として公開されています。
- [InheritedProvider] は、`context.watch` を実行したときに得られる一般的な `InheritedWidget` です。

以下では、状態として `ValueNotifier` を使用するカスタムプロバイダーの例を示します。
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### ウィジェットが頻繁に再構築されます。どうしたらいいですか？

context.watch`の代わりに`context.select` を使用すると、取得したオブジェクトの特定のプロパティのセットだけをリッスンすることができます。

例えば以下のようにコードを書くと、

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

`name` 以外が変更されるとウィジェットがリビルドされる可能性があります。

その代わりに、`context.select` を使って `name` プロパティだけをリッスンすることができます。

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

この方法では、`name` 以外が変更されてもウィジェットが不必要に再構築されることはありません。

同様に、[Consumer]/[Selector]も使用可能です。これらのオプションの `child` 引数は、ウィジェットツリーの特定の部分のみを再構築することを可能にします。

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

この例では、`A` が更新されると `Bar` だけが再構築されます。`Foo` と `Baz` は不必要に再構築されません。

#### 同じ型で 2 種類のプロバイダーを取得できますか？

いいえ、できません。

同じ型を共有する複数のプロバイダを持つことができますが、ウィジェットはそのうちの 1 つだけを取得することができます。

その代わりに、両方のプロバイダに異なるタイプを明示的に与えると効果的でしょう。

例えば以下の代わりに、

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

以下であることが好ましいです。

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### インターフェースを使用して実装を提供することはできますか？

はい、できます。

コンパイラにはインターフェイスが使用されることを示す型ヒントを与えなければならず、その実装は `create` で提供されます。

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

### 既存のプロバイダー

`provider` は異なる型のオブジェクトに対して、いくつかの異なる種類の "provider" を公開します。

利用可能な全オブジェクトのリストは [こちら](https://pub.dev/documentation/provider/latest/provider/provider-library.html) です。

| name                                                                                                                          | description                                                                                                                                                                          |
| ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | プロバイダの最も基本的な形態。値を受け取り、その値が何であれそれを公開します。                                                                                                       |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | Listenable オブジェクトのための特定のプロバイダです。ListenableProvider はオブジェクトをリスニングし、リスナーが呼ばれるたびにそれに依存するウィジェットに再構築をリクエストします。 |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | ChangeNotifier 用の ListenableProvider の仕様です。必要な時に自動的に `ChangeNotifier.dispose` を呼び出します。                                                                      |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | ValueListenable をリッスンし、`ValueListenable.value`のみを公開します。                                                                                                              |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Stream をリッスンして、最新の値を公開します。                                                                                                                                        |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | `Future` を受け取り future の処理が完了したときに依存関係を更新します。                                                                                                              |

### 私のアプリケーションはあまりにも多くのプロバイダーを持っているので StackOverflowError をスローします。どうすればいいですか？

非常に多くのプロバイダ (150 以上) がある場合、一度に多くのウィジェットを構築することになるためデバイスによっては `StackOverflowError` がスローされる可能性があります。

このような場合、いくつかの解決策があります。

- アプリケーションにスプラッシュ・スクリーンがある場合、プロバイダを一度にマウントするのではなく時間をかけてマウントしてみてください。

  以下のような場合に、

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

  スプラッシュ・スクリーンのアニメーションの中では以下のように定義してください。

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

- `MultiProvider` を使用しないことを検討してください。

  `MultiProvider` は各プロバイダの間にウィジェットを追加することによって動作します。
  `MultiProvider` を使用しない場合は `StackOverflowError` に達するまでの制限を増やすことができます。

[provider.of]: https://pub.dev/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.dev/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.dev/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html
