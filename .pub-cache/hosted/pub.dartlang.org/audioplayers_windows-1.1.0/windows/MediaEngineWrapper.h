#pragma once

#include <tuple>

#include "MediaFoundationHelpers.h"
#include "MediaEngineExtension.h"

namespace media
{

// This class handles creation and management of the MediaFoundation
// MediaEngine.
// - It uses the provided IMFMediaSource to feed media samples into the
//   MediaEngine pipeline.
class MediaEngineWrapper : public winrt::implements<MediaEngineWrapper, IUnknown>
{
  public:
    using ErrorCB = std::function<void(MF_MEDIA_ENGINE_ERR,HRESULT)>;

    enum class BufferingState
    {
        HAVE_NOTHING = 0,
        HAVE_ENOUGH = 1
    };
    using BufferingStateChangeCB = std::function<void(BufferingState)>;

    MediaEngineWrapper(std::function<void()> initializedCB, ErrorCB errorCB, BufferingStateChangeCB bufferingStateChangeCB,
                       std::function<void()> playbackEndedCB, std::function<void()> timeUpdateCB, std::function<void()> seekCompletedCB)
        : m_initializedCB(initializedCB), m_errorCB(errorCB), m_bufferingStateChangeCB(bufferingStateChangeCB),
          m_playbackEndedCB(playbackEndedCB), m_timeUpdateCB(timeUpdateCB), m_seekCompletedCB(seekCompletedCB)
    {
    }
    ~MediaEngineWrapper() {}

    // Create the media engine
    void Initialize();

    // Initialize with the provided media source
    void SetMediaSource(IMFMediaSource* mediaSource);

    // Stop playback and cleanup resources
    void Pause();
    void Shutdown();

    // Control various aspects of playback
    void StartPlayingFrom(uint64_t timeStamp);
    void Resume();
    void SetPlaybackRate(double playbackRate);
    void SetVolume(float volume);
    void SetBalance(double balance);
    void SetLooping(bool isLooping);
    void SeekTo(uint64_t timeStamp);

    // Query the current playback position
    uint64_t GetMediaTime();
    uint64_t GetDuration();

    bool GetLooping();

    std::vector<std::tuple<uint64_t, uint64_t>> GetBufferedRanges();

  private:
    wil::critical_section m_lock;
    std::function<void()> m_initializedCB;
    ErrorCB m_errorCB;
    BufferingStateChangeCB m_bufferingStateChangeCB;
    std::function<void()> m_playbackEndedCB;
    std::function<void()> m_timeUpdateCB;
    std::function<void()> m_seekCompletedCB;
    MFPlatformRef m_platformRef;
    winrt::com_ptr<IMFMediaEngine> m_mediaEngine;
    winrt::com_ptr<MediaEngineExtension> m_mediaEngineExtension;
    winrt::com_ptr<IMFMediaEngineNotify> m_callbackHelper;
    void CreateMediaEngine();
    void OnLoaded();
    void OnError(MF_MEDIA_ENGINE_ERR error, HRESULT hr);
    void OnBufferingStateChange(BufferingState state);
    void OnPlaybackEnded();
    void OnTimeUpdate();
    void OnSeekCompleted();
};

} // namespace media