// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.firestore;

import android.util.Log;
import com.google.firebase.FirebaseApp;
import com.google.firebase.Timestamp;
import com.google.firebase.firestore.Blob;
import com.google.firebase.firestore.DocumentChange;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreSettings;
import com.google.firebase.firestore.GeoPoint;
import com.google.firebase.firestore.LoadBundleTaskProgress;
import com.google.firebase.firestore.Query;
import com.google.firebase.firestore.QuerySnapshot;
import com.google.firebase.firestore.SnapshotMetadata;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

class FlutterFirebaseFirestoreMessageCodec extends StandardMessageCodec {
  public static final FlutterFirebaseFirestoreMessageCodec INSTANCE =
      new FlutterFirebaseFirestoreMessageCodec();
  private static final byte DATA_TYPE_DATE_TIME = (byte) 128;
  private static final byte DATA_TYPE_GEO_POINT = (byte) 129;
  private static final byte DATA_TYPE_DOCUMENT_REFERENCE = (byte) 130;
  private static final byte DATA_TYPE_BLOB = (byte) 131;
  private static final byte DATA_TYPE_ARRAY_UNION = (byte) 132;
  private static final byte DATA_TYPE_ARRAY_REMOVE = (byte) 133;
  private static final byte DATA_TYPE_DELETE = (byte) 134;
  private static final byte DATA_TYPE_SERVER_TIMESTAMP = (byte) 135;
  private static final byte DATA_TYPE_TIMESTAMP = (byte) 136;
  private static final byte DATA_TYPE_INCREMENT_DOUBLE = (byte) 137;
  private static final byte DATA_TYPE_INCREMENT_INTEGER = (byte) 138;
  private static final byte DATA_TYPE_DOCUMENT_ID = (byte) 139;
  private static final byte DATA_TYPE_FIELD_PATH = (byte) 140;
  private static final byte DATA_TYPE_NAN = (byte) 141;
  private static final byte DATA_TYPE_INFINITY = (byte) 142;
  private static final byte DATA_TYPE_NEGATIVE_INFINITY = (byte) 143;
  private static final byte DATA_TYPE_FIRESTORE_INSTANCE = (byte) 144;
  private static final byte DATA_TYPE_FIRESTORE_QUERY = (byte) 145;
  private static final byte DATA_TYPE_FIRESTORE_SETTINGS = (byte) 146;

  @Override
  protected void writeValue(ByteArrayOutputStream stream, Object value) {
    if (value instanceof Date) {
      stream.write(DATA_TYPE_DATE_TIME);
      writeLong(stream, ((Date) value).getTime());
    } else if (value instanceof Timestamp) {
      stream.write(DATA_TYPE_TIMESTAMP);
      writeLong(stream, ((Timestamp) value).getSeconds());
      writeInt(stream, ((Timestamp) value).getNanoseconds());
    } else if (value instanceof GeoPoint) {
      stream.write(DATA_TYPE_GEO_POINT);
      writeAlignment(stream, 8);
      writeDouble(stream, ((GeoPoint) value).getLatitude());
      writeDouble(stream, ((GeoPoint) value).getLongitude());
    } else if (value instanceof DocumentReference) {
      stream.write(DATA_TYPE_DOCUMENT_REFERENCE);
      writeValue(stream, ((DocumentReference) value).getFirestore().getApp().getName());
      writeValue(stream, ((DocumentReference) value).getPath());
    } else if (value instanceof DocumentSnapshot) {
      writeDocumentSnapshot(stream, (DocumentSnapshot) value);
    } else if (value instanceof QuerySnapshot) {
      writeQuerySnapshot(stream, (QuerySnapshot) value);
    } else if (value instanceof DocumentChange) {
      writeDocumentChange(stream, (DocumentChange) value);
    } else if (value instanceof LoadBundleTaskProgress) {
      writeLoadBundleTaskProgress(stream, (LoadBundleTaskProgress) value);
    } else if (value instanceof SnapshotMetadata) {
      writeSnapshotMetadata(stream, (SnapshotMetadata) value);
    } else if (value instanceof Blob) {
      stream.write(DATA_TYPE_BLOB);
      writeBytes(stream, ((Blob) value).toBytes());
    } else if (value instanceof Double) {
      Double doubleValue = (Double) value;
      if (Double.isNaN(doubleValue)) {
        stream.write(DATA_TYPE_NAN);
      } else if (doubleValue.equals(Double.NEGATIVE_INFINITY)) {
        stream.write(DATA_TYPE_NEGATIVE_INFINITY);
      } else if (doubleValue.equals(Double.POSITIVE_INFINITY)) {
        stream.write(DATA_TYPE_INFINITY);
      } else {
        super.writeValue(stream, value);
      }
    } else {
      super.writeValue(stream, value);
    }
  }

