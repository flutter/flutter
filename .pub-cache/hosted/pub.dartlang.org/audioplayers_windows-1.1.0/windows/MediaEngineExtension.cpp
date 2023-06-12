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

#include "MediaEngineWrapper.h"
#include "MediaFoundationHelpers.h"
#include <Audioclient.h>

#include "MediaEngineExtension.h"

using namespace Microsoft::WRL;

namespace media
{

IFACEMETHODIMP MediaEngineExtension::CanPlayType(BOOL /*isAudioOnly*/, BSTR /*mimeType*/, MF_MEDIA_ENGINE_CANPLAY* result) noexcept
{
    *result = MF_MEDIA_ENGINE_CANPLAY_NOT_SUPPORTED;
    return S_OK;
}

IFACEMETHODIMP MediaEngineExtension::BeginCreateObject(BSTR /*url*/, IMFByteStream* /*byteStream*/, MF_OBJECT_TYPE type, IUnknown** cancelCookie,
                                                       IMFAsyncCallback* callback, IUnknown* state) noexcept
try
{
    if(cancelCookie)
    {
        *cancelCookie = nullptr;
    }
    winrt::com_ptr<IUnknown> localSource;
    {
        auto lock = m_lock.lock();
        THROW_HR_IF(MF_E_SHUTDOWN, m_hasShutdown);
        localSource = m_mfMediaSource;
    }

    if(type == MF_OBJECT_MEDIASOURCE && localSource != nullptr)
    {
        winrt::com_ptr<IMFAsyncResult> asyncResult;
        THROW_IF_FAILED(MFCreateAsyncResult(localSource.get(), callback, state, asyncResult.put()));
        THROW_IF_FAILED(asyncResult->SetStatus(S_OK));
        m_uriType = ExtensionUriType::CustomSource;
        // Invoke the callback synchronously since no outstanding work is required.
        THROW_IF_FAILED(callback->Invoke(asyncResult.get()));
    }
    else
    {
        THROW_HR(MF_E_UNEXPECTED);
    }

    return S_OK;
}
CATCH_RETURN();

STDMETHODIMP MediaEngineExtension::CancelObjectCreation(_In_ IUnknown* /*cancelCookie*/) noexcept
{
    // Cancellation not supported
    return E_NOTIMPL;
}

STDMETHODIMP MediaEngineExtension::EndCreateObject(IMFAsyncResult* result, IUnknown** object) noexcept
try
{
    *object = nullptr;
    if(m_uriType == ExtensionUriType::CustomSource)
    {
        THROW_IF_FAILED(result->GetStatus());
        THROW_IF_FAILED(result->GetObject(object));
        m_uriType = ExtensionUriType::Unknown;
    }
    else
    {
        THROW_HR(MF_E_UNEXPECTED);
    }
    return S_OK;
}
CATCH_RETURN();

void MediaEngineExtension::SetMediaSource(IUnknown* mfMediaSource)
{
    auto lock = m_lock.lock();
    THROW_HR_IF(MF_E_SHUTDOWN, m_hasShutdown);
    m_mfMediaSource.copy_from(mfMediaSource);
}

// Break circular references.
void MediaEngineExtension::Shutdown()
{
    auto lock = m_lock.lock();
    if(!m_hasShutdown)
    {
        m_mfMediaSource = nullptr;
        m_hasShutdown = true;
    }
}

} // namespace media