// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.db;

/// An implementation of [ModelDB] based on model class annotations.
///
/// The two constructors will scan loaded dart libraries for classes with a
/// [Kind] annotation.
///
/// An example on how to write a model class is:
///     @Kind
///     class Person extends db.Model {
///       @StringProperty
///       String name;
///
///       @IntProperty
///       int age;
///
///       @DateTimeProperty
///       DateTime dateOfBirth;
///     }
///
/// These classes must either extend [Model] or [ExpandoModel]. Furthermore
/// they must have an empty default constructor which can be used to construct
/// model objects when doing lookups/queries from datastore.
class ModelDBImpl implements ModelDB {
  final Map<_ModelDescription, Map<String, Property>> _modelDesc2Properties =
      {};
  final Map<String, _ModelDescription> _kind2ModelDesc = {};
  final Map<_ModelDescription, mirrors.ClassMirror> _modelDesc2ClassMirror = {};
  final Map<_ModelDescription, Type> _type2ModelDesc = {};
  final Map<Type, _ModelDescription> _modelDesc2Type = {};

  /// Initializes a new [ModelDB] from all libraries.
  ///
  /// This will scan all libraries for classes with a [Kind] annotation.
  ///
  /// In case an error is encountered (e.g. two model classes with the same kind
  /// name) a [StateError] will be thrown.
  ModelDBImpl() {
    // WARNING: This is O(n) of the source code, which is very bad!
    // Would be nice to have: `currentMirrorSystem().subclassesOf(Model)`
    _initialize(mirrors.currentMirrorSystem().libraries.values);
  }

  /// Initializes a new [ModelDB] from all libraries.
  ///
  /// This will scan the given [librarySymbol] for classes with a [Kind]
  /// annotation.
  ///
  /// In case an error is encountered (e.g. two model classes with the same kind
  /// name) a [StateError] will be thrown.
  ModelDBImpl.fromLibrary(Symbol librarySymbol) {
    _initialize([mirrors.currentMirrorSystem().findLibrary(librarySymbol)]);
  }

  /// Converts a [ds.Key] to a [Key]. The key returned will have the correct
  /// id type which is either `Key<String>` or `Key<int>`.
  @override
  Key fromDatastoreKey(ds.Key datastoreKey) {
    var namespace = Partition(datastoreKey.partition.namespace);
    var key = namespace.emptyKey;
    for (var element in datastoreKey.elements) {
      var type = _type2ModelDesc[_kind2ModelDesc[element.kind]!];
      if (type == null) {
        throw StateError(
            'Could not find a model associated with kind "${element.kind}". '
            'Please ensure a model class was annotated with '
            '`@Kind(name: "${element.kind}")`.');
      }
      final elementId = element.id;
      if (elementId is String) {
        key = key.append<String>(type, id: elementId);
      } else if (elementId is int) {
        key = key.append<int>(type, id: elementId);
      } else {
        throw StateError('Key must be either String or int, but '
            'was ${elementId.runtimeType} for key ${element.kind}');
      }
    }
    return key;
  }

  /// Converts a [Key] to a [ds.Key].
  @override
  ds.Key toDatastoreKey(Key dbKey) {
    var elements = <ds.KeyElement>[];
    var currentKey = dbKey;
    while (!currentKey.isEmpty) {
      var id = currentKey.id;

      var modelDescription = _modelDescriptionForType(currentKey.type)!;
      var kind = modelDescription.kindName(this);

      var useIntegerId = modelDescription.useIntegerId;

      if (useIntegerId && id != null && id is! int) {
        throw ArgumentError('Expected an integer id property but '
            'id was of type ${id.runtimeType}');
      }
      if (!useIntegerId && (id != null && id is! String)) {
        throw ArgumentError('Expected a string id property but '
            'id was of type ${id.runtimeType}');
      }

      elements.add(ds.KeyElement(kind, id));
      currentKey = currentKey.parent!;
    }
    var partition = currentKey._parent as Partition;
    return ds.Key(elements.reversed.toList(),
        partition: ds.Partition(partition.namespace));
  }

  /// Converts a [Model] instance to a [ds.Entity].
  @override
  ds.Entity toDatastoreEntity(Model model) {
    try {
      var modelDescription = _modelDescriptionForType(model.runtimeType)!;
      return modelDescription.encodeModel(this, model);
    } catch (error, stack) {
      throw ArgumentError('Error while encoding entity ($error, $stack).');
    }
  }

  /// Converts a [ds.Entity] to a [Model] instance.
  @override
  T? fromDatastoreEntity<T extends Model>(ds.Entity? entity) {
    if (entity == null) {
      return null;
    }
    var key = fromDatastoreKey(entity.key);
    var kind = entity.key.elements.last.kind;
    var modelDescription = _kind2ModelDesc[kind];
    if (modelDescription == null) {
      throw StateError('Trying to deserialize entity of kind '
          '$kind, but no Model class available for it.');
    }

    try {
      return modelDescription.decodeEntity<T>(this, key, entity);
    } catch (error, stack) {
      throw StateError('Error while decoding entity ($error, $stack).');
    }
  }

  /// Returns the string representation of the kind of model class [type].
  ///
  /// If the model class `type` is not found it will throw an `ArgumentError`.
  @override
  String kindName(Type type) {
    var kind = _modelDesc2Type[type]?.kind;
    if (kind == null) {
      throw ArgumentError('The class $type was not associated with a kind.');
    }
    return kind;
  }

  /// Returns the name of the property corresponding to the kind [kind] and
  /// [fieldName].
  @override
  String? fieldNameToPropertyName(String kind, String fieldName) {
    var modelDescription = _kind2ModelDesc[kind];
    if (modelDescription == null) {
      throw ArgumentError('The kind "$kind" is unknown.');
    }
    return modelDescription.fieldNameToPropertyName(fieldName);
  }

  /// Converts [value] according to the [Property] named [name] in [type].
  @override
  Object? toDatastoreValue(String kind, String fieldName, Object? value,
      {bool forComparison = false}) {
    var modelDescription = _kind2ModelDesc[kind];
    if (modelDescription == null) {
      throw ArgumentError('The kind "$kind" is unknown.');
    }
    return modelDescription.encodeField(this, fieldName, value,
        forComparison: forComparison);
  }

  Iterable<_ModelDescription> get _modelDescriptions {
    return _modelDesc2Type.values;
  }

  Map<String, Property> _propertiesForModel(
      _ModelDescription modelDescription) {
    return _modelDesc2Properties[modelDescription]!;
  }

  _ModelDescription? _modelDescriptionForType(Type? type) {
    return _modelDesc2Type[type!];
  }

  mirrors.ClassMirror? _modelClass(_ModelDescription md) {
    return _modelDesc2ClassMirror[md];
  }

  void _initialize(Iterable<mirrors.LibraryMirror> libraries) {
    for (var lm in libraries) {
      lm.declarations.values
          .whereType<mirrors.ClassMirror>()
          .where((d) => d.hasReflectedType)
          .forEach((declaration) {
        _tryLoadNewModelClass(declaration);
      });
    }

    // Ask every [ModelDescription] to compute whatever global state it wants
    // to have.
    for (var modelDescription in _modelDescriptions) {
      modelDescription.initialize(this);
    }

    // Ask every [ModelDescription] whether we should register it with a given
    // kind name.
    for (var modelDescription in _modelDescriptions) {
      var kindName = modelDescription.kindName(this);
      if (_kind2ModelDesc.containsKey(kindName)) {
        throw StateError('Cannot have two ModelDescriptions '
            'with the same kind ($kindName)');
      }
      _kind2ModelDesc[kindName] = modelDescription;
    }
  }

  void _tryLoadNewModelClass(mirrors.ClassMirror classMirror) {
    Kind? kindAnnotation;
    for (var instance in classMirror.metadata) {
      if (instance.reflectee.runtimeType == Kind) {
        if (kindAnnotation != null) {
          throw StateError(
              'Cannot have more than one ModelMetadata() annotation '
              'on a Model class');
        }
        kindAnnotation = instance.reflectee as Kind?;
      }
    }

    if (kindAnnotation != null) {
      var name = kindAnnotation.name;
      var integerId = kindAnnotation.idType == IdType.Integer;
      var stringId = kindAnnotation.idType == IdType.String;

      // Fall back to the class name.
      name ??= mirrors.MirrorSystem.getName(classMirror.simpleName);

      // This constraint should be guaranteed by the Kind() const constructor.
      assert((integerId && !stringId) || (!integerId && stringId));

      _tryLoadNewModelClassFull(classMirror, name, integerId);
    }
  }

