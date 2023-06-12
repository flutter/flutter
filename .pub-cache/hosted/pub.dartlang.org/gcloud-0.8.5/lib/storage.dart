// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library provides access to Google Cloud Storage.
///
/// Google Cloud Storage is an object store for binary objects. Each
/// object has a set of metadata attached to it. For more information on
/// Google Cloud Storage see https://developers.google.com/storage/.
///
/// There are two main concepts in Google Cloud Storage: Buckets and Objects.
/// A bucket is a container for objects and objects are the actual binary
/// objects.
///
/// The API has two main classes for dealing with buckets and objects.
///
/// The class `Storage` is the main API class providing access to working
/// with buckets. This is the 'bucket service' interface.
///
/// The class `Bucket` provide access to working with objects in a specific
/// bucket. This is the 'object service' interface.
///
/// Both buckets have objects, have names. The bucket namespace is flat and
/// global across all projects. This means that a bucket is always
/// addressable using its name without requiring further context.
///
/// Within buckets the object namespace is also flat. Object are *not*
/// organized hierarchical. However, as object names allow the slash `/`
/// character this is often used to simulate a hierarchical structure
/// based on common prefixes.
///
/// This package uses relative and absolute names to refer to objects. A
/// relative name is just the object name within a bucket, and requires the
/// context of a bucket to be used. A relative name just looks like this:
///
///     object_name
///
/// An absolute name includes the bucket name and uses the `gs://` prefix
/// also used by the `gsutil` tool. An absolute name looks like this.
///
///     gs://bucket_name/object_name
///
/// In most cases relative names are used. Absolute names are typically
/// only used for operations involving objects in different buckets.
///
/// For most of the APIs in ths library which take instances of other classes
/// from this library it is the assumption that the actual implementations
/// provided here are used.
library gcloud.storage;

import 'dart:async';
import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;
import 'dart:convert';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:http/http.dart' as http;

import 'common.dart';
import 'service_scope.dart' as ss;

export 'common.dart';

part 'src/storage_impl.dart';

const Symbol _storageKey = #gcloud.storage;

/// Access the [Storage] object available in the current service scope.
///
/// The returned object will be the one which was previously registered with
/// [registerStorageService] within the current (or a parent) service scope.
///
/// Accessing this getter outside of a service scope will result in an error.
/// See the `package:gcloud/service_scope.dart` library for more information.
Storage get storageService => ss.lookup(_storageKey) as Storage;

/// Registers the [storage] object within the current service scope.
///
/// The provided `storage` object will be available via the top-level
/// `storageService` getter.
///
/// Calling this function outside of a service scope will result in an error.
/// Calling this function more than once inside the same service scope is not
/// allowed.
void registerStorageService(Storage storage) {
  ss.register(_storageKey, storage);
}

int _jenkinsHash(List e) {
  const _hashMask = 0x3fffffff;
  var hash = 0;
  for (var i = 0; i < e.length; i++) {
    var c = e[i].hashCode;
    hash = (hash + c) & _hashMask;
    hash = (hash + (hash << 10)) & _hashMask;
    hash ^= (hash >> 6);
  }
  hash = (hash + (hash << 3)) & _hashMask;
  hash ^= (hash >> 11);
  hash = (hash + (hash << 15)) & _hashMask;
  return hash;
}

/// An ACL (Access Control List) describes access rights to buckets and
/// objects.
///
/// An ACL is a prioritized sequence of access control specifications,
/// which individually prevent or grant access.
/// The access controls are described by [AclEntry] objects.
class Acl {
  final List<AclEntry> _entries;

  /// The entries in the ACL.
  List<AclEntry> get entries => UnmodifiableListView<AclEntry>(_entries);

  /// Create a new ACL with a list of ACL entries.
  Acl(Iterable<AclEntry> entries) : _entries = List.from(entries);

  Acl._fromBucketAcl(storage_api.Bucket bucket)
      : _entries = [
          for (final control
              in bucket.acl ?? const <storage_api.BucketAccessControl>[])
            AclEntry(_aclScopeFromEntity(control.entity!),
                _aclPermissionFromRole(control.role))
        ];

  Acl._fromObjectAcl(storage_api.Object object)
      : _entries = [
          for (final entry in object.acl ?? <storage_api.ObjectAccessControl>[])
            AclEntry(_aclScopeFromEntity(entry.entity!),
                _aclPermissionFromRole(entry.role)),
        ];

  static AclScope _aclScopeFromEntity(String entity) {
    if (entity.startsWith('user-')) {
      var tmp = entity.substring(5);
      var at = tmp.indexOf('@');
      if (at != -1) {
        return AccountScope(tmp);
      } else {
        return StorageIdScope(tmp);
      }
    } else if (entity.startsWith('group-')) {
      return GroupScope(entity.substring(6));
    } else if (entity.startsWith('domain-')) {
      return DomainScope(entity.substring(7));
    } else if (entity.startsWith('allAuthenticatedUsers-')) {
      return AclScope.allAuthenticated;
    } else if (entity.startsWith('allUsers-')) {
      return AclScope.allUsers;
    } else if (entity.startsWith('project-')) {
      var tmp = entity.substring(8);
      var dash = tmp.indexOf('-');
      if (dash != -1) {
        return ProjectScope(tmp.substring(dash + 1), tmp.substring(0, dash));
      }
    }
    return OpaqueScope(entity);
  }

  static AclPermission _aclPermissionFromRole(String? role) {
    if (role == 'READER') return AclPermission.READ;
    if (role == 'WRITER') return AclPermission.WRITE;
    if (role == 'OWNER') return AclPermission.FULL_CONTROL;
    throw UnsupportedError(
        "Server returned a unsupported permission role '$role'");
  }

  List<storage_api.BucketAccessControl> _toBucketAccessControlList() {
    return _entries.map((entry) => entry._toBucketAccessControl()).toList();
  }

  List<storage_api.ObjectAccessControl> _toObjectAccessControlList() {
    return _entries.map((entry) => entry._toObjectAccessControl()).toList();
  }

  @override
  late final int hashCode = _jenkinsHash(_entries);

