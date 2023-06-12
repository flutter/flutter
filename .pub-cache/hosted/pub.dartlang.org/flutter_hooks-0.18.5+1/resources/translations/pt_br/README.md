[English](https://github.com/rrousselGit/flutter_hooks/blob/master/README.md) | [Português](https://github.com/rrousselGit/flutter_hooks/blob/master/packages/flutter_hooks/resources/translations/pt_br/README.md)

[![Build Status](https://travis-ci.org/rrousselGit/flutter_hooks.svg?branch=master)](https://travis-ci.org/rrousselGit/flutter_hooks) [![codecov](https://codecov.io/gh/rrousselGit/flutter_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/flutter_hooks) [![pub package](https://img.shields.io/pub/v/flutter_hooks.svg)](https://pub.dartlang.org/packages/flutter_hooks) [![pub package](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

<img src="https://raw.githubusercontent.com/rrousselGit/flutter_hooks/master/packages/flutter_hooks/flutter-hook.svg?sanitize=true" width="200">

# Flutter Hooks

Uma implementação dos React Hooks para o Flutter: https://medium.com/@dan_abramov/making-sense-of-react-hooks-fdbde8803889

Hooks são uma nova forma de gerenciar o ciclo de vida de um `Widget`. Eles existem
por uma razão: aumentar o compartilhamento de código _entre_ widgets, removendo código
duplicado.

## Motivação

`StatefulWidget` sofrem de um grande problema: é bem difícil reutilizar a lógica,
por exemplo de um `initState` ou `dispose`. Um exemplo é o `AnimationController`:

```dart
class Example extends StatefulWidget {
  final Duration duration;

  const Example({Key? key, @required this.duration})
      : assert(duration != null),
        super(key: key);

  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(Example oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

Todos os widgets que desejarem usar um `AnimationController`, terão de implementar
quase tudo isso do zero, o que é obviamente indesejável.

Os mixins do Dart resolvem parcialmente esse problema, porém outros problemas acabam
sendo gerados:

- Um mixin só pode ser usado uma vez por uma classe
- Mixins e classes compartilham o mesmo objeto.\
  Isso significa que se dois mixins definirem uma variável com o mesmo nome, o resultado
  pode variar entre um erro de compilação ou um comportamento inesperado.

---

Essa biblioteca propõe uma terceira solução:

```dart
class Example extends HookWidget {
  const Example({Key? key, @required this.duration})
      : assert(duration != null),
        super(key: key);

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    return Container();
  }
}
```
Esse código é equivalente ao do exemplo anterior. Ele continua descartando o
`AnimationController` no `dispose` e continua atualizando o `duration` quando
`Example.duration` muda.
Você provavelmente está pensando:

> Para onde foi toda a lógica?

A lógica foi movida para o `useAnimationController`, uma funcionalidade incluida
diretamente nessa biblioteca (veja [Hooks Existentes](https://github.com/rrousselGit/flutter_hooks#existing-hooks)).
Isso é o que chamamos de _Hook_.

Hooks são novos tipos de objetos com algumas peculiaridades:

- Eles só podem ser usados durante o método `build` de um widgets que utiliza o mix-in
  `Hooks`.
- O mesmo Hook pode ser reutilizado infinitas vezes.
  O código a seguir define dois `Animation Controller` independentes, e eles são
  preservados quando o widget passa por um rebuild.

  ```dart
  Widget build(BuildContext context) {
    final controller = useAnimationController();
    final controller2 = useAnimationController();
    return Container();
  }
  ```

- Hooks são inteiramente independentes um do outro e do widget.\
  Isso significa que eles podem ser facilmente extraídos em um pacote
  e publicados no [pub](https://pub.dartlang.org/) para outros desenvolvedores
  utilizarem

## Princípios

Similar ao `State`, hooks são armazenados no `Element` de um `Widget`. Mas, ao invés
de ter apenas um `State`, o `Element` armazena um `List<Hook>`. Então, para usar um
`Hook`, deve-se chamar `Hook.use`.

O hook retornado pelo `use` é baseado no número de vezes que ele é chamado.
A primeira chamada retorna o primeiro hook; a segunda chamada retorna o segundo hook,
a terceira retorna o terceiro hook, ...

Se ainda não parece tão claro, veja uma simples implementação do Hook a seguir:

```dart
class HookElement extends Element {
  List<HookState> _hooks;
  int _hookIndex;

  T use<T>(Hook<T> hook) => _hooks[_hookIndex++].build(this);

  @override
  performRebuild() {
    _hookIndex = 0;
    super.performRebuild();
  }
}
```

Para maiores explicações sobre como são implementados, aqui está um ótimo artigo
sobre como eles funcionam no React: https://medium.com/@ryardley/react-hooks-not-magic-just-arrays-cd4f1857236e

## Regras

Como os hooks são obtidos através do seu index, algumas regras devem ser respeitadas:

### SEMPRE defina seus hooks com `use`:

```dart
Widget build(BuildContext context) {
  // começa com `use`, bom nome
  useMyHook();
  // não começa com `use`, pode confundir outro desenvolvedor por achar que isso não é um hook
  myHook();
  // ....
}
```

### CHAME os hooks sem nenhuma condição

```dart
Widget build(BuildContext context) {
  useMyHook();
  // ....
}
```

### NÃO envolva-os em uma condicional

```dart
Widget build(BuildContext context) {
  if (condition) {
    useMyHook();
  }
  // ....
}
```

---

### Sobre o hot-reload

Como os hooks são obtidos pelo seu index, você pode achar que talvez um hot-reload durante uma refatoração pode quebrar a aplicação

Felizmente não, `HookWidget` substitui o comportamento padrão do hot-reload para trabalhar com os hooks. Porém, existem algumas situações em que o estado de um Hook pode ser resetado.

Considere a seguinte lista de hooks:

```dart
useA();
useB(0);
useC();
```

Então considere que após o hot-reload, nós editamos o parâmetro do `HookB`:

```dart
useA();
useB(42);
useC();
```

Tudo funciona perfeitamente bem; todos os hooks mantém seu estado.

Agora considere que removemos o `HookB`. Agora temos:

```dart
useA();
useC();
```

Nessa situação, `HookA` mantém seu estado, mas `HookC` é resetado.
Isso acontece por que quando uma refatoração é feita, todos os hooks _após_ a primeira linha são descartados.
Como `HookC` é colocado após `HookB`, ele acaba sendo descartado.

## Como usar

Existem duas formas de criar um hook:

- Uma função

  Funções são a forma mais comum de se criar um Hook. Graças aos hooks serem
  combináveis, uma função é capaz de combinar outros hooks para criar um hook
  customizado. Como convenção, essas funções utilizam o prefixo `use`.

  O exemplo a seguir define um hook customizado que cria uma variável e mostra
  seu valor no console sempre que o valor é modificado:

  ```dart
  ValueNotifier<T> useLoggedState<T>(BuildContext context, [T initialData]) {
    final result = useState<T>(initialData);
    useValueChanged(result.value, (_, __) {
      print(result.value);
    });
    return result;
  }
  ```

- Classe

  Quando um hook fica muito complexo, é possível converte-lo para uma classe que extende de `Hook`, que pode ser usado como `Hook.use`.\
  Como uma classe, o hook vai parecer bem similar ao `State` e terá acesso ao
  ciclo de vida e métodos como `initHook`, `dispose` e `setState`
  É uma boa prática esconder a classe em uma função, por exemplo:

  ```dart
  Result useMyHook(BuildContext context) {
    return use(const _TimeAlive());
  }
  ```

  Este exemplo defina um hook que mostra a hora quando o `State` é posto como alive.

  ```dart
  class _TimeAlive extends Hook<void> {
    const _TimeAlive();

    @override
    _TimeAliveState createState() => _TimeAliveState();
  }

  class _TimeAliveState extends HookState<void, _TimeAlive> {
    DateTime start;

    @override
    void initHook() {
      super.initHook();
      start = DateTime.now();
    }

    @override
    void build(BuildContext context) {}

    @override
    void dispose() {
      print(DateTime.now().difference(start));
      super.dispose();
    }
  }
  ```

## Hooks exisentes

Flutter_hooks possui uma lista de hooks reutilizáveis.

Eles são divididos em diferentes tipos:

### Primitivos

Um conjunto de hooks que interagem com diferentes ciclos de vida de um widget

| Nome                                                                                                              | descrição                                                    |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| [useEffect](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useEffect.html)             | Útil para side-effects e opcionalmente, cancelá-los.         |
| [useState](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useState.html)               | Cria uma variável e escuta suas mudanças.                    |
| [useMemoized](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html)         | Guarda a instância de um objeto complexo.                    |
| [useContext](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useContext.html)           | Obtém o `BuildContext` do `HookWidget`.                      |
| [useValueChanged](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueChanged.html) | Observa o value e chama um callback sempre que o valor muda. |

### Object binding

Essa categoria de hooks permite manipular objetos existentes do Flutter/Dart com hooks.
Eles serão responsáveis por criar/atualizar/descartar o objeto.

#### dart:async:

| nome                                                                                                                      | descrição                                                              |
| ------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| [useStream](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStream.html)                     | Inscreve em uma `Stream` e retorna o estado atual num `AsyncSnapshot`. |
| [useStreamController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useStreamController.html) | Cria um `StreamController` automaticamente descartado.                 |
| [useFuture](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFuture.html)                     | Inscreve em uma `Future` e retorna o estado atual num `AsyncSnapshot`. |

#### Animação:

| nome                                                                                                                              | descrição                                                 |
| --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| [useSingleTickerProvider](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useSingleTickerProvider.html) | Cria um único `TickerProvider`.                           |
| [useAnimationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimationController.html)   | Cria um `AnimationController` automaticamente descartado. |
| [useAnimation](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useAnimation.html)                       | Inscreve um uma `Animation` e retorna seu valor.          |

#### Listenable:

| nome                                                                                                                    | descrição                                                                                 |
| ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [useListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useListenable.html)           | Inscreve em um `Listenable` e marca o widget para um rebuild quando o listener é chamado. |
| [useValueNotifier](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueNotifier.html)     | Cria um `ValueNotifier` automaticamente descartado.                                       |
| [useValueListenable](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useValueListenable.html) | Inscreve em um `ValueListenable` e retorna seu valor.                                     |

#### Misc

São vários hooks sem um tema particular.

| nome                                                                                                                                | descrição                                           |
| ----------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| [useReducer](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useReducer.html)                             | Uma alternativa `useState` para estados complexos.  |
| [usePrevious](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/usePrevious.html)                           | Retorna o argumento anterior chamado [usePrevious]. |
| [useTextEditingController](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useTextEditingController-constant.html) | Cria um `TextEditingController`                     |
| [useFocusNode](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useFocusNode.html)                         | Cria um `FocusNode`                                 |
| [useTabController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTabController.html)                 | Cria e descarta um `TabController`.                 |
| [useScrollController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useScrollController.html)           | Cria e descarta um `ScrollController`.              |
| [useTransformationController](https://pub.dartlang.org/documentation/flutter_hooks/latest/flutter_hooks/useTransformationController.html)           | Cria e descarta um `TransformationController`.              |

## Contribuições

Contribuições são bem vindas!

Se você acha que está faltando algum hook, sinta-se livre para abrir um pull-request.

Para um hook customizado ser mergeado, você precisa fazer o seguinte:

- Descrever o caso de uso

  Abrir uma issue explicando por que precisamos desse hook, como usar, ...
  Isso é importante por que um hook não será mergeado se não atender um
  grande número de pessoas

  Se o seu hook foi rejeitado, não se preocupe! A rejeição não significa que
  ele não pode ser mergeado no future se mais pessoas se interessarem nele.
  Sinta-se livre para publicar seu próprio hook como um pacote no [pub](https://pub.dev)

- Escreva testes para o seu hook

  Um hook não será mergeado a não ser que esteja completamente testado, para evitar
  quebras no futuro.

- Adicione-o ao Readme e escreva uma documentação para ele.
