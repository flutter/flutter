#include "config.h"
#include "bindings/core/dart/DartInspectorRuntimeAgent.h"

#include "bindings/common/ScriptState.h"
#include "bindings/core/dart/DartInjectedScript.h"
#include "bindings/core/dart/DartInjectedScriptManager.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "core/inspector/InjectedScript.h"
#include "core/inspector/InspectorState.h"
#include "platform/JSONValues.h"

using blink::TypeBuilder::Runtime::ExecutionContextDescription;

namespace blink {

static ScriptDebugServer::PauseOnExceptionsState setPauseOnExceptionsState(ScriptDebugServer::PauseOnExceptionsState newState)
{
    DartScriptDebugServer& scriptDebugServer = DartScriptDebugServer::shared();
    ScriptDebugServer::PauseOnExceptionsState presentState = scriptDebugServer.pauseOnExceptionsState();
    if (presentState != newState)
        scriptDebugServer.setPauseOnExceptionsState(newState);
    return presentState;
}

DartInspectorRuntimeAgent::DartInspectorRuntimeAgent(DartInjectedScriptManager* injectedScriptManager, InspectorRuntimeAgent* inspectorRuntimeAgent)
{
    m_injectedScriptManager = injectedScriptManager;
    m_inspectorRuntimeAgent = inspectorRuntimeAgent;
}

DartInjectedScript* DartInspectorRuntimeAgent::injectedScriptForEval(ErrorString* errorString, const int* executionContextId)
{
    if (!executionContextId) {
        return 0;
    }
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForId(*executionContextId);
    if (injectedScript == 0)
        *errorString = "Execution context with given id not found.";
    return injectedScript;
}

void DartInspectorRuntimeAgent::evaluate(ErrorString* errorString, const String& expression, const String* const objectGroup, const bool* const includeCommandLineAPI, const bool* const doNotPauseOnExceptionsAndMuteConsole, const int* executionContextId, const bool* const returnByValue, const bool* generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>& result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>& exceptionDetails)
{
    DartInjectedScript* injectedScript = injectedScriptForEval(errorString, executionContextId);
    if (!injectedScript)
        return;
    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = ScriptDebugServer::DontPauseOnExceptions;
    if (asBool(doNotPauseOnExceptionsAndMuteConsole))
        previousPauseOnExceptionsState = setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
    if (asBool(doNotPauseOnExceptionsAndMuteConsole))
        m_inspectorRuntimeAgent->muteConsole();

    injectedScript->evaluate(errorString, expression, objectGroup ? *objectGroup : "", asBool(includeCommandLineAPI), asBool(returnByValue), asBool(generatePreview), &result, wasThrown, &exceptionDetails);

    if (asBool(doNotPauseOnExceptionsAndMuteConsole)) {
        m_inspectorRuntimeAgent->unmuteConsole();
        setPauseOnExceptionsState(previousPauseOnExceptionsState);
    }
}

void DartInspectorRuntimeAgent::callFunctionOn(ErrorString* errorString, const String& objectId, const String& expression, const RefPtr<JSONArray>* const optionalArguments, const bool* const doNotPauseOnExceptionsAndMuteConsole, const bool* const returnByValue, const bool* generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>& result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForObjectId(objectId);
    if (!injectedScript) {
        *errorString = "Inspected frame has gone";
        return;
    }
    String arguments;
    if (optionalArguments)
        arguments = (*optionalArguments)->toJSONString();

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = ScriptDebugServer::DontPauseOnExceptions;
    if (asBool(doNotPauseOnExceptionsAndMuteConsole))
        previousPauseOnExceptionsState = setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
    if (asBool(doNotPauseOnExceptionsAndMuteConsole))
        m_inspectorRuntimeAgent->muteConsole();

    injectedScript->callFunctionOn(errorString, objectId, expression, arguments, asBool(returnByValue), asBool(generatePreview), &result, wasThrown);

    if (asBool(doNotPauseOnExceptionsAndMuteConsole)) {
        m_inspectorRuntimeAgent->unmuteConsole();
        setPauseOnExceptionsState(previousPauseOnExceptionsState);
    }

}

void DartInspectorRuntimeAgent::getCompletions(ErrorString* errorString, const String& expression, const int* executionContextId, RefPtr<TypeBuilder::Array<String> >& result)
{
    DartInjectedScript* injectedScript = injectedScriptForEval(errorString, executionContextId);
    if (!injectedScript)
        return;

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
    m_inspectorRuntimeAgent->muteConsole();

    injectedScript->getCompletions(errorString, expression, &result);

    m_inspectorRuntimeAgent->unmuteConsole();
    setPauseOnExceptionsState(previousPauseOnExceptionsState);

}

void DartInspectorRuntimeAgent::getProperties(ErrorString* errorString, const String& objectId, const bool* ownProperties, const bool* accessorPropertiesOnly, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::PropertyDescriptor> >& result, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::InternalPropertyDescriptor> >& internalProperties)
{
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForObjectId(objectId);
    if (!injectedScript) {
        *errorString = "Inspected frame has gone";
        return;
    }

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
    m_inspectorRuntimeAgent->muteConsole();

    injectedScript->getProperties(errorString, objectId, asBool(ownProperties), asBool(accessorPropertiesOnly), &result);

    if (!asBool(accessorPropertiesOnly))
        injectedScript->getInternalProperties(errorString, objectId, &internalProperties);

    m_inspectorRuntimeAgent->unmuteConsole();
    setPauseOnExceptionsState(previousPauseOnExceptionsState);
}

void DartInspectorRuntimeAgent::getProperty(ErrorString* errorString, const String& objectId, const RefPtr<JSONArray>& propertyPath, RefPtr<TypeBuilder::Runtime::RemoteObject>& result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForObjectId(objectId);
    if (!injectedScript) {
        *errorString = "Inspected frame has gone";
        return;
    }

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
    m_inspectorRuntimeAgent->muteConsole();

    injectedScript->getProperty(errorString, objectId, propertyPath, &result, wasThrown);

    m_inspectorRuntimeAgent->unmuteConsole();
    setPauseOnExceptionsState(previousPauseOnExceptionsState);
}

void DartInspectorRuntimeAgent::releaseObject(ErrorString*, const String& objectId)
{
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForObjectId(objectId);
    if (injectedScript)
        injectedScript->releaseObject(objectId);
}

void DartInspectorRuntimeAgent::releaseObjectGroup(ErrorString*, const String& objectGroup)
{
    m_injectedScriptManager->releaseObjectGroup(objectGroup);
}

int DartInspectorRuntimeAgent::addExecutionContextToFrontendHelper(ScriptState* scriptState, bool isPageContext, const String& name, const String& frameId)
{
    return m_injectedScriptManager->injectedScriptIdFor(scriptState);
}

} // namespace blink