  static bool _isRequiredAnnotation(mirrors.InstanceMirror annotation) {
    return annotation.type.simpleName == #Required;
  }

  /// Returns true if a  constructor invocation is valid even if the specified
  /// [parameter] is omitted.
  ///
  /// This is  true for named parameters, optional parameters, and parameters
  /// with a default value.
  static bool _canBeOmitted(mirrors.ParameterMirror parameter) {
    if (parameter.metadata.any(_isRequiredAnnotation)) {
      return false;
    }
    return parameter.isOptional ||
        parameter.isNamed ||
        parameter.hasDefaultValue;
  }

  /// Returns true if the specified [classMirror] has a default (unnamed)
  /// constructor that accepts an empty arguments list.
  @visibleForTesting
  static bool hasDefaultConstructor(mirrors.ClassMirror classMirror) {
    for (var declaration in classMirror.declarations.values) {
      if (declaration is mirrors.MethodMirror) {
        if (declaration.isConstructor &&
            declaration.constructorName == const Symbol('') &&
            declaration.parameters.every(_canBeOmitted)) {
          return true;
        }
      }
    }
    return false;
  }

  void _tryLoadNewModelClassFull(
      mirrors.ClassMirror modelClass, String name, bool useIntegerId) {
    assert(!_modelDesc2Type.containsKey(modelClass.reflectedType));

    _ModelDescription modelDesc;
    if (_isExpandoClass(modelClass)) {
      modelDesc = _ExpandoModelDescription(name, useIntegerId);
    } else {
      modelDesc = _ModelDescription(name, useIntegerId);
    }

    _type2ModelDesc[modelDesc] = modelClass.reflectedType;
    _modelDesc2Type[modelClass.reflectedType] = modelDesc;
    _modelDesc2ClassMirror[modelDesc] = modelClass;
    _modelDesc2Properties[modelDesc] =
        _propertiesFromModelDescription(modelClass);

    // Ensure we have an empty constructor.
    if (!hasDefaultConstructor(modelClass)) {
      throw StateError('Class ${modelClass.simpleName} does not have a default '
          'constructor.');
    }
  }

  Map<String, Property> _propertiesFromModelDescription(
      mirrors.ClassMirror modelClassMirror) {
    var properties = <String, Property>{};
    var propertyNames = <String>{};

    // Loop over all classes in the inheritance path up to the Object class.
    while (modelClassMirror.superclass != null) {
      var memberMap = modelClassMirror.instanceMembers;
      // Loop over all declarations (which includes fields)
      modelClassMirror.declarations
          .forEach((Symbol fieldSymbol, mirrors.DeclarationMirror decl) {
        // Look if the symbol is a getter and we have metadata attached to it.
        if (memberMap.containsKey(fieldSymbol) &&
            memberMap[fieldSymbol]!.isGetter) {
          final propertyAnnotations = decl.metadata
              .map((mirrors.InstanceMirror mirror) => mirror.reflectee)
              .whereType<Property>()
              .toList();

          if (propertyAnnotations.length > 1) {
            throw StateError(
                'Cannot have more than one Property annotation on a model '
                'field.');
          } else if (propertyAnnotations.length == 1) {
            var property = propertyAnnotations.first;

            // Get a String representation of the field and the value.
            var fieldName = mirrors.MirrorSystem.getName(fieldSymbol);

            // Determine the name to use for the property in datastore.
            var propertyName = property.propertyName;
            propertyName ??= fieldName;

            if (properties.containsKey(fieldName)) {
              throw StateError(
                  'Cannot have two Property objects describing the same field '
                  'in a model object class hierarchy.');
            }

            if (propertyNames.contains(propertyName)) {
              throw StateError(
                  'Cannot have two Property objects mapping to the same '
                  'datastore property name "$propertyName".');
            }
            properties[fieldName] = property;
            propertyNames.add(propertyName);
          }
        }
      });
      modelClassMirror = modelClassMirror.superclass!;
    }

    return properties;
  }

