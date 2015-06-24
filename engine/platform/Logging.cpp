/*
 * Copyright (C) 2003, 2006 Apple Computer, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/platform/Logging.h"

#include "sky/engine/wtf/text/WTFString.h"

#if !LOG_DISABLED

namespace blink {

WTFLogChannel LogNotYetImplemented =  { WTFLogChannelOff };

WTFLogChannel LogFrames =             { WTFLogChannelOff };
WTFLogChannel LogLoading =            { WTFLogChannelOff };
WTFLogChannel LogEvents =             { WTFLogChannelOff };

WTFLogChannel LogEditing =            { WTFLogChannelOff };

WTFLogChannel LogSpellingAndGrammar = { WTFLogChannelOff };
WTFLogChannel LogBackForward =        { WTFLogChannelOff };
WTFLogChannel LogHistory =            { WTFLogChannelOff };

WTFLogChannel LogPlatformLeaks =      { WTFLogChannelOff };
WTFLogChannel LogResourceLoading =    { WTFLogChannelOff };

WTFLogChannel LogNetwork =            { WTFLogChannelOff };
WTFLogChannel LogFTP =                { WTFLogChannelOff };
WTFLogChannel LogThreading =          { WTFLogChannelOff };
WTFLogChannel LogStorageAPI =         { WTFLogChannelOff };

WTFLogChannel LogMedia =              { WTFLogChannelOff };
WTFLogChannel LogArchives =           { WTFLogChannelOff };
WTFLogChannel LogProgress =           { WTFLogChannelOff };

WTFLogChannel LogFileAPI =            { WTFLogChannelOff };

WTFLogChannel LogScriptedAnimationController = { WTFLogChannelOff };
WTFLogChannel LogTimers =                      { WTFLogChannelOff };

WTFLogChannel* getChannelFromName(const String& channelName)
{
    if (!(channelName.length() >= 2))
        return 0;

    if (equalIgnoringCase(channelName, String("BackForward")))
        return &LogBackForward;

    if (equalIgnoringCase(channelName, String("Editing")))
        return &LogEditing;

    if (equalIgnoringCase(channelName, String("Events")))
        return &LogEvents;

    if (equalIgnoringCase(channelName, String("Frames")))
        return &LogFrames;

    if (equalIgnoringCase(channelName, String("FTP")))
        return &LogFTP;

    if (equalIgnoringCase(channelName, String("History")))
        return &LogHistory;

    if (equalIgnoringCase(channelName, String("Loading")))
        return &LogLoading;

    if (equalIgnoringCase(channelName, String("Media")))
        return &LogMedia;

    if (equalIgnoringCase(channelName, String("Network")))
        return &LogNetwork;

    if (equalIgnoringCase(channelName, String("NotYetImplemented")))
        return &LogNotYetImplemented;

    if (equalIgnoringCase(channelName, String("PlatformLeaks")))
        return &LogPlatformLeaks;

    if (equalIgnoringCase(channelName, String("ResourceLoading")))
        return &LogResourceLoading;

    if (equalIgnoringCase(channelName, String("Progress")))
        return &LogProgress;

    if (equalIgnoringCase(channelName, String("SpellingAndGrammar")))
        return &LogSpellingAndGrammar;

    if (equalIgnoringCase(channelName, String("StorageAPI")))
        return &LogStorageAPI;

    if (equalIgnoringCase(channelName, String("Threading")))
        return &LogThreading;

    if (equalIgnoringCase(channelName, String("FileAPI")))
        return &LogFileAPI;

    if (equalIgnoringCase(channelName, String("ScriptedAnimationController")))
        return &LogScriptedAnimationController;

    if (equalIgnoringCase(channelName, String("Timers")))
        return &LogTimers;

    return 0;
}

}

#endif // !LOG_DISABLED
