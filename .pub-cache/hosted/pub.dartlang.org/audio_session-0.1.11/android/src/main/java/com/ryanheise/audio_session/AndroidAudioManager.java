package com.ryanheise.audio_session;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioDeviceCallback;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.media.MicrophoneInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Pair;
import android.view.KeyEvent;
import androidx.media.AudioAttributesCompat;
import androidx.media.AudioFocusRequestCompat;
import androidx.media.AudioManagerCompat;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AndroidAudioManager implements MethodCallHandler {
    // TODO: synchronize access
    private static Singleton singleton;

    private BinaryMessenger messenger;
    private MethodChannel channel;

    public AndroidAudioManager(Context applicationContext, BinaryMessenger messenger) {
        if (singleton == null)
            singleton = new Singleton(applicationContext);
        this.messenger = messenger;
        channel = new MethodChannel(messenger, "com.ryanheise.android_audio_manager");
        singleton.add(this);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        try {
            List<?> args = (List<?>)call.arguments;
            switch (call.method) {
            case "requestAudioFocus": {
                result.success(singleton.requestAudioFocus(args));
                break;
            }
            case "abandonAudioFocus": {
                result.success(singleton.abandonAudioFocus());
                break;
            }
            case "dispatchMediaKeyEvent": {
                result.success(singleton.dispatchMediaKeyEvent((Map<?, ?>)args.get(0)));
                break;
            }
            case "isVolumeFixed": {
                result.success(singleton.isVolumeFixed());
                break;
            }
            case "adjustStreamVolume": {
                result.success(singleton.adjustStreamVolume((Integer)args.get(0), (Integer)args.get(1), (Integer)args.get(2)));
                break;
            }
            case "adjustVolume": {
                result.success(singleton.adjustVolume((Integer)args.get(0), (Integer)args.get(1)));
                break;
            }
            case "adjustSuggestedStreamVolume": {
                result.success(singleton.adjustSuggestedStreamVolume((Integer)args.get(0), (Integer)args.get(1), (Integer)args.get(2)));
                break;
            }
            case "getRingerMode": {
                result.success(singleton.getRingerMode());
                break;
            }
            case "getStreamMaxVolume": {
                result.success(singleton.getStreamMaxVolume((Integer)args.get(0)));
                break;
            }
            case "getStreamMinVolume": {
                result.success(singleton.getStreamMinVolume((Integer)args.get(0)));
                break;
            }
            case "getStreamVolume": {
                result.success(singleton.getStreamVolume((Integer)args.get(0)));
                break;
            }
            case "getStreamVolumeDb": {
                result.success(singleton.getStreamVolumeDb((Integer)args.get(0), (Integer)args.get(1), (Integer)args.get(2)));
                break;
            }
            case "setRingerMode": {
                result.success(singleton.setRingerMode((Integer)args.get(0)));
                break;
            }
            case "setStreamVolume": {
                result.success(singleton.setStreamVolume((Integer)args.get(0), (Integer)args.get(1), (Integer)args.get(2)));
                break;
            }
            case "isStreamMute": {
                result.success(singleton.isStreamMute((Integer)args.get(0)));
                break;
            }
            case "getAvailableCommunicationDevices": {
                result.success(singleton.getAvailableCommunicationDevices());
                break;
            }
            case "setCommunicationDevice": {
                result.success(singleton.setCommunicationDevice((Integer)args.get(0)));
                break;
            }
            case "getCommunicationDevice": {
                result.success(singleton.getCommunicationDevice());
                break;
            }
            case "clearCommunicationDevice": {
                result.success(singleton.clearCommunicationDevice());
                break;
            }
            case "setSpeakerphoneOn": {
                result.success(singleton.setSpeakerphoneOn((Boolean)args.get(0)));
                break;
            }
            case "isSpeakerphoneOn": {
                result.success(singleton.isSpeakerphoneOn());
                break;
            }
            case "setAllowedCapturePolicy": {
                result.success(singleton.setAllowedCapturePolicy((Integer)args.get(0)));
                break;
            }
            case "getAllowedCapturePolicy": {
                result.success(singleton.getAllowedCapturePolicy());
                break;
            }
            case "isBluetoothScoAvailableOffCall": {
                result.success(singleton.isBluetoothScoAvailableOffCall());
                break;
            }
            case "startBluetoothSco": {
                result.success(singleton.startBluetoothSco());
                break;
            }
            case "stopBluetoothSco": {
                result.success(singleton.stopBluetoothSco());
                break;
            }
            case "setBluetoothScoOn": {
                result.success(singleton.setBluetoothScoOn((Boolean)args.get(0)));
                break;
            }
            case "isBluetoothScoOn": {
                result.success(singleton.isBluetoothScoOn());
                break;
            }
            case "setMicrophoneMute": {
                result.success(singleton.setMicrophoneMute((Boolean)args.get(0)));
                break;
            }
            case "isMicrophoneMute": {
                result.success(singleton.isMicrophoneMute());
                break;
            }
            case "setMode": {
                result.success(singleton.setMode((Integer)args.get(0)));
                break;
            }
            case "getMode": {
                result.success(singleton.getMode());
                break;
            }
            case "isMusicActive": {
                result.success(singleton.isMusicActive());
                break;
            }
            case "generateAudioSessionId": {
                result.success(singleton.generateAudioSessionId());
                break;
            }
            case "setParameters": {
                result.success(singleton.setParameters((String)args.get(0)));
                break;
            }
            case "getParameters": {
                result.success(singleton.getParameters((String)args.get(0)));
                break;
            }
            case "playSoundEffect": {
                result.success(singleton.playSoundEffect((Integer)args.get(0), (Double)args.get(1)));
                break;
            }
            case "loadSoundEffects": {
                result.success(singleton.loadSoundEffects());
                break;
            }
            case "unloadSoundEffects": {
                result.success(singleton.unloadSoundEffects());
                break;
            }
            case "getProperty": {
                result.success(singleton.getProperty((String)args.get(0)));
                break;
            }
            case "getDevices": {
                result.success(singleton.getDevices((Integer)args.get(0)));
                break;
            }
            case "getMicrophones": {
                result.success(singleton.getMicrophones());
                break;
            }
            case "isHapticPlaybackSupported": {
                result.success(singleton.isHapticPlaybackSupported());
                break;
            }
            default: {
                result.notImplemented();
                break;
            }
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.error("Error: " + e, null, null);
        }
    }

    public void dispose() {
        channel.setMethodCallHandler(null);
        singleton.remove(this);
        if (singleton.isEmpty()) {
            singleton.dispose();
            singleton = null;
        }
        channel = null;
        messenger = null;
    }

    /**
     * To emulate iOS's AVAudioSession, we maintain a single app-wide audio
     * focus request and noisy receiver at any one time which all isolates
     * share access to.
     */
    private static class Singleton {
        private final Handler handler = new Handler(Looper.getMainLooper());
        private List<AndroidAudioManager> instances = new ArrayList<>();
        private AudioFocusRequestCompat audioFocusRequest;
        private BroadcastReceiver noisyReceiver;
        private Context applicationContext;
        private AudioManager audioManager;
        private Object audioDeviceCallback;
        private List<AudioDeviceInfo> devices = new ArrayList<AudioDeviceInfo>();

        private static List<?> encodeAudioDevices(AudioDeviceInfo[] devices) {
            ArrayList<Map<String, Object>> result = new ArrayList<>();
            for (AudioDeviceInfo device : devices) {
                result.add(encodeAudioDevice(device));
            }
            return result;
        }

        private static Map<String, Object> encodeAudioDevice(AudioDeviceInfo device) {
            return mapOf(
                "id", device.getId(),
                "productName", device.getProductName(),
                "address", device.getAddress(),
                "isSource", device.isSource(),
                "isSink", device.isSink(),
                "sampleRates", device.getSampleRates(),
                "channelMasks", device.getChannelMasks(),
                "channelIndexMasks", device.getChannelIndexMasks(),
                "channelCounts", device.getChannelCounts(),
                "encodings", device.getEncodings(),
                "type", device.getType()
            );
        }

        public Singleton(Context applicationContext) {
            this.applicationContext = applicationContext;
            audioManager = (AudioManager)applicationContext.getSystemService(Context.AUDIO_SERVICE);
            if (Build.VERSION.SDK_INT >= 23) {
                initAudioDeviceCallback();
            }
        }

        private void initAudioDeviceCallback() {
            audioDeviceCallback = new AudioDeviceCallback() {
                @Override
                public void onAudioDevicesAdded(AudioDeviceInfo[] addedDevices) {
                    invokeMethod("onAudioDevicesAdded", encodeAudioDevices(addedDevices));
                }
                @Override
                public void onAudioDevicesRemoved(AudioDeviceInfo[] removedDevices) {
                    invokeMethod("onAudioDevicesRemoved", encodeAudioDevices(removedDevices));
                }
            };
            audioManager.registerAudioDeviceCallback((AudioDeviceCallback)audioDeviceCallback, handler);
        }

        public void add(AndroidAudioManager manager) {
            instances.add(manager);
        }

        public void remove(AndroidAudioManager manager) {
            instances.remove(manager);
        }

        public boolean isEmpty() {
            return instances.size() == 0;
        }

        private boolean requestAudioFocus(List<?> args) {
            if (audioFocusRequest != null) {
                return true;
            }
            Map<?, ?> request = (Map<?, ?>)args.get(0);
            AudioFocusRequestCompat.Builder builder = new AudioFocusRequestCompat.Builder((Integer)request.get("gainType"));
            builder.setOnAudioFocusChangeListener(focusChange -> {
                if (focusChange == AudioManager.AUDIOFOCUS_LOSS) abandonAudioFocus();
                invokeMethod("onAudioFocusChanged", focusChange);
            });
            if (request.get("audioAttributes") != null) {
                builder.setAudioAttributes(decodeAudioAttributes((Map<?, ?>)request.get("audioAttributes")));
            }
            if (request.get("willPauseWhenDucked") != null) {
                builder.setWillPauseWhenDucked((Boolean)request.get("willPauseWhenDucked"));
            }
            audioFocusRequest = builder.build();
            int status = AudioManagerCompat.requestAudioFocus(audioManager, audioFocusRequest);
            boolean success = status == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
            if (success) {
                registerNoisyReceiver();
            }
            return success;
        }

        private boolean abandonAudioFocus() {
            if (applicationContext == null) return false;
            unregisterNoisyReceiver();
            if (audioFocusRequest == null) {
                return true;
            } else {
                int status = AudioManagerCompat.abandonAudioFocusRequest(audioManager, audioFocusRequest);
                audioFocusRequest = null;
                return status == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
            }
        }

        private Object dispatchMediaKeyEvent(Map<?, ?> rawKeyEvent) {
            requireApi(19);
            KeyEvent keyEvent = new KeyEvent(
                    getLong(rawKeyEvent.get("downTime")),
                    getLong(rawKeyEvent.get("eventTime")),
                    (Integer)rawKeyEvent.get("action"),
                    (Integer)rawKeyEvent.get("code"),
                    (Integer)rawKeyEvent.get("repeat"),
                    (Integer)rawKeyEvent.get("metaState"),
                    (Integer)rawKeyEvent.get("deviceId"),
                    (Integer)rawKeyEvent.get("scancode"),
                    (Integer)rawKeyEvent.get("flags"),
                    (Integer)rawKeyEvent.get("source"));
            audioManager.dispatchMediaKeyEvent(keyEvent);
            return null;
        }
        private Object isVolumeFixed() {
            requireApi(21);
            return audioManager.isVolumeFixed();
        }
        private Object adjustStreamVolume(int streamType, int direction, int flags) {
            audioManager.adjustStreamVolume(streamType, direction, flags);
            return null;
        }
        private Object adjustVolume(int direction, int flags) {
            audioManager.adjustVolume(direction, flags);
            return null;
        }
        private Object adjustSuggestedStreamVolume(int direction, int suggestedStreamType, int flags) {
            audioManager.adjustSuggestedStreamVolume(direction, suggestedStreamType, flags);
            return null;
        }
        private Object getRingerMode() {
            return audioManager.getRingerMode();
        }
        private Object getStreamMaxVolume(int streamType) {
            return audioManager.getStreamMaxVolume(streamType);
        }
        private Object getStreamMinVolume(int streamType) {
            requireApi(28);
            return audioManager.getStreamMinVolume(streamType);
        }
        private Object getStreamVolume(int streamType) {
            return audioManager.getStreamVolume(streamType);
        }
        private Object getStreamVolumeDb(int streamType, int index, int deviceType) {
            requireApi(28);
            return audioManager.getStreamVolumeDb(streamType, index, deviceType);
        }
        private Object setRingerMode(int ringerMode) {
            audioManager.setRingerMode(ringerMode);
            return null;
        }
        private Object setStreamVolume(int streamType, int index, int flags) {
            audioManager.setStreamVolume(streamType, index, flags);
            return null;
        }
        private Object isStreamMute(int streamType) {
            requireApi(23);
            return audioManager.isStreamMute(streamType);
        }
        private List<Map<String, Object>> getAvailableCommunicationDevices() {
            requireApi(31);
            devices = audioManager.getAvailableCommunicationDevices();
            ArrayList<Map<String, Object>> result = new ArrayList<Map<String, Object>>();
            for (AudioDeviceInfo device : devices) {
                result.add(encodeAudioDevice(device));
            }
            return result;
        }
        private boolean setCommunicationDevice(Integer deviceId) {
            requireApi(31);
            for (AudioDeviceInfo device : devices) {
                if (device.getId() == deviceId) {
                    return audioManager.setCommunicationDevice(device);
                }
            }
            return false;
        }
        private Map<String, Object> getCommunicationDevice() {
            requireApi(31);
            return encodeAudioDevice(audioManager.getCommunicationDevice());
        }
        private Object clearCommunicationDevice() {
            requireApi(31);
            audioManager.clearCommunicationDevice();
            return null;
        }
        private Object setSpeakerphoneOn(boolean enabled) {
            audioManager.setSpeakerphoneOn(enabled);
            return null;
        }
        private Object isSpeakerphoneOn() {
            return audioManager.isSpeakerphoneOn();
        }
        private Object setAllowedCapturePolicy(int capturePolicy) {
            requireApi(29);
            audioManager.setAllowedCapturePolicy(capturePolicy);
            return null;
        }
        private Object getAllowedCapturePolicy() {
            requireApi(29);
            return audioManager.getAllowedCapturePolicy();
        }
        private Object isBluetoothScoAvailableOffCall() {
            return audioManager.isBluetoothScoAvailableOffCall();
        }
        private Object startBluetoothSco() {
            audioManager.startBluetoothSco();
            return null;
        }
        private Object stopBluetoothSco() {
            audioManager.stopBluetoothSco();
            return null;
        }
        private Object setBluetoothScoOn(boolean enabled) {
            audioManager.setBluetoothScoOn(enabled);
            return null;
        }
        private Object isBluetoothScoOn() {
            return audioManager.isBluetoothScoOn();
        }
        private Object setMicrophoneMute(boolean enabled) {
            audioManager.setMicrophoneMute(enabled);
            return null;
        }
        private Object isMicrophoneMute() {
            return audioManager.isMicrophoneMute();
        }
        private Object setMode(int mode) {
            audioManager.setMode(mode);
            return null;
        }
        private Object getMode() {
            return audioManager.getMode();
        }
        private Object isMusicActive() {
            return audioManager.isMusicActive();
        }
        private Object generateAudioSessionId() {
            requireApi(21);
            return audioManager.generateAudioSessionId();
        }
        private Object setParameters(String parameters) {
            audioManager.setParameters(parameters);
            return null;
        }
        private Object getParameters(String keys) {
            return audioManager.getParameters(keys);
        }
        private Object playSoundEffect(int effectType, Double volume) {
            if (volume != null) {
                audioManager.playSoundEffect(effectType, (float)((double)volume));
            } else {
                audioManager.playSoundEffect(effectType);
            }
            return null;
        }
        private Object loadSoundEffects() {
            audioManager.loadSoundEffects();
            return null;
        }
        private Object unloadSoundEffects() {
            audioManager.unloadSoundEffects();
            return null;
        }
        private Object getProperty(String arg) {
            requireApi(17);
            return audioManager.getProperty(arg);
        }
        private Object getDevices(int flags) {
            requireApi(23);
            ArrayList<Map<String, Object>> result = new ArrayList<>();
            AudioDeviceInfo[] devices = audioManager.getDevices(flags);
            for (int i = 0; i < devices.length; i++) {
                AudioDeviceInfo device = devices[i];
                String address = null;
                if (Build.VERSION.SDK_INT >= 28) {
                    address = device.getAddress();
                }
                result.add(mapOf(
                    "id", device.getId(),
                    "productName", device.getProductName(),
                    "address", address,
                    "isSource", device.isSource(),
                    "isSink", device.isSink(),
                    "sampleRates", intArrayToList(device.getSampleRates()),
                    "channelMasks", intArrayToList(device.getChannelMasks()),
                    "channelIndexMasks", intArrayToList(device.getChannelIndexMasks()),
                    "channelCounts", intArrayToList(device.getChannelCounts()),
                    "encodings", intArrayToList(device.getEncodings()),
                    "type", device.getType()
                ));
            }
            return result;
        }
        private Object getMicrophones() throws IOException {
            requireApi(28);
            ArrayList<Map<String, Object>> result = new ArrayList<>();
            List<MicrophoneInfo> microphones = audioManager.getMicrophones();
            for (MicrophoneInfo microphone : microphones) {
                List<List<Double>> frequencyResponse = new ArrayList<>();
                for (Pair<Float, Float> pair : microphone.getFrequencyResponse()) {
                    frequencyResponse.add(new ArrayList<Double>(Arrays.asList((double)((float)pair.first), (double)((float)pair.second))));
                }
                List<List<Integer>> channelMapping = new ArrayList<>();
                for (Pair<Integer, Integer> pair : microphone.getChannelMapping()) {
                    channelMapping.add(new ArrayList<Integer>(Arrays.asList(pair.first, pair.second)));
                }
                result.add(mapOf(
                    "description", microphone.getDescription(),
                    "id", microphone.getId(),
                    "type", microphone.getType(),
                    "address", microphone.getAddress(),
                    "location", microphone.getLocation(),
                    "group", microphone.getGroup(),
                    "indexInTheGroup", microphone.getIndexInTheGroup(),
                    "position", coordinate3fToList(microphone.getPosition()),
                    "orientation", coordinate3fToList(microphone.getOrientation()),
                    "frequencyResponse", frequencyResponse,
                    "channelMapping", channelMapping,
                    "sensitivity", microphone.getSensitivity(),
                    "maxSpl", microphone.getMaxSpl(),
                    "minSpl", microphone.getMinSpl(),
                    "directionality", microphone.getDirectionality()
                ));
            }
            return result;
        }

        private Object isHapticPlaybackSupported() {
            requireApi(29);
            return audioManager.isHapticPlaybackSupported();
        }

        private void registerNoisyReceiver() {
            if (noisyReceiver != null) return;
            noisyReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    if (AudioManager.ACTION_AUDIO_BECOMING_NOISY.equals(intent.getAction())) {
                        invokeMethod("onBecomingNoisy");
                    }
                }
            };
            applicationContext.registerReceiver(noisyReceiver, new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY));
        }

        private void unregisterNoisyReceiver() {
            if (noisyReceiver == null || applicationContext == null) return;
            applicationContext.unregisterReceiver(noisyReceiver);
            noisyReceiver = null;
        }

        private AudioAttributesCompat decodeAudioAttributes(Map<?, ?> attributes) {
            AudioAttributesCompat.Builder builder = new AudioAttributesCompat.Builder();
            if (attributes.get("contentType") != null) {
                builder.setContentType((Integer)attributes.get("contentType"));
            }
            if (attributes.get("flags") != null) {
                builder.setFlags((Integer)attributes.get("flags"));
            }
            if (attributes.get("usage") != null) {
                builder.setUsage((Integer)attributes.get("usage"));
            }
            return builder.build();
        }

        private void invokeMethod(String method, Object... args) {
            for (AndroidAudioManager instance : instances) {
                ArrayList<Object> list = new ArrayList<Object>(Arrays.asList(args));
                instance.channel.invokeMethod(method, list);
            }
        }

        public void dispose() {
            abandonAudioFocus();
            if (Build.VERSION.SDK_INT >= 23) {
                disposeAudioDeviceCallback();
            }
            applicationContext = null;
            audioManager = null;
        }

        private void disposeAudioDeviceCallback() {
            audioManager.unregisterAudioDeviceCallback((AudioDeviceCallback)audioDeviceCallback);
        }
    }

    static void requireApi(int level) {
        if (Build.VERSION.SDK_INT < level)
            throw new RuntimeException("Requires API level " + level);
    }

    static Map<String, Object> mapOf(Object... args) {
        Map<String, Object> map = new HashMap<>();
        for (int i = 0; i < args.length; i += 2) {
            map.put((String)args[i], args[i + 1]);
        }
        return map;
    }

    static ArrayList<Integer> intArrayToList(int[] a) {
        ArrayList<Integer> list = new ArrayList<>();
        for (int i = 0; i < a.length; i++) {
            list.add(a[i]);
        }
        return list;
    }

    static ArrayList<Double> doubleArrayToList(double[] a) {
        ArrayList<Double> list = new ArrayList<>();
        for (int i = 0; i < a.length; i++) {
            list.add(a[i]);
        }
        return list;
    }

    static ArrayList<Double> coordinate3fToList(MicrophoneInfo.Coordinate3F coordinate) {
        ArrayList<Double> list = new ArrayList<>();
        list.add((double)coordinate.x);
        list.add((double)coordinate.y);
        list.add((double)coordinate.z);
        return list;
    }

    static Long getLong(Object o) {
        return (o == null || o instanceof Long) ? (Long)o : Long.valueOf((Integer) o);
    }
}
