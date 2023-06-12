#pragma once

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/event_stream_handler.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#undef GetCurrentTime
#include <shobjidl.h> 

#include <unknwn.h>
#include <winrt/Windows.Foundation.Collections.h>
#include "winrt/Windows.System.h"

#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <wincodec.h>
#include <future>

#include <unknwn.h>

// Include prior to C++/WinRT Headers
#include <wil/cppwinrt.h>

// Windows Implementation Library
#include <wil/resource.h>
#include <wil/result_macros.h>

// MediaFoundation headers
#include <mfapi.h>
#include <mferror.h>
#include <mfmediaengine.h>

// STL headers
#include <functional>
#include <memory>

#include <Audioclient.h>

#include "MediaEngineWrapper.h"
#include "MediaFoundationHelpers.h"

#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <wincodec.h>

using namespace winrt;

class AudioPlayer {

public:

    AudioPlayer(std::string playerId, flutter::MethodChannel<flutter::EncodableValue>* channel);

    void Dispose();
    void SetLooping(bool isLooping);
    void SetVolume(double volume);
    void SetPlaybackSpeed(double playbackSpeed);
    void SetBalance(double balance);
    void Play();
    void Pause();
    void Resume();
    bool GetLooping();
    int64_t GetPosition();
    int64_t GetDuration();
    void SeekTo(int64_t seek);

    void SetSourceUrl(std::string url);

    virtual ~AudioPlayer();

private:

    // Media members
    media::MFPlatformRef m_mfPlatform;
    winrt::com_ptr<media::MediaEngineWrapper> m_mediaEngineWrapper;

    bool _isInitialized = false;
    std::string _url{};

    void SendInitialized();

    void OnMediaError(MF_MEDIA_ENGINE_ERR error, HRESULT hr);
    void OnMediaStateChange(media::MediaEngineWrapper::BufferingState bufferingState);
    void OnPlaybackEnded();
    void OnDurationUpdate();
    void OnTimeUpdate();
    void OnSeekCompleted();

    std::string _playerId;

    flutter::MethodChannel<flutter::EncodableValue>* _channel;

};