  private void writeSnapshotMetadata(ByteArrayOutputStream stream, SnapshotMetadata value) {
    Map<String, Boolean> metadataMap = new HashMap<>();
    metadataMap.put("hasPendingWrites", value.hasPendingWrites());
    metadataMap.put("isFromCache", value.isFromCache());
    writeValue(stream, metadataMap);
  }

  private void writeDocumentChange(ByteArrayOutputStream stream, DocumentChange value) {
    Map<String, Object> changeMap = new HashMap<>();

    String type = null;
    switch (value.getType()) {
      case ADDED:
        type = "DocumentChangeType.added";
        break;
      case MODIFIED:
        type = "DocumentChangeType.modified";
        break;
      case REMOVED:
        type = "DocumentChangeType.removed";
        break;
    }

    changeMap.put("type", type);
    changeMap.put("data", value.getDocument().getData());
    changeMap.put("path", value.getDocument().getReference().getPath());
    changeMap.put("oldIndex", value.getOldIndex());
    changeMap.put("newIndex", value.getNewIndex());
    changeMap.put("metadata", value.getDocument().getMetadata());

    writeValue(stream, changeMap);
  }

  private void writeQuerySnapshot(ByteArrayOutputStream stream, QuerySnapshot value) {
    List<String> paths = new ArrayList<>();
    Map<String, Object> querySnapshotMap = new HashMap<>();
    List<Map<String, Object>> documents = new ArrayList<>();
    List<SnapshotMetadata> metadatas = new ArrayList<>();

    DocumentSnapshot.ServerTimestampBehavior serverTimestampBehavior =
        FlutterFirebaseFirestorePlugin.serverTimestampBehaviorHashMap.get(value.hashCode());

    for (DocumentSnapshot document : value.getDocuments()) {
      paths.add(document.getReference().getPath());
      if (serverTimestampBehavior != null) {
        documents.add(document.getData(serverTimestampBehavior));
      } else {
        documents.add(document.getData());
      }
      metadatas.add(document.getMetadata());
    }

    querySnapshotMap.put("paths", paths);
    querySnapshotMap.put("documents", documents);
    querySnapshotMap.put("metadatas", metadatas);
    querySnapshotMap.put("documentChanges", value.getDocumentChanges());
    querySnapshotMap.put("metadata", value.getMetadata());

    FlutterFirebaseFirestorePlugin.serverTimestampBehaviorHashMap.remove(value.hashCode());
    writeValue(stream, querySnapshotMap);
  }

  private void writeLoadBundleTaskProgress(
      ByteArrayOutputStream stream, LoadBundleTaskProgress snapshot) {
    Map<String, Object> snapshotMap = new HashMap<>();

    snapshotMap.put("bytesLoaded", snapshot.getBytesLoaded());
    snapshotMap.put("documentsLoaded", snapshot.getDocumentsLoaded());
    snapshotMap.put("totalBytes", snapshot.getTotalBytes());
    snapshotMap.put("totalDocuments", snapshot.getTotalDocuments());

    LoadBundleTaskProgress.TaskState taskState = snapshot.getTaskState();
    String convertedState = "running";

    switch (taskState) {
      case RUNNING:
        convertedState = "running";
        break;
      case SUCCESS:
        convertedState = "success";
        break;
      case ERROR:
        convertedState = "error";
        break;
    }

    snapshotMap.put("taskState", convertedState);

    writeValue(stream, snapshotMap);
  }

  @SuppressWarnings("ConstantConditions")
  private void writeDocumentSnapshot(ByteArrayOutputStream stream, DocumentSnapshot value) {
    Map<String, Object> snapshotMap = new HashMap<>();

    snapshotMap.put("path", value.getReference().getPath());

    if (value.exists()) {
      DocumentSnapshot.ServerTimestampBehavior serverTimestampBehavior =
          FlutterFirebaseFirestorePlugin.serverTimestampBehaviorHashMap.get(value.hashCode());
      if (serverTimestampBehavior != null) {
        snapshotMap.put("data", value.getData(serverTimestampBehavior));
      } else {
        snapshotMap.put("data", value.getData());
      }
    } else {
      snapshotMap.put("data", null);
    }

    snapshotMap.put("metadata", value.getMetadata());

    FlutterFirebaseFirestorePlugin.serverTimestampBehaviorHashMap.remove(value.hashCode());
    writeValue(stream, snapshotMap);
  }

