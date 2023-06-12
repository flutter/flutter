#pragma once

#include <flutter_linux/flutter_linux.h>

#include <future>
#include <map>
#include <memory>
#include <sstream>
#include <string>

// STL headers
#include <functional>
#include <map>
#include <memory>
#include <sstream>
#include <string>

extern "C" {
#include <gst/gst.h>
}

class AudioPlayer {
public:
    AudioPlayer(std::string playerId, FlMethodChannel *channel);

    int64_t GetPosition();

    int64_t GetDuration();

    bool GetLooping();

    void Play();

    void Pause();

    void Resume();

    void Dispose();

    void SetBalance(float balance);

    void SetLooping(bool isLooping);

    void SetVolume(double volume);

    void SetPlaybackRate(double rate);

    void SetPosition(int64_t position);

    void SetSourceUrl(std::string url);

    virtual ~AudioPlayer();

private:
    // Gst members
    GstElement *playbin;
    GstElement *source;
    GstElement *panorama;
    GstBus *bus;

    bool _isInitialized = false;
    bool _isLooping = false;
    bool _isSeekCompleted = true;
    double _playbackRate = 1.0;

    std::string _url{};
    std::string _playerId;
    FlMethodChannel *_channel;

    static void SourceSetup(GstElement *playbin, GstElement *source,
                            GstElement **p_src);

    static gboolean OnBusMessage(GstBus *bus, GstMessage *message,
                                 AudioPlayer *data);

    static gboolean OnRefresh(AudioPlayer *data);

    void SetPlayback(int64_t seekTo, double rate);

    void OnMediaError(GError *error, gchar *debug);

    void OnMediaStateChange(GstObject *src, GstState *old_state,
                            GstState *new_state);

    void OnPositionUpdate();

    void OnDurationUpdate();

    void OnSeekCompleted();

    void OnPlaybackEnded();
};
