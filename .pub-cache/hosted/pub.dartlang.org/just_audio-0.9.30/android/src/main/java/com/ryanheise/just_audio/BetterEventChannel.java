package com.ryanheise.just_audio;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;

public class BetterEventChannel implements EventSink {
    private EventSink eventSink;

	public BetterEventChannel(final BinaryMessenger messenger, final String id) {
        EventChannel eventChannel = new EventChannel(messenger, id);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(final Object arguments, final EventSink eventSink) {
                BetterEventChannel.this.eventSink = eventSink;
            }

            @Override
            public void onCancel(final Object arguments) {
                eventSink = null;
            }
        });
	}

    @Override
    public void success(Object event) {
        if (eventSink != null) eventSink.success(event);
    }

    @Override
    public void error(String errorCode, String errorMessage, Object errorDetails) {
        if (eventSink != null) eventSink.error(errorCode, errorMessage, errorDetails);
    }

    @Override
    public void endOfStream() {
        if (eventSink != null) eventSink.endOfStream();
    }
}
