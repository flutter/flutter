[English](https://github.com/rrousselGit/provider/blob/master/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) <a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

[InheritedWidget]을 더 쉽게 사용하고 보다 재사용할 수 있도록 만들어진 래퍼입니다.

[InheritedWidget]을 직접 작성하는 것 대신 `provider`를 사용함으로써, 아래와 같은 이점을 가질 수 있습니다.

- 리소스의 단순화된 할당/해제
- 지연 로딩(lazy-loading)
- 클래스를 새로 만들 때 마다 매번 작성해야했던 부분을 크게 줄임
- devtool 친화적 : Provider를 사용하면 Application State가 Flutter devtool에 표시됨
- 이러한 [InheritedWidget]들을 소비(consume)하는 일반적인 방법을 제시 ([Provider.of]/[Consumer]/[Selector] 참고)
- 복잡성이 기하급수적으로 증가하는 수신 매커니즘(listening mechanism)을 가진 클래스에 대한 확장성 향상(예 : 알림 발송에 O(N)인 [ChangeNotifier]).

`provider`에 대한 자세한 내용은 [문서](https://pub.dev/documentation/provider/latest/provider/provider-library.html)를 참고해주세요.

참고 항목:

- [The official Flutter state management documentation](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple) : `provider` + [ChangeNotifier] 사용법에 대한 쇼케이스
- [flutter architecture sample](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider) : `provider` + [ChangeNotifier]를 사용한 앱 구현
- `provider`를 아키텍처에 활용한 [flutter_bloc](https://github.com/felangel/bloc)와 [Mobx](https://github.com/mobxjs/mobx.dart)

## 4.x.x에서 5.0.0-nullsafety로의 마이그레이션

- 이제 `FutureProvider`와 `StreamProvider`를 위한 `initialData`가 필요합니다.

  마이그레이션을 위해 아래와 같은 내용은

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

  이제 이렇게 작성합니다.

  ```dart
  FutureProvider<int?>(
    initialValue: null,
    create: (context) => Future.value(42),
    child: MyApp(),
  )

  Widget build(BuildContext context) {
    // be sure to specify the ? in watch<int?>
    final value = context.watch<int?>();
    return Text('$value');
  }
  ```

- `ValueListenableProvider`가 삭제되었습니다.

  마이그레이션 시, 대신 `Provider`를 `ValueListenableBuilder`와 결합하여 사용할 수 있습니다.

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

## 사용법

### 값 노출하기

#### 새 객체 인스턴스 노출하기

Providers는 단순히 값을 노출 시켜줄 뿐만 아니라, 값의 생성(create), 수신(listen) 그리고 해제(dispose)를 할 수 있도록 합니다.

신규 생성한 객체를 노출하기 위해 provider의 기본 생성자를 사용하세요.
만약 객체를 **생성**하고 싶다면 `.value` 생성자를 _사용하지마세요._ 그렇지 않으면 의도치 않은 부작용이 나타날 수 있습니다.

값을 생성하기 위해 `.value` 생성자를 사용하는 것이 왜 바람직하지 않은지 확인하려면 [StackOverflow 답변](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)을 확인하세요.

- **DO** : `create` 안에서 신규 오브젝트를 생성하세요.

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- **DON'T** : 객체를 생성하기 위해 `Provider.value`를 사용하지 마세요.

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- **DON'T** : 시간에 따라 변경될 수 있는 변수로 객체를 만들지 마세요.

  만약 그렇게 생성하였다면, 생성된 객체는 값이 변화해도 업데이트되지 않습니다.

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

만약 시간에 따라 변경될 수 있는 변수를 객체에 전달하려면
`ProxyProvider` 사용을 고려하세요.

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**NOTE**:

provider의 `create`/`update` 콜백을 사용할 때, 이 콜백이 기본적으로 Lazy하게 호출된다는 점에 유의해야합니다.

즉, 해당 값을 한 번 이상 호출하기 전에는 `create`/`update` 콜백이 호출되지 않습니다.
이 동작은 `lazy` 파라미터를 사용해 일부 로직을 사전 연산(pre-compute)하고자 하는 경우 비활성화 될 수 있습니다.

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### 기존 객체 인스턴스를 재사용하기

객체 인스턴스가 이미 생성되었고, 해당 객체를 노출시키길 원하는 경우 provider의 `.value` 생성자를 사용하는 것이 가장 좋습니다.

그렇지 않으면 객체가 아직 사용되고 있는 도중에 `dispose` 메소드가 호출될 수 도 있습니다.

- **DO** : 이미 존재하는 [ChangeNotifier]를 공급(provide)하기 위해서 `ChangeNotifierProvider.value`를 사용하세요.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **DON'T** : 이미 존재하는 [ChangeNotifier]를 기본 생성자를 사용해서 재사용하지 마세요.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### 값 읽기

값을 읽는 가장 쉬운 방법은 [BuildContext]의 확장 메소드를 활용하는 것입니다.

- `context.watch<T>()` : 위젯이 `T`의 변화를 감지할 수 있도록 합니다.
- `context.read<T>()` : `T`를 변화 감지 없이 return 합니다.
- `context.select<T, R>(R cb(T value))` : `T`의 일부 작은 영역에 대해서만 위젯이 변화를 감지할 수 있도록 합니다.

또한 `watch`와 유사하게 동작하는 정적 메소드(static method)인 `Provider.of<T>(context)`를 사용할 수도 있습니다.
`Provider.of<T>(context, listen: false)`처럼 `listen` 파라미터를 `false`로 하면 `read`와 유사하게 동작합니다.

`context.read<T>()`는 값이 변경되었을 때 위젯을 재빌드하지 않음으로 `StatelessWidget.build`/`State.build` 안에서 호출될 수 없음을 유의하세요.
반면, 이러한 메소드들 밖에서는 자유롭게 호출될 수 있습니다.

이러한 메소드들은 전달된 `BuildContext`와 관련된 위젯에서 시작해 위젯 트리에서 발견되며,
발견된 가장 가까운 `T` 타입 변수를 반환합니다. (아무것도 찾을 수 없는 경우 예외가 발생 합니다.)

이 작업은 O(1)입니다. 작업에 위젯 트리를 순차적으로 탐색하는 일이 포함 되어있지 않습니다.

이 위젯은 첫 번째 예시인 [값 노출하기](#값-노출하기)에서 노출된 `String`을 읽고 "Hello World."를 렌더합니다.

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // Don't forget to pass the type of the object you want to obtain to `watch`!
      context.watch<String>(),
    );
  }
}
```

이러한 메소드들을 사용하는 대신에, 우리는 [Consumer]와 [Selector]를 사용할 수 있습니다.

이 기능은 성능을 최적화하거나, provider의 `BuildContext` 하위 항목에 접근하기 어려울 때 유용하게 활용할 수 있습니다.

더 많은 정보가 필요하다면 아래와 같은 문서를 참고하세요.

- [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do)
- [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html) 문서
- [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html) 문서

### provider의 선택적 의존

때때로 우리는 provider가 존재하지 않는 경우를 지원하고 싶을 수도 있습니다.
예를 들어 provider 외부 등 다양한 위치에서 사용될 수 있는 위젯의 경우가 있습니다.

그렇게 하기 위해서, `context.watch`/`context.read`을 호출할 때 generic 타입 대신 nullable 타입을 사용합니다.
예를 들어 아래와 같이 사용하는 경우,

```dart
context.watch<Model>()
```

매칭되는 provider를 찾지 못한 경우 `ProviderNotFoundException` 예외가 발생합니다.
대신 아래와 같이 사용하면,

```dart
context.watch<Model?>()
```

매칭되는 provider를 찾지 못하더라도 예외를 발생시키는 대신, `null`을 반환합니다.

### MultiProvider

규모가 큰 어플리케이션에서 많은 값을 주입하면 `Provider`가 급격하게 중첩될 수 있습니다.

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

이를 아래와 같이 작성할 수 있습니다.

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

두 코드는 완전히 동일하게 동작합니다.
`MultiProvider`는 오직 코드의 외관을 바꿔줄 뿐입니다.

### ProxyProvider

3.0.0 버젼부터 새로운 provider인 `ProxyProvider`가 추가되었습니다.

`ProxyProvider`는 다른 provider들의 여러 값을 하나의 객체로 묶어 `Provider`로 전달하는 provider입니다.

그러면 해당 신규 객체는 우리가 의존하는 provider 중 하나가 업데이트될 때마다 업데이트됩니다.

아래 예제에서는 다른 provider에서 온 `counter`를 기반으로 `translations`를 빌드하기 위해 `ProxyProvider` 를 사용하고 있습니다.

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

이것은 아래와 같은 다양한 변형이 가능합니다.

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  클래스 이름 뒤의 숫자는 `ProxyProvider`가 의존하는 다른 공급자의 수입니다.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  모두 비슷하게 동작하지만,
  `ChangeNotifierProxyProvider`는 값을 그 결과를 `Provider`를 보내는 대신, `ChangeNotifierProvider`로 보냅니다.

### FAQ

#### 내 객체들을 인스펙터에서 확인할 수 있나요?

Flutter는 지정된 시점에 위젯 트리가 어떤 것인지 보여주는 [devtool](https://github.com/flutter/devtools)이 함께 제공됩니다.

provider는 위젯이기 때문에 마찬가지로 devtool에서 볼 수 있습니다.

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

여기에서 한 provider를 클릭하면 해당 provider가 노출하고 있는 값을 볼 수 있습니다.

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(`example` 폴더를 사용하는 devtool 스크린샷)

#### devtool에 "Instance of MyClass" 밖에 안보여요. 어떻게 해야하나요?

기본적으로 devTool은 `toString`에 의존하기 때문에 기본 설정인 "Instance of MyClass"로 보여집니다.

보다 유용하게 사용하기 위해서, 다음과 같은 두 가지 솔루션이 있습니다.

- Flutter의 [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) API를 사용하세요.

  대부분의 경우 객체에 [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html)로 커스텀한 [DiagnosticableTreeMixin]를 사용

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    void debugFillProperties(DiagnosticPropertiesBuilder properties) {
      super.debugFillProperties(properties);
      // list all the properties of your class here.
      // See the documentation of debugFillProperties for more information.
      properties.add(IntProperty('a', a));
      properties.add(StringProperty('b', b));
    }
  }
  ```

- `toString`을 재정의(override) 하세요.

  만약 [DiagnosticableTreeMixin]를 사용할 수 없다면 (Flutter를 사용하지 않는 패키지 등),
  `toString`를 재정의해서 사용할 수 있습니다.

  이것은 [DiagnosticableTreeMixin]를 사용하는 것 보다 쉽지만, 객체의 세부정보를 확장하거나 축소할 수 없는 만큼 보다 덜 강력합니다.

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

#### Provider를 `initState`안에 넣었을 때 예외가 발생합니다. 어떻게 해야하나요?

이 예외는 다시 호출되지 않는 생명 주기(life-cycle)에서 provider를 감지하려고 하기 때문에 발생합니다.

때문에 `build`와 같은 다른 생명 주기에서 사용하거나, 업데이트에 관련 없음을 명시해주어야합니다.

때문에 아래와 같이 작성하는 대신,

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

이렇게 작성할 수 있습니다.

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

이는 값이 변경될 때마다(그리고 변경될 때만) '`value`가 출력됩니다.

또는 다음과 같이 작성할 수 있습니다.

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

이는 `value`를 한번 출력하고 _업데이트를 무시합니다._

#### 객체들의 hot-reload를 어떻게 다룰 수 있나요?

제공된 객체에 `ReassembleHandler`를 구현할 수 있습니다.

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

그 후 일반적으로 `provider`와 함께 사용합니다.

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### [ChangeNotifier]를 사용하며 업데이트할 때 예외가 발생합니다. 무슨 일이 일어나고 있는 거죠?

_위젯 트리가 빌드되는 동안_ 하위 항목 중 하나에서 [ChangeNotifier]를 수정하고 있기 때문에 문제가 발생할 수 있습니다.

일반적으로 이러한 상황은 notifier 안에 future가 저장된 상태에서 http 요청을 시작할 때 발생합니다.

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

상태 업데이트가 동기화되어있으므로 이 작업은 허용되지 않습니다.

이는 즉, 어떤 위젯은 변경이 일어나기 전에 빌드될 수 있으며(오래된 값을 받음), 또 어떤 위젯은 변경이 완료된 후에 빌드될 수 있습니다(새로운 값을 받음).
이로인해 UI에 불일치가 발생할 수 있으므로, 이는 허용되지 않습니다.

대신 전체 트리에 동일하게 영향을 미치는 위치에서 변경을 수행해야합니다.

- 모델의 provider 생성자 `create`인자 안에서 직접 수행하기 :

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  외부 변수가 없는 경우 유용합니다.

- 프레임 끝에 비동기식으로 수행하기 :
  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>().fetchSomething(someValue);
    );
  }
  ```
  약간 덜 이상적이지만, 변경 사항에 매개변수를 전달할 수 있습니다.

#### 복잡한 상태의 경우 [ChangeNotifier]를 써야하나요?

아닙니다.

모든 객체를 사용하여 상태를 나타낼 수 있습니다. 예를 들어 대체 구조로 `Provider.value()`와 `StatefulWidget`를 결합하여 사용할 수 있습니다.

아래 예시는 이러한 구조를 사용한 반증 사례입니다.

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

다음 작업을 통해 상태를 읽을 수 있습니다.

```dart
return Text(context.watch<int>().toString());
```

또한 다음과 같이 상태를 수정할 수 있습니다.

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

또는 직접 provider를 만들 수도 있습니다.

#### 나만의 provider를 만들 수 있나요?

네. `provider`는 provider를 완전하게 구성하는 작은 컴포넌트들을 모두 공개하고 있습니다.

이는 아래와 같은 것들을 포함합니다.

- 어떤 위젯이던지 `MultiProvider`와 함께 동작하도록 만들어주는 `SingleChildStatelessWidget`.
  이 인터페이스는 `package:provider/single_child_widget`의 일부로 노출됩니다.

- `context.watch`를 할 때 얻을 수 있는 일반적인 `InheritedWidget`인 [InheritedProvider].

다음은 `ValueNotifier`를 상태로 사용하는 사용자 지정 provider의 예입니다.
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### 위젯이 너무 자주 재빌드됩니다. 어떻게 하나요?

`context.watch`를 사용하는 대신, 객체의 특정한 부분 만을 추적하는 `context.select`를 사용할 수 있습니다.

예를 들어 다음과 같이 작성한다면,

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

`name`이 아닌 다른 프로퍼티가 변경되어도 위젯이 재빌드될 것입니다.

대신에 `context.select`를 사용해 `name` 프로퍼티만 추적하게하면,

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

이렇게 하면 `name` 프로퍼티가 아닌 변화가 발생하더라도 불필요하게 위젯을 재빌드하지 않습니다.

유사하게 [Consumer]/[Selector]를 사용할 수도 있습니다. 이들이 가지고 있는 `child` 매개변수는 위젯 트리의 특정 부분만 재빌드할 수 있도록 해줍니다.

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

위 예시에서 `A`가 업데이트 되었을 때 오직 `Bar`만 재빌드됩니다. `Foo`는 불필요하게 재빌드되지 않습니다.

#### 동일한 타입을 사용하는 다른 provider들을 함께 사용할 수 있나요?

없습니다. 여러 provider가 동일한 타입을 공유할 수 있지만, 위젯은 가장 가까운 상위 provider 하나 만을 가져올 수 있습니다.

대신 두 provider에게 명시적으로 다른 타입을 제공하면 좋습니다.

아래와 같이 작성하는 대신,

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

이렇게 작성하는 것이 좋습니다.

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### 인터페이스를 사용하거나 구현을 제공할 수 있나요?

네, 생성 시 제공된 구현과 함께 인터페이스가 사용될 것임을 나타내는 형식 힌트를 컴파일러에 제공해야 합니다.

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

### 현재 제공되는 provider

`provider` 는 다른 객체 타입에 대해 몇 가지 다른 "provider"를 제공합니다.

모든 객체의 리스트는 [여기](https://pub.dev/documentation/provider/latest/provider/provider-library.html)에서 확인할 수 있습니다.

| 이름                                                                                                                          | 설명                                                                                                                                                        |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | The most 기본적인 provider 형태. 어떤 값이던 간에 값을 노출시킵니다.                                                                                        |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | Listenable 객체를 위한 특수한 provider. ListenableProvider는 listener가 호출될 때마다 오브젝트를 수신하고 오브젝트에 종속된 위젯을 재구성하도록 요청합니다. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | ChangeNotifier용 ListenableProvider 사양. 필요할 때 자동으로 `ChangeNotifier.dispose`를 호출합니다.                                                         |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | ValueListenable을 수신하고, `ValueListenable.value`만을 노출합니다.                                                                                         |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | 스트림을 수신하고 최신 값을 표시합니다.                                                                                                                     |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | `Future`를 받고, 완성되었을 때 의존된 객체를 업데이트합니다.                                                                                                |

### 내 애플리케이션에서 너무 많은 프로바이더를 가지고 있어 StackOverflowError 예외가 발생합니다. 어떻게 해결하면 좋을까요?


만약 매우 많은 프로바이더(150 이상)가 있는 경우, 한 번에 많은 위젯을 빌드되기 때문에 디바이스에 따라서는 `StackOverflowError` 예외가 발생될 가능성이 있습니다.

이 경우 몇 가지 해결책이 있습니다.

- 만약 애플리케이션에 스플래시 화면이 있는 경우, provider를 한번에 마운트하는 대신 시간이 지남에 따라 마운트해 보세요.

  아래의 예제코드와 같을 경우:

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

  스플래시 스크린 애니메이션에서 아래와 같이 처리해보세요.

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

- `MultiProvider`를 사용하지 않는 것을 고려해보세요.
  - `MultiProvider` 는 `각 프로바이더의 사이에 위젯을 추가하는 것`으로 동작합니다.
  - `MultiProvider` 를 사용하지 않는 경우는 `StackOverflowError` 에 이를 때까지의 제한을 늘릴 수가 있습니다.


## Sponsors

<p align="center">
  <a href="https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg">
    <img src='https://raw.githubusercontent.com/rrousselGit/freezed/master/sponsorkit/sponsors.svg'/>
  </a>
</p>

[provider.of]: https://pub.dev/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.dev/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.dev/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html
[buildcontext]: https://api.flutter.dev/flutter/widgets/BuildContext-class.html
