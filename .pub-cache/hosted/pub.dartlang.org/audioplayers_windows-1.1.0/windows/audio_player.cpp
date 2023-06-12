#include <flutter/event_channel.h>
#include <flutter/event_stream_handler.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <comdef.h>
#include <shobjidl.h>

#include "audio_player.h"

#undef GetCurrentTime

using namespace winrt;

AudioPlayer::AudioPlayer(std::string playerId, flutter::MethodChannel<flutter::EncodableValue>* channel) :
    _playerId(playerId), _channel(channel)
{
    m_mfPlatform.Startup();

    // Callbacks invoked by the media engine wrapper
    auto onError = std::bind(&AudioPlayer::OnMediaError, this, std::placeholders::_1, std::placeholders::_2);
    auto onBufferingStateChanged = std::bind(&AudioPlayer::OnMediaStateChange, this, std::placeholders::_1);
    auto onPlaybackEndedCB = std::bind(&AudioPlayer::OnPlaybackEnded, this);
    auto onTimeUpdateCB = std::bind(&AudioPlayer::OnTimeUpdate, this);
    auto onSeekCompletedCB = std::bind(&AudioPlayer::OnSeekCompleted, this);

    // Create and initialize the MediaEngineWrapper which manages media playback
    m_mediaEngineWrapper = winrt::make_self<media::MediaEngineWrapper>(nullptr, onError, onBufferingStateChanged, onPlaybackEndedCB, onTimeUpdateCB, onSeekCompletedCB);

    m_mediaEngineWrapper->Initialize();
}

void AudioPlayer::SetSourceUrl(std::string url) {
    if(_url != url) {
        _url = url;
        // Create a source resolver to create an IMFMediaSource for the content URL.
        // This will create an instance of an inbuilt OS media source for playback.
        // An application can skip this step and instantiate a custom IMFMediaSource implementation instead.
        winrt::com_ptr<IMFSourceResolver> sourceResolver;
        THROW_IF_FAILED(MFCreateSourceResolver(sourceResolver.put()));
        constexpr uint32_t sourceResolutionFlags = MF_RESOLUTION_MEDIASOURCE | MF_RESOLUTION_CONTENT_DOES_NOT_HAVE_TO_MATCH_EXTENSION_OR_MIME_TYPE | MF_RESOLUTION_READ;
        MF_OBJECT_TYPE objectType = {};
        
        winrt::com_ptr<IMFMediaSource> mediaSource;
        THROW_IF_FAILED(sourceResolver->CreateObjectFromURL(winrt::to_hstring(url).c_str(), sourceResolutionFlags, nullptr, &objectType, reinterpret_cast<IUnknown**>(mediaSource.put_void())));

        _isInitialized = false;
        m_mediaEngineWrapper->SetMediaSource(mediaSource.get());
    }
}

AudioPlayer::~AudioPlayer() {
}

void AudioPlayer::OnMediaError(MF_MEDIA_ENGINE_ERR error, HRESULT hr) {
    LOG_HR_MSG(hr, "MediaEngine error (%d)", error);
    if(this->_channel) {
        _com_error err(hr);

        std::wstring wstr(err.ErrorMessage());

        int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
        std::string ret = std::string(size, 0);
        WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, &wstr[0], (int)wstr.size(), &ret[0], size, NULL, NULL);

        this->_channel->InvokeMethod("audio.onError",
            std::make_unique<flutter::EncodableValue>(
                flutter::EncodableMap({
                    {flutter::EncodableValue("playerId"), flutter::EncodableValue(_playerId)},
                    {flutter::EncodableValue("value"), flutter::EncodableValue(ret)}
                })));
    }
}

void AudioPlayer::OnMediaStateChange(media::MediaEngineWrapper::BufferingState bufferingState) {
    if(bufferingState != media::MediaEngineWrapper::BufferingState::HAVE_NOTHING) {
        if (!this->_isInitialized) {
            this->_isInitialized = true;
            this->SendInitialized();
        }
    }
}

void AudioPlayer::OnPlaybackEnded() {
    SeekTo(0);
    if (GetLooping()) {
        Play();
    }
    if(this->_channel) {
        this->_channel->InvokeMethod("audio.onComplete",
            std::make_unique<flutter::EncodableValue>(
                flutter::EncodableMap({
                    {flutter::EncodableValue("playerId"), flutter::EncodableValue(_playerId)},
                    {flutter::EncodableValue("value"), flutter::EncodableValue(true)}
                })));
    }
}

void AudioPlayer::OnTimeUpdate() {
    if(this->_channel) {
        this->_channel->InvokeMethod("audio.onCurrentPosition",
            std::make_unique<flutter::EncodableValue>(
                flutter::EncodableMap({
                    {flutter::EncodableValue("playerId"), flutter::EncodableValue(_playerId)},
                    {flutter::EncodableValue("value"), flutter::EncodableValue((int64_t)m_mediaEngineWrapper->GetMediaTime() / 10000)}
                })));
    }
}

void AudioPlayer::OnDurationUpdate() {
    if(this->_channel) {
        this->_channel->InvokeMethod("audio.onDuration",
            std::make_unique<flutter::EncodableValue>(
                flutter::EncodableMap({
                    {flutter::EncodableValue("playerId"), flutter::EncodableValue(_playerId)},
                    {flutter::EncodableValue("value"), flutter::EncodableValue((int64_t)m_mediaEngineWrapper->GetDuration() / 10000)}
                })));
    }
}

void AudioPlayer::OnSeekCompleted() {
    if(this->_channel) {
        this->_channel->InvokeMethod("audio.onSeekComplete",
            std::make_unique<flutter::EncodableValue>(
                flutter::EncodableMap({
                    {flutter::EncodableValue("playerId"), flutter::EncodableValue(_playerId)},
                    {flutter::EncodableValue("value"), flutter::EncodableValue(true)}
                })));
    }
}

void AudioPlayer::SendInitialized() {
    OnDurationUpdate();
    OnTimeUpdate();
}

void AudioPlayer::Dispose() {
    if (_isInitialized) {
        m_mediaEngineWrapper->Pause();
    }
    _channel = nullptr;
    _isInitialized = false;
}

void AudioPlayer::SetLooping(bool isLooping) {
    m_mediaEngineWrapper->SetLooping(isLooping);
}

bool AudioPlayer::GetLooping() {
    return m_mediaEngineWrapper->GetLooping();
}

void AudioPlayer::SetVolume(double volume) {
    if (volume > 1) {
        volume = 1;
    } else if (volume < 0) {
        volume = 0;
    }
    m_mediaEngineWrapper->SetVolume((float)volume);
}

void AudioPlayer::SetPlaybackSpeed(double playbackSpeed) {
    m_mediaEngineWrapper->SetPlaybackRate(playbackSpeed);
}

void AudioPlayer::SetBalance(double balance) {
    m_mediaEngineWrapper->SetBalance(balance);
}

void AudioPlayer::Play() {
    m_mediaEngineWrapper->StartPlayingFrom(m_mediaEngineWrapper->GetMediaTime());
    OnDurationUpdate();
}

void AudioPlayer::Pause() {
    m_mediaEngineWrapper->Pause();
}

void AudioPlayer::Resume() {
    m_mediaEngineWrapper->Resume();
    OnDurationUpdate();
}

int64_t AudioPlayer::GetPosition() {
    return m_mediaEngineWrapper->GetMediaTime();
}

int64_t AudioPlayer::GetDuration() {
    return m_mediaEngineWrapper->GetDuration();
}

void AudioPlayer::SeekTo(int64_t seek) {
    m_mediaEngineWrapper->SeekTo(seek);
}
