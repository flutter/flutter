// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

type JSCompileTarget = "dart2js" | "dartdevc";
type WasmCompileTarget = "dart2wasm";

export type CompileTarget = JSCompileTarget | WasmCompileTarget;
export type WebRenderer = "canvaskit" | "skwasm";
export type BrowserEngine = "blink" | "gecko" | "webkit" | "unknown";

interface ApplicationBuildBase {
  renderer: WebRenderer;
}

export interface JSApplicationBuild extends ApplicationBuildBase {
  compileTarget: JSCompileTarget;
  mainJsPath: string;
}

export interface WasmApplicationBuild extends ApplicationBuildBase {
  compileTarget: WasmCompileTarget;
  mainWasmPath: string;
  jsSupportRuntimePath: string;
}

export type ApplicationBuild = JSApplicationBuild | WasmApplicationBuild;

export interface BuildConfig {
  /** @deprecated Flutter's service worker is deprecated and will be removed in a future Flutter release*/
  serviceWorkerVersion: string;
  engineRevision: string;
  useLocalCanvasKit?: boolean;
  builds: ApplicationBuild[];
}

export interface BrowserEnvironment {
  browserEngine: BrowserEngine;
  hasImageCodecs: boolean;
  hasChromiumBreakIterators: boolean;
  supportsWasmGC: boolean;
  crossOriginIsolated: boolean;
  webGLVersion: number;
  isChromeExtension: boolean;
}

type CanvasKitVariant =
  "auto" |
  "full" |
  "chromium";

type WasmAllowList = {
  [k in BrowserEngine]?: boolean;
}

export interface FlutterConfiguration {
  assetBase?: string;
  canvasKitBaseUrl?: string;
  canvasKitVariant?: CanvasKitVariant;
  renderer?: WebRenderer;
  enableWimp?: boolean;
  hostElement?: HTMLElement;
  fontFallbackBaseUrl?: string;
  /** @deprecated use `entrypointBaseUrl` instead*/
  entryPointBaseUrl?: string;
  entrypointBaseUrl?: string;
  forceSingleThreadedSkwasm?: boolean;
  wasmAllowList?: WasmAllowList;
}

/** @deprecated Flutter's service worker is deprecated and will be removed in a future Flutter release*/
export interface ServiceWorkerSettings {
  serviceWorkerVersion: string;
  serviceWorkerUrl?: string;
  timeoutMillis?: number;
}

export interface AppRunner {
  runApp: () => void;
}

export interface EngineInitializer {
  initializeEngine: () => Promise<AppRunner>;
}

export type OnEntrypointLoadedCallback =
  (initializer: EngineInitializer) => void;
