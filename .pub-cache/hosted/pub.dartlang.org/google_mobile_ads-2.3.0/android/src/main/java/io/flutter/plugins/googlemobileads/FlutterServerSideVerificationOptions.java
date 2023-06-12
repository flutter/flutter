package io.flutter.plugins.googlemobileads;

import androidx.annotation.Nullable;
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions;
import java.util.Objects;

/** A wrapper for {@link ServerSideVerificationOptions}. */
class FlutterServerSideVerificationOptions {

  @Nullable private final String userId;
  @Nullable private final String customData;

  public FlutterServerSideVerificationOptions(
      @Nullable String userId, @Nullable String customData) {
    this.userId = userId;
    this.customData = customData;
  }

  @Nullable
  public String getUserId() {
    return userId;
  }

  @Nullable
  public String getCustomData() {
    return customData;
  }

  /** Gets an equivalent {@link ServerSideVerificationOptions}. */
  public ServerSideVerificationOptions asServerSideVerificationOptions() {
    ServerSideVerificationOptions.Builder builder = new ServerSideVerificationOptions.Builder();
    if (userId != null) {
      builder.setUserId(userId);
    }
    if (customData != null) {
      builder.setCustomData(customData);
    }
    return builder.build();
  }

  @Override
  public boolean equals(@Nullable Object obj) {
    if (this == obj) {
      return true;
    }
    if (!(obj instanceof FlutterServerSideVerificationOptions)) {
      return false;
    }
    FlutterServerSideVerificationOptions other = (FlutterServerSideVerificationOptions) obj;
    return Objects.equals(other.userId, userId) && Objects.equals(other.customData, customData);
  }

  @Override
  public int hashCode() {
    return Objects.hash(userId, customData);
  }
}
