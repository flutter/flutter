// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.oknet;

import android.util.Log;

import com.squareup.okhttp.Call;
import com.squareup.okhttp.Callback;
import com.squareup.okhttp.Headers;
import com.squareup.okhttp.MediaType;
import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.RequestBody;
import com.squareup.okhttp.Response;
import com.squareup.okhttp.ResponseBody;

import org.chromium.base.TraceEvent;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.MojoResult;
import org.chromium.mojo.system.Pair;
import org.chromium.mojom.mojo.HttpHeader;
import org.chromium.mojom.mojo.NetworkError;
import org.chromium.mojom.mojo.UrlLoader;
import org.chromium.mojom.mojo.UrlLoaderStatus;
import org.chromium.mojom.mojo.UrlRequest;
import org.chromium.mojom.mojo.UrlResponse;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.WritableByteChannel;
import java.nio.charset.Charset;
import java.nio.charset.UnsupportedCharsetException;
import java.util.concurrent.Executor;

import okio.BufferedSource;


/**
 * OkHttp implementation of UrlLoader.
 */
public class UrlLoaderImpl implements UrlLoader {
    private static final String TAG = "UrlLoaderImpl";
    private final Core mCore;
    private final OkHttpClient mClient;
    private final Executor mExecutor;
    private boolean mIsLoading;
    private NetworkError mError;

    private static long sNextTracingId = 1;
    private final long mTracingId;

    class CopyToPipeJob implements Runnable {
        private ResponseBody mBody;
        private BufferedSource mSource;
        private DataPipe.ProducerHandle mProducer;

        public CopyToPipeJob(ResponseBody body, DataPipe.ProducerHandle producerHandle) {
            mBody = body;
            mSource = body.source();
            mProducer = producerHandle;
        }

        @Override
        public void run() {
            TraceEvent.begin("UrlLoaderImpl::CopyToPipeJob::copy");
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
                    // No one read the pipe, they just closed it.
                    if (e.getMojoResult() == MojoResult.FAILED_PRECONDITION) {
                        break;
                    } else if (e.getMojoResult() == MojoResult.SHOULD_WAIT) {
                        mCore.wait(mProducer, Core.HandleSignals.WRITABLE, -1);
                    } else {
                        throw e;
                    }
                } catch (IOException e) {
                    Log.e(TAG, "mSource.read failed", e);
                    break;
                }
            } while (result != -1);

