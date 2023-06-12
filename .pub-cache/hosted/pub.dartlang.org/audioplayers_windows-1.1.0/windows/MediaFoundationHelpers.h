#pragma once

namespace media
{

class MFPlatformRef
{
  public:
    MFPlatformRef() {}

    virtual ~MFPlatformRef() { Shutdown(); }

    void Startup()
    {
        if(!m_started)
        {
            THROW_IF_FAILED(MFStartup(MF_VERSION, MFSTARTUP_FULL));
            m_started = true;
        }
    }

    void Shutdown()
    {
        if(m_started)
        {
            THROW_IF_FAILED(MFShutdown());
            m_started = false;
        }
    }

  private:
    bool m_started = false;
};

class MFCallbackBase : public winrt::implements<MFCallbackBase, IMFAsyncCallback>
{
  public:
    MFCallbackBase(DWORD flags = 0, DWORD queue = MFASYNC_CALLBACK_QUEUE_MULTITHREADED) : m_flags(flags), m_queue(queue) {}

    DWORD GetQueue() const { return m_queue; }
    DWORD GetFlags() const { return m_flags; }

    // IMFAsyncCallback methods
    IFACEMETHODIMP GetParameters(_Out_ DWORD* flags, _Out_ DWORD* queue)
    {
        *flags = m_flags;
        *queue = m_queue;
        return S_OK;
    }

  private:
    DWORD m_flags = 0;
    DWORD m_queue = 0;
};

class SyncMFCallback
    : public MFCallbackBase
{
  public:
    SyncMFCallback() { m_invokeEvent.create(); }

    void Wait(uint32_t timeout = INFINITE)
    { 
        if(!m_invokeEvent.wait(timeout))
        {
            THROW_HR(ERROR_TIMEOUT);
        }
    }

    IMFAsyncResult* GetResult() { return m_result.get(); }

    // IMFAsyncCallback methods

    IFACEMETHODIMP Invoke(_In_opt_ IMFAsyncResult* result) noexcept override
    try
    {
        m_result.copy_from(result);
        m_invokeEvent.SetEvent();
        return S_OK;
    }
    CATCH_RETURN();

  private:
    wil::unique_event m_invokeEvent;
    winrt::com_ptr<IMFAsyncResult> m_result;
};

class MFWorkItem : public MFCallbackBase
{
public:
    MFWorkItem(std::function<void()> callback, DWORD flags = 0, DWORD queue = MFASYNC_CALLBACK_QUEUE_MULTITHREADED) : MFCallbackBase(flags, queue)
    {
        m_callback = callback;
    }

    // IMFAsyncCallback methods

    IFACEMETHODIMP Invoke(_In_opt_ IMFAsyncResult* /*result*/) noexcept override
    try
    {
        m_callback();
        return S_OK;
    }
    CATCH_RETURN();

private:
    std::function<void()> m_callback;
};

inline void MFPutWorkItem(std::function<void()> callback)
{
    winrt::com_ptr<MFWorkItem> workItem = winrt::make_self<MFWorkItem>(callback);
    THROW_IF_FAILED(MFPutWorkItem2(workItem->GetQueue(), 0, workItem.get(), nullptr));
}

// Helper function for ensuring that the provided callback runs synchronously on a MTA thread.
// All MediaFoundation calls should be made on a MTA thread to avoid subtle deadlock bugs due to objects inadvertedly being created in a STA
inline void RunSyncInMTA(std::function<void()> callback)
{
    APTTYPE apartmentType = {};
    APTTYPEQUALIFIER qualifier = {};

    THROW_IF_FAILED(CoGetApartmentType(&apartmentType, &qualifier));

    if(apartmentType == APTTYPE_MTA)
    {
        wil::unique_couninitialize_call unique_coinit;
        if(qualifier == APTTYPEQUALIFIER_IMPLICIT_MTA)
        {
            unique_coinit = wil::CoInitializeEx_failfast(COINIT_MULTITHREADED);
        }
        callback();
    }
    else
    {
        wil::unique_event complete;
        complete.create();
        MFPutWorkItem([&](){
            callback();
            complete.SetEvent();
        });
        complete.wait();
    }
}

constexpr uint64_t c_hnsPerSecond = 10000000;

template<typename SecondsT>
inline uint64_t ConvertSecondsToHns(SecondsT seconds)
{
    return static_cast<uint64_t>(seconds) * c_hnsPerSecond;
}

template<typename HnsT>
inline double ConvertHnsToSeconds(HnsT hns)
{
    return static_cast<double>(hns) / c_hnsPerSecond;
}


} // namespace media