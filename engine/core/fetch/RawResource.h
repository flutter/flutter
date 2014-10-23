/*
    Copyright (C) 1998 Lars Knoll (knoll@mpi-hd.mpg.de)
    Copyright (C) 2001 Dirk Mueller <mueller@kde.org>
    Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
    Copyright (C) 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef RawResource_h
#define RawResource_h

#include "core/fetch/ResourceClient.h"
#include "core/fetch/ResourcePtr.h"

namespace blink {
class RawResourceCallback;
class RawResourceClient;

class RawResource FINAL : public Resource {
public:
    typedef RawResourceClient ClientType;

    RawResource(const ResourceRequest&, Type);

    virtual bool canReuse(const ResourceRequest&) const OVERRIDE;

private:
    virtual void didAddClient(ResourceClient*) OVERRIDE;
    virtual void appendData(const char*, int) OVERRIDE;

    virtual bool shouldIgnoreHTTPStatusCodeErrors() const OVERRIDE { return true; }

    virtual void willSendRequest(ResourceRequest&, const ResourceResponse&) OVERRIDE;
    virtual void updateRequest(const ResourceRequest&) OVERRIDE;
    virtual void responseReceived(const ResourceResponse&) OVERRIDE;
    virtual void didSendData(unsigned long long bytesSent, unsigned long long totalBytesToBeSent) OVERRIDE;
    virtual void didDownloadData(int) OVERRIDE;
};

#if ENABLE(SECURITY_ASSERT)
inline bool isRawResource(const Resource& resource)
{
    Resource::Type type = resource.type();
    return type == Resource::MainResource || type == Resource::Raw || type == Resource::Media || type == Resource::ImportResource;
}
#endif
inline RawResource* toRawResource(const ResourcePtr<Resource>& resource)
{
    ASSERT_WITH_SECURITY_IMPLICATION(!resource || isRawResource(*resource.get()));
    return static_cast<RawResource*>(resource.get());
}

class RawResourceClient : public ResourceClient {
public:
    virtual ~RawResourceClient() { }
    static ResourceClientType expectedType() { return RawResourceType; }
    virtual ResourceClientType resourceClientType() const OVERRIDE FINAL { return expectedType(); }

    virtual void dataSent(Resource*, unsigned long long /* bytesSent */, unsigned long long /* totalBytesToBeSent */) { }
    virtual void responseReceived(Resource*, const ResourceResponse&) { }
    virtual void dataReceived(Resource*, const char* /* data */, int /* length */) { }
    virtual void updateRequest(Resource*, const ResourceRequest&) { }
    virtual void dataDownloaded(Resource*, int) { }
};

}

#endif // RawResource_h
