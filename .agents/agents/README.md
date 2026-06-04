# Flutter Repository Agents

This directory (`.agents/agents`) hosts autonomous agent configurations tailored for contributors across the Flutter repository.

## Overview and Philosophy

* **Persona and Team-Based Collections:** Long term, our goal is to maintain curated, persona- or team-based collections of skills and agent configurations (such as the `android-agent`).
* **Personal Onboarding Agents (`reidbaker-agent`):** Personal agent setups like the `reidbaker-agent` are included primarily to help contributors experience successful end-to-end agent workflows and onboard easily. Once we hit a critical mass of personalized configurations, the intention is to deprecate and remove personal agents from this central repository. Contributors who wish to publish and share highly individualized personal agents can then host them in their own individual GitHub repositories.

## Contributing and Maintenance

When adding new agents or skills to this directory, follow these strict guidelines:

1. **CODEOWNERS:** Just like standalone skills, every agent directory must be assigned a clear owner or team in the repository's root `CODEOWNERS` file.
2. **Validation:** Any contributor-managed local skills authored specifically for an agent (i.e., local `.agents/agents/<agent_name>/skills/` files, **not** third-party dependencies installed via `npx`) must be registered in the repository's skill validation test suite (`dev/tools/test/validate_skills_test.dart`).
