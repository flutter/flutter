[English](https://github.com/rrousselGit/provider/blob/master/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.cn/docs/development/packages-and-plugins/favorites)

对 [InheritedWidget][] 组件的上层封装，使其更易用，更易复用。

使用 `provider` 而非手动书写 [InheritedWidget][]，有以下的优势:

- 简化的资源分配与处置
- 懒加载
- 创建新类时减少大量的模板代码
- 支持 DevTools
- 更通用的调用 [InheritedWidget][] 的方式（参考 [Provider.of][]/[Consumer][]/[Selector][]）
- 提升类的可扩展性，整体的监听架构时间复杂度以指数级增长（如 [ChangeNotifier][]， 其复杂度为 O(N)）

想了解更多 `provider` 相关内容，请参考
[文档](https://pub.flutter-io.cn/documentation/provider/latest/provider/provider-library.html)

更多内容:

- [Flutter 官方的状态管理文档](https://flutter.cn/docs/development/data-and-backend/state-mgmt/simple)，
  展示如何将 `provider` 与 [ChangeNotifier][] 结合使用。
- [Flutter 架构示例](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider)，
  使用 `provider` 与 [ChangeNotifier][] 实现的具体应用。
- [flutter_bloc](https://github.com/felangel/bloc) 和
  [Mobx](https://github.com/mobxjs/mobx.dart)，在 BLoC 与 Mobx 架构中使用 `provider`。

## 自 4.x.x 版本升级到 5.0.0-nullsafety

- `FutureProvider` 和 `StreamProvider` 现在要求声明 `initialData`。

  待迁移的旧代码：

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

  迁移后：

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

- `ValueListenableProvider` 已被移除

  你只需要将 `ValueListenableBuilder` 与 `Provider` 结合使用即可：

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

## 使用

### 暴露一个值

#### 暴露一个新的对象实例

Provider 不仅可以暴露出一个值，同时也可以创建、监听和销毁它。

要暴露一个新创建的对象，你可以使用这个 provider 的默认构造。
而如果你想在开始监听时再 **创建** 一个对象，
**不推荐**使用 `.value` 构造函数，否则可能会有你预期外的副作用。

你可以阅读在 [StackOverflow 上的回答](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
以了解为什么不推荐使用 `.value` 构造函数创建值。

- **推荐** 在 `create` 内创建新对象\*\*。

  ```dart
  Provider(
    create: (_) => MyModel(),
    child: ...
  )
  ```

- **不推荐** 使用 `Provider.value` 创建新对象\*\*。

  ```dart
  ChangeNotifierProvider.value(
    value: MyModel(),
    child: ...
  )
  ```

- **不推荐** 以可能随时间改变的变量创建对象。

  在以下变量发生变化的场景里，你的对象将不会跟随值的变化而更新。

  ```dart
  int count;

  Provider(
    create: (_) => MyModel(count),
    child: ...
  )
  ```

  如果你想将可能被外界修改的变量传入给对象，请使用 `ProxyProvider`：

  ```dart
  int count;

  ProxyProvider0(
    update: (_， __) => MyModel(count),
    child: ...
  )
  ```

**请注意：**

在使用一个 provider 的 `create` 和 `update` 回调时，回调函数默认是延迟调用的。

也就是说，变量被读取时，`create` 和 `update` 函数才会被调用。

如果你想预先计算一些对象内的逻辑，可以使用 `lazy` 参数来禁用这一行为。

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### 复用一个已存在的对象实例：

如果你要将一个已经存在的对象实例暴露出来，
你应当使用 provider 的 `.value` 构造函数。

如果你没有这么做，那么在你调用对象的 `dispose` 方法时，
这个对象可能仍然在被使用，导致无法释放。

- **推荐** 使用 `ChangeNotifierProvider.value` 来提供一个当前已存在的 [ChangeNotifier][]

  ```dart
  MyChangeNotifier variable;

  ChangeNotifierProvider.value(
    value: variable,
    child: ...
  )
  ```

- **不推荐** 使用默认的构造函数来尝试复用一个已存在的 [ChangeNotifier][]

  ```dart
  MyChangeNotifier variable;

  ChangeNotifierProvider(
    create: (_) => variable,
    child: ...
  )
  ```

### 读取值

最简单的读取值的方式就是使用 `BuildContext` 上的扩展属性（由 `provider` 注入）。

- `context.watch<T>()`，widget 能够监听到 `T` 类型的 provider 发生的改变。
- `context.read<T>()`，直接返回 `T`，不会监听改变。
- `context.select<T，R>(R cb(T value))`，允许 widget 只监听 `T` 上的一部分内容的改变。

你也可以使用 `Provider.of<T>(context)` 这一静态方法，它的表现类似 `watch`，
而在你为传入 `listen: false` 参数时（例如 `Provider.of<T>(context，listen: false)`），
它的表现与 `read` 类似。

值得注意的是，`context.read<T>()` 方法不会在值变化时让 widget 重新构建，
并且不能在 `StatelessWidget.build` 和 `State.build` 内调用.
换句话说，它可以在除了这两个方法以外的任意位置调用。

上面列举的这些方法会从传入的 `BuildContext` 关联的 widget 开始，向上查找 widget 树，
并返回查找到的层级最近的 `T` 类型的 provider（未找到时将抛出错误）。

值得一提的是，该操作的复杂度是 O(1)，它实际上并不会遍历整个组件树。

结合上面第一个 [暴露一个值](#暴露一个值) 的例子，
widget 会读取暴露出的 `String` 并渲染 `Hello World`。

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

如果不想使用这些方法，你也也可以使用 [Consumer][] 和 [Selector][]。

它们往往在一些需要 **性能优化** 的场景，
以及当 widget 很难获取到 provider 所在层级以下的 `BuildContext` 时非常有用。

查阅 [FAQ](#我的-widget-重新-build-太频繁了，我应该怎么做？)
或关于 [Consumer][] 和 [Selector][] 的文档了解更多。

### 依赖可能不存在的 Provider

某些情况下，我们可能需要支持 provider 不存在的查询。
例如一个可能在 provider 以外使用的封装复用的 widget。

此时你可以将 `context.watch` 和 `context.read` 对应的 `T` 声明为可空的类型。

假设原有的代码为：

```dart
context.watch<Model>()
```

会在找不到 provider 时抛出 `ProviderNotFoundException`，而按以下方法修改后：

```dart
context.watch<Model?>()
```

在查询时会尝试找到匹配 provider，未找到时返回 `null` 而不会抛出异常。

### MultiProvider

在大型应用中注入较多内容时，`Provider` 的时候很容易产生多层嵌套：

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

这时你可以使用 `MultiProvider`：

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

以上两个例子的实际表现是一致的，`MultiProvider` 仅仅是改变了代码的书写方式。

### ProxyProvider

从 3.0.0 开始，我们提供了一种新的 provider：`ProxyProvider`。

`ProxyProvider` 能够将多个 provider 的值聚合为一个新对象，将结果传递给 `Provider`。

这个新对象会在其依赖的任意一个 provider 更新后同步更新。

下面的例子使用了 `ProxyProvider`，基于另一个 provider 的 counter 值进行转化。

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

它还有其他不同的形式：

- `ProxyProvider`、`ProxyProvider2`、`ProxyProvider3` ...

  类名后的数字是 `ProxyProvider` 依赖的 provider 的数量。

- `ProxyProvider`、`ChangeNotifierProxyProvider`、`ListenableProxyProvider` ...

  它们工作的方式是相似的，但 `ChangeNotifierProxyProvider`
  会将它的值传递给 `ChangeNotifierProvider` 而非 `Provider`。

### 常见问题

#### 我是否能查看(inspect)我的对象的内容?

Flutter 提供的 [DevTools](https://github.com/flutter/devtools) 能够展示特定时刻下的 widget 树。

既然 provider 也同样是 widget，那么它们同样能通过 DevTools 进行查看。

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

点击一个 provider，即可查看它暴露出的值:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

（以上的开发者工具截图来自于 `/example` 文件夹下的示例）

#### DevTools 只显示了「Instance of MyClass」，我应该怎么做？

默认情况下，DevTools 基于 `toString`，也就使得默认结果是「Instance of MyClass」。

如果要得到更多信息，你有两种方式:

- 使用 Flutter 提供的 [Diagnosticable](https://api.flutter-io.cn/flutter/foundation/Diagnosticable-mixin.html) API

  在大多数情况下，你只需要在对象上使用 [DiagnosticableTreeMixin][diagnosticabletreemixin] 即可，
  以下是一个自定义 [debugFillProperties](https://api.flutter-io.cn/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html)
  实现的例子:

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

- 重写 `toString` 方法

  如果你无法使用 [DiagnosticableTreeMixin][diagnosticabletreemixin]（比如你的类在一个不依赖于 Flutter 的 package 中），
  那么你可以通过重写 `toString` 方法来达成效果。

  这比使用 [DiagnosticableTreeMixin][diagnosticabletreemixin] 要更简单，但能力也有着不足：
  你无法查看你的对象内部细节。

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

#### 在 `initState` 方法里调用 provider 的获取方法时发生了异常，我应该怎么做?

异常的出现是因为你尝试在一个 **永远不会再次被调用的生命周期** 监听 provider。

这意味着你要么使用另外一个生命周期 (`build`)，要么显式声明你并不在意后续更新。

也就是说，原本你的代码是：

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

现在你应该这么写：

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

此时 print 只会在 `value` 变化时执行。

或者你也可以这么做：

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

这样只会打印一次 `value`，并且 **忽略后续的更新**。

#### 如何在热更新 (hot-reload) 时处理我的对象？

你可以将你的 provider 对象实现 `ReassembleHandler` 类：

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

它们通常会和 `provider` 一同使用:

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### 使用 [ChangeNotifier] 时，在更新后出现了异常，发生了什么？

通常这是因为 **在 widget 树正在构建时**，[ChangeNotifier][] 的某个后代更改了 ChangeNotifier。

最典型的情况是一个发起 Http 请求的 `Future` 被保存在 notifier 内部：

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

这是不被允许的，因为更改会立即生效。

也就是说，一些 widget 可能在 **变更发生前**（获取到旧的值）构建，
而另一些则可能在 **变更后**（获取到新的值）构建。
这可能造成 UI 不一致，因此是被禁止的。

所以，你应该在整个 widget 树都能受影响的位置执行变更：

- 在你的 model 的构造方法内直接调用：

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  在不需要传入形参的情况下，这是相当有用的。

- 在构建帧的末尾异步执行 (`Future.microtask`)：

  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>(context).fetchSomething(someValue);
    );
  }
  ```

  这可能不是理想的使用方式，但你可以利用这样的方法向变更传递参数。

#### 处理复杂状态时必须使用 [ChangeNotifier][] 吗？

当然不是。

你可以使用任意对象来表示你的状态。举例来说，
一个可选的架构方案是使用 `Provider.value` 配合 `StatefulWidget`。

下面是使用这种架构的计数器示例：

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

我们可以通过以下的方式来读取状态：

```dart
return Text(context.watch<int>().toString());
```

接着按以下的方式来修改状态：

```dart
return FloatingActionButton(
onPressed: () => context.read<ExampleState>().increment(),
child: Icon(Icons.plus_one),
);
```

又或者自定义 provider 进行处理。

#### 我可以创建自己的 Provider 吗？

可以，`provider`暴露出了所有构建功能完备的 provider 所需的组件，它包含:

- `SingleChildStatelessWidget`，任意的 widget 都能够与 `MultiProvider` 协作。
  这个接口暴露为 `package:provider/single_child_widget` 的一部分。
- [InheritedProvider][]，在使用 `context.watch` 时可获取的通用 `InheritedWidget`。

此处为一个使用 `ValueNotifier` 作为状态自定义 provider 的例子：
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### 我的 widget 重新 build 太频繁了，我应该怎么做？

你可以使用 `context.select` 而非 `context.watch` 来指定只监听对象的部分属性:

举例来说，你可以这么写:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

这可能导致 widget 在 `name` 以外的属性发生变化时也重新进行了构建。

你可以使用 `context.select` 来单独监听 `name` 属性：

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

如此一来，widget 就不会在 `name` 以外的属性变化时，进行不必要的重构建了。

同样，你也可以使用 [Consumer][]/[Selector][]，
可选的 `child` 参数使得 widget 树中只有指定的一部分会重构建。

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

在这个示例中，只有 `Bar` 会在 `A` 更新时重构建，
`Foo` 与`Baz` 会避免进行不必要的重复构建。

#### 我可以使用相同类型来查找两个不同的 provider 吗？

不。当你有两个相同类型的不同 provider 时，一个 widget 只会获取 **最近的一个**。

你必须显式声明两个 provider 为不同类型，而不是：

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

推荐的写法:

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### 我可以消费一个接口并且提供一个实现吗？

可以，编译器需要你提供类型提示 (`type hint`)，来指定将要被消费的接口，
同时你需要在 `create` 中提供具体实现:

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

#### 现有的 providers

`provider` 中提供了几种不同类型的「provider」，供不同类型的对象使用。

完整的可用列表参见 [此处](https://pub.flutter-io.cn/documentation/provider/latest/provider/provider-library.html)。

| 名称                                                                                                                           | 描述                                                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| [Provider](https://pub.flutter-io.cn/documentation/provider/latest/provider/Provider-class.html)                               | 最基础的 provider 组成，接收一个任意值并暴露它。                                                             |
| [ListenableProvider](https://pub.flutter-io.cn/documentation/provider/latest/provider/ListenableProvider-class.html)           | 供可监听对象使用的特殊 provider。ListenableProvider 会监听对象，并在监听器被调用时更新依赖此对象的 widgets。 |
| [ChangeNotifierProvider](https://pub.flutter-io.cn/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | 为 ChangeNotifier 提供的 ListenableProvider 规范，会在需要时自动调用 `ChangeNotifier.dispose`。              |
| [ValueListenableProvider](https://pub.flutter-io.cn/documentation/provider/latest/provider/ValueListenableProvider-class.html) | 监听 ValueListenable，并且只暴露出 `ValueListenable.value`。                                                 |
| [StreamProvider](https://pub.flutter-io.cn/documentation/provider/latest/provider/StreamProvider-class.html)                   | 监听流，并暴露出当前的最新值。                                                                               |
| [FutureProvider](https://pub.flutter-io.cn/documentation/provider/latest/provider/FutureProvider-class.html)                   | 接收一个 `Future`，并在其进入 complete 状态时更新依赖它的组件。                                              |

[provider.of]: https://pub.flutter-io.cn/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.flutter-io.cn/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.flutter-io.cn/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter-io.cn/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter-io.cn/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.flutter-io.cn/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter-io.cn/flutter/foundation/DiagnosticableTreeMixin-mixin.html
