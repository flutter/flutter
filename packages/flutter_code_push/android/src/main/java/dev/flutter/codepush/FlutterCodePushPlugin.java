package dev.flutter.codepush;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.io.IOException;

public final class FlutterCodePushPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String CHANNEL_NAME = "dev.flutter.codepush/updater";

  private MethodChannel channel;
  private CodePushStorage storage;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);
    storage = new CodePushStorage(binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
    storage = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    try {
      switch (call.method) {
        case "readCurrentPatchNumber":
          result.success(storage.readCurrentPatchNumber());
          return;
        case "stagePatchFromUrls":
          stagePatchFromUrls(call, result);
          return;
        case "applyStagedPatch":
          storage.applyStagedPatch();
          result.success(null);
          return;
        case "clearActivePatch":
          storage.clearActivePatch();
          result.success(null);
          return;
        default:
          result.notImplemented();
      }
    } catch (IOException exception) {
      result.error("code_push_io", exception.getMessage(), null);
    } catch (Exception exception) {
      result.error("code_push_error", exception.getMessage(), null);
    }
  }

  private void stagePatchFromUrls(@NonNull MethodCall call, @NonNull Result result)
      throws IOException {
    Integer patchNumber = call.argument("patch_number");
    String releaseVersion = call.argument("release_version");
    String dataDownloadUrl = call.argument("data_download_url");
    String instrDownloadUrl = call.argument("instr_download_url");
    String dataSha256 = call.argument("isolate_data_sha256");
    String instrSha256 = call.argument("isolate_instr_sha256");
    Number dataLengthBytes = call.argument("isolate_data_length_bytes");
    Number instrLengthBytes = call.argument("isolate_instr_length_bytes");
    Boolean enabled = call.argument("enabled");

    if (patchNumber == null
        || releaseVersion == null
        || dataDownloadUrl == null
        || instrDownloadUrl == null
        || dataSha256 == null
        || instrSha256 == null) {
      result.error("invalid_args", "Missing required patch fields.", null);
      return;
    }

    storage.stagePatchFromUrls(
        patchNumber,
        releaseVersion,
        dataDownloadUrl,
        instrDownloadUrl,
        dataSha256,
        instrSha256,
        dataLengthBytes == null ? null : dataLengthBytes.longValue(),
        instrLengthBytes == null ? null : instrLengthBytes.longValue(),
        enabled == null || enabled);
    result.success(null);
  }
}
