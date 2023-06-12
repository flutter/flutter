[English](https://github.com/rrousselGit/provider/blob/master/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](./resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) [![Gitter](https://badges.gitter.im/flutter_provider/community.svg)](https://gitter.im/flutter_provider/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

Un wrapper alrededor de [InheritedWidget]
para hacerlo más fácil de usar y más utilizable.

Al utilizar `provider` en lugar de escribir manualmente los [InheritedWidget], obtendrás:

- asignación/eliminación simplificada de los recursos
- lazy-loading
- un boilerplate muy reducido en lugar de hacer una nueva clase cada vez.
- compatibilidad con devtools
- una manera común de consumir esto [InheritedWidget]s (ver [Provider.of]/[Consumer]/[Selector])
- incrementa la escalabilidad de tus clases con un mecanismo de escucha (listener) que crece exponencialmente
  en complejidad (tales como [ChangeNotifier], el cual es O(N²) al enviar notificaciones)

Para leer más acerca de `provider`, leé su [documentación](https://pub.dev/documentation/provider/latest/provider/provider-library.html).

Ver también:

- [La documentación oficial de Flutter en gestión de estado](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple), la cual muestra como usar `provider` + [ChangeNotifier]
- [Ejemplos de arquitectura en Flutter](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider), la cual contiene una implementación de una app usando `provider` + [ChangeNotifier]
- [flutter_bloc](https://github.com/felangel/bloc) y [Mobx](https://github.com/mobxjs/mobx.dart), los cuales usan `provider` en su arquitectura.

## Migrar de v3.x.0 a v4.0.0

- Los parámetros `builder` e `initialBuilder` de providers son eliminados.

  - `initialBuilder` deberá ser reemplazado por `create`.
  - `builder` de "proxy" providers deberá ser reemplazado por `update`
  - `builder` de providers clásicos deberá ser reemplazado por `create`.

- las nuevas callbacks `create`/`update` son lazy-loaded, lo cual significa que serán llamadas
  la primera vez que su valor sea leído, en lugar de la primera vez que el usuario sea creado.

  Si esto no se quiere, puedes deshabilitar el lazy-loading pasando el valor `lazy: false` a
  el provider de tu elección.

  ```dart
  FutureProvider(
    create: (_) async => doSomeHttpRequest(),
    lazy: false,
    child: ...
  )
  ```

- `ProviderNotFoundError` es renombrado a `ProviderNotFoundException`.

- La interface `SingleChildCloneableWidget` es eliminada y reemplazada por un nuevo tipo
  de widget `SingleChildWidget`.

  Ve [este issue](https://github.com/rrousselGit/provider/issues/237) para detalles
  acerca de como migrar.

- [Selector] ahora comparará más profundamente el valor anterior y nuevo si estas son colecciones.

  Si este no quiere, puedes revertir el comportamiento pasando el parámetro `shouldRebuild` al
  [Selector]

  ```dart
  Selector<Selected, Consumed>(
    shouldRebuild: (previous, next) => previous == next,
    builder: ...,
  )
  ```

- `DelegateWidget` y su familia han sido eliminados. En su lugar, para providers personalizados tendrán
  subclasses directas [InheritedProvider] o un provider existente.

## Uso

### Exponiendo un valor

#### Exponiendo una nueva instancia del objeto

Los providers permiten no solo exponer un valor, sino también crear/escuchar/eliminar.

Para exponer un objeto recién creado, utilice el constructor por defecto de un provider.
_No uses_ el constructor `.value` si quieres **crear** un objeto, o
podrías tener efectos secundarios no deseados.

Ve [esta respuesta de stackoverflow](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
la cual explica en mayor detalle, por qué usar el constructor `.value` para crear nuevos valores no es óptimo.

- **DO** crea un nuevo objeto dentro de `create`.

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- **DON'T** usar `Provider.value` para crear tu objeto.

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- **DON'T** crear tu objeto de variables que pueden cambiar en el tiempo.

  En esta situación, tu objeto nunca será actualizado cuando el
  valor cambie.

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

Si quieres pasar variables que puede cambiar en el tiempo de tu objeto,
considera utilizar `ProxyProvider`:

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**NOTA**:

Cuando se utiliza la llamada de `create`/`update` de un provider, vale la pena señalar que en esta llamada
se llama `lazy` por defecto.

Lo que esto significa es que, hasta que el valor sea solicitado al menos una vez, el `create`/`update`
no se llamarán las callback.

Este comportamiento puede ser desactivado si quieres precalcular algo de lógica, usando el parámetro `lazy`:

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### Reutilizando una instancia de un objeto existente:

Si ya tienes una instancia de un objeto y quieres exponerlo,
deberías usar el constructor `.value` de un proveedor.

Si no lo hace, puede llamar al método `dispose` de tu objeto cuando todavía está en uso.

- **DO** usa `ChangeNotifierProvider.value` para un provider tipo
  [ChangeNotifier] existente.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **DON'T** reutiliza un [ChangeNotifier] existente usando su constructor por defecto.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### Leyendo un valor

La manera mas fácil de leer un valor es usando los métodos de su extensión en [BuildContext]:

- `context.watch<T>()`, el cual hace que el widget escuche los cambios en `T`.
- `context.read<T>()`, este regresa `T` sin escucharlo.
- `context.select<T, R>(R cb(T value))`, permite al widget escuchar solo una pequeña parte de `T`.

O utiliza el método estático `Provider.of<T>(context)`, el cual se comporta similar a `watch` y cuando le pasa el valor `false`
al parámetro `listen` como `Provider.of<T>(context, liste: false)` se comportará similar a `read`

Vale la pena decir que `context.read<T>()` no hará que tu widget haga un rebuild cuando el valor cambia y no puede ser
llamado dentro de `StatelessWidget.build`/`State.build`. Por otro lado, puede ser llamado libremente fuera de estos métodos.

Estos métodos buscarán en el árbol de los widgets a partir del widget asociado
con el `BuildContext` pasado, y devolverá la variable de tipo más cercano
`T` encontrada (o lanzara una `exception` si no encuentra nada).

Vale la pena señalar que esta operación es O(1). No implica realmente recorrer
en el árbol de los widgets.

Combinado con el primer ejemplo de [exponer un valor](#exposing-a-value), este
el widget leerá el `String` expuesto y mostrará "Hola Mundo".

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

Otra opción, en lugar de utilizar estos métodos, podemos usar [Consumer] y [Selector].

Estos pueden ayudar a optimizar el desempeño o cuando es difícil de obtener
el `BuildContext` descendiente del provider

Ve las [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do) o la documentación de [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
y [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html) para más información.

### MultiProvider

Cuando inyectamos muchos valores en una aplicación grande, `Provider` puede convertirse
muy anidado rápidamente.

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

A:

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

El comportamiento de ambos ejemplos es el mismo. `Multiprovider` solo cambia la
apariencia del código.

### ProxyProvider

Desde la versión 3.0.0, existe un nuevo tipo de provider: `ProxyProvider`.

`ProxyProvider` es un provider que combina múltiples valores de otros provider
dentro de un nuevo objeto, y envía el resultado a `Provider`.

Este nuevo objeto será actualizado cuando uno de los providers de los que depende
sea actualizado.

El siguiente ejemplo usa `ProxyProvider` para construir una traducción de acuerdo a un contador
que viene de otro provider.

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

Viene con múltiples variaciones, tales como:

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  El dígito después del nombre de la clase es el número de providers que
  `ProxyProvider` depende.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  Todos trabajan de manera similar, pero en lugar de enviar el resultado del `Provider`,
  el `ChangeNotifierProxyProvider` enviará su valor a un `ChangeNotifierProvider`.

### FAQ

#### Puedo ver el contenido de mis objetos?

Flutter viene con [devtools](https://github.com/flutter/devtools), el cual muestra
cómo el árbol de widgets, está en un momento determinado.

Ya que los providers son widgets, también son visibles en las devtools:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

De ahí, si tu presionas un provider, serás capaz de ver los valores que contiene:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(screenshot de las devtools usando la carpeta de `example`)

#### Devtool solo muestran "Instance of MyClass". Que puedo hacer?

Por defecto, devtool necesita `toString`, el cual por defecto es "Instance of MyClass".

Para algo más útil, tienes dos opciones:

- Usa el API [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) de Flutter.

  Para la mayoría de los casos, esto se logrará utilizando [DiagnosticableTreeMixin]
  en tus objetos, siguiendo la implementación personalizada de [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html).

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

- override `toString`.

  Si no puedes usar [DiagnosticableTreeMixin] (como si tu clase estuviera en un paquete
  que no depende de Flutter), entonces puedes simplemente usar el método override `toString`.

  Esto es más fácil que usar [DiagnosticableTreeMixin] pero es menos poderoso:
  No podrás expandir/contraer los detalles de tu objeto.

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

#### Me aparece una exception cuando obtengo Providers dentro de `initState`. Que puedo hacer?

Esta excepción ocurre porque estás tratando de escuchar a un provider de un
life-cycle que nunca jamás será llamado de nuevo.

Significa que debes usar otro ciclo de vida (`build`), o explícitamente
específica que no te importan las actualizaciones.

Entonces, en lugar de:

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

puedes hacer esto:

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

El cual imprime `value` cuando sea que cambie (y solo cuando cambie)

También puedes hacer esto:

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

El cual imprimirá `value` una vez _e ignorará las actualizaciones._

#### Como manejar hot-reload en mis objetos?

Puedes hacer que el objeto de tu provider implemente `ReassembleHandler`:

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

Después úsalo de forma normal con `provider`:

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### Utilizo [ChangeNotifier] y tengo una exception cuando se actualiza, que sucede?

Es probable que esto ocurra porque se está modificando el [ChangeNotifier] de uno de
sus descendientes, _mientras que el árbol de los widgets se está construyendo_.

Una situación típica en la que esto ocurre es cuando se inicia una petición http, donde
el futuro está almacenado dentro del notifier:

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

Esto no está permitido, porque la actualización es inmediata.

Lo que significa que algunos widgets pueden construir _antes_ de la mutación, mientras que otros
widgets construirán _después_ de la mutación.
Esto podría causar inconsistencias en su UI y por lo tanto no está permitido.

En su lugar, deberías realizar esa mutación en un lugar que afectará a todo
el árbol por igual:

- directamente dentro del `create` de tu provider/constructor de tu modelo:

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  Esto es útil cuando no existe un "parámetro externo".

- asincronamente al final del frame
  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>(context).fetchSomething(someValue);
    );
  }
  ```
  Esto es ligeramente menos ideal, pero permite pasar parámetros a la mutación.

#### Tengo que usar [ChangeNotifier] para estados complejos?

No.

Puedes utilizar un objeto para representar tu estado. Por ejemplo, otra opción
es usar la arquitectura de `Provider.value()` combinada con `StatefulWidget`.

Aquí está un ejemplo del counter usando tal arquitectura:

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

donde podemos leer el estado haciendo esto:

```dart
return Text(context.watch<int>().toString());
```

y modificar el estado con:

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

También, puedes crear tu propio provider.

#### Puedo hacer mi propio Provider?

Si. `provider` muestra todos los pequeños componentes para hacer el tuyo.

Esto incluye:

- `SingleChildStatelessWidget`, para hacer que el widget funcione con `MultiProvider`.
  Esta interfaz es expuesta como parte de `package:provider/single_child_widget`

- [InheritedProvider], el `InheritedWidget` genérico obtenido cuando hacemos `context.watch`.

Aquí está un ejemplo de un provider personalizado para usar `ValueNotifier` como estado:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### Mi widget hace muchos rebuilds, que puedo hacer?

En lugar de usar `context.watch`, puedes usar `context.select` para escuchar solo a un conjunto
específico de propiedades en el objeto obtenido

Por ejemplo, podrías escribir esto:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

Podría provocar que el widget haga rebuild, si otro aparte de `name` cambia.

En su lugar, puedes usar `context.select` para escuchar solo los cambios en la propiedad `name`:

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

De esta manera, el widget no realizará rebuilds innecesarios si algo aparte de `name` cambia.

Similarmente, puedes utilizar [Consumer]/[Selector].
Su propiedad `child` opcional permite solo hacer rebuild en una parte especifica del
árbol de widgets.

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

En este ejemplo, solo `Bar` hará un rebuild cuando `A` actualice. `Foo` y `Baz` no harán builds
innecesarios.

#### Puedo obtener dos providers diferentes usando el mismo tipo?

No. Aunque puedes tener varios providers compartiendo el mismo tipo, un widget
será capaz de obtener sólo uno de ellos: el ancestro más cercano.

En cambio, debe dar explícitamente a ambos proveedores un tipo diferente

En lugar de:

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

Utiliza:

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### Puedo consumir una interfaz y proveer una implementación?

Sí, se debe dar una pista del tipo al compilador para indicar que la interfaz se consumirá, con la implementación prevista en create.

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

### Providers existentes

`provider` nos muestra algunos tipos diferentes de "provider" para diferentes tipos de objetos.

La lista completa de todos los objetos disponibles esta [aquí](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| Nombre                                                                                                                        | Descripción                                                                                                                                                                               |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | La forma más básica de provider. Toma un valor y lo expone, sea cual sea el valor.                                                                                                        |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | Un proveedor específico para el objeto Listenable. ListenableProvider escuchará el objeto y pedirá a los widgets que dependen de él que lo reconstruyan siempre que se llame al listener. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | Se especifica el tipo de ListenableProvider para ChangeNotifier. Este llamará automáticamente `ChangeNotifier.dispose` cuando lo necesite.                                                |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Escucha al ValueListenable y solo muestra `ValueListenable.value`.                                                                                                                        |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Escucha a un Stream y muestra el último valor emitido.                                                                                                                                    |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Toma un `Future` y actualiza a sus dependientes cuando el futuro es completado.                                                                                                           |

[provider.of]: https://pub.dev/documentation/provider/latest/provider/Provider/of.html
[selector]: https://pub.dev/documentation/provider/latest/provider/Selector-class.html
[consumer]: https://pub.dev/documentation/provider/latest/provider/Consumer-class.html
[changenotifier]: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
[inheritedwidget]: https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html
[inheritedprovider]: https://pub.dev/documentation/provider/latest/provider/InheritedProvider-class.html
[diagnosticabletreemixin]: https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin-mixin.html
