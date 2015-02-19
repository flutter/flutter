// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.oknet;

import com.squareup.okhttp.Call;
import com.squareup.okhttp.Callback;
import com.squareup.okhttp.Headers;
import com.squareup.okhttp.MediaType;
import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.Response;
import com.squareup.okhttp.ResponseBody;

import org.chromium.mojo.system.AsyncWaiter;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.MojoResult;
import org.chromium.mojo.system.Pair;
import org.chromium.mojom.mojo.NetworkError;
import org.chromium.mojom.mojo.UrlLoader;
import org.chromium.mojom.mojo.UrlLoaderStatus;
import org.chromium.mojom.mojo.UrlRequest;
import org.chromium.mojom.mojo.UrlResponse;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;

import okio.BufferedSource;

/**
 * OkHttp implementation of UrlLoader.
 */
public class UrlLoaderImpl implements UrlLoader {
    private Core mCore;
    private OkHttpClient mClient;
    private boolean mIsLoading;
    private NetworkError mError;

    class CopyToPipeJob {
        private BufferedSource mSource;
        private DataPipe.ProducerHandle mProducer;

        public CopyToPipeJob(BufferedSource source, DataPipe.ProducerHandle producerHandle) {
            mSource = source;
            mProducer = producerHandle;
        }

        public void copy() throws IOException {
            int result = 0;
            do {
                try {
                    ByteBuffer buffer = mProducer.beginWriteData(0, DataPipe.WriteFlags.none());
                    // TODO(abarth): There must be a way to do this without the temporary buffer.
                    byte[] tmp = new byte[buffer.capacity()];
                    result = mSource.read(tmp);
                    buffer.put(tmp);
                    mProducer.endWriteData(result == -1 ? 0 : result);
                } catch (MojoException e) {
                    if (e.getMojoResult() != MojoResult.SHOULD_WAIT) throw e;
                    copyMoreAsync();
                    return;
                }
            } while (result != -1);

            mIsLoading = false;
            mProducer.close();
        }

        private void copyMoreAsync() {
            AsyncWaiter w = mCore.getDefaultAsyncWaiter();
            w.asyncWait(mProducer, Core.HandleSignals.WRITABLE, -1, new AsyncWaiter.Callback() {
                @Override
                public void onResult(int result) {
                    assert result == MojoResult.OK;
                    try {
                        copy();
                    } catch (IOException e) {
                        mIsLoading = false;
                        mProducer.close();
                    }
                }
                @Override
                public void onError(MojoException exception) {
                    mIsLoading = false;
                    mProducer.close();
                }
            });
        }
    }

    public UrlLoaderImpl(Core core, OkHttpClient client) {
        assert core != null;
        mCore = core;
        mClient = client;
        mIsLoading = false;
        mError = null;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void start(UrlRequest request, StartResponse callback) {
        mIsLoading = true;
        mError = null;

        Request.Builder builder =
                new Request.Builder().url(request.url).method(request.method, null);

        if (request.headers != null) {
            for (String header : request.headers) {
                String[] parts = header.split(":");
                String name = parts[0].trim();
                String value = parts.length > 1 ? parts[2].trim() : "";
                builder.addHeader(name, value);
            }
        }

        // TODO(abarth): body, responseBodyBufferSize, autoFollowRedirects, bypassCache.
        final StartResponse responseCallback = callback;
        Call call = mClient.newCall(builder.build());
        call.enqueue(new Callback() {
            @Override
            public void onFailure(Request request, IOException e) {
                mError = new NetworkError();
                // TODO(abarth): Which mError.code should we set?
                mError.description = e.toString();
                UrlResponse urlResponse = new UrlResponse();
                urlResponse.error = mError;
                responseCallback.call(urlResponse);

                mIsLoading = false;
            }

            @Override
            public void onResponse(Response response) {
                UrlResponse urlResponse = new UrlResponse();
                urlResponse.url = response.request().urlString();
                urlResponse.statusCode = response.code();
                urlResponse.statusLine = response.message();

                Headers headers = response.headers();
                urlResponse.headers = new String[headers.size()];
                for (int i = 0; i < headers.size(); ++i) {
                    String name = headers.name(i);
                    String value = headers.value(i);
                    urlResponse.headers[i] = name + ": " + value;
                }

                ResponseBody body = response.body();
                MediaType mediaType = body.contentType();
                if (mediaType != null) {
                    urlResponse.mimeType = mediaType.type() + "/" + mediaType.subtype();
                    Charset charset = mediaType.charset();
                    if (charset != null)
                        urlResponse.charset = charset.displayName();
                }

                Pair<DataPipe.ProducerHandle, DataPipe.ConsumerHandle> handles =
                        mCore.createDataPipe(null);
                DataPipe.ProducerHandle producerHandle = handles.first;
                DataPipe.ConsumerHandle consumerHandle = handles.second;
                urlResponse.body = consumerHandle;
                responseCallback.call(urlResponse);
                CopyToPipeJob job = new CopyToPipeJob(body.source(), producerHandle);
                try {
                    job.copy();
                } catch (IOException e) {
                    mIsLoading = false;
                    producerHandle.close();
                }
            }
        });
    }

    @Override
    public void followRedirect(FollowRedirectResponse callback) {
        // TODO(abarth): Implement redirects.
        callback.call(new UrlResponse());
    }

    @Override
    public void queryStatus(QueryStatusResponse callback) {
        UrlLoaderStatus status = new UrlLoaderStatus();
        status.error = mError;
        status.isLoading = mIsLoading;
        callback.call(status);
    }
}