  @override
  bool operator ==(Object other) {
    if (other is Acl) {
      List entries = _entries;
      List otherEntries = other._entries;
      if (entries.length != otherEntries.length) return false;
      for (var i = 0; i < entries.length; i++) {
        if (entries[i] != otherEntries[i]) return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  String toString() => 'Acl($_entries)';
}

/// An ACL entry specifies that an entity has a specific access permission.
///
/// A permission grants a specific permission to the entity.
class AclEntry {
  final AclScope scope;
  final AclPermission permission;

  AclEntry(this.scope, this.permission);

  storage_api.BucketAccessControl _toBucketAccessControl() {
    var acl = storage_api.BucketAccessControl();
    acl.entity = scope._storageEntity;
    acl.role = permission._storageBucketRole;
    return acl;
  }

  storage_api.ObjectAccessControl _toObjectAccessControl() {
    var acl = storage_api.ObjectAccessControl();
    acl.entity = scope._storageEntity;
    acl.role = permission._storageObjectRole;
    return acl;
  }

  @override
  late final int hashCode = _jenkinsHash([scope, permission]);

  @override
  bool operator ==(Object other) {
    return other is AclEntry &&
        scope == other.scope &&
        permission == other.permission;
  }

  @override
  String toString() => 'AclEntry($scope, $permission)';
}

/// An ACL scope specifies an entity for which a permission applies.
///
/// A scope can be one of:
///
///   * Google Storage ID
///   * Google account email address
///   * Google group email address
///   * Google Apps domain
///   * Special identifier for all Google account holders
///   * Special identifier for all users
///
/// See https://cloud.google.com/storage/docs/accesscontrol for more details.
abstract class AclScope {
  /// ACL type for scope representing a Google Storage id.
  static const int _typeStorageId = 0;

  /// ACL type for scope representing a project entity.
  static const int _typeProject = 1;

  /// ACL type for scope representing an account holder.
  static const int _typeAccount = 2;

  /// ACL type for scope representing a group.
  static const int _typeGroup = 3;

  /// ACL type for scope representing a domain.
  static const int _typeDomain = 4;

  /// ACL type for scope representing all authenticated users.
  static const int _typeAllAuthenticated = 5;

  /// ACL type for scope representing all users.
  static const int _typeAllUsers = 6;

  /// ACL type for scope representing an unsupported scope.
  static const int _typeOpaque = 7;

  /// The id of the actual entity this ACL scope represents. The actual values
  /// are set in the different subclasses.
  final String _id;

  /// The type of this acope this ACL scope represents.
  final int _type;

  /// ACL scope for all authenticated users.
  static AllAuthenticatedScope allAuthenticated = AllAuthenticatedScope();

  /// ACL scope for all users.
  static AllUsersScope allUsers = AllUsersScope();

  AclScope._(this._type, this._id);

  @override
  late final int hashCode = _jenkinsHash([_type, _id]);

  @override
  bool operator ==(Object other) {
    return other is AclScope && _type == other._type && _id == other._id;
  }

  @override
  String toString() => 'AclScope($_storageEntity)';

  String get _storageEntity;
}

/// An ACL scope for an entity identified by a 'Google Storage ID'.
///
/// The [storageId] is a string of 64 hexadecimal digits that identifies a
/// specific Google account holder or a specific Google group.
class StorageIdScope extends AclScope {
  StorageIdScope(String storageId)
      : super._(AclScope._typeStorageId, storageId);

  /// Google Storage ID.
  String get storageId => _id;

  @override
  String get _storageEntity => 'user-$_id';
}

/// An ACL scope for an entity identified by an individual email address.
class AccountScope extends AclScope {
  AccountScope(String email) : super._(AclScope._typeAccount, email);

  /// Email address.
  String get email => _id;

  @override
  String get _storageEntity => 'user-$_id';
}

/// An ACL scope for an entity identified by an Google Groups email.
class GroupScope extends AclScope {
  GroupScope(String group) : super._(AclScope._typeGroup, group);

  /// Group name.
  String get group => _id;

  @override
  String get _storageEntity => 'group-$_id';
}

/// An ACL scope for an entity identified by a domain name.
class DomainScope extends AclScope {
  DomainScope(String domain) : super._(AclScope._typeDomain, domain);

  /// Domain name.
  String get domain => _id;

  @override
  String get _storageEntity => 'domain-$_id';
}

/// An ACL scope for an project related entity.
class ProjectScope extends AclScope {
  /// Project role.
  ///
  /// Possible values are `owners`, `editors` and `viewers`.
  final String role;

  ProjectScope(String project, this.role)
      : super._(AclScope._typeProject, project);

  /// Project ID.
  String get project => _id;

  @override
  String get _storageEntity => 'project-$role-$_id';
}

/// An ACL scope for an unsupported scope.
class OpaqueScope extends AclScope {
  OpaqueScope(String id) : super._(AclScope._typeOpaque, id);

  @override
  String get _storageEntity => _id;
}

/// ACL scope for a all authenticated users.
class AllAuthenticatedScope extends AclScope {
  AllAuthenticatedScope() : super._(AclScope._typeAllAuthenticated, 'invalid');

  @override
  String get _storageEntity => 'allAuthenticatedUsers';
}

/// ACL scope for a all users.
class AllUsersScope extends AclScope {
  AllUsersScope() : super._(AclScope._typeAllUsers, 'invalid');

  @override
  String get _storageEntity => 'allUsers';
}

/// Permissions for individual scopes in an ACL.
class AclPermission {
  /// Provide read access.
  // ignore: constant_identifier_names
  static const READ = AclPermission._('READER');

  /// Provide write access.
  ///
  /// For objects this permission is the same as [FULL_CONTROL].
  // ignore: constant_identifier_names
  static const WRITE = AclPermission._('WRITER');

  /// Provide full control.
  ///
  /// For objects this permission is the same as [WRITE].
  // ignore: constant_identifier_names
  static const FULL_CONTROL = AclPermission._('OWNER');

  final String _id;

  const AclPermission._(this._id);

  String get _storageBucketRole => _id;

  String get _storageObjectRole => this == WRITE ? FULL_CONTROL._id : _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is AclPermission && _id == other._id;
  }

  @override
  String toString() => 'AclPermission($_id)';
}

/// Definition of predefined ACLs.
///
/// There is a convenient way of referring to number of _predefined_ ACLs. These
/// predefined ACLs have explicit names, and can _only_ be used to set an ACL,
/// when either creating or updating a bucket or object. This set of predefined
/// ACLs are expanded on the server to their actual list of [AclEntry] objects.
/// When information is retrieved on a bucket or object, this expanded list will
/// be present. For a description of these predefined ACLs see:
/// https://cloud.google.com/storage/docs/accesscontrol#extension.
class PredefinedAcl {
  final String _name;
  const PredefinedAcl._(this._name);

  /// Predefined ACL for the 'authenticated-read' ACL. Applies to both buckets
  /// and objects.
  static const PredefinedAcl authenticatedRead =
      PredefinedAcl._('authenticatedRead');

  /// Predefined ACL for the 'private' ACL. Applies to both buckets
  /// and objects.
  static const PredefinedAcl private = PredefinedAcl._('private');

  /// Predefined ACL for the 'project-private' ACL. Applies to both buckets
  /// and objects.
  static const PredefinedAcl projectPrivate = PredefinedAcl._('projectPrivate');

  /// Predefined ACL for the 'public-read' ACL. Applies to both buckets
  /// and objects.
  static const PredefinedAcl publicRead = PredefinedAcl._('publicRead');

  /// Predefined ACL for the 'public-read-write' ACL. Applies only to buckets.
  static const PredefinedAcl publicReadWrite =
      PredefinedAcl._('publicReadWrite');

  /// Predefined ACL for the 'bucket-owner-full-control' ACL. Applies only to
  /// objects.
  static const PredefinedAcl bucketOwnerFullControl =
      PredefinedAcl._('bucketOwnerFullControl');

  /// Predefined ACL for the 'bucket-owner-read' ACL. Applies only to
  /// objects.
  static const PredefinedAcl bucketOwnerRead =
      PredefinedAcl._('bucketOwnerRead');

  @override
  String toString() => 'PredefinedAcl($_name)';
}

/// Information on a bucket.
abstract class BucketInfo {
  /// Name of the bucket.
  String get bucketName;

  /// Entity tag for the bucket.
  String get etag;

  /// When this bucket was created.
  DateTime get created;

  /// Bucket ID.
  String get id;

  /// Acl of the bucket.
  Acl get acl;
}

/// Access to Cloud Storage
abstract class Storage {
  /// List of required OAuth2 scopes for Cloud Storage operation.
  // ignore: constant_identifier_names
  static const List<String> SCOPES = <String>[
    storage_api.StorageApi.devstorageFullControlScope
  ];

  /// Initializes access to cloud storage.
  factory Storage(http.Client client, String project) = _StorageImpl;

  /// Create a cloud storage bucket.
  ///
  /// Creates a cloud storage bucket named [bucketName].
  ///
  /// The bucket ACL can be set by passing [predefinedAcl] or [acl]. If both
  /// are passed the entries from [acl] with be followed by the expansion of
  /// [predefinedAcl].
  ///
  /// Returns a [Future] which completes when the bucket has been created.
  Future createBucket(String bucketName,
      {PredefinedAcl? predefinedAcl, Acl? acl});

  /// Delete a cloud storage bucket.
  ///
  /// Deletes the cloud storage bucket named [bucketName].
  ///
  /// If the bucket is not empty the operation will fail.
  ///
  /// The returned [Future] completes when the operation is finished.
  Future deleteBucket(String bucketName);

  /// Access bucket object operations.
  ///
  /// Instantiates a `Bucket` object referring to the bucket named [bucketName].
  ///
  /// When an object is created using the resulting `Bucket` an ACL will always
  /// be set. If the object creation does not pass any explicit ACL information
  /// a default ACL will be used.
  ///
  /// If the arguments [defaultPredefinedObjectAcl] or [defaultObjectAcl] are
  /// passed they define the default ACL. If both are passed the entries from
  /// [defaultObjectAcl] with be followed by the expansion of
  /// [defaultPredefinedObjectAcl] when an object is created.
  ///
  /// Otherwise the default object ACL attached to the bucket will be used.
  ///
  /// Returns a `Bucket` instance.
  Bucket bucket(String bucketName,
      {PredefinedAcl? defaultPredefinedObjectAcl, Acl? defaultObjectAcl});

  /// Check whether a cloud storage bucket exists.
  ///
  /// Checks whether the bucket named [bucketName] exists.
  ///
  /// Returns a [Future] which completes with `true` if the bucket exists.
  Future<bool> bucketExists(String bucketName);

  /// Get information on a bucket
  ///
  /// Provide metadata information for bucket named [bucketName].
  ///
  /// Returns a [Future] which completes with a `BucketInfo` object.
  Future<BucketInfo> bucketInfo(String bucketName);

  /// List names of all buckets.
  ///
  /// Returns a [Stream] of bucket names.
  Stream<String> listBucketNames();

  /// Start paging through names of all buckets.
  ///
  /// The maximum number of buckets in each page is specified in [pageSize].
  ///
  /// Returns a [Future] which completes with a `Page` object holding the
  /// first page. Use the `Page` object to move to the next page of buckets.
  Future<Page<String>> pageBucketNames({int pageSize = 50});

  /// Copy an object.
  ///
  /// Copy object [src] to object [dest].
  ///
  /// The names of [src] and [dest] must be absolute.
  Future copyObject(String src, String dest);
}

/// Information on a specific object.
///
/// This class provides access to information on an object. This includes
/// both the properties which are provided by Cloud Storage (such as the
/// MD5 hash) and the properties which can be changed (such as content type).
///
///  The properties provided by Cloud Storage are direct properties on this
///  object.
///
///  The mutable properties are properties on the `metadata` property.
abstract class ObjectInfo {
  /// Name of the object.
  String get name;

  /// Length of the data.
  int get length;

  /// When this object was updated.
  DateTime get updated;

  /// Entity tag for the object.
  String get etag;

  /// MD5 hash of the object.
  List<int> get md5Hash;

  /// CRC32c checksum, as described in RFC 4960.
  int get crc32CChecksum;

  /// URL for direct download.
  Uri get downloadLink;

  /// Object generation.
  ObjectGeneration get generation;

  /// Additional metadata.
  ObjectMetadata get metadata;
}

/// Generational information on an object.
class ObjectGeneration {
  /// Object generation.
  final String objectGeneration;

  /// Metadata generation.
  final int metaGeneration;

  const ObjectGeneration(this.objectGeneration, this.metaGeneration);
}

/// Access to object metadata.
abstract class ObjectMetadata {
  factory ObjectMetadata(
      {Acl? acl,
      String? contentType,
      String? contentEncoding,
      String? cacheControl,
      String? contentDisposition,
      String? contentLanguage,
      Map<String, String>? custom}) = _ObjectMetadata;

  /// ACL.
  Acl? get acl;

  /// `Content-Type` for this object.
  String? get contentType;

  /// `Content-Encoding` for this object.
  String? get contentEncoding;

  /// `Cache-Control` for this object.
  String? get cacheControl;

  /// `Content-Disposition` for this object.
  String? get contentDisposition;

  /// `Content-Language` for this object.
  ///
  /// The value of this field must confirm to RFC 3282.
  String? get contentLanguage;

  /// Custom metadata.
  Map<String, String>? get custom;

  /// Create a copy of this object with some values replaced.
  ///
  // TODO: This cannot be used to set values to null.
  ObjectMetadata replace(
      {Acl? acl,
      String? contentType,
      String? contentEncoding,
      String? cacheControl,
      String? contentDisposition,
      String? contentLanguage,
      Map<String, String>? custom});
}

/// Result from List objects in a bucket.
///
/// Listing operate like a directory listing, despite the object
/// namespace being flat.
///
/// See [Bucket.list] for information on how the hierarchical structure
/// is determined.
class BucketEntry {
  /// Whether this is information on an object.
  final bool isObject;

  /// Name of object or directory.
  final String name;

  BucketEntry._object(this.name) : isObject = true;

  BucketEntry._directory(this.name) : isObject = false;

  /// Whether this is a prefix.
  bool get isDirectory => !isObject;
}

/// Access to operations on a specific cloud storage bucket.
abstract class Bucket {
  /// Name of this bucket.
  String get bucketName;

  /// Absolute name of an object in this bucket. This includes the gs:// prefix.
  String absoluteObjectName(String objectName);

  /// Create a new object.
  ///
  /// Create an object named [objectName] in the bucket.
  ///
  /// If an object named [objectName] already exists this object will be
  /// replaced.
  ///
  /// If the length of the data to write is known in advance this can be passed
  /// as [length]. This can help to optimize the upload process.
  ///
  /// Additional metadata on the object can be passed either through the
  /// `metadata` argument or through the specific named arguments
  /// (such as `contentType`). Values passed through the specific named
  /// arguments takes precedence over the values in `metadata`.
  ///
  /// If [contentType] is not passed the default value of
  /// `application/octet-stream` will be used.
  ///
  /// It is possible to at one of the predefined ACLs on the created object
  /// using the [predefinedAcl] argument. If the [metadata] argument contain a
  /// ACL as well, this ACL with be followed by the expansion of
  /// [predefinedAcl].
  ///
  /// Returns a `StreamSink` where the object content can be written. When
  /// The object content has been written the `StreamSink` completes with
  /// an `ObjectInfo` instance with the information on the object created.
  StreamSink<List<int>> write(String objectName,
      {int? length,
      ObjectMetadata? metadata,
      Acl? acl,
      PredefinedAcl? predefinedAcl,
      String? contentType});

  /// Create an new object in the bucket with specified content.
  ///
  /// Writes [bytes] to the created object.
  ///
  /// See [write] for more information on the additional arguments.
  ///
  /// Returns a `Future` which completes with an `ObjectInfo` instance when
  /// the object is written.
  Future<ObjectInfo> writeBytes(String name, List<int> bytes,
      {ObjectMetadata? metadata,
      Acl? acl,
      PredefinedAcl? predefinedAcl,
      String? contentType});

  /// Read object content as byte stream.
  ///
  /// If [offset] is provided, [length] must also be provided.
  ///
  /// If [length] is provided, it must be greater than `0`.
  ///
  /// If there is a problem accessing the file, a [DetailedApiRequestError] is
  /// thrown.
  Stream<List<int>> read(String objectName, {int? offset, int? length});

  /// Lookup object metadata.
  ///
  // TODO: More documentation
  Future<ObjectInfo> info(String name);

  /// Delete an object.
  ///
  // TODO: More documentation
  Future delete(String name);

  /// Update object metadata.
  ///
  // TODO: More documentation
  Future updateMetadata(String objectName, ObjectMetadata metadata);

  /// List objects in the bucket.
  ///
  /// Listing operates like a directory listing, despite the object
  /// namespace being flat. Unless [delimiter] is specified, the character `/`
  /// is being used to separate object names into directory components.
  /// To list objects recursively, the [delimiter] can be set to empty string.
  ///
  /// Retrieves a list of objects and directory components starting
  /// with [prefix].
  ///
  /// Returns a [Stream] of [BucketEntry]. Each element of the stream
  /// represents either an object or a directory component.
  Stream<BucketEntry> list({String? prefix, String? delimiter});

  /// Start paging through objects in the bucket.
  ///
  /// The maximum number of objects in each page is specified in [pageSize].
  ///
  /// See [list] for more information on the other arguments.
  ///
  /// Returns a `Future` which completes with a `Page` object holding the
  /// first page. Use the `Page` object to move to the next page.
  Future<Page<BucketEntry>> page(
      {String? prefix, String? delimiter, int pageSize = 50});
}
