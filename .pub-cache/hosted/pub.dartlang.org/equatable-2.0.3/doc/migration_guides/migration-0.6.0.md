# Migration to v0.6.0

## Properties must be passed using the `props` getter instead of `super`

### Before

```dart
class Person extends Equatable {
    const Person(this.name) : super([name]);

    final String name;
}
```

### After

```dart
class Person extends Equatable {
    const Person(this.name);

    final String name;

    @override
    List<Object> get props => [name];
}
```

### Justification

Based on feedback/observations, one of the most common mistakes made when using Equatable is forgetting to pass the props to super. This change will force developers to override `props` making it a lot less error-prone.

## Adding the `@immutable` decorator is redundant and can be omitted.

### Before

```dart
@immutable
class Person extends Equatable { ... }
```

### After

```dart
class Person extends Equatable { ... }
```

### Justification

Equatable enforces immutable internally so the decorator is not necessary.

## Abstract class constructor optional props are not needed

### Before

```dart
class MyClass extends Equatable {
    MyClass([List<Object> props = const[]]) : super(props);
}

class MySubClass extends MyClass {
    const MySubClass(this.data) : super([data]);

    final int data;
}
```

### After

```dart
class MyClass extends Equatable {
    const MyClass();
}

class MySubClass extends MyClass {
    const MySubClass(this.data);

    final int data;
    
    @override
    List<Object> get props => [data];
}
```

### Justification

Since props are no longer passed via `super` having optional props in the abstract constructor is unnecessary. In addition, the `props` getter allows for `const` classes which offer significant performance improvements. `const` constructors should be used over non-const constructors.
