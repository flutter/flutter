/*
 * Copyright (c) 2014, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "core/fetch/ImageResource.h"
#include "core/fetch/MemoryCache.h"
#include "core/fetch/Resource.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/fetch/ResourcePtr.h"
#include "core/html/HTMLDocument.h"
#include "platform/network/ResourceRequest.h"
#include "public/platform/Platform.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefPtr.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

// An URL for the original request.
const char kResourceURL[] = "http://resource.com/";

// The origin time of our first request.
const char kOriginalRequestDateAsString[] = "Thu, 25 May 1977 18:30:00 GMT";
const double kOriginalRequestDateAsDouble = 233433000.;

const char kOneDayBeforeOriginalRequest[] = "Wed, 24 May 1977 18:30:00 GMT";
const char kOneDayAfterOriginalRequest[] = "Fri, 26 May 1977 18:30:00 GMT";

const unsigned char kAConstUnsignedCharZero = 0;

class CachingCorrectnessTest : public ::testing::Test {
protected:
    void advanceClock(double seconds)
    {
        m_proxyPlatform.advanceClock(seconds);
    }

    ResourcePtr<Resource> resourceFromResourceResponse(ResourceResponse response, Resource::Type type = Resource::Raw)
    {
        if (response.url().isNull())
            response.setURL(KURL(ParsedURLString, kResourceURL));
        ResourcePtr<Resource> resource =
            new Resource(ResourceRequest(response.url()), type);
        resource->setResponse(response);
        memoryCache()->add(resource.get());

        return resource;
    }

    ResourcePtr<Resource> resourceFromResourceRequest(ResourceRequest request, Resource::Type type = Resource::Raw)
    {
        if (request.url().isNull())
            request.setURL(KURL(ParsedURLString, kResourceURL));
        ResourcePtr<Resource> resource =
            new Resource(request, type);
        resource->setResponse(ResourceResponse(KURL(ParsedURLString, kResourceURL), "text/html", 0, nullAtom, String()));
        memoryCache()->add(resource.get());

        return resource;
    }

    ResourcePtr<Resource> fetchImage()
    {
        FetchRequest fetchRequest(ResourceRequest(KURL(ParsedURLString, kResourceURL)), FetchInitiatorInfo());
        return m_fetcher->fetchImage(fetchRequest);
    }

    ResourceFetcher* fetcher() const { return m_fetcher.get(); }

private:
    // A simple platform that mocks out the clock, for cache freshness testing.
    class ProxyPlatform : public blink::Platform {
    public:
        ProxyPlatform() : m_elapsedSeconds(0.) { }

        void advanceClock(double seconds)
        {
            m_elapsedSeconds += seconds;
        }

    private:
        // From blink::Platform:
        virtual double currentTime()
        {
            return kOriginalRequestDateAsDouble + m_elapsedSeconds;
        }

        // These blink::Platform methods must be overriden to make a usable object.
        virtual const unsigned char* getTraceCategoryEnabledFlag(const char* categoryName)
        {
            return &kAConstUnsignedCharZero;
        }

        double m_elapsedSeconds;
    };

    virtual void SetUp()
    {
        m_savedPlatform = blink::Platform::current();
        blink::Platform::initialize(&m_proxyPlatform);

        // Save the global memory cache to restore it upon teardown.
        m_globalMemoryCache = replaceMemoryCacheForTesting(MemoryCache::create());

        // Create a ResourceFetcher that has a real Document, but is not attached to a LocalFrame.
        const KURL kDocumentURL(ParsedURLString, "http://document.com/");
        m_document = HTMLDocument::create();
        m_fetcher = ResourceFetcher::create(m_document.get());
    }

    virtual void TearDown()
    {
        memoryCache()->evictResources();

        // Yield the ownership of the global memory cache back.
        replaceMemoryCacheForTesting(m_globalMemoryCache.release());

        blink::Platform::initialize(m_savedPlatform);
    }

    blink::Platform* m_savedPlatform;
    ProxyPlatform m_proxyPlatform;

    OwnPtr<MemoryCache> m_globalMemoryCache;

    RefPtr<HTMLDocument> m_document;
    RefPtr<ResourceFetcher> m_fetcher;
};

TEST_F(CachingCorrectnessTest, FreshFromLastModified)
{
    ResourceResponse fresh200Response;
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Last-Modified", kOneDayBeforeOriginalRequest);

    ResourcePtr<Resource> fresh200 = resourceFromResourceResponse(fresh200Response);

    // Advance the clock within the implicit freshness period of this resource before we make a request.
    advanceClock(600.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_EQ(fresh200, fetched);
}

TEST_F(CachingCorrectnessTest, FreshFromExpires)
{
    ResourceResponse fresh200Response;
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    ResourcePtr<Resource> fresh200 = resourceFromResourceResponse(fresh200Response);

    // Advance the clock within the freshness period of this resource before we make a request.
    advanceClock(24. * 60. * 60. - 15.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_EQ(fresh200, fetched);
}

TEST_F(CachingCorrectnessTest, FreshFromMaxAge)
{
    ResourceResponse fresh200Response;
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Cache-Control", "max-age=600");

    ResourcePtr<Resource> fresh200 = resourceFromResourceResponse(fresh200Response);

    // Advance the clock within the freshness period of this resource before we make a request.
    advanceClock(500.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_EQ(fresh200, fetched);
}

// The strong validator causes a revalidation to be launched, and the proxy and original resources leak because of their reference loop.
TEST_F(CachingCorrectnessTest, DISABLED_ExpiredFromLastModified)
{
    ResourceResponse expired200Response;
    expired200Response.setHTTPStatusCode(200);
    expired200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    expired200Response.setHTTPHeaderField("Last-Modified", kOneDayBeforeOriginalRequest);

    ResourcePtr<Resource> expired200 = resourceFromResourceResponse(expired200Response);

    // Advance the clock beyond the implicit freshness period.
    advanceClock(24. * 60. * 60. * 0.2);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(expired200, fetched);
}

TEST_F(CachingCorrectnessTest, ExpiredFromExpires)
{
    ResourceResponse expired200Response;
    expired200Response.setHTTPStatusCode(200);
    expired200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    expired200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    ResourcePtr<Resource> expired200 = resourceFromResourceResponse(expired200Response);

    // Advance the clock within the expiredness period of this resource before we make a request.
    advanceClock(24. * 60. * 60. + 15.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(expired200, fetched);
}

// If the image hasn't been loaded in this "document" before, then it shouldn't have list of available images logic.
TEST_F(CachingCorrectnessTest, NewImageExpiredFromExpires)
{
    ResourceResponse expired200Response;
    expired200Response.setHTTPStatusCode(200);
    expired200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    expired200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    ResourcePtr<Resource> expired200 = resourceFromResourceResponse(expired200Response, Resource::Image);

    // Advance the clock within the expiredness period of this resource before we make a request.
    advanceClock(24. * 60. * 60. + 15.);

    ResourcePtr<Resource> fetched = fetchImage();
    EXPECT_NE(expired200, fetched);
}

// If the image has been loaded in this "document" before, then it should have list of available images logic, and so
// normal cache testing should be bypassed.
TEST_F(CachingCorrectnessTest, ReuseImageExpiredFromExpires)
{
    ResourceResponse expired200Response;
    expired200Response.setHTTPStatusCode(200);
    expired200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    expired200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    ResourcePtr<Resource> expired200 = resourceFromResourceResponse(expired200Response, Resource::Image);

    // Advance the clock within the freshness period, and make a request to add this image to the document resources.
    advanceClock(15.);
    ResourcePtr<Resource> firstFetched = fetchImage();
    EXPECT_EQ(expired200, firstFetched);

    // Advance the clock within the expiredness period of this resource before we make a request.
    advanceClock(24. * 60. * 60. + 15.);

    ResourcePtr<Resource> fetched = fetchImage();
    EXPECT_EQ(expired200, fetched);
}

TEST_F(CachingCorrectnessTest, ExpiredFromMaxAge)
{
    ResourceResponse expired200Response;
    expired200Response.setHTTPStatusCode(200);
    expired200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    expired200Response.setHTTPHeaderField("Cache-Control", "max-age=600");

    ResourcePtr<Resource> expired200 = resourceFromResourceResponse(expired200Response);

    // Advance the clock within the expiredness period of this resource before we make a request.
    advanceClock(700.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(expired200, fetched);
}

TEST_F(CachingCorrectnessTest, FreshButNoCache)
{
    ResourceResponse fresh200NocacheResponse;
    fresh200NocacheResponse.setHTTPStatusCode(200);
    fresh200NocacheResponse.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200NocacheResponse.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);
    fresh200NocacheResponse.setHTTPHeaderField("Cache-Control", "no-cache");

    ResourcePtr<Resource> fresh200Nocache = resourceFromResourceResponse(fresh200NocacheResponse);

    // Advance the clock within the freshness period of this resource before we make a request.
    advanceClock(24. * 60. * 60. - 15.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(fresh200Nocache, fetched);
}

TEST_F(CachingCorrectnessTest, RequestWithNoCahe)
{
    ResourceRequest noCacheRequest;
    noCacheRequest.setHTTPHeaderField("Cache-Control", "no-cache");
    ResourcePtr<Resource> noCacheResource = resourceFromResourceRequest(noCacheRequest);
    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(noCacheResource, fetched);
}

TEST_F(CachingCorrectnessTest, FreshButNoStore)
{
    ResourceResponse fresh200NostoreResponse;
    fresh200NostoreResponse.setHTTPStatusCode(200);
    fresh200NostoreResponse.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200NostoreResponse.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);
    fresh200NostoreResponse.setHTTPHeaderField("Cache-Control", "no-store");

    ResourcePtr<Resource> fresh200Nostore = resourceFromResourceResponse(fresh200NostoreResponse);

    // Advance the clock within the freshness period of this resource before we make a request.
    advanceClock(24. * 60. * 60. - 15.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(fresh200Nostore, fetched);
}

TEST_F(CachingCorrectnessTest, RequestWithNoStore)
{
    ResourceRequest noStoreRequest;
    noStoreRequest.setHTTPHeaderField("Cache-Control", "no-store");
    ResourcePtr<Resource> noStoreResource = resourceFromResourceRequest(noStoreRequest);
    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(noStoreResource, fetched);
}

// FIXME: Determine if ignoring must-revalidate for blink is correct behaviour.
// See crbug.com/340088 .
TEST_F(CachingCorrectnessTest, DISABLED_FreshButMustRevalidate)
{
    ResourceResponse fresh200MustRevalidateResponse;
    fresh200MustRevalidateResponse.setHTTPStatusCode(200);
    fresh200MustRevalidateResponse.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200MustRevalidateResponse.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);
    fresh200MustRevalidateResponse.setHTTPHeaderField("Cache-Control", "must-revalidate");

    ResourcePtr<Resource> fresh200MustRevalidate = resourceFromResourceResponse(fresh200MustRevalidateResponse);

    // Advance the clock within the freshness period of this resource before we make a request.
    advanceClock(24. * 60. * 60. - 15.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(fresh200MustRevalidate, fetched);
}

TEST_F(CachingCorrectnessTest, FreshWithFreshRedirect)
{
    KURL redirectUrl(ParsedURLString, kResourceURL);
    const char redirectTargetUrlString[] = "http://redirect-target.com";
    KURL redirectTargetUrl(ParsedURLString, redirectTargetUrlString);

    ResourcePtr<Resource> firstResource = new Resource(ResourceRequest(redirectUrl), Resource::Raw);

    ResourceResponse fresh301Response;
    fresh301Response.setURL(redirectUrl);
    fresh301Response.setHTTPStatusCode(301);
    fresh301Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh301Response.setHTTPHeaderField("Location", redirectTargetUrlString);
    fresh301Response.setHTTPHeaderField("Cache-Control", "max-age=600");

    // Add the redirect to our request.
    ResourceRequest redirectRequest = ResourceRequest(redirectTargetUrl);
    firstResource->willSendRequest(redirectRequest, fresh301Response);

    // Add the final response to our request.
    ResourceResponse fresh200Response;
    fresh200Response.setURL(redirectTargetUrl);
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    firstResource->setResponse(fresh200Response);
    memoryCache()->add(firstResource.get());

    advanceClock(500.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_EQ(firstResource, fetched);
}

TEST_F(CachingCorrectnessTest, FreshWithStaleRedirect)
{
    KURL redirectUrl(ParsedURLString, kResourceURL);
    const char redirectTargetUrlString[] = "http://redirect-target.com";
    KURL redirectTargetUrl(ParsedURLString, redirectTargetUrlString);

    ResourcePtr<Resource> firstResource = new Resource(ResourceRequest(redirectUrl), Resource::Raw);

    ResourceResponse stale301Response;
    stale301Response.setURL(redirectUrl);
    stale301Response.setHTTPStatusCode(301);
    stale301Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    stale301Response.setHTTPHeaderField("Location", redirectTargetUrlString);

    // Add the redirect to our request.
    ResourceRequest redirectRequest = ResourceRequest(redirectTargetUrl);
    firstResource->willSendRequest(redirectRequest, stale301Response);

    // Add the final response to our request.
    ResourceResponse fresh200Response;
    fresh200Response.setURL(redirectTargetUrl);
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    firstResource->setResponse(fresh200Response);
    memoryCache()->add(firstResource.get());

    advanceClock(500.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(firstResource, fetched);
}

TEST_F(CachingCorrectnessTest, 302RedirectNotImplicitlyFresh)
{
    KURL redirectUrl(ParsedURLString, kResourceURL);
    const char redirectTargetUrlString[] = "http://redirect-target.com";
    KURL redirectTargetUrl(ParsedURLString, redirectTargetUrlString);

    ResourcePtr<Resource> firstResource = new Resource(ResourceRequest(redirectUrl), Resource::Raw);

    ResourceResponse fresh302Response;
    fresh302Response.setURL(redirectUrl);
    fresh302Response.setHTTPStatusCode(302);
    fresh302Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh302Response.setHTTPHeaderField("Last-Modified", kOneDayBeforeOriginalRequest);
    fresh302Response.setHTTPHeaderField("Location", redirectTargetUrlString);

    // Add the redirect to our request.
    ResourceRequest redirectRequest = ResourceRequest(redirectTargetUrl);
    firstResource->willSendRequest(redirectRequest, fresh302Response);

    // Add the final response to our request.
    ResourceResponse fresh200Response;
    fresh200Response.setURL(redirectTargetUrl);
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    firstResource->setResponse(fresh200Response);
    memoryCache()->add(firstResource.get());

    advanceClock(500.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_NE(firstResource, fetched);
}

TEST_F(CachingCorrectnessTest, 302RedirectExplicitlyFreshMaxAge)
{
    KURL redirectUrl(ParsedURLString, kResourceURL);
    const char redirectTargetUrlString[] = "http://redirect-target.com";
    KURL redirectTargetUrl(ParsedURLString, redirectTargetUrlString);

    ResourcePtr<Resource> firstResource = new Resource(ResourceRequest(redirectUrl), Resource::Raw);

    ResourceResponse fresh302Response;
    fresh302Response.setURL(redirectUrl);
    fresh302Response.setHTTPStatusCode(302);
    fresh302Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh302Response.setHTTPHeaderField("Cache-Control", "max-age=600");
    fresh302Response.setHTTPHeaderField("Location", redirectTargetUrlString);

    // Add the redirect to our request.
    ResourceRequest redirectRequest = ResourceRequest(redirectTargetUrl);
    firstResource->willSendRequest(redirectRequest, fresh302Response);

    // Add the final response to our request.
    ResourceResponse fresh200Response;
    fresh200Response.setURL(redirectTargetUrl);
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    firstResource->setResponse(fresh200Response);
    memoryCache()->add(firstResource.get());

    advanceClock(500.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_EQ(firstResource, fetched);
}

TEST_F(CachingCorrectnessTest, 302RedirectExplicitlyFreshExpires)
{
    KURL redirectUrl(ParsedURLString, kResourceURL);
    const char redirectTargetUrlString[] = "http://redirect-target.com";
    KURL redirectTargetUrl(ParsedURLString, redirectTargetUrlString);

    ResourcePtr<Resource> firstResource = new Resource(ResourceRequest(redirectUrl), Resource::Raw);

    ResourceResponse fresh302Response;
    fresh302Response.setURL(redirectUrl);
    fresh302Response.setHTTPStatusCode(302);
    fresh302Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh302Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);
    fresh302Response.setHTTPHeaderField("Location", redirectTargetUrlString);

    // Add the redirect to our request.
    ResourceRequest redirectRequest = ResourceRequest(redirectTargetUrl);
    firstResource->willSendRequest(redirectRequest, fresh302Response);

    // Add the final response to our request.
    ResourceResponse fresh200Response;
    fresh200Response.setURL(redirectTargetUrl);
    fresh200Response.setHTTPStatusCode(200);
    fresh200Response.setHTTPHeaderField("Date", kOriginalRequestDateAsString);
    fresh200Response.setHTTPHeaderField("Expires", kOneDayAfterOriginalRequest);

    firstResource->setResponse(fresh200Response);
    memoryCache()->add(firstResource.get());

    advanceClock(500.);

    ResourcePtr<Resource> fetched = fetch();
    EXPECT_EQ(firstResource, fetched);
}

} // namespace
