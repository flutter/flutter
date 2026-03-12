In the interest of transparency, we want to share high-level details of our roadmap so that others can see our priorities and make plans based on the work we are doing.

Our plans will evolve over time based on customer feedback and new market opportunities. We will use our surveys and feedback on GitHub issues to prioritize work. The list here shouldn't be viewed either as exhaustive nor a promise that we will complete all this work. If you have feedback about what you think we should work on, we encourage you to get in touch by [filing an issue](https://github.com/flutter/flutter/issues/new/choose), or using the "thumbs-up" emoji reaction on an issue's first comment. Because Flutter is an open source project, we invite contributions both towards the themes presented below and in other areas.

*If you are a contributor or team of contributors with long-term plans for [contributing to Flutter](../../CONTRIBUTING.md), and would like your planned efforts reflected in the roadmap, please reach via email to roadmap-input@flutter.dev.*

# **2026**

This roadmap is aspirational. It represents content primarily gathered from those of us who work on Flutter and Dart as employees of Google. By now non-Google contributors outnumber those employed by Google, so this is not an exhaustive list of all the new and exciting things that we hope will come this year\! As always it can be difficult to accurately forecast engineering work — even more so for an open source project. So please be mindful that what we cover here is a statement of intent and not a guarantee.

## High-fidelity multiplatform: Impeller, Wasm, and beyond

We will continue to deliver the best multiplatform stack by focusing on native-level quality and performance. Our 2026 goals include completing the migration to the [**Impeller**](https://docs.flutter.dev/perf/impeller) renderer on Android, and removing the legacy Skia backend on Android 10 and above. We continue to see Impeller as the best solution for fast startup and reduced jank. We are also committed to deep platform integration, ensuring day-zero support for [**Android 17**](https://developer.android.com/) and the upcoming iOS releases, alongside continued accessibility improvements for web, and multi-window desktop environments. For Desktop, our partners at Canonical continue to make progress on improving multi-window support. For Flutter on the web, we intend for [**WebAssembly (Wasm)**](https://webassembly.org/) to become the default to deliver native-quality experiences and performance. We are also collaborating with community-led frameworks like [Jaspr](https://jaspr.site/) for developers seeking a traditional, DOM-based approach to high-performance web-first applications and websites.

## **GenUI, ephemeral experiences and agentic apps**

We will continue to explore the new paradigm of building application architecture to enable **dynamic and expressive UIs**—interfaces that adapt in real-time to user intent. This is powered by the [**Flutter GenUI SDK**](https://docs.flutter.dev/ai/genui) and the [**A2UI protocol**](https://a2ui.org/), enabling AI models to generate rich user experiences dynamically. To support this, we are investigating evolving the Dart language by adding support for interpreted bytecode in the Dart runtime. This enables "ephemeral" code delivery, where specific portions of an app can be loaded on demand.

## **Full-Stack Dart: Bring your tooling everywhere**

We are broadening our stack to support the evolution towards full-stack and agentive apps. A major focus is **Dart Cloud Functions** for Firebase, providing ~10ms cold starts to ensure high-performance backend logic. We are also investigating Dart support for the **Google Cloud SDK** to enable you to easily connect and build your backend on Google Cloud. Additionally, we are working with the [Genkit](https://genkit.dev/) team on enabling Dart support, to help you build sophisticated AI features using Dart.

## **AI-reimagined developer experience**

AI coding agents are disrupting the way apps are built. To ensure high quality developer experience, we'll continue to collaborate within Google to ensure Dart and Flutter have top-tier support in [**Gemini CLI**](https://docs.flutter.dev/ai/create-with-ai#gemini-cli) and [**Antigravity**](https://docs.flutter.dev/ai/create-with-ai#antigravity), ensuring core workflows like stateful hot reload work seamlessly with AI agents. We are also investing in [**MCP (Model Context Protocol)** servers](https://docs.flutter.dev/ai/mcp-server) for Dart tooling, enabling AI agents to perform complex refactors and choose secure, performant libraries with high accuracy.

## **Sustainable open-source & governance**

To unlock Flutter's full potential, we are moving towards an open and sustainable operating model. This includes decoupling the [**Material**](https://m3.material.io/) and [**Cupertino**](https://developer.apple.com/design/human-interface-guidelines/components) design systems into standalone packages to accelerate development, and improving the extensibility of the Flutter Engine and command line tools so that support for new platforms can be authored "out-of-tree." We are also continuing to work with the open source community, customers, and partners to democratize architectural decisions and increase community contributions to the core framework.

In 2026, we are deepening our commitment to the ecosystem by formalizing how we collaborate with our most invested stakeholders. Central to this effort is the expansion of our **Consultancy Program**, **Google Developer Expert (GDE) network**, **Customer Advisory Board (CAB)**, and our **Partners Advisory Board (PAB)**, which provide direct feedback to our teams. By leveraging these avenues alongside our community programs, we aim to bridge the gap between developing Dart and Flutter and real-world applications built using them. These community programs will ensure that our roadmap is informed by diverse needs from our global audience of developers in various industries. These initiatives, combined with our desire for democratized architectural decisions, will not only increase visibility for community expertise but also foster a more resilient ecosystem for Flutter to continue to thrive.

## **Modern syntax & compiled performance**

Dart continues to evolve as a high-performance language for the client and server. In 2026, we plan to ship [**Primary Constructors**](https://github.com/dart-lang/language/issues/2364) to streamline class declarations and [**Augmentations**](https://github.com/dart-lang/language/issues/4154) to simplify code generation. We will continue to focus on improving `build_runner` as our main code generation tool. We are also improving **Dart/Wasm** compilation for modern browsers and refactoring the analyzer to improve performance for large-scale applications.

## **Bringing developers to Flutter and Dart**

Our recently completed new [Dart and Flutter learning pathway](https://docs.flutter.dev/learn/pathway) provides a streamlined, guided onboarding path for new builders. In 2026, we plan to continue our outreach and community-driven efforts both in-person and across digital platforms like X, YouTube, our blog, and documentation to improve the experience for developers and their LLMs and coding tools when building high quality Dart and Flutter applications.

## **Predictable delivery**

We plan a minimum of **four stable releases** for both Dart and Flutter and 12 beta releases in 2026. We are investing in further test automation to reduce release coordination failures and ensure that every release meets our high standards for stability and performance.

_We maintain an [archive of roadmaps from previous years]([Archive]-Old-Roadmaps.md) in a separate page._