  final _originalExpandoModelClass = mirrors.reflectClass(ExpandoModel);
  final _originalModelClass = mirrors.reflectClass(Model);

  bool _isExpandoClass(mirrors.ClassMirror? modelClass) {
    while (modelClass != null && modelClass.superclass != modelClass) {
      if (modelClass.originalDeclaration == _originalExpandoModelClass) {
        return true;
      } else if (modelClass.originalDeclaration == _originalModelClass) {
        return false;
      }

      modelClass = modelClass.superclass;
    }
    throw StateError('This should be unreachable.');
  }
}

class _ModelDescription<T extends Model> {
  final HashMap<String, String> _property2FieldName = HashMap<String, String>();
  final HashMap<String, String> _field2PropertyName = HashMap<String, String>();
  final Set<String> _indexedProperties = <String>{};
  final Set<String> _unIndexedProperties = <String>{};

  final String kind;
  final bool useIntegerId;

  _ModelDescription(this.kind, this.useIntegerId);

  void initialize(ModelDBImpl db) {
    // Compute propertyName -> fieldName mapping.
    db._propertiesForModel(this).forEach((String fieldName, Property prop) {
      // The default of a datastore property name is the fieldName.
      // It can be overridden with [Property.propertyName].
      var propertyName = prop.propertyName;
      propertyName ??= fieldName;

      _property2FieldName[propertyName] = fieldName;
      _field2PropertyName[fieldName] = propertyName;
    });

    // Compute properties & unindexed properties
    db._propertiesForModel(this).forEach((String fieldName, Property prop) {
      var propertyName = prop.propertyName;
      propertyName ??= fieldName;

      if (prop.indexed) {
        _indexedProperties.add(propertyName);
      } else {
        _unIndexedProperties.add(propertyName);
      }
    });
  }

  String kindName(ModelDBImpl db) => kind;

  ds.Entity encodeModel(ModelDBImpl db, T model) {
    var key = db.toDatastoreKey(model.key);

    var properties = <String, Object?>{};
    var mirror = mirrors.reflect(model);

    db._propertiesForModel(this).forEach((String fieldName, Property prop) {
      _encodeProperty(db, model, mirror, properties, fieldName, prop);
    });

    return ds.Entity(key, properties,
        unIndexedProperties: _unIndexedProperties);
  }

  void _encodeProperty(
      ModelDBImpl db,
      Model model,
      mirrors.InstanceMirror mirror,
      Map properties,
      String fieldName,
      Property prop) {
    var propertyName = prop.propertyName;
    propertyName ??= fieldName;

    var value =
        mirror.getField(mirrors.MirrorSystem.getSymbol(fieldName)).reflectee;
    if (!prop.validate(db, value)) {
      throw StateError('Property validation failed for '
          'property $fieldName while trying to serialize entity of kind '
          '${model.runtimeType}. ');
    }
    properties[propertyName] = prop.encodeValue(db, value);
  }

  H decodeEntity<H extends Model>(ModelDBImpl db, Key key, ds.Entity entity) {
    // NOTE: this assumes a default constructor for the model classes!
    var classMirror = db._modelClass(this)!;
    var mirror = classMirror.newInstance(const Symbol(''), []);

    // Set the id and the parent key
    mirror.reflectee.id = key.id;
    mirror.reflectee.parentKey = key.parent;

    db._propertiesForModel(this).forEach((String fieldName, Property prop) {
      _decodeProperty(db, entity, mirror, fieldName, prop);
    });
    return mirror.reflectee as H;
  }

  void _decodeProperty(ModelDBImpl db, ds.Entity entity,
      mirrors.InstanceMirror mirror, String fieldName, Property prop) {
    var propertyName = fieldNameToPropertyName(fieldName);

    var rawValue = entity.properties[propertyName!];
    var value = prop.decodePrimitiveValue(db, rawValue);

    if (!prop.validate(db, value)) {
      throw StateError('Property validation failed while '
          'trying to deserialize entity of kind '
          '${entity.key.elements.last.kind} (property name: $propertyName)');
    }

    try {
      mirror.setField(mirrors.MirrorSystem.getSymbol(fieldName), value);
    } on TypeError catch (error) {
      throw StateError('Error trying to set property "${prop.propertyName}" '
          'to $value for field "$fieldName": $error');
    }
  }

