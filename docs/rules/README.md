# AI rules for Flutter

This directory contains `rules.md`, the default set of AI rules for building
Flutter apps, following best-practices.

## Device & Editor Specific Limits

Different AI coding assistants and tools have varying limits for their "rules" or "custom instructions" files. *Last updated: 2025-12-12.*

| Tool / Product | Rules File / Feature | **Soft / Hard Limit** | Notes & Sources |
| :--- | :--- | :--- | :--- |
| **Aider** | `.aider.conf.yml` / `CONVENTIONS.md` | **No Hard Limit** | Uses `CONVENTIONS.md` for rules. Limited by model context window.<br>**Source:** Aider Docs: Configuration |
| **Antigravity** (Google) | `.agent/rules/*.md` | **12,000 characters** (Hard) | **Source:** User Screenshot (Client-side validation error).<br>No public documentation found specifying this exact client limit yet. |
| **CodeRabbit** | `.coderabbit.yaml` Instructions | **10,000 characters** (Hard) | "Instructions: max 10000 characters."<br>**Source:** CodeRabbit Docs: Configuration |
| **Cursor** | `.cursorrules` | **No Hard Limit** | "There is no limit to the .cursorrules file... generally recommend keeping valid rules."<br>**Source:** Cursor Community Forum |
| **Gemini CLI** | Input Context | **1M+ Tokens** (Context) | Limited by model context (approx 700k words). Practical per-file limits (e.g. 20MB) may apply.<br>**Source:** Google Cloud: Gemini Models |
| **GitHub Copilot** | **Chat** Instructions | **~2 Pages** (Soft) | "We recommend... no longer than 2 pages."<br>**Source:** GitHub Docs: Custom Instructions |
| **GitHub Copilot** | **Code Review** Instructions | **4,000 characters** (Hard) | "Instructions... limited to 4000 characters."<br>**Source:** GitHub Docs: Custom Instructions |
| **Goose** | `.goosehints` / `AGENTS.md` | **No Hard Limit** | Limited by model context. Auto-compacts conversation when full.<br>**Source:** Block Goose: Context Management |
| **JetBrains AI** | `.aiassistant/rules` | **No Hard Limit** | Limited only by the model's context window (prompts are trimmed if too large).<br>**Source:** JetBrains Blog: AI Assistant Update |
| **OpenAI** (ChatGPT) | Custom Instructions | **1,500 characters** (Hard) | "Instructions... 1500 character limit."<br>**Source:** OpenAI Help: Custom Instructions |