  @Override
  protected Object readValueOfType(byte type, ByteBuffer buffer) {
    switch (type) {
      case DATA_TYPE_DATE_TIME:
        return new Date(buffer.getLong());
      case DATA_TYPE_TIMESTAMP:
        return new Timestamp(buffer.getLong(), buffer.getInt());
      case DATA_TYPE_GEO_POINT:
        readAlignment(buffer, 8);
        return new GeoPoint(buffer.getDouble(), buffer.getDouble());
      case DATA_TYPE_DOCUMENT_REFERENCE:
        FirebaseFirestore firestore = (FirebaseFirestore) readValue(buffer);
        final String path = (String) readValue(buffer);
        return firestore.document(path);
      case DATA_TYPE_BLOB:
        final byte[] bytes = readBytes(buffer);
        return Blob.fromBytes(bytes);
      case DATA_TYPE_ARRAY_UNION:
        return FieldValue.arrayUnion(toArray(readValue(buffer)));
      case DATA_TYPE_ARRAY_REMOVE:
        return FieldValue.arrayRemove(toArray(readValue(buffer)));
      case DATA_TYPE_DELETE:
        return FieldValue.delete();
      case DATA_TYPE_SERVER_TIMESTAMP:
        return FieldValue.serverTimestamp();
      case DATA_TYPE_INCREMENT_INTEGER:
        final Number integerIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(integerIncrementValue.intValue());
      case DATA_TYPE_INCREMENT_DOUBLE:
        final Number doubleIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(doubleIncrementValue.doubleValue());
      case DATA_TYPE_DOCUMENT_ID:
        return FieldPath.documentId();
      case DATA_TYPE_FIRESTORE_INSTANCE:
        return readFirestoreInstance(buffer);
      case DATA_TYPE_FIRESTORE_QUERY:
        return readFirestoreQuery(buffer);
      case DATA_TYPE_FIRESTORE_SETTINGS:
        return readFirestoreSettings(buffer);
      case DATA_TYPE_NAN:
        return Double.NaN;
      case DATA_TYPE_INFINITY:
        return Double.POSITIVE_INFINITY;
      case DATA_TYPE_NEGATIVE_INFINITY:
        return Double.NEGATIVE_INFINITY;
      case DATA_TYPE_FIELD_PATH:
        final int size = readSize(buffer);
        final List<Object> list = new ArrayList<>(size);
        for (int i = 0; i < size; i++) {
          list.add(readValue(buffer));
        }
        return FieldPath.of((String[]) list.toArray(new String[0]));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  private FirebaseFirestore readFirestoreInstance(ByteBuffer buffer) {
    String appName = (String) readValue(buffer);
    FirebaseFirestoreSettings settings = (FirebaseFirestoreSettings) readValue(buffer);

    synchronized (FlutterFirebaseFirestorePlugin.firestoreInstanceCache) {
      if (FlutterFirebaseFirestorePlugin.getCachedFirebaseFirestoreInstanceForKey(appName)
          != null) {
        return FlutterFirebaseFirestorePlugin.getCachedFirebaseFirestoreInstanceForKey(appName);
      }

      FirebaseApp app = FirebaseApp.getInstance(appName);
      FirebaseFirestore firestore = FirebaseFirestore.getInstance(app);

      firestore.setFirestoreSettings(settings);

      FlutterFirebaseFirestorePlugin.setCachedFirebaseFirestoreInstanceForKey(firestore, appName);
      return firestore;
    }
  }

  private FirebaseFirestoreSettings readFirestoreSettings(ByteBuffer buffer) {
    @SuppressWarnings("unchecked")
    Map<String, Object> settingsMap = (Map<String, Object>) readValue(buffer);

    FirebaseFirestoreSettings.Builder settingsBuilder = new FirebaseFirestoreSettings.Builder();

    if (settingsMap.get("persistenceEnabled") != null) {
      settingsBuilder.setPersistenceEnabled(
          (Boolean) Objects.requireNonNull(settingsMap.get("persistenceEnabled")));
    }

    if (settingsMap.get("host") != null) {
      settingsBuilder.setHost((String) Objects.requireNonNull(settingsMap.get("host")));
      // Only allow changing ssl if host is also specified.
      if (settingsMap.get("sslEnabled") != null) {
        settingsBuilder.setSslEnabled(
            (Boolean) Objects.requireNonNull(settingsMap.get("sslEnabled")));
      }
    }

    if (settingsMap.get("cacheSizeBytes") != null) {
      Long cacheSizeBytes = 104857600L;
      Object value = settingsMap.get("cacheSizeBytes");

      if (value instanceof Long) {
        cacheSizeBytes = (Long) value;
      } else if (value instanceof Integer) {
        cacheSizeBytes = Long.valueOf((Integer) value);
      }

      if (cacheSizeBytes == -1) {
        settingsBuilder.setCacheSizeBytes(FirebaseFirestoreSettings.CACHE_SIZE_UNLIMITED);
      } else {
        settingsBuilder.setCacheSizeBytes(cacheSizeBytes);
      }
    }

    return settingsBuilder.build();
  }

  private Query readFirestoreQuery(ByteBuffer buffer) {
    try {
      @SuppressWarnings("unchecked")
      Map<String, Object> values = (Map<String, Object>) readValue(buffer);
      FirebaseFirestore firestore =
          (FirebaseFirestore) Objects.requireNonNull(values.get("firestore"));

      String path = (String) Objects.requireNonNull(values.get("path"));
      boolean isCollectionGroup = (boolean) values.get("isCollectionGroup");
      @SuppressWarnings("unchecked")
      Map<String, Object> parameters = (Map<String, Object>) values.get("parameters");

      Query query;
      if (isCollectionGroup) {
        query = firestore.collectionGroup(path);
      } else {
        query = firestore.collection(path);
      }

      if (parameters == null) return query;

      // "where" filters
      @SuppressWarnings("unchecked")
      List<List<Object>> filters =
          (List<List<Object>>) Objects.requireNonNull(parameters.get("where"));
      for (List<Object> condition : filters) {
        FieldPath fieldPath = (FieldPath) condition.get(0);
        String operator = (String) condition.get(1);
        Object value = condition.get(2);

        if ("==".equals(operator)) {
          query = query.whereEqualTo(fieldPath, value);
        } else if ("!=".equals(operator)) {
          query = query.whereNotEqualTo(fieldPath, value);
        } else if ("<".equals(operator)) {
          query = query.whereLessThan(fieldPath, value);
        } else if ("<=".equals(operator)) {
          query = query.whereLessThanOrEqualTo(fieldPath, value);
        } else if (">".equals(operator)) {
          query = query.whereGreaterThan(fieldPath, value);
        } else if (">=".equals(operator)) {
          query = query.whereGreaterThanOrEqualTo(fieldPath, value);
        } else if ("array-contains".equals(operator)) {
          query = query.whereArrayContains(fieldPath, value);
        } else if ("array-contains-any".equals(operator)) {
          @SuppressWarnings("unchecked")
          List<Object> listValues = (List<Object>) value;
          query = query.whereArrayContainsAny(fieldPath, listValues);
        } else if ("in".equals(operator)) {
          @SuppressWarnings("unchecked")
          List<Object> listValues = (List<Object>) value;
          query = query.whereIn(fieldPath, listValues);
        } else if ("not-in".equals(operator)) {
          @SuppressWarnings("unchecked")
          List<Object> listValues = (List<Object>) value;
          query = query.whereNotIn(fieldPath, listValues);
        } else {
          Log.w(
              "FLTFirestoreMsgCodec",
              "An invalid query operator " + operator + " was received but not handled.");
        }
      }

      // "limit" filters
      Number limit = (Number) parameters.get("limit");
      if (limit != null) query = query.limit(limit.longValue());

      Number limitToLast = (Number) parameters.get("limitToLast");
      if (limitToLast != null) query = query.limitToLast(limitToLast.longValue());

      // "orderBy" filters
      @SuppressWarnings("unchecked")
      List<List<Object>> orderBy = (List<List<Object>>) parameters.get("orderBy");
      if (orderBy == null) return query;

      for (List<Object> order : orderBy) {
        FieldPath fieldPath = (FieldPath) order.get(0);
        boolean descending = (boolean) order.get(1);

        Query.Direction direction =
            descending ? Query.Direction.DESCENDING : Query.Direction.ASCENDING;

        query = query.orderBy(fieldPath, direction);
      }

      // cursor queries
      @SuppressWarnings("unchecked")
      List<Object> startAt = (List<Object>) parameters.get("startAt");
      if (startAt != null) query = query.startAt(Objects.requireNonNull(startAt.toArray()));

      @SuppressWarnings("unchecked")
      List<Object> startAfter = (List<Object>) parameters.get("startAfter");
      if (startAfter != null)
        query = query.startAfter(Objects.requireNonNull(startAfter.toArray()));

      @SuppressWarnings("unchecked")
      List<Object> endAt = (List<Object>) parameters.get("endAt");
      if (endAt != null) query = query.endAt(Objects.requireNonNull(endAt.toArray()));

      @SuppressWarnings("unchecked")
      List<Object> endBefore = (List<Object>) parameters.get("endBefore");
      if (endBefore != null) query = query.endBefore(Objects.requireNonNull(endBefore.toArray()));

      return query;
    } catch (Exception exception) {
      Log.e(
          "FLTFirestoreMsgCodec",
          "An error occurred while parsing query arguments, this is most likely an error with this SDK.",
          exception);
      return null;
    }
  }

  private Object[] toArray(Object source) {
    if (source instanceof List) {
      return ((List<?>) source).toArray();
    }

    if (source == null) {
      return new ArrayList<>().toArray();
    }

    String sourceType = source.getClass().getCanonicalName();
    String message = "java.util.List was expected, unable to convert '%s' to an object array";
    throw new IllegalArgumentException(String.format(message, sourceType));
  }
}