            mIsLoading = false;
            mProducer.close();
            try {
                mBody.close();
            } catch (IOException e) {
                Log.e(TAG, "mBody.close failed", e);
            }
            TraceEvent.finishAsync("UrlLoaderImpl", mTracingId);
            TraceEvent.end("UrlLoaderImpl::CopyToPipeJob::copy");
        }
    }

    public UrlLoaderImpl(Core core, OkHttpClient client, Executor executor) {
        assert core != null;
        mCore = core;
        mClient = client;
        mExecutor = executor;
        mIsLoading = false;
        mError = null;
        mTracingId = sNextTracingId++;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void start(UrlRequest request, StartResponse callback) {
        mExecutor.execute(new StartRequestJob(request, callback));
    }

    class StartRequestJob implements Runnable {
        private final UrlRequest mRequest;
        private final StartResponse mCallback;

        public StartRequestJob(UrlRequest request, StartResponse callback) {
            mRequest = request;
            mCallback = callback;
        }

        @Override
        public void run() {

            TraceEvent.startAsync("UrlLoaderImpl", mTracingId);
            mIsLoading = true;
            mError = null;

            URL url = null;
            try {
                url = new URL(mRequest.url);
            } catch (MalformedURLException e) {
                Log.w(TAG, "Failed to parse url " + mRequest.url);
                mError = new NetworkError();
                // TODO(abarth): Which mError.code should we set?
                mError.description = e.toString();
                UrlResponse urlResponse = new UrlResponse();
                urlResponse.url = mRequest.url;
                urlResponse.error = mError;
                mCallback.call(urlResponse);
                return;
            }

            Request.Builder builder = new Request.Builder().url(url);

            String contentType = null;
            if (mRequest.headers != null) {
                for (HttpHeader header : mRequest.headers) {
                    if (header.name.toLowerCase().equals("content-type"))
                        contentType = header.value;
                    builder.addHeader(header.name, header.value);
                }
            }

            RequestBody body = null;
            if (mRequest.body != null && mRequest.body[0] != null) {
                if (mRequest.body.length > 1) {
                    Log.w(TAG, "POST requests with multiple bodies are not supported");
                }

                DataPipe.ConsumerHandle consumer = mRequest.body[0];
                ByteArrayOutputStream bodyStream = new ByteArrayOutputStream();
                WritableByteChannel dest = Channels.newChannel(bodyStream);
                do {
                    try {
                        ByteBuffer buffer = consumer.beginReadData(0, DataPipe.ReadFlags.NONE);
                        if (buffer.capacity() == 0) break;
                        dest.write(buffer);
                        consumer.endReadData(buffer.capacity());
                    } catch (IOException e) {
                        throw new MojoException(e);
                    } catch (MojoException e) {
                        // No one read the pipe, they just closed it.
                        if (e.getMojoResult() == MojoResult.FAILED_PRECONDITION) {
                            break;
                        } else if (e.getMojoResult() == MojoResult.SHOULD_WAIT) {
                            mCore.wait(consumer, Core.HandleSignals.READABLE, -1);
                        } else {
                            throw e;
                        }
                    }
                } while (true);
                if (contentType == null)
                    contentType = "application/x-www-form-urlencoded; charset=utf8";
                MediaType mediaType = MediaType.parse(contentType);
                body = RequestBody.create(mediaType, bodyStream.toByteArray());
            }

            builder.method(mRequest.method, body);

            // TODO(abarth): responseBodyBufferSize, autoFollowRedirects, bypassCache.
            Call call = mClient.newCall(builder.build());
            call.enqueue(new Callback() {
                @Override
                public void onFailure(Request request, IOException e) {
                    Log.w(TAG, "Network failure loading " + mRequest.url);
                    mError = new NetworkError();
                    // TODO(abarth): Which mError.code should we set?
                    mError.description = e.toString();
                    UrlResponse urlResponse = new UrlResponse();
                    urlResponse.url = mRequest.url;
                    urlResponse.error = mError;
                    mCallback.call(urlResponse);

                    mIsLoading = false;
                    TraceEvent.finishAsync("UrlLoaderImpl", mTracingId);
                }

                @Override
                public void onResponse(Response response) {
                    UrlResponse urlResponse = new UrlResponse();
                    urlResponse.url = response.request().urlString();
                    urlResponse.statusCode = response.code();
                    urlResponse.statusLine = response.message();

                    if (urlResponse.statusCode >= 400) {
                        Log.w(TAG, "Failed to load: " + urlResponse.url + " ("
                                + urlResponse.statusCode + ")");
                    }

                    Headers headers = response.headers();
                    urlResponse.headers = new HttpHeader[headers.size()];
                    for (int i = 0; i < headers.size(); ++i) {
                        HttpHeader header = new HttpHeader();
                        header.name = headers.name(i);
                        header.value = headers.value(i);
                        urlResponse.headers[i] = header;
                    }

                    ResponseBody body = response.body();
                    MediaType mediaType = body.contentType();
                    if (mediaType != null) {
                        urlResponse.mimeType = mediaType.type() + "/" + mediaType.subtype();
                        try {
                          Charset charset = mediaType.charset();
                          if (charset != null) {
                              urlResponse.charset = charset.displayName();
                          }
                        } catch (UnsupportedCharsetException e) {
                          Log.e(TAG, "Unsupported charset", e);
                        }
                    }

                    Pair<DataPipe.ProducerHandle, DataPipe.ConsumerHandle> handles =
                            mCore.createDataPipe(null);
                    DataPipe.ProducerHandle producerHandle = handles.first;
                    DataPipe.ConsumerHandle consumerHandle = handles.second;
                    urlResponse.body = consumerHandle;
                    mCallback.call(urlResponse);
                    mExecutor.execute(new CopyToPipeJob(body, producerHandle));
                }
            });
        }
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
