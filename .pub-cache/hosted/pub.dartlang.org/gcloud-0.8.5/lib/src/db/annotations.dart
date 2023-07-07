// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.db;

/// Annotation used to mark dart classes which can be stored into datastore.
///
/// The `Kind` annotation on a class as well as other `Property` annotations on
/// fields or getters of the class itself (and any of it's superclasses) up to
/// the [Model] class describe the *mapping* of *dart objects* to datastore
/// *entities*.
///
/// An "entity" is an object which can be stored into Google Cloud Datastore.
/// It contains a number of named "properties", some of them might get indexed,
/// others are not. A "property" value can be of a limited set of supported
/// types (such as `int` and `String`).
///
/// Here is an example of a dart model class which can be stored into datastore:
///     @Kind()
///     class Person extends db.Model {
///       @StringProperty()
///       String name;
///
///       @IntProperty()
///       int age;
///
///       @DateTimeProperty()
///       DateTime dateOfBirth;
///     }
class Kind {
  /// The kind name used when saving objects to datastore.
  ///
  /// If `null` the name will be the same as the class name at which the
  /// annotation is placed.
  final String? name;

  /// The type, either [ID_TYPE_INTEGER] or [ID_TYPE_STRING].
  final IdType idType;

  /// Annotation specifying the name of this kind and whether to use integer or
  /// string `id`s.
  ///
  /// If `name` is omitted, it will default to the name of class to which this
  /// annotation is attached to.
  const Kind({this.name, this.idType = IdType.Integer});
}

/// The type used for id's of an entity.
class IdType {
  /// Use integer ids for identifying entities.
  // ignore: constant_identifier_names
  static const IdType Integer = IdType('Integer');

  /// Use string ids for identifying entities.
  // ignore: constant_identifier_names
  static const IdType String = IdType('String');

  final core.String _type;

  const IdType(this._type);

  @override
  core.String toString() => 'IdType: $_type';
}

/// Describes a property of an Entity.
///
/// Please see [Kind] for an example on how to use them.
abstract class Property {
  /// The name of the property.
  ///
  /// If it is `null`, the name will be the same as used in the
  /// model class.
  final String? propertyName;

  /// Specifies whether this property is required or not.
  ///
  /// If required is `true`, it will be enforced when saving model objects to
  /// the datastore and when retrieving them.
  final bool required;

  /// Specifies whether this property should be indexed or not.
  ///
  /// When running queries no this property, it is necessary to set [indexed] to
  /// `true`.
  final bool indexed;

  const Property(
      {this.propertyName, this.required = false, this.indexed = true});

  bool validate(ModelDB db, Object? value) {
    if (required && value == null) return false;
    return true;
  }

  Object? encodeValue(ModelDB db, Object? value, {bool forComparison = false});

  Object? decodePrimitiveValue(ModelDB db, Object? value);
}

/// An abstract base class for primitive properties which can e.g. be used
/// within a composed `ListProperty`.
abstract class PrimitiveProperty extends Property {
  const PrimitiveProperty(
      {String? propertyName, bool required = false, bool indexed = true})
      : super(propertyName: propertyName, required: required, indexed: indexed);

  @override
  Object? encodeValue(ModelDB db, Object? value,
          {bool forComparison = false}) =>
      value;

  @override
  Object? decodePrimitiveValue(ModelDB db, Object? value) => value;
}

/// A boolean [Property].
///
/// It will validate that values are booleans before writing them to the
/// datastore and when reading them back.
class BoolProperty extends PrimitiveProperty {
  const BoolProperty(
      {String? propertyName, bool required = false, bool indexed = true})
      : super(propertyName: propertyName, required: required, indexed: indexed);

  @override
  bool validate(ModelDB db, Object? value) =>
      super.validate(db, value) && (value == null || value is bool);
}

/// A integer [Property].
///
/// It will validate that values are integers before writing them to the
/// datastore and when reading them back.
class IntProperty extends PrimitiveProperty {
  const IntProperty(
      {String? propertyName, bool required = false, bool indexed = true})
      : super(propertyName: propertyName, required: required, indexed: indexed);

  @override
  bool validate(ModelDB db, Object? value) =>
      super.validate(db, value) && (value == null || value is int);
}

/// A double [Property].
///
/// It will validate that values are doubles before writing them to the
/// datastore and when reading them back.
class DoubleProperty extends PrimitiveProperty {
  const DoubleProperty(
      {String? propertyName, bool required = false, bool indexed = true})
      : super(propertyName: propertyName, required: required, indexed: indexed);

  @override
  bool validate(ModelDB db, Object? value) =>
      super.validate(db, value) && (value == null || value is double);
}

/// A string [Property].
///
/// It will validate that values are strings before writing them to the
/// datastore and when reading them back.
class StringProperty extends PrimitiveProperty {
  const StringProperty(
      {String? propertyName, bool required = false, bool indexed = true})
      : super(propertyName: propertyName, required: required, indexed: indexed);

