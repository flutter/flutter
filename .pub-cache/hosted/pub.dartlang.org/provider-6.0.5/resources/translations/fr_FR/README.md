[English](https://github.com/rrousselGit/provider/blob/master/README.md) | [French](https://github.com/rrousselGit/provider/blob/master/resources/translations/fr_FR/README.md) | [Português](https://github.com/rrousselGit/provider/blob/master/resources/translations/pt_br/README.md) | [简体中文](https://github.com/rrousselGit/provider/blob/master/resources/translations/zh-CN/README.md) | [Español](https://github.com/rrousselGit/provider/blob/master/resources/translations/es_MX/README.md) | [한국어](https://github.com/rrousselGit/provider/blob/master/resources/translations/ko-KR/README.md) | [বাংলা](/resources/translations/bn_BD/README.md) | [日本語](https://github.com/rrousselGit/provider/blob/master/resources/translations/ja_JP/README.md)

<a href="https://github.com/rrousselGit/provider/actions"><img src="https://github.com/rrousselGit/provider/workflows/Build/badge.svg" alt="Build Status"></a>
[![codecov](https://codecov.io/gh/rrousselGit/provider/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/provider) <a href="https://discord.gg/Bbumvej"><img src="https://img.shields.io/discord/765557403865186374.svg?logo=discord&color=blue" alt="Discord"></a>

[<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/flutter_favorite.png" width="200" />](https://flutter.dev/docs/development/packages-and-plugins/favorites)

Une enveloppe autour de [InheritedWidget] pour les rendre plus faciles à utiliser et plus réutilisables.

En utilisant `provider` au lieu d'écrire manuellement [InheritedWidget], vous obtenez:

- allocation simplifiée/disposition des ressources
- chargement paresseux
- une réduction considérable de l'encombrement par rapport à la création d'une nouvelle classe à chaque fois
- convivial pour les devtools - grâce au Provider, l'état de votre application sera visible dans le devtool de Flutter
- une façon commune de consommer ces [InheritedWidget]s (voir [Provider.of]/[Consumer]/[Selector]).
- l'extensibilité accrue pour les classes dont le mécanisme d'écoute croît de façon exponentielle en complexité (comme [ChangeNotifier], qui est O(N) pour la distribution des notifications).

Pour en savoir plus sur un `provider`, voir sa [documentation](https://pub.dev/documentation/provider/latest/provider/provider-library.html).

Voir aussi:

- [La documentation officielle sur la gestion de l'état de Flutter](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple), qui montre comment utiliser `provider`. + [ChangeNotifier]
- [Exemple d'architecture flutter](https://github.com/brianegan/flutter_architecture_samples/tree/master/change_notifier_provider), qui contient une implémentation de cette application en utilisant `provider` + [ChangeNotifier]
- [flutter_bloc](https://github.com/felangel/bloc) et [Mobx](https://github.com/mobxjs/mobx.dart), qui utilise un `provider` dans leur architecture

## Migration de 4.x.x vers 5.0.0-nullsafety

- `initialData` pour `FutureProvider` et `StreamProvider` est maintenant requis.

  Pour migrer, ce qui était avant :

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

  est maintenant:

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

- `ValueListenableProvider` est supprimé

  Pour migrer, vous pouvez plutôt utiliser `Provider` combiné avec `ValueListenableBuilder`:

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

## Usage

### Exposer une valeur

#### Exposer une nouvelle instance d'objet

Les providers vous permettent non seulement d'exposer une valeur, mais aussi de la créer, de l'écouter et d'en disposer.

Pour exposer un objet nouvellement créé, utilisez le constructeur par défaut d'un provider.
N'utilisez _pas_ le constructeur `.value` si vous voulez **créer** un objet, ou vous pourriez avoir des effets secondaires indésirables.

Voir [cette réponse de StackOverflow](https://stackoverflow.com/questions/52249578/how-to-deal-with-unwanted-widget-build)
qui explique pourquoi l'utilisation du constructeur `.value` pour créer des valeurs est indésirable.

- **FAIRE** créer un nouvel objet dans `create`.

```dart
Provider(
  create: (_) => MyModel(),
  child: ...
)
```

- **NE PAS** utilisez `Provider.value` pour créer votre objet.

```dart
ChangeNotifierProvider.value(
  value: MyModel(),
  child: ...
)
```

- **NE PAS** créer votre objet à partir des variables qui peuvent changer dans le temps.

  Dans une telle situation, votre objet ne serait jamais mis à jour lorsque la valeur change.

```dart
int count;

Provider(
  create: (_) => MyModel(count),
  child: ...
)
```

Si vous voulez passer des variables qui peuvent changer dans le temps à votre objet,
pensez à utiliser `ProxyProvider` :

```dart
int count;

ProxyProvider0(
  update: (_, __) => MyModel(count),
  child: ...
)
```

**NOTE**:

Lorsque vous utilisez le callback `create`/`update` d'un provider, il est intéressant de noter que ce callback est appelé de manière paresseuse(lazy) par défaut.

Cela signifie que tant que la valeur n'est pas demandée au moins une fois, les callbacks `create`/`update` ne seront pas appelés.

Ce comportement peut être désactivé si vous voulez pré-calculer une logique, en utilisant le paramètre `lazy` :

```dart
MyProvider(
  create: (_) => Something(),
  lazy: false,
)
```

#### Réutilisation d'une instance d'objet existante :

Si vous avez déjà une instance d'objet et que vous voulez l'exposer, il serait préférable d'utiliser le constructeur `.value` d'un provider.

Si vous ne le faites pas, vous risquez d'appeler la méthode `dispose` de votre objet alors qu'il est encore utilisé.

- **FAIRE** utilisez `ChangeNotifierProvider.value` pour fournir un [ChangeNotifier] existant.

```dart
MyChangeNotifier variable;

ChangeNotifierProvider.value(
  value: variable,
  child: ...
)
```

- **NE PAS** réutiliser un [ChangeNotifier] existant en utilisant le constructeur par défaut

```dart
MyChangeNotifier variable;

ChangeNotifierProvider(
  create: (_) => variable,
  child: ...
)
```

### Lire une valeur

Le moyen le plus simple de lire une valeur consiste à utiliser les méthodes d'extension sur [BuildContext]:

- `context.watch<T>()`, qui fait écouter au widget les changements sur `T`
- `context.read<T>()`, qui retourne `T` sans l'écouter
- `context.select<T, R>(R cb(T value))`, qui permet à un widget d'écouter seulement une petite partie de `T`.

On peut également utiliser la méthode statique `Provider.of<T>(context)`, qui se comportera de manière similaire
à `watch`. Lorsque le paramètre `listen` est défini à `false` (comme dans `Provider.of<T>(context, listen: false)`), alors il se comportera de la même manière que `read`.

Il est important de noter que `context.read<T>()` ne reconstruira pas un widget lorsque la valeur
et il ne peut pas être appelé dans `StatelessWidget.build`/`State.build`.
D'un autre côté, elle peut être appelée librement en dehors de ces méthodes.

Ces méthodes vont chercher dans l'arborescence des widgets en partant du widget associé
associé au `BuildContext` passé et retourneront la variable de type `T` la plus proche
trouvée (ou throw si rien n'est trouvé).

Cette opération est O(1). Elle n'implique pas de marcher dans l'arborescence des widgets.

Combiné avec le premier exemple d'[exposition d'une valeur](#exposing-a-value), ceci
le widget lira la `String` exposée et rendra "Hello World".

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      // N'oubliez pas de passer le type de l'objet que vous voulez obtenir à `watch`!
      context.watch<String>(),
    );
  }
}
```

Au lieu d'utiliser ces méthodes, nous pouvons aussi utiliser [Consumer] et [Selector].

Celles-ci peuvent être utiles pour optimiser les performances ou lorsqu'il est difficile de
d'obtenir un descendant `BuildContext` du provider.

Voir le [FAQ](https://github.com/rrousselGit/provider#my-widget-rebuilds-too-often-what-can-i-do)
ou la documentation de [Consumer](https://pub.dev/documentation/provider/latest/provider/Consumer-class.html)
et [Selector](https://pub.dev/documentation/provider/latest/provider/Selector-class.html)
pour plus d'informations.

### En option en fonction d'un provider

Parfois, nous pouvons vouloir prendre en charge les cas où un provider n'existe pas. Un
exemple serait pour les widgets réutilisables qui pourraient être utilisés à divers endroits,
y compris en dehors d'un provider.

Pour ce faire, lors de l'appel de `context.watch`/`context.read`, faites en sorte que le type générique
soit nullable. Tel qu'au lieu de:

```dart
context.watch<Model>()
```

qui lancera une `ProviderNotFoundException` si aucun provider ne correspond
sont trouvés, faites :

```dart
context.watch<Model?>()
```

qui tentera d'obtenir un provider correspondant. Mais s'il n'en trouve pas,
`null` sera renvoyé au lieu d'être lancé.

### MultiProvider

Lors de l'injection de nombreuses valeurs dans de grandes applications, `Provider` peut rapidement devenir
assez imbriqué:

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

Le comportement des deux exemples est strictement le même. `MultiProvider` ne change que
l'apparition du code.

`ProxyProvider` est un provider qui combine plusieurs valeurs d'autres providers dans un nouvel objet et envoie le résultat à `Provider`.

Ce nouvel objet sera ensuite mis à jour chaque fois que l'un des providers dont nous dépendons sera mis à jour.

L'exemple suivant utilise `ProxyProvider` pour créer des traductions basées sur un compteur provenant d'un autre provider.

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

  String get title => 'Vous avez cliqué $_value fois';
}
```

Il existe de nombreuses variantes, telles que :

- `ProxyProvider` vs `ProxyProvider2` vs `ProxyProvider3`, ...

  Ce chiffre après le nom de la classe correspond au nombre des autres providers dont dépend `ProxyProvider`.

- `ProxyProvider` vs `ChangeNotifierProxyProvider` vs `ListenableProxyProvider`, ...

  Ils fonctionnent tous de manière similaire, mais au lieu d'envoyer le résultat dans un `Provider`,
  un `ChangeNotifierProxyProvider` enverra sa valeur à un `ChangeNotifierProvider`.

### FAQ

#### Puis-je inspecter le contenu de mes objets ?

Flutter est livré avec un [devtool] (https://github.com/flutter/devtools) qui permet d'afficher
ce qu'est l'arborescence des widgets à un moment donné.

Les providers étant des widgets, ils sont également visibles dans ce devtool:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/devtools_providers.jpg" width="200" />

De là, si vous cliquez sur un provider, vous pourrez voir la valeur qu'il expose:

<img src="https://raw.githubusercontent.com/rrousselGit/provider/master/resources/expanded_devtools.jpg" width="200" />

(capture d'écran des devtools utilisant le dossier "exemple")

#### Le devtool affiche uniquement "Instance of MyClass". Que puis-je faire ?

Par défaut, le devtool s'appuie sur `toString`, qui donne par défaut "Instance of MyClass".

Pour avoir quelque chose de plus utile, vous avez deux solutions:

- utiliser l'API [Diagnosticable](https://api.flutter.dev/flutter/foundation/Diagnosticable-mixin.html) de Flutter.

  Dans la plupart des cas, j'utiliserai [DiagnosticableTreeMixin] sur vos objets, puis une implémentation personnalisée de [debugFillProperties](https://api.flutter.dev/flutter/foundation/DiagnosticableTreeMixin/debugFillProperties.html).

  ```dart
  class MyClass with DiagnosticableTreeMixin {
    MyClass({this.a, this.b});

    final int a;
    final String b;

    @override
    void debugFillProperties(DiagnosticPropertiesBuilder properties) {
      super.debugFillProperties(properties);
      // listez toutes les propriétés de votre classe ici.
      // Consultez la documentation de debugFillProperties pour plus d'informations.
      properties.add(IntProperty('a', a));
      properties.add(StringProperty('b', b));
    }
  }
  ```

- Override `toString`.

  Si vous ne pouvez pas utiliser [DiagnosticableTreeMixin] (par exemple, si votre classe est dans un package
  qui ne dépend pas de Flutter), vous pouvez override `toString`.

  C'est plus facile que d'utiliser [DiagnosticableTreeMixin] mais c'est moins puissant:
  Vous ne serez pas en mesure d'étendre/réduire les détails de votre objet.

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

#### J'ai une exception lors de l'obtention des Providers dans `initState`. Que dois-je faire ?

Cette exception se produit parce que vous essayez d'écouter un provider à partir d'un
cycle de vie qui ne sera plus jamais rappelé.

Cela signifie que vous devez soit utiliser un autre cycle de vie ("build"), soit explicitement
précisez que vous ne vous souciez pas des mises à jour.

Ainsi, au lieu de :

```dart
initState() {
  super.initState();
  print(context.watch<Foo>().value);
}
```

vous pouvez faire:

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

Ce qui imprimera `value` chaque fois qu'il changera (et seulement quand il changera).

Alternativement, vous pouvez faire:

```dart
initState() {
  super.initState();
  print(context.read<Foo>().value);
}
```

Ce qui imprimera `value` une fois _et ignorera les mises à jour._

#### Comment gérer le hot-reload sur mes objets ?

Vous pouvez faire en sorte que votre objet fourni implémente `ReassembleHandler`:

```dart
class Example extends ChangeNotifier implements ReassembleHandler {
  @override
  void reassemble() {
    print('Did hot-reload');
  }
}
```

Ensuite, utilisé typiquement avec `provider`:

```dart
ChangeNotifierProvider(create: (_) => Example()),
```

#### J'utilise le [ChangeNotifier], et j'ai une exception lorsque je le mets à jour. Que se passe-t-il?

Cela se produit probablement parce que vous modifiez le [ChangeNotifier] à partir de l'un de ses descendants _pendant la construction de l'arborescence des widgets_.

Une situation typique où cela se produit est lors du démarrage d'une requête http, où le futur est stocké dans le notificateur :

```dart
initState() {
  super.initState();
  context.read<MyNotifier>().fetchSomething();
}
```

Ceci n'est pas autorisé car la mise à jour de l'état est synchrone.

Cela signifie que certains widgets peuvent être construits _avant_ que la mutation se produise (obtention d'une ancienne valeur), tandis que d'autres widgets seront construits _après_ que la mutation est terminée (obtention d'une nouvelle valeur). Cela pourrait entraîner des incohérences dans votre interface utilisateur et n'est donc pas autorisé.

Au lieu de cela, vous devriez effectuer cette mutation dans un endroit qui affecterait l'ensemble de l'arbre(tree) de manière égale:

- directement dans le `create` de votre provider/constructeur de votre modèle:

  ```dart
  class MyNotifier with ChangeNotifier {
    MyNotifier() {
      _fetchSomething();
    }

    Future<void> _fetchSomething() async {}
  }
  ```

  Ceci est utile lorsqu'il n'y a pas de "paramètre externe".

- de manière asynchrone en fin de trame:
  ```dart
  initState() {
    super.initState();
    Future.microtask(() =>
      context.read<MyNotifier>().fetchSomething(someValue);
    );
  }
  ```
  Elle est légèrement moins idéale, mais permet de passer des paramètres à la mutation.

#### Dois-je utiliser [ChangeNotifier] pour les états complexes ?

Non.

Vous pouvez utiliser n'importe quel objet pour représenter votre état. Par exemple, une architecture alternative consiste à utiliser
`Provider.value()` combiné avec un `StatefulWidget`.

Voici un exemple de compteur utilisant une telle architecture:

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

où nous pouvons lire l'état en faisant:

```dart
return Text(context.watch<int>().toString());
```

et modifiez l'état avec:

```dart
return FloatingActionButton(
  onPressed: () => context.read<ExampleState>().increment(),
  child: Icon(Icons.plus_one),
);
```

Alternativement, vous pouvez créer votre propre provider.

#### Puis-je créer mon provider ?

Oui. `provider` expose tous les petits composants qui font un provider à part entière.

Ceci inclut:

- `SingleChildStatelessWidget`, pour que tout widget fonctionne avec `MultiProvider`.
  Cette interface est exposée dans le cadre de `package:provider/single_child_widget`.

- [InheritedProvider], le `InheritedWidget` générique obtenu en faisant `context.watch`.

Voici un exemple de provider personnalisé pour utiliser `ValueNotifier` comme état:
https://gist.github.com/rrousselGit/4910f3125e41600df3c2577e26967c91

#### Mon widget se reconstruit trop souvent. Que puis-je faire?

Au lieu de `context.watch`, vous pouvez utiliser `context.select` pour écouter seulement l'ensemble spécifique de propriétés sur l'objet obtenu.

Par exemple, alors que vous pouvez écrire:

```dart
Widget build(BuildContext context) {
  final person = context.watch<Person>();
  return Text(person.name);
}
```

Cela peut entraîner la reconstruction du widget si quelque chose d'autre que `name` change.

Au lieu de cela, vous pouvez utiliser `context.select` pour écouter uniquement la propriété `name`:

```dart
Widget build(BuildContext context) {
  final name = context.select((Person p) => p.name);
  return Text(name);
}
```

De cette façon, le widget ne se reconstruira pas inutilement si quelque chose d'autre que `name` change.

De même, vous pouvez utiliser [Consumer]/[Selector]. Leur argument facultatif `child` permet de reconstruire uniquement une partie particulière de l'arborescence des widgets:

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

Dans cet exemple, seul `Bar` sera reconstruit lorsque `A` sera mis à jour. 'Foo' et 'Baz' ne le feront pas
reconstruire inutilement.

#### Puis-je obtenir deux providers différents utilisant le même type ?

Non. Bien que vous puissiez avoir plusieurs providers partageant le même type, un widget ne pourra en obtenir qu'un seul : l'ancêtre le plus proche.

Au lieu de cela, il serait utile que vous donniez explicitement aux deux providers un type différent.

Au lieu de:

```dart
Provider<String>(
  create: (_) => 'England',
  child: Provider<String>(
    create: (_) => 'London',
    child: ...,
  ),
),
```

Préfère:

```dart
Provider<Country>(
  create: (_) => Country('England'),
  child: Provider<City>(
    create: (_) => City('London'),
    child: ...,
  ),
),
```

#### Puis-je consommer une interface et fournir une implémentation ?

Oui, un indice de type doit être donné au compilateur pour indiquer que l'interface sera consommée, avec l'implémentation fournie dans create.

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

### Providers existants

`provider` expose quelques types différents de "provider" pour différents types d'objets.

La liste complète de tous les objets disponibles est [ici](https://pub.dev/documentation/provider/latest/provider/provider-library.html)

| nom                                                                                                                           | description                                                                                                                                                                                       |
| ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Provider](https://pub.dartlang.org/documentation/provider/latest/provider/Provider-class.html)                               | La forme la plus élémentaire de provider. Il prend une valeur et l'expose, quelle que soit la valeur.                                                                                             |
| [ListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ListenableProvider-class.html)           | Un provider spécifique pour l'objet Listenable. ListenableProvider écoutera l'objet et demandera aux widgets qui en dépendent de se reconstruire chaque fois que l'écouteur(listener) est appelé. |
| [ChangeNotifierProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ChangeNotifierProvider-class.html)   | Une spécification de ListenableProvider pour ChangeNotifier. Il appellera automatiquement `ChangeNotifier.dispose` en cas de besoin.                                                              |
| [ValueListenableProvider](https://pub.dartlang.org/documentation/provider/latest/provider/ValueListenableProvider-class.html) | Écoutez un ValueListenable et exposez uniquement `ValueListenable.value`.                                                                                                                         |
| [StreamProvider](https://pub.dartlang.org/documentation/provider/latest/provider/StreamProvider-class.html)                   | Ecoutez un Stream et exposez la dernière valeur émise.                                                                                                                                            |
| [FutureProvider](https://pub.dartlang.org/documentation/provider/latest/provider/FutureProvider-class.html)                   | Prend un `Future` et met à jour les dépendants lorsque le future se termine.                                                                                                                      |

### Mon application génère une erreur StackOverflowError parce que j'ai trop de providers, que puis-je faire ?

Si vous avez un très grand nombre de providers (150+), il est possible que certains appareils lancent un `StackOverflowError` parce que vous finissez par construire trop de widgets à la fois.

Dans cette situation, vous avez quelques solutions:

- Si votre application dispose d'un splash-screen, essayez de monter vos providers au fil du temps plutôt qu'en une seule fois.

  Vous pourriez le faire:

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

  où pendant l'animation de votre splash screen, vous feriez:

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

- Envisagez de désactiver l'utilisation de `MultiProvider`.
  `MultiProvider` fonctionne en ajoutant un widget entre chaque provider. Ne pas utiliser `MultiProvider` peut
  augmentez la limite avant qu'une `StackOverflowError` ne soit atteinte.

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
