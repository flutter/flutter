// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.db;

/// Represents a unique identifier for a [Model] stored in a datastore.
///
/// The [Key] can be incomplete if it's id is `null`. In this case the id will
/// be automatically allocated and set at commit time.
class Key<T> {
  // Either KeyImpl or PartitionImpl
  final Object _parent;

  final Type? type;
  final T? id;

  Key(Key parent, this.type, this.id) : _parent = parent {
    if (type == null) {
      throw ArgumentError('The type argument must not be null.');
    }
    if (id != null && id is! String && id is! int) {
      throw ArgumentError('The id argument must be an integer or a String.');
    }
  }

  Key.emptyKey(Partition partition)
      : _parent = partition,
        type = null,
        id = null;

  /// Parent of this [Key].
  Key? get parent {
    if (_parent is Key) {
      return _parent as Key;
    }
    return null;
  }

  /// The partition of this [Key].
  Partition get partition {
    var obj = _parent;
    while (obj is! Partition) {
      obj = (obj as Key)._parent;
    }
    return obj;
  }

  Key<U> append<U>(Type modelType, {U? id}) {
    return Key<U>(this, modelType, id);
  }

  bool get isEmpty => _parent is Partition;

  @override
  bool operator ==(Object other) {
    return other is Key &&
        _parent == other._parent &&
        type == other.type &&
        id == other.id;
  }

  @override
  int get hashCode => _parent.hashCode ^ type.hashCode ^ id.hashCode;

  /// Converts `Key<dynamic>` to `Key<U>`.
  Key<U> cast<U>() => Key<U>(parent!, type, id as U?);
}

/// Represents a datastore partition.
///
/// A datastore is partitioned into namespaces. The default namespace is
/// `null`.
class Partition {
  final String? namespace;

  Partition(this.namespace) {
    if (namespace == '') {
      throw ArgumentError('The namespace must not be an empty string');
    }
  }

  /// Returns an empty [Key].
  ///
  /// Entities where the parent [Key] is empty will create their own entity
  /// group.
  Key get emptyKey => Key.emptyKey(this);

  @override
  bool operator ==(Object other) {
    return other is Partition && namespace == other.namespace;
  }

  @override
  int get hashCode => namespace.hashCode;
}

/// Superclass for all model classes.
///
/// Every model class has a [id] of type [T] which must be `int` or `String`, and
/// a [parentKey]. The [key] getter is returning the key for the model object.
abstract class Model<T> {
  T? id;
  Key? parentKey;

  Key<T> get key => parentKey!.append(runtimeType, id: id);
}

/// Superclass for all expanded model classes.
///
/// The [ExpandoModel] class adds support for having dynamic properties. You can
/// set arbitrary fields on these models. The expanded values must be values
/// accepted by the [RawDatastore] implementation.
abstract class ExpandoModel<T> extends Model<T> {
  final Map<String, Object?> additionalProperties = {};

  @override
  Object? noSuchMethod(Invocation invocation) {
    var name = mirrors.MirrorSystem.getName(invocation.memberName);
    if (name.endsWith('=')) name = name.substring(0, name.length - 1);
    if (invocation.isGetter) {
      return additionalProperties[name];
    } else if (invocation.isSetter) {
      var value = invocation.positionalArguments[0];
      additionalProperties[name] = value;
      return value;
    } else {
      throw ArgumentError('Unsupported noSuchMethod call on ExpandoModel');
    }
  }
}