  @override
  bool validate(ModelDB db, Object? value) =>
      super.validate(db, value) && (value == null || value is String);
}

/// A key [Property].
///
/// It will validate that values are keys before writing them to the
/// datastore and when reading them back.
class ModelKeyProperty extends PrimitiveProperty {
  const ModelKeyProperty(
      {String? propertyName, bool required = false, bool indexed = true})
      : super(propertyName: propertyName, required: required, indexed: indexed);

  @override
  bool validate(ModelDB db, Object? value) =>
      super.validate(db, value) && (value == null || value is Key);

  @override
  Object? encodeValue(ModelDB db, Object? value, {bool forComparison = false}) {
    if (value == null) return null;
    return db.toDatastoreKey(value as Key);
  }

  @override
  Object? decodePrimitiveValue(ModelDB db, Object? value) {
    if (value == null) return null;
    return db.fromDatastoreKey(value as ds.Key);
  }
}

/// A binary blob [Property].
///
/// It will validate that values are blobs before writing them to the
/// datastore and when reading them back. Blob values will be represented by
/// List<int>.
class BlobProperty extends PrimitiveProperty {
  const BlobProperty({String? propertyName, bool required = false})
      : super(propertyName: propertyName, required: required, indexed: false);

  // NOTE: We don't validate that the entries of the list are really integers
  // of the range 0..255!
  // If an untyped list was created the type check will always succeed. i.e.
  //   "[1, true, 'bar'] is List<int>" evaluates to `true`
  @override
  bool validate(ModelDB db, Object? value) =>
      super.validate(db, value) && (value == null || value is List<int>);

  @override
  Object? encodeValue(ModelDB db, Object? value, {bool forComparison = false}) {
    if (value == null) return null;
    return ds.BlobValue(value as List<int>);
  }

  @override
  Object? decodePrimitiveValue(ModelDB db, Object? value) {
    if (value == null) return null;

    return (value as ds.BlobValue).bytes;
  }
}

/// A datetime [Property].
///
/// It will validate that values are DateTime objects before writing them to the
/// datastore and when reading them back.
class DateTimeProperty extends PrimitiveProperty {
  const DateTimeProperty(
      {String? propertyName, bool required = false, bool indexed = true})
      : super(propertyName: propertyName, required: required, indexed: indexed);

  @override
  bool validate(ModelDB db, Object? value) =>
      super.validate(db, value) && (value == null || value is DateTime);

  @override
  Object? decodePrimitiveValue(ModelDB db, Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value ~/ 1000, isUtc: true);
    }
    return value;
  }
}

/// A composed list [Property], with a `subProperty` for the list elements.
///
/// It will validate that values are List objects before writing them to the
/// datastore and when reading them back. It will also validate the elements
/// of the list itself.
class ListProperty extends Property {
  final PrimitiveProperty subProperty;

  // TODO: We want to support optional list properties as well.
  // Get rid of "required: true" here.
  const ListProperty(this.subProperty,
      {String? propertyName, bool indexed = true})
      : super(propertyName: propertyName, required: true, indexed: indexed);

  @override
  bool validate(ModelDB db, Object? value) {
    if (!super.validate(db, value) || value is! List) return false;

    for (var entry in value) {
      if (!subProperty.validate(db, entry)) return false;
    }
    return true;
  }

  @override
  Object? encodeValue(ModelDB db, Object? value, {bool forComparison = false}) {
    if (forComparison) {
      // If we have comparison of list properties (i.e. repeated property names)
      // the comparison object must not be a list, but the value itself.
      // i.e.
      //
      //   class Article {
      //      ...
      //      @ListProperty(StringProperty())
      //      List<String> tags;
      //      ...
      //   }
      //
      // should be queried via
      //
      //   await db.query(Article, 'tags=', "Dart").toList();
      //
      // So the [value] for the comparison is of type `String` and not
      // `List<String>`!
      return subProperty.encodeValue(db, value, forComparison: true);
    }

    if (value == null) return null;
    var list = value as List;
    if (list.isEmpty) return null;
    if (list.length == 1) return subProperty.encodeValue(db, list[0]);
    return list.map((value) => subProperty.encodeValue(db, value)).toList();
  }

  @override
  Object decodePrimitiveValue(ModelDB db, Object? value) {
    if (value == null) return [];
    if (value is! List) return [subProperty.decodePrimitiveValue(db, value)];
    return value
        .map((entry) => subProperty.decodePrimitiveValue(db, entry))
        .toList();
  }
}

/// A convenience [Property] for list of strings.
class StringListProperty extends ListProperty {
  const StringListProperty({String? propertyName, bool indexed = true})
      : super(const StringProperty(),
            propertyName: propertyName, indexed: indexed);

  @override
  Object decodePrimitiveValue(ModelDB db, Object? value) {
    return (super.decodePrimitiveValue(db, value) as core.List).cast<String>();
  }
}
