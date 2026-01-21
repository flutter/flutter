# AI rules for Flutter

This directory contains the default set of AI rules for building Flutter apps, following best practices.

*   `rules.md`: The comprehensive master rule set.
*   `rules_10k.md`: A condensed version (<10k chars) for tools with stricter context limits.
*   `rules_4k.md`: A highly concise version (<4k chars) for limited contexts.
*   `rules_1k.md`: An ultra-compact version (<1k chars) for very strict limits.

## Device & Editor Specific Limits

Different AI coding assistants and tools have varying limits for their "rules" or "custom instructions" files. *Last updated: 2026-01-05.*

| Tool / Product | Rules File / Feature | **Soft / Hard Limit** | Notes & Sources |
| Tool / Product | Limit | Source | Notes |
| :--- | :--- | :--- | :--- |
| Aider | No Hard Limit | [Aider Conventions](https://aider.chat/docs/usage/conventions.html) | Limited by model context window. |
| Antigravity (Google) | 12,000 characters (Hard) | Internal Source | Validated via client-side error message. |
| Claude Code | No Hard Limit | [Claude Code Docs](https://support.claude.com/en/articles/11647753-understanding-usage-and-length-limits) | Uses `CLAUDE.md`. Context limited. |
| CodeRabbit | 1,000 characters (Hard) | [CodeRabbit Docs](https://docs.coderabbit.ai/pr-reviews/pre-merge-checks#ui-configuration) | Applied to "Instructions" field. |
| Cursor | No Hard Limit | [Cursor Docs](https://cursor.com/docs/context/rules) | Keep rules under 500 lines |
| Gemini CLI | 1M+ Tokens (Context) | [Vertex AI Docs](https://cloud.google.com/vertex-ai/generative-ai/docs/long-context) | Pactical limit is model context window. |
| GitHub Copilot | ~2 Pages (Soft) / 4k chars | [Copilot Docs](https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot) | Chat: ~2 pages context. Code Review: 4000 char hard limit. |
| Goose | No Hard Limit | [Goose Docs](https://block.github.io/goose/) | Uses "summarize" or "truncate" context strategies. |
| JetBrains AI | No Hard Limit | [JetBrains AI Docs](https://www.jetbrains.com/help/idea/ai-assistant.html) | Context managed by AI Assistant; no fixed file size limit. |
| OpenAI (ChatGPT) | 1,500 characters | [OpenAI Help](https://help.openai.com/en/articles/8096356-chatgpt-custom-instructions) | Is there a character limit for custom instructions? |
