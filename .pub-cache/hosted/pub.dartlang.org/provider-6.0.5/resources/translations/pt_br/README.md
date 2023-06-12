[English](https://github.com/rrousselGit/provider/blob/master/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md)

[![Build Status](https://travis-ci.org/rrousselGit/provider.svg?branch=master)](https://travis-ci.org/rrousselGit/provider)
[![pub package](https://img.shields.io/pub/v/provider.svg)](https://pub.dev/packages/provider) [![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

Um wrapper para o [InheritedWidget] tornando-os mais fáceis de usar e reutilizáveis.

Usando o `provider` ao invés de usar [InheritedWidget], você ganha:

- alocação/disposição simplificada de recursos
- lazy-loading
- redução considerável de código desnecessário toda vez que se cria uma class
- compatível com devtools
- uma maneira comum de consumir [InheritedWidget]s (consulte [Provider.of]/[Consumer]/[Selector])
- maior escalabilidade para classes com um mecanismo de escuta que cresce exponencialmente em complexidade (como [ChangeNotifier], que é O(N) para notificações de despacho).

Para ler mais sobre o `provider`, veja a [documentação](https://pub.dev/documentation/provider/latest/provider/provider-library.html).

## Migrando de 4.x.x para 5.0.0-nullsafety

- `initialData` para `FutureProvider` e `StreamProvider` é mandatório.

  Para migrar, o que antes era:

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

  E agora:

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

- `ValueListenableProvider` foi removido

  Para migrar, você pode usar `Provider` combinado com `ValueListenableBuilder`:

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

## Uso

### Expondo um valor

#### Expondo a instância de um novo objeto

Providers permitem não apenas expor um valor, mas também criar/escutar/descartar os mesmos.

Para expor um obejto criado, use o construtor padrão do provider.
Não use `.value` se quiser **criar** um objeto ou terá efeitos indesejados.

Veja [esta resposta no stackoverflow](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
que explica em detalhes porque usar o construtor `.value` não é recomendado.

- **CRIE** um novo objeto dentro de `create`.

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- **NÃO** use `Provider.value` para criar o seu objeto.

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- **NÃO** crie seu objeto de variáveis que podem mudar com o tempo.

  Nestas situações, seu objeto nunca poderá ser atualizado quando um valor for alterado.

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

Se você quiser passar variáveis que pode mudar para seu objeto, use o `ProxyProvider`:

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**NOTA**:

Quando usar o callback `create`/`update` de um provider, é importante salientar que este callback é chamado de forma lazy por padrão.

Isto significa que, até que o valor seja solicitado no mínimo uma vez, o `create`/`update` não será chamado.

Este comportamento pode ser desativado se você quiser computar previamente com alguma lógica, usando o parâmetro 'lazy':

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### Reutilizar uma instância de um objeto existente.

Se você já possui uma instância de um objeto e deseja expô-la, você deve usar o construtor `.value` do provider.

Se não o fizer, o método `dispose` poderá ser chamado mesmo que ainda esteja em uso.

- **USE** `ChangeNotifierProvider.value` para prover um [ChangeNotifier] existente

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **NÃO** reuse um [ChangeNotifier] existente com o construtor padrão

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### Lendo um valor

A forma mais fácil de ler um valor é usando os métodos extensões do [BuildContext]:

- `context.watch<T>()`, faz o widget escutar mudanças em `T`
- `context.read<T>()`, retorna `T` sem escutar
- `context.select<T, R>(R cb(T value))`, permite o widget escutar apenas uma pequena parte de `T`

Ou use o método estático `Provider.of<T>(context)`, que é semelhante ao `watch` e qunado passado `false` para o parâmetro `listen` como `Provider.of<T>(context,listen: false)` se comporta de maneira similar ao `read`.

É importante notar que `context.read<T>()` não fará o widget reconstruir quando o valor for alterado e não podee estar dentro de `StatelessWidget.build`/`State.build`. Porém pode ser chamado fora destes métodos.

Esse método irá olhar na árvore de widgets acima começando pelo widget associado
ao `BuildContext` passado e retornará a variável mais próxima do tipo
`T` que foi encontrada (ou lançará uma exceção se nada for encontrado).

É importante notar que esta operação é O(1). Não envolve caminhar pela árvore de widget.

Combinado com o primeiro exemplo de [expondo um valor](#expondo-um-valor), esse
widget irá ler a variável `String` exposta e renderizar "Hello World."

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

Ao invés de usar `Provider.of` podemos usar [Consumer] e [Selector].

Isto poder ser útil para performance ou quando for difícil de obter um descendente `BuildContext` do provider.

Veja o [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) ou a documentação do [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
e [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
para mais informações.

### MultiProvider

Quando injetando vários valores em grandes aplicações, `Provider` pode rapidamente ficar complexo com vários descendentes:

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

Para:

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

O comportamento de ambos é exatamente o mesmo. `MultiProvider` apenas muda o visual do código.

### ProxyProvider

Desde o 3.0.0, há um novo tipo de provider: `ProxyProvider`.

`ProxyProvider` é um provider que combina vários valores de outros providers em um novo objeto e envia o resultado para o `Provider`.

Este novo objeto irá ser atualizado quando o provider que depende dele for atualizado.

O exemplo abaixo usa `ProxyProvider` para construir translações com base no contador de outro provider.

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

Vem com outras opções tais como:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  O digito depois da classe é o número de outros providers que no qual o
  `ProxyProvider` depende.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  Funcionam da mesma maneira, mas ao invés de enviar o resultado para um `Provider`,
  o `ChangeNotifierProxyProvider` envia o valor para `ChangeNotifierProvider`.

### FAQ

#### Posso inspecionar o conteúdo dos meus objetos?

Flutter vem com [devtool](https://github.com/flutter/devtools) que mostra
a árvore de widgets do momento.

Como os providers são widgets, eles também são visíveis no devtool:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

Daqui, se clicar em um provider, você verá o valor que ele expõe:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(screenshot do devtools usando a pasta `example`)

#### O devtool só mostra "Instance of MyClass". O que fazer?

Por padrão, o devtool usa `toString`, que tem como padrão "Instance of MyClass".

Para algo mais útil, existem duas soluções:

- use API [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) do Flutter

  Para a maioria dos casos, isso é feito usando [DiagnosticableTreeMixin] nos seus objetos, seguido de uma implementação customizada de [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html).

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

- sobrescreva `toString`.

  Se não for possbile usar [DiagnosticableTreeMixin] (como se sua classe estiver em um pacote que não depende do Flutter), você pode simplesmente sobrescrever `toString`.
  Isto é mais fácil que usar [DiagnosticableTreeMixin] mas menos poderoso:
  Não será possível expandir/colapsar os detalhes de seus objetos.

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

#### Recebo uma exceção quando obtenho Providers dentro de um `initState`. O que fazer?

Esta exceção acontece pois você está tentando escutar um provider de um ciclo-de-vida que nunca será chamado de novo.

Significa que você precisa usar um outro ciclo-de-vida (`build`), ou explicitamente especificar que você nao importa com atualizações.

Como, ao invés de:

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

você pode:

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

que ira imprimir `value` toda vez que mudar (e somente quando mudar).

Você também pode:

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

Que vai mostrar `value` uma vez _e ignorar atualizações._

#### Como lidar com hot-reload nos meus objetos?

Você pode fazer seu objeto provider implementar `ReassembleHandler`:

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

E usar normalmente com `provider`:

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### Eu uso [ChangeNotifier] e recebo uma exceção quando o atualizo, o que está acontecendo?

Possivelmente você esta tentando modificar o [ChangeNotifier] de um de seus descendentes _enquanto a árvore de widgets está sendo construída_.

Uma situação comum é quando se inicia uma solicitação http, onde o futuro é armazenado em um notifier:

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

Isto não é permitido, pois a modificação precisa ser imediata.

O que significa que alguns widgets podem ser construídos _antes_ da mutação acontecer (recebendo um valor antigo),
equanto outros serão construídos _depois_ da mutação se completar (recebendo um novo valor).
Isto pode gerar inconsistências na sua interface gráfica e por isso não é permitido.

Ao invés disso, você pode fazer a mutação em algum lugar que afeta toda a árvore igualmente:

- diretamente dentro de `create` do seu provider/construtor do seu modelo:

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  Isto pode ser útil quando nao há 'parametro externo'.

- de forma assíncrona no final de um frame:

  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>(context).fetchSomething(someValue);
    );
  }
  ```

  É menos ideal, mas permite passar parâmetros para a mutação.

#### Preciso usar [ChangeNotifier] for complex states?

Não.

Você pode utilizar qualquer objeto para representar o seu estado. Por exemplo, uma arquitetura
alternativa é usar o `Provider.value()` combinado com um `StatefulWidget`.

Aqui está um exemplo de contador usando essa arquitetura:

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

Onde podemos ler o estado usando:

```dart
return Text(context.watch<int>().toString());
```

e modificar o estado com:

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

Alternativamente, você pode criar o seu próprio provider.

#### Posso criar o meu próprio Provider?

Sim. O `provider` expõe todos os pequenos componentes que tornam um provider completo.

Isso inclui:

- `SingleChildCloneableWidget`, para fazer com que qualquer widget funcione com o `MultiProvider`.
  Esta interface é exposta como porte do `package:provider/single_child_widget`

- [InheritedProvider], o `InheritedWidget` generico é obtido usando o `Provider.of`.

Aqui está um exempo de um provider cutomizado que usa o `ValueNotifier` como estado:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### Meu widget é reconstruído com frequência, o que posso fazer?

Ao invés de usar `context.watch`, pode usar `context.select` para escutar algumas partes específicasa do objeto.

Por exemplo:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

Fará o widget reconstruir quando algo que não seja 'nome' mudar.

Ao invés, você pode usar `context.select` para escutar somente a propriedade `name`:

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

Desta forma, o widget não ira necessariamente reconstruir se algo que não seja `name` mudar.

De forma parecida, você pode usar [Consumer]/[Selector].

O argumento opcional `child` permite a reconstrução de uma parte específica da árvore de widgets:

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

Nesse exemplo, somente `Bar` será reconstruído quando `A` for atualizado. `Foo` e `Baz` não
serão reconstruídos desnecessariamente.

#### Posso obter dois providers diferentes usando o mesmo tipo?

Não. Embora você possa ter vários providers compartilhando o mesmo tipo, um widget
só ira conseguir obter apenas um deles: o ancestral mais próximo.

Ao invés disso, você deve dar explicitamente tipos diferentes a ambos providers.

Em vez de:

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

Prefira:

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### Posso consumir uma interface e fazer a implementação?

Sim, uma dica de tipo tem que ser especificada para o compilador para indicar que a interface será consumida, com a implmentação do create.

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

## Providers existentes

O `provider` expõe alguns diferentes tipos de "provider" para diferentes tipos de objetos.

A lista completa de todos os objetos disponiveis está [aqui](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| nome                                                                                                                          | descrição                                                                                                                                                                                                |
| ----------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | A forma mais básica de provider. Ele pega um valor e o expõe, qualquer que seja o valor.                                                                                                                 |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | Um provider especifico para objetos que possam ser ouvidos. O ListenableProvider irá ouvir o objetor e pedir para que os widgets que dependam dele sejam reconstruídos sempre que o ouvinte for chamado. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | Uma especificação do ListenableProvider para ChangeNotifier. Ele chama automaticamente o `ChangeNotifier.dispose` quando preciso.                                                                        |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Escuta um ValueListenable e apenas expoe o `ValueListenable.value`.                                                                                                                                      |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Escuta uma Stream e expoe o ultimo valor emitido.                                                                                                                                                        |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Recebe um `Future` e atualiza os depedentes quando o future for atualizado.                                                                                                                              |

[provider.of]: https://pub.dev/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.dev/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.dev/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html