  String? fieldNameToPropertyName(String fieldName) {
    return _field2PropertyName[fieldName];
  }

  String? propertyNameToFieldName(ModelDBImpl db, String propertySearchName) {
    return _property2FieldName[propertySearchName];
  }

  Object? encodeField(ModelDBImpl db, String fieldName, Object? value,
      {bool enforceFieldExists = true, bool forComparison = false}) {
    var property = db._propertiesForModel(this)[fieldName];
    if (property != null) {
      return property.encodeValue(db, value, forComparison: forComparison);
    }
    if (enforceFieldExists) {
      throw ArgumentError(
          'A field named "$fieldName" does not exist in kind "$kind".');
    }
    return null;
  }
}

// NOTE/TODO:
// Currently expanded properties are only
//   * decoded if there are no clashes in [usedNames]
//   * encoded if there are no clashes in [usedNames]
// We might want to throw an error if there are clashes, because otherwise
//   - we may end up removing properties after a read-write cycle
//   - we may end up dropping added properties in a write
// ([usedNames] := [realFieldNames] + [realPropertyNames])
class _ExpandoModelDescription extends _ModelDescription<ExpandoModel> {
  late Set<String> realFieldNames;
  late Set<String> realPropertyNames;
  late Set<String> usedNames;

  _ExpandoModelDescription(String kind, bool useIntegerId)
      : super(kind, useIntegerId);

  @override
  void initialize(ModelDBImpl db) {
    super.initialize(db);

    realFieldNames = Set<String>.from(_field2PropertyName.keys);
    realPropertyNames = Set<String>.from(_property2FieldName.keys);
    usedNames = <String>{}
      ..addAll(realFieldNames)
      ..addAll(realPropertyNames);
  }

  @override
  ds.Entity encodeModel(ModelDBImpl db, ExpandoModel model) {
    var entity = super.encodeModel(db, model);
    var properties = entity.properties;
    model.additionalProperties.forEach((String key, Object? value) {
      // NOTE: All expanded properties will be indexed.
      if (!usedNames.contains(key)) {
        properties[key] = value;
      }
    });
    return entity;
  }

  @override
  T decodeEntity<T extends Model>(ModelDBImpl db, Key key, ds.Entity entity) {
    var model = super.decodeEntity(db, key, entity) as ExpandoModel;
    var properties = entity.properties;
    properties.forEach((String key, Object? value) {
      if (!usedNames.contains(key)) {
        model.additionalProperties[key] = value;
      }
    });
    // TODO: check if there is a more elegant solution than this
    return model as T;
  }

  @override
  String fieldNameToPropertyName(String fieldName) {
    var propertyName = super.fieldNameToPropertyName(fieldName);
    // If the ModelDescription doesn't know about [fieldName], it's an
    // expanded property, where propertyName == fieldName.
    propertyName ??= fieldName;
    return propertyName;
  }

  @override
  String propertyNameToFieldName(ModelDBImpl db, String propertyName) {
    var fieldName = super.propertyNameToFieldName(db, propertyName);
    // If the ModelDescription doesn't know about [propertyName], it's an
    // expanded property, where propertyName == fieldName.
    fieldName ??= propertyName;
    return fieldName;
  }

  @override
  Object encodeField(ModelDBImpl db, String fieldName, Object? value,
      {bool enforceFieldExists = true, bool forComparison = false}) {
    // The [enforceFieldExists] argument is intentionally ignored.

    var primitiveValue = super.encodeField(db, fieldName, value,
        enforceFieldExists: false, forComparison: forComparison);
    // If superclass can't encode field, we return value here (and assume
    // it's primitive)
    // NOTE: Implicit assumption:
    // If value != null then superclass will return != null.
    // TODO: Ensure [value] is primitive in this case.
    primitiveValue ??= value;
    return primitiveValue!;
  }
}
