#include "audio_player.h"

#include <flutter_linux/flutter_linux.h>

#include "Logger.h"

AudioPlayer::AudioPlayer(std::string playerId, FlMethodChannel *channel)
        : _playerId(playerId), _channel(channel) {
    gst_init(NULL, NULL);
    playbin = gst_element_factory_make("playbin", "playbin");
    if (!playbin) {
        Logger::Error(std::string("Not all elements could be created."));
        return;
    }

    // Setup stereo balance controller
    panorama = gst_element_factory_make("audiopanorama", "audiopanorama");
    if (panorama) {
        GstElement *audiosink = gst_element_factory_make("autoaudiosink", "audio_sink");

        GstElement *audiobin = gst_bin_new("audiobin");
        gst_bin_add_many(GST_BIN(audiobin), panorama, audiosink, NULL);
        gst_element_link(panorama, audiosink);

        GstPad *sinkpad = gst_element_get_static_pad(panorama, "sink");
        gst_element_add_pad(audiobin, gst_ghost_pad_new("sink", sinkpad));
        gst_object_unref(GST_OBJECT(sinkpad));

        g_object_set(G_OBJECT(playbin), "audio-sink", audiobin, NULL);
        gst_object_unref(GST_OBJECT(audiobin));

        g_object_set(G_OBJECT(panorama), "method", 1, NULL);
    }

    // Setup source options
    g_signal_connect(playbin, "source-setup",
                     G_CALLBACK(AudioPlayer::SourceSetup), &source);

    bus = gst_element_get_bus(playbin);

    // Watch bus messages for one time events
    gst_bus_add_watch(bus, (GstBusFunc) AudioPlayer::OnBusMessage, this);

    // Refresh continuously to emit reoccurring events
    g_timeout_add(1000, (GSourceFunc) AudioPlayer::OnRefresh, this);
}

AudioPlayer::~AudioPlayer() {}

void AudioPlayer::SourceSetup(GstElement *playbin, GstElement *source,
                              GstElement **p_src) {
    // Allow sources from unencrypted / misconfigured connections
    if (g_object_class_find_property(G_OBJECT_GET_CLASS(source),
                                     "ssl-strict") != 0) {
        g_object_set(G_OBJECT(source), "ssl-strict", FALSE, NULL);
    }
};

void AudioPlayer::SetSourceUrl(std::string url) {
    if (_url != url) {
        _url = url;
        gst_element_set_state(playbin, GST_STATE_NULL);
        if (!_url.empty()) {
            g_object_set(playbin, "uri", _url.c_str(), NULL);
            if (playbin->current_state != GST_STATE_READY) {
                gst_element_set_state(playbin, GST_STATE_READY);
            }
        }
        _isInitialized = false;
    }
}

gboolean AudioPlayer::OnBusMessage(GstBus *bus, GstMessage *message,
                                   AudioPlayer *data) {
    switch (GST_MESSAGE_TYPE(message)) {
        case GST_MESSAGE_ERROR: {
            GError *err;
            gchar *debug;

            gst_message_parse_error(message, &err, &debug);
            data->OnMediaError(err, debug);
            g_error_free(err);
            g_free(debug);
            break;
        }
        case GST_MESSAGE_STATE_CHANGED:
            GstState old_state, new_state;

            gst_message_parse_state_changed(message, &old_state, &new_state,
                                            NULL);
            data->OnMediaStateChange(message->src, &old_state, &new_state);
            break;
        case GST_MESSAGE_EOS:
            gst_element_set_state(data->playbin, GST_STATE_READY);
            data->OnPlaybackEnded();
            break;
        case GST_MESSAGE_DURATION_CHANGED:
            data->OnDurationUpdate();
            break;
        case GST_MESSAGE_ASYNC_DONE:
            if (!data->_isSeekCompleted) {
                data->OnSeekCompleted();
                data->_isSeekCompleted = true;
            }
            break;
        default:
            // For more GstMessage types see:
            // https://gstreamer.freedesktop.org/documentation/gstreamer/gstmessage.html?gi-language=c#enumerations
            break;
    }

    // Continue watching for messages
    return TRUE;
};

