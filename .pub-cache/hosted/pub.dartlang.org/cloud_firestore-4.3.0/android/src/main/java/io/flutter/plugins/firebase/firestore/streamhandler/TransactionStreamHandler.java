/*
 * Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

package io.flutter.plugins.firebase.firestore.streamhandler;

import android.os.Handler;
import android.os.Looper;
import androidx.annotation.Nullable;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.FirebaseFirestoreException.Code;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.firestore.Transaction;
import com.google.firebase.firestore.TransactionOptions;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestoreTransactionResult;
import io.flutter.plugins.firebase.firestore.utils.ExceptionConverter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class TransactionStreamHandler implements OnTransactionResultListener, StreamHandler {

  /** Callback when the transaction has been started. */
  public interface OnTransactionStartedListener {
    void onStarted(Transaction transaction);
  }

  final OnTransactionStartedListener onTransactionStartedListener;

  public TransactionStreamHandler(OnTransactionStartedListener onTransactionStartedListener) {
    this.onTransactionStartedListener = onTransactionStartedListener;
  }

  final Semaphore semaphore = new Semaphore(0);
  final Map<String, Object> response = new HashMap<>();
  final Handler mainLooper = new Handler(Looper.getMainLooper());

  @Override
  public void onListen(Object arguments, EventSink events) {
    @SuppressWarnings("unchecked")
    Map<String, Object> argumentsMap = (Map<String, Object>) arguments;

    FirebaseFirestore firestore =
        (FirebaseFirestore) Objects.requireNonNull(argumentsMap.get("firestore"));

    Object value = argumentsMap.get("timeout");
    Long timeout;

    if (value instanceof Long) {
      timeout = (Long) value;
    } else if (value instanceof Integer) {
      timeout = Long.valueOf((Integer) value);
    } else {
      timeout = 5000L;
    }

    // Always sent by the PlatformChannel
    int maxAttempts = (int) argumentsMap.get("maxAttempts");

    firestore
        .runTransaction(
            new TransactionOptions.Builder().setMaxAttempts(maxAttempts).build(),
            transaction -> {
              onTransactionStartedListener.onStarted(transaction);

              Map<String, Object> attemptMap = new HashMap<>();
              attemptMap.put("appName", firestore.getApp().getName());

              mainLooper.post(() -> events.success(attemptMap));

              try {
                if (!semaphore.tryAcquire(timeout, TimeUnit.MILLISECONDS)) {
                  return FlutterFirebaseFirestoreTransactionResult.failed(
                      new FirebaseFirestoreException("timed out", Code.DEADLINE_EXCEEDED));
                }
              } catch (InterruptedException e) {
                return FlutterFirebaseFirestoreTransactionResult.failed(
                    new FirebaseFirestoreException("interrupted", Code.DEADLINE_EXCEEDED));
              }

              if (response.isEmpty()) {
                return FlutterFirebaseFirestoreTransactionResult.complete();
              }
              final String resultType = (String) response.get("type");

              if ("ERROR".equalsIgnoreCase(resultType)) {
                return FlutterFirebaseFirestoreTransactionResult.complete();
              }

              @SuppressWarnings("unchecked")
              List<Map<String, Object>> commands =
                  (List<Map<String, Object>>) response.get("commands");

              for (Map<String, Object> command : commands) {
                String type = (String) Objects.requireNonNull(command.get("type"));
                String path = (String) Objects.requireNonNull(command.get("path"));
                DocumentReference documentReference = firestore.document(path);

                @SuppressWarnings("unchecked")
                Map<String, Object> data = (Map<String, Object>) command.get("data");

                switch (type) {
                  case "DELETE":
                    transaction.delete(documentReference);
                    break;
                  case "UPDATE":
                    transaction.update(documentReference, Objects.requireNonNull(data));
                    break;
                  case "SET":
                    {
                      @SuppressWarnings("unchecked")
                      Map<String, Object> options =
                          (Map<String, Object>) Objects.requireNonNull(command.get("options"));
                      SetOptions setOptions = null;

                      if (options.get("merge") != null && (boolean) options.get("merge")) {
                        setOptions = SetOptions.merge();
                      } else if (options.get("mergeFields") != null) {
                        @SuppressWarnings("unchecked")
                        List<FieldPath> fieldPathList =
                            (List<FieldPath>) Objects.requireNonNull(options.get("mergeFields"));
                        setOptions = SetOptions.mergeFieldPaths(fieldPathList);
                      }

                      if (setOptions == null) {
                        transaction.set(documentReference, Objects.requireNonNull(data));
                      } else {
                        transaction.set(
                            documentReference, Objects.requireNonNull(data), setOptions);
                      }

                      break;
                    }
                }
              }
              return FlutterFirebaseFirestoreTransactionResult.complete();
            })
        .addOnCompleteListener(
            task -> {
              final HashMap<String, Object> map = new HashMap<>();
              if (task.getException() != null || task.getResult().exception != null) {
                final @Nullable Exception exception =
                    task.getException() != null ? task.getException() : task.getResult().exception;
                map.put("appName", firestore.getApp().getName());
                map.put("error", ExceptionConverter.createDetails(exception));
              } else if (task.getResult() != null) {
                map.put("complete", true);
              }

              mainLooper.post(
                  () -> {
                    events.success(map);
                    events.endOfStream();
                  });
            });
  }

  @Override
  public void onCancel(Object arguments) {
    semaphore.release();
  }

  @Override
  public void receiveTransactionResponse(Map<String, Object> result) {
    response.putAll(result);
    semaphore.release();
  }
}
