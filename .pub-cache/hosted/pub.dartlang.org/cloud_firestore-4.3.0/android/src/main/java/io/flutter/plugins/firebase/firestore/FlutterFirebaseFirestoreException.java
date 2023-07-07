// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.firestore;

import com.google.firebase.firestore.FirebaseFirestoreException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class FlutterFirebaseFirestoreException extends Exception {
  private static final String ERROR_ABORTED =
      "The operation was aborted, typically due to a concurrency issue like transaction aborts, etc.";
  private static final String ERROR_ALREADY_EXISTS =
      "Some document that we attempted to create already exists.";
  private static final String ERROR_CANCELLED =
      "The operation was cancelled (typically by the caller).";
  private static final String ERROR_DATA_LOSS = "Unrecoverable data loss or corruption.";
  private static final String ERROR_DEADLINE_EXCEEDED =
      "Deadline expired before operation could complete. For operations that change the state of the system, this error may be returned even if the operation has completed successfully. For example, a successful response from a server could have been delayed long enough for the deadline to expire.";
  private static final String ERROR_FAILED_PRECONDITION =
      "Operation was rejected because the system is not in a state required for the operation's execution. If performing a query, ensure it has been indexed via the Firebase console.";
  private static final String ERROR_INTERNAL =
      "Internal errors. Means some invariants expected by underlying system has been broken. If you see one of these errors, something is very broken.";
  private static final String ERROR_INVALID_ARGUMENT =
      "Client specified an invalid argument. Note that this differs from failed-precondition. invalid-argument indicates arguments that are problematic regardless of the state of the system (e.g., an invalid field name).";
  private static final String ERROR_NOT_FOUND = "Some requested document was not found.";
  private static final String ERROR_OUT_OF_RANGE = "Operation was attempted past the valid range.";
  private static final String ERROR_PERMISSION_DENIED =
      "The caller does not have permission to execute the specified operation.";
  private static final String ERROR_RESOURCE_EXHAUSTED =
      "Some resource has been exhausted, perhaps a per-user quota, or perhaps the entire file system is out of space.";
  private static final String ERROR_UNAUTHENTICATED =
      "The request does not have valid authentication credentials for the operation.";
  private static final String ERROR_UNAVAILABLE =
      "The service is currently unavailable. This is a most likely a transient condition and may be corrected by retrying with a backoff.";
  private static final String ERROR_UNIMPLEMENTED =
      "Operation is not implemented or not supported/enabled.";
  private static final String ERROR_UNKNOWN =
      "Operation is not implemented or not supported/enabled.";

  private final String code;
  private final String message;

  public FlutterFirebaseFirestoreException(
      FirebaseFirestoreException nativeException, Throwable cause) {
    super(nativeException != null ? nativeException.getMessage() : "", cause);

    String code = null;
    String message = null;

    if (cause != null && cause.getMessage() != null && cause.getMessage().contains(":")) {
      String causeMessage = cause.getMessage();
      Matcher matcher = Pattern.compile("([A-Z_]{3,25}):\\s(.*)").matcher(causeMessage);

      if (matcher.find()) {
        String foundCode = matcher.group(1).trim();
        String foundMessage = matcher.group(2).trim();
        switch (foundCode) {
          case "ABORTED":
            code = "aborted";
            message = ERROR_ABORTED;
            break;
          case "ALREADY_EXISTS":
            code = "already-exists";
            message = ERROR_ALREADY_EXISTS;
            break;
          case "CANCELLED":
            code = "cancelled";
            message = ERROR_CANCELLED;
            break;
          case "DATA_LOSS":
            code = "data-loss";
            message = ERROR_DATA_LOSS;
            break;
          case "DEADLINE_EXCEEDED":
            code = "deadline-exceeded";
            message = ERROR_DEADLINE_EXCEEDED;
            break;
          case "FAILED_PRECONDITION":
            code = "failed-precondition";
            if (foundMessage.contains("query requires an index")
                || foundMessage.contains("ensure it has been indexed")) {
              message = foundMessage;
            } else {
              message = ERROR_FAILED_PRECONDITION;
            }
            break;
          case "INTERNAL":
            code = "internal";
            message = ERROR_INTERNAL;
            break;
          case "INVALID_ARGUMENT":
            code = "invalid-argument";
            message = ERROR_INVALID_ARGUMENT;
            break;
          case "NOT_FOUND":
            code = "not-found";
            message = ERROR_NOT_FOUND;
            break;
          case "OUT_OF_RANGE":
            code = "out-of-range";
            message = ERROR_OUT_OF_RANGE;
            break;
          case "PERMISSION_DENIED":
            code = "permission-denied";
            message = ERROR_PERMISSION_DENIED;
            break;
          case "RESOURCE_EXHAUSTED":
            code = "resource-exhausted";
            message = ERROR_RESOURCE_EXHAUSTED;
            break;
          case "UNAUTHENTICATED":
            code = "unauthenticated";
            message = ERROR_UNAUTHENTICATED;
            break;
          case "UNAVAILABLE":
            code = "unavailable";
            message = ERROR_UNAVAILABLE;
            break;
          case "UNIMPLEMENTED":
            code = "unimplemented";
            message = ERROR_UNIMPLEMENTED;
            break;
          case "UNKNOWN":
            code = "unknown";
            message = ERROR_UNKNOWN;
            break;
        }
      }
    }

    if (code == null && nativeException != null) {
      switch (nativeException.getCode()) {
        case ABORTED:
          code = "aborted";
          message = ERROR_ABORTED;
          break;
        case ALREADY_EXISTS:
          code = "already-exists";
          message = ERROR_ALREADY_EXISTS;
          break;
        case CANCELLED:
          code = "cancelled";
          message = ERROR_CANCELLED;
          break;
        case DATA_LOSS:
          code = "data-loss";
          message = ERROR_DATA_LOSS;
          break;
        case DEADLINE_EXCEEDED:
          code = "deadline-exceeded";
          message = ERROR_DEADLINE_EXCEEDED;
          break;
        case FAILED_PRECONDITION:
          code = "failed-precondition";
          if (nativeException.getMessage() != null
                  && nativeException.getMessage().contains("query requires an index")
              || nativeException.getMessage().contains("ensure it has been indexed")) {
            message = nativeException.getMessage();
          } else {
            message = ERROR_FAILED_PRECONDITION;
          }
          break;
        case INTERNAL:
          code = "internal";
          message = ERROR_INTERNAL;
          break;
        case INVALID_ARGUMENT:
          code = "invalid-argument";
          message = ERROR_INVALID_ARGUMENT;
          break;
        case NOT_FOUND:
          code = "not-found";
          message = ERROR_NOT_FOUND;
          break;
        case OUT_OF_RANGE:
          code = "out-of-range";
          message = ERROR_OUT_OF_RANGE;
          break;
        case PERMISSION_DENIED:
          code = "permission-denied";
          message = ERROR_PERMISSION_DENIED;
          break;
        case RESOURCE_EXHAUSTED:
          code = "resource-exhausted";
          message = ERROR_RESOURCE_EXHAUSTED;
          break;
        case UNAUTHENTICATED:
          code = "unauthenticated";
          message = ERROR_UNAUTHENTICATED;
          break;
        case UNAVAILABLE:
          code = "unavailable";
          message = ERROR_UNAVAILABLE;
          break;
        case UNIMPLEMENTED:
          code = "unimplemented";
          message = ERROR_UNIMPLEMENTED;
          break;
        case UNKNOWN:
          code = "unknown";
          message = "Unknown error or an error from a different error domain.";
          break;
        default:
          // Even though UNKNOWN exists, this is a fallback
          code = "unknown";
          message = "An unknown error occurred";
      }
    }

    this.code = code;
    this.message = message;
  }

  public String getCode() {
    return code;
  }

  @Override
  public String getMessage() {
    return message;
  }
}
