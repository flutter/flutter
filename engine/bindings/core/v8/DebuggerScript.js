/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

(function () {

var DebuggerScript = {};

DebuggerScript.PauseOnExceptionsState = {
    DontPauseOnExceptions: 0,
    PauseOnAllExceptions: 1,
    PauseOnUncaughtExceptions: 2
};

DebuggerScript.ScopeInfoDetails = {
    AllScopes: 0,
    FastAsyncScopes: 1,
    NoScopes: 2
};

DebuggerScript._pauseOnExceptionsState = DebuggerScript.PauseOnExceptionsState.DontPauseOnExceptions;
Debug.clearBreakOnException();
Debug.clearBreakOnUncaughtException();

DebuggerScript.getAfterCompileScript = function(eventData)
{
    return DebuggerScript._formatScript(eventData.script_.script_);
}

DebuggerScript.getWorkerScripts = function()
{
    var result = [];
    var scripts = Debug.scripts();
    for (var i = 0; i < scripts.length; ++i) {
        var script = scripts[i];
        // Workers don't share same V8 heap now so there is no need to complicate stuff with
        // the context id like we do to discriminate between scripts from different pages.
        // However we need to filter out v8 native scripts.
        if (script.context_data && script.context_data === "worker")
            result.push(DebuggerScript._formatScript(script));
    }
    return result;
}

DebuggerScript.getFunctionScopes = function(fun)
{
    var mirror = MakeMirror(fun);
    var count = mirror.scopeCount();
    if (count == 0)
        return null;
    var result = [];
    for (var i = 0; i < count; i++) {
        var scopeDetails = mirror.scope(i).details();
        result[i] = {
            type: scopeDetails.type(),
            object: DebuggerScript._buildScopeObject(scopeDetails.type(), scopeDetails.object())
        };
    }
    return result;
}

DebuggerScript.getCollectionEntries = function(object)
{
    var mirror = MakeMirror(object, true /* transient */);
    if (mirror.isMap())
        return mirror.entries();
    if (mirror.isSet()) {
        var result = [];
        var values = mirror.values();
        for (var i = 0; i < values.length; ++i)
            result.push({ value: values[i] });
        return result;
    }
}

DebuggerScript.getInternalProperties = function(value)
{
    var properties = ObjectMirror.GetInternalProperties(value);
    var result = [];
    for (var i = 0; i < properties.length; i++) {
        var mirror = properties[i];
        result.push({
            name: mirror.name(),
            value: mirror.value().value()
        });
    }
    return result;
}

DebuggerScript.setFunctionVariableValue = function(functionValue, scopeIndex, variableName, newValue)
{
    var mirror = MakeMirror(functionValue);
    if (!mirror.isFunction())
        throw new Error("Function value has incorrect type");
    return DebuggerScript._setScopeVariableValue(mirror, scopeIndex, variableName, newValue);
}

DebuggerScript._setScopeVariableValue = function(scopeHolder, scopeIndex, variableName, newValue)
{
    var scopeMirror = scopeHolder.scope(scopeIndex);
    if (!scopeMirror)
        throw new Error("Incorrect scope index");
    scopeMirror.setVariableValue(variableName, newValue);
    return undefined;
}

DebuggerScript.getScripts = function(contextData)
{
    var result = [];

    if (!contextData)
        return result;
    var comma = contextData.indexOf(",");
    if (comma === -1)
        return result;
    // Context data is a string in the following format:
    // ("page"|"injected")","<page id>
    var idSuffix = contextData.substring(comma); // including the comma

    var scripts = Debug.scripts();
    for (var i = 0; i < scripts.length; ++i) {
        var script = scripts[i];
        if (script.context_data && script.context_data.lastIndexOf(idSuffix) != -1)
            result.push(DebuggerScript._formatScript(script));
    }
    return result;
}

DebuggerScript._formatScript = function(script)
{
    var lineEnds = script.line_ends;
    var lineCount = lineEnds.length;
    var endLine = script.line_offset + lineCount - 1;
    var endColumn;
    // V8 will not count last line if script source ends with \n.
    if (script.source[script.source.length - 1] === '\n') {
        endLine += 1;
        endColumn = 0;
    } else {
        if (lineCount === 1)
            endColumn = script.source.length + script.column_offset;
        else
            endColumn = script.source.length - (lineEnds[lineCount - 2] + 1);
    }

    return {
        id: script.id,
        name: script.nameOrSourceURL(),
        sourceURL: script.source_url,
        sourceMappingURL: script.source_mapping_url,
        source: script.source,
        startLine: script.line_offset,
        startColumn: script.column_offset,
        endLine: endLine,
        endColumn: endColumn,
        isContentScript: !!script.context_data && script.context_data.indexOf("injected") == 0
    };
}

DebuggerScript.setBreakpoint = function(execState, info)
{
    var positionAlignment = info.interstatementLocation ? Debug.BreakPositionAlignment.BreakPosition : Debug.BreakPositionAlignment.Statement;
    var breakId = Debug.setScriptBreakPointById(info.sourceID, info.lineNumber, info.columnNumber, info.condition, undefined, positionAlignment);

    var locations = Debug.findBreakPointActualLocations(breakId);
    if (!locations.length)
        return undefined;
    info.lineNumber = locations[0].line;
    info.columnNumber = locations[0].column;
    return breakId.toString();
}

DebuggerScript.removeBreakpoint = function(execState, info)
{
    Debug.findBreakPoint(info.breakpointId, true);
}

DebuggerScript.pauseOnExceptionsState = function()
{
    return DebuggerScript._pauseOnExceptionsState;
}

DebuggerScript.setPauseOnExceptionsState = function(newState)
{
    DebuggerScript._pauseOnExceptionsState = newState;

    if (DebuggerScript.PauseOnExceptionsState.PauseOnAllExceptions === newState)
        Debug.setBreakOnException();
    else
        Debug.clearBreakOnException();

    if (DebuggerScript.PauseOnExceptionsState.PauseOnUncaughtExceptions === newState)
        Debug.setBreakOnUncaughtException();
    else
        Debug.clearBreakOnUncaughtException();
}

DebuggerScript.frameCount = function(execState)
{
    return execState.frameCount();
}

DebuggerScript.currentCallFrame = function(execState, data)
{
    var maximumLimit = data >> 2;
    var scopeDetailsLevel = data & 3;

    var frameCount = execState.frameCount();
    if (maximumLimit && maximumLimit < frameCount)
        frameCount = maximumLimit;
    var topFrame = undefined;
    for (var i = frameCount - 1; i >= 0; i--) {
        var frameMirror = execState.frame(i);
        topFrame = DebuggerScript._frameMirrorToJSCallFrame(frameMirror, topFrame, scopeDetailsLevel);
    }
    return topFrame;
}

DebuggerScript.currentCallFrameByIndex = function(execState, index)
{
    if (index < 0)
        return undefined;
    var frameCount = execState.frameCount();
    if (index >= frameCount)
        return undefined;
    return DebuggerScript._frameMirrorToJSCallFrame(execState.frame(index), undefined, DebuggerScript.ScopeInfoDetails.NoScopes);
}

DebuggerScript.stepIntoStatement = function(execState)
{
    execState.prepareStep(Debug.StepAction.StepIn, 1);
}

DebuggerScript.stepOverStatement = function(execState, callFrame)
{
    execState.prepareStep(Debug.StepAction.StepNext, 1);
}

DebuggerScript.stepOutOfFunction = function(execState, callFrame)
{
    execState.prepareStep(Debug.StepAction.StepOut, 1);
}

// Returns array in form:
//      [ 0, <v8_result_report> ] in case of success
//   or [ 1, <general_error_message>, <compiler_message>, <line_number>, <column_number> ] in case of compile error, numbers are 1-based.
// or throws exception with message.
DebuggerScript.liveEditScriptSource = function(scriptId, newSource, preview)
{
    var scripts = Debug.scripts();
    var scriptToEdit = null;
    for (var i = 0; i < scripts.length; i++) {
        if (scripts[i].id == scriptId) {
            scriptToEdit = scripts[i];
            break;
        }
    }
    if (!scriptToEdit)
        throw("Script not found");

    var changeLog = [];
    try {
        var result = Debug.LiveEdit.SetScriptSource(scriptToEdit, newSource, preview, changeLog);
        return [0, result];
    } catch (e) {
        if (e instanceof Debug.LiveEdit.Failure && "details" in e) {
            var details = e.details;
            if (details.type === "liveedit_compile_error") {
                var startPosition = details.position.start;
                return [1, String(e), String(details.syntaxErrorMessage), Number(startPosition.line), Number(startPosition.column)];
            }
        }
        throw e;
    }
}

DebuggerScript.clearBreakpoints = function(execState, info)
{
    Debug.clearAllBreakPoints();
}

DebuggerScript.setBreakpointsActivated = function(execState, info)
{
    Debug.debuggerFlags().breakPointsActive.setValue(info.enabled);
}

DebuggerScript.getScriptSource = function(eventData)
{
    return eventData.script().source();
}

DebuggerScript.setScriptSource = function(eventData, source)
{
    if (eventData.script().data() === "injected-script")
        return;
    eventData.script().setSource(source);
}

DebuggerScript.getScriptName = function(eventData)
{
    return eventData.script().script_.nameOrSourceURL();
}

DebuggerScript.getBreakpointNumbers = function(eventData)
{
    var breakpoints = eventData.breakPointsHit();
    var numbers = [];
    if (!breakpoints)
        return numbers;

    for (var i = 0; i < breakpoints.length; i++) {
        var breakpoint = breakpoints[i];
        var scriptBreakPoint = breakpoint.script_break_point();
        numbers.push(scriptBreakPoint ? scriptBreakPoint.number() : breakpoint.number());
    }
    return numbers;
}

DebuggerScript.isEvalCompilation = function(eventData)
{
    var script = eventData.script();
    return (script.compilationType() === Debug.ScriptCompilationType.Eval);
}

// NOTE: This function is performance critical, as it can be run on every
// statement that generates an async event (like addEventListener) to support
// asynchronous call stacks. Thus, when possible, initialize the data lazily.
DebuggerScript._frameMirrorToJSCallFrame = function(frameMirror, callerFrame, scopeDetailsLevel)
{
    // Stuff that can not be initialized lazily (i.e. valid while paused with a valid break_id).
    // The frameMirror and scopeMirror can be accessed only while paused on the debugger.
    var frameDetails = frameMirror.details();

    var funcObject = frameDetails.func();
    var sourcePosition = frameDetails.sourcePosition();
    var thisObject = frameDetails.receiver();

    var isAtReturn = !!frameDetails.isAtReturn();
    var returnValue = isAtReturn ? frameDetails.returnValue() : undefined;

    var scopeMirrors = (scopeDetailsLevel === DebuggerScript.ScopeInfoDetails.NoScopes ? [] : frameMirror.allScopes(scopeDetailsLevel === DebuggerScript.ScopeInfoDetails.FastAsyncScopes));
    var scopeTypes = new Array(scopeMirrors.length);
    var scopeObjects = new Array(scopeMirrors.length);
    for (var i = 0; i < scopeMirrors.length; ++i) {
        var scopeDetails = scopeMirrors[i].details();
        scopeTypes[i] = scopeDetails.type();
        scopeObjects[i] = scopeDetails.object();
    }

    // Calculated lazily.
    var scopeChain;
    var funcMirror;
    var location;

    function lazyScopeChain()
    {
        if (!scopeChain) {
            scopeChain = [];
            for (var i = 0; i < scopeObjects.length; ++i)
                scopeChain.push(DebuggerScript._buildScopeObject(scopeTypes[i], scopeObjects[i]));
            scopeObjects = null; // Free for GC.
        }
        return scopeChain;
    }

    function ensureFuncMirror()
    {
        if (!funcMirror) {
            funcMirror = MakeMirror(funcObject);
            if (!funcMirror.isFunction())
                funcMirror = new UnresolvedFunctionMirror(funcObject);
        }
        return funcMirror;
    }

    function ensureLocation()
    {
        if (!location) {
            var script = ensureFuncMirror().script();
            if (script)
                location = script.locationFromPosition(sourcePosition, true);
            if (!location)
                location = { line: 0, column: 0 };
        }
        return location;
    }

    function line()
    {
        return ensureLocation().line;
    }

    function column()
    {
        return ensureLocation().column;
    }

    function sourceID()
    {
        var script = ensureFuncMirror().script();
        return script && script.id();
    }

    function scriptName()
    {
        var script = ensureFuncMirror().script();
        return script && script.name();
    }

    function functionName()
    {
        var func = ensureFuncMirror();
        if (!func.resolved())
            return undefined;
        var displayName;
        var valueMirror = func.property("displayName").value();
        if (valueMirror && valueMirror.isString())
            displayName = valueMirror.value();
        return displayName || func.name() || func.inferredName();
    }

    function evaluate(expression)
    {
        return frameMirror.evaluate(expression, false).value();
    }

    function restart()
    {
        return Debug.LiveEdit.RestartFrame(frameMirror);
    }

    function setVariableValue(scopeNumber, variableName, newValue)
    {
        return DebuggerScript._setScopeVariableValue(frameMirror, scopeNumber, variableName, newValue);
    }

    function stepInPositions()
    {
        var stepInPositionsV8 = frameMirror.stepInPositions();
        var stepInPositionsProtocol;
        if (stepInPositionsV8) {
            stepInPositionsProtocol = [];
            var script = ensureFuncMirror().script();
            if (script) {
                var scriptId = String(script.id());
                for (var i = 0; i < stepInPositionsV8.length; i++) {
                    var item = {
                        scriptId: scriptId,
                        lineNumber: stepInPositionsV8[i].position.line,
                        columnNumber: stepInPositionsV8[i].position.column
                    };
                    stepInPositionsProtocol.push(item);
                }
            }
        }
        return JSON.stringify(stepInPositionsProtocol);
    }

    return {
        "sourceID": sourceID,
        "line": line,
        "column": column,
        "scriptName": scriptName,
        "functionName": functionName,
        "thisObject": thisObject,
        "scopeChain": lazyScopeChain,
        "scopeType": scopeTypes,
        "evaluate": evaluate,
        "caller": callerFrame,
        "restart": restart,
        "setVariableValue": setVariableValue,
        "stepInPositions": stepInPositions,
        "isAtReturn": isAtReturn,
        "returnValue": returnValue
    };
}

DebuggerScript._buildScopeObject = function(scopeType, scopeObject)
{
    var result;
    switch (scopeType) {
    case ScopeType.Local:
    case ScopeType.Closure:
    case ScopeType.Catch:
        // For transient objects we create a "persistent" copy that contains
        // the same properties.
        // Reset scope object prototype to null so that the proto properties
        // don't appear in the local scope section.
        result = { __proto__: null };
        var properties = MakeMirror(scopeObject, true /* transient */).properties();
        for (var j = 0; j < properties.length; j++) {
            var name = properties[j].name();
            if (name.charAt(0) === ".")
                continue; // Skip internal variables like ".arguments"
            result[name] = properties[j].value_;
        }
        break;
    case ScopeType.Global:
    case ScopeType.With:
        result = scopeObject;
        break;
    case ScopeType.Block:
        // Unsupported yet. Mustn't be reachable.
        break;
    }
    return result;
}

DebuggerScript.getPromiseDetails = function(eventData)
{
    return {
        "promise": eventData.promise().value(),
        "parentPromise": eventData.parentPromise().value(),
        "status": eventData.status()
    };
}

// We never resolve Mirror by its handle so to avoid memory leaks caused by Mirrors in the cache we disable it.
ToggleMirrorCache(false);

return DebuggerScript;
})();