// Compare with refresh_ui in
// https://gstreamer.freedesktop.org/documentation/tutorials/basic/toolkit-integration.html?gi-language=c#walkthrough
gboolean AudioPlayer::OnRefresh(AudioPlayer *data) {
    // We do not want to update anything unless we are in the PAUSED or PLAYING states
    if (data->playbin->current_state == GST_STATE_PLAYING) {
        data->OnPositionUpdate();
    }
    return TRUE;
}

void AudioPlayer::OnMediaError(GError *error, gchar *debug) {
    std::ostringstream oss;
    oss << "Error: " << error->code << "; message=" << error->message;
    g_print("%s\n", oss.str().c_str());
    if (this->_channel) {
        g_autoptr(FlValue)
        map = fl_value_new_map();
        fl_value_set_string(map, "playerId",
                            fl_value_new_string(_playerId.c_str()));
        fl_value_set_string(map, "value",
                            fl_value_new_string(oss.str().c_str()));

        fl_method_channel_invoke_method(this->_channel, "audio.onError", map,
                                        nullptr, nullptr, nullptr);
    }
}

void AudioPlayer::OnMediaStateChange(GstObject *src, GstState *old_state,
                                     GstState *new_state) {
    if (strcmp(GST_OBJECT_NAME(src), "playbin") == 0) {
        if (*new_state >= GST_STATE_READY) {
            if (!this->_isInitialized) {
                this->_isInitialized = true;
                Pause(); // Need to set to pause state, in order to get duration
            }
        } else if (this->_isInitialized) {
            this->_isInitialized = false;
        }
    }
}

void AudioPlayer::OnPositionUpdate() {
    if (this->_channel) {
        g_autoptr(FlValue)
        map = fl_value_new_map();
        fl_value_set_string(map, "playerId",
                            fl_value_new_string(_playerId.c_str()));
        fl_value_set_string(map, "value", fl_value_new_int(GetPosition()));
        fl_method_channel_invoke_method(this->_channel,
                                        "audio.onCurrentPosition", map, nullptr,
                                        nullptr, nullptr);
    }
}

void AudioPlayer::OnDurationUpdate() {
    if (this->_channel) {
        g_autoptr(FlValue)
        map = fl_value_new_map();
        fl_value_set_string(map, "playerId",
                            fl_value_new_string(_playerId.c_str()));
        fl_value_set_string(map, "value", fl_value_new_int(GetDuration()));
        fl_method_channel_invoke_method(this->_channel, "audio.onDuration", map,
                                        nullptr, nullptr, nullptr);
    }
}

void AudioPlayer::OnSeekCompleted() {
    if (this->_channel) {
        OnPositionUpdate();
        g_autoptr(FlValue)
        map = fl_value_new_map();
        fl_value_set_string(map, "playerId",
                            fl_value_new_string(_playerId.c_str()));
        fl_value_set_string(map, "value", fl_value_new_bool(true));
        fl_method_channel_invoke_method(this->_channel, "audio.onSeekComplete",
                                        map, nullptr, nullptr, nullptr);
    }
}

void AudioPlayer::OnPlaybackEnded() {
    SetPosition(0);
    if (GetLooping()) {
        Play();
    }
    if (this->_channel) {
        g_autoptr(FlValue)
        map = fl_value_new_map();
        fl_value_set_string(map, "playerId",
                            fl_value_new_string(_playerId.c_str()));
        fl_value_set_string(map, "value", fl_value_new_bool(true));

        fl_method_channel_invoke_method(this->_channel, "audio.onComplete", map,
                                        nullptr, nullptr, nullptr);
    }
}

void AudioPlayer::SetBalance(float balance) {
    if (!panorama) {
       Logger::Error(std::string("Audiopanorama was not initialized"));
       return;
    }

    if (balance > 1.0f) {
        balance = 1.0f;
    } else if (balance < -1.0f) {
        balance = -1.0f;
    }
    g_object_set(G_OBJECT(panorama), "panorama", balance, NULL);
}

void AudioPlayer::SetLooping(bool isLooping) {
    _isLooping = isLooping;
}

bool AudioPlayer::GetLooping() {
    return _isLooping;
}

void AudioPlayer::SetVolume(double volume) {
    if (volume > 1) {
        volume = 1;
    } else if (volume < 0) {
        volume = 0;
    }
    g_object_set(G_OBJECT(playbin), "volume", volume, NULL);
}

/**
 * A rate of 1.0 means normal playback rate, 2.0 means double speed.
 * Negatives values means backwards playback.
 * A value of 0.0 will pause the player.
 *
 * @param position the position in milliseconds
 * @param rate the playback rate (speed)
 */
void AudioPlayer::SetPlayback(int64_t position, double rate) {
    if (!_isInitialized) {
        return;
    }
    // See:
    // https://gstreamer.freedesktop.org/documentation/tutorials/basic/playback-speed.html?gi-language=c
    if (!_isSeekCompleted) {
        return;
    }
    if (rate == 0) {
        // Do not set rate if it's 0, rather pause.
        Pause();
        return;
    }

    if (_playbackRate != rate) {
        _playbackRate = rate;
    }
    _isSeekCompleted = false;

    GstEvent *seek_event;
    if (rate > 0) {
        seek_event = gst_event_new_seek(
                rate, GST_FORMAT_TIME,
                GstSeekFlags(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE),
                GST_SEEK_TYPE_SET, position * GST_MSECOND, GST_SEEK_TYPE_NONE, -1);
    } else {
        seek_event = gst_event_new_seek(
                rate, GST_FORMAT_TIME,
                GstSeekFlags(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE),
                GST_SEEK_TYPE_SET, 0, GST_SEEK_TYPE_SET, position * GST_MSECOND);
    }
    if (!gst_element_send_event(playbin, seek_event)) {
        Logger::Error(std::string("Could not set playback to position ") +
                      std::to_string(position) + std::string(" and rate ") +
                      std::to_string(rate) + std::string("."));
        _isSeekCompleted = true;
    }
}

void AudioPlayer::SetPlaybackRate(double rate) {
    SetPlayback(GetPosition(), rate);
}

/**
 * @param position the position in milliseconds
 */
void AudioPlayer::SetPosition(int64_t position) {
    if (!_isInitialized) {
        return;
    }
    SetPlayback(position, _playbackRate);
}

/**
 * @return int64_t the position in milliseconds
 */
int64_t AudioPlayer::GetPosition() {
    gint64 current = 0;
    if (!gst_element_query_position(playbin, GST_FORMAT_TIME, &current)) {
        Logger::Error(std::string("Could not query current position."));
        return 0;
    }
    return current / 1000000;
}

/**
 * @return int64_t the duration in milliseconds
 */
int64_t AudioPlayer::GetDuration() {
    gint64 duration = 0;
    if (!gst_element_query_duration(playbin, GST_FORMAT_TIME, &duration)) {
        Logger::Error(std::string("Could not query current duration."));
        return 0;
    }
    return duration / 1000000;
}

void AudioPlayer::Play() {
    if (!_isInitialized) {
        return;
    }
    SetPosition(0);
    Resume();
}

void AudioPlayer::Pause() {
    GstStateChangeReturn ret = gst_element_set_state(playbin, GST_STATE_PAUSED);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        Logger::Error(
                std::string("Unable to set the pipeline to the paused state."));
        return;
    }
    OnPositionUpdate(); // Update to exact position when pausing
}

void AudioPlayer::Resume() {
    if (!_isInitialized) {
        return;
    }
    GstStateChangeReturn ret =
            gst_element_set_state(playbin, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        Logger::Error(
                std::string("Unable to set the pipeline to the playing state."));
        return;
    }
    // Update position and duration when start playing, as no event is emitted elsewhere
    OnPositionUpdate(); 
    OnDurationUpdate();
}

void AudioPlayer::Dispose() {
    if (_isInitialized) {
        Pause();
    }
    gst_object_unref(bus);
    gst_object_unref(source);
    gst_object_unref(panorama);

    gst_element_set_state(playbin, GST_STATE_NULL);
    gst_object_unref(playbin);

    _channel = nullptr;
    _isInitialized = false;
}
