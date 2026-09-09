---
name: natural-writing
description: Contains well-defined rules for creating natural, accurate, and readable writing. Use whenever authoring longer text, like analysis documents, PR or CL descriptions, or documentation.
---
# Rules for Natural Writing

This document outlines strict rules to avoid common "AI-isms"—stylistic and structural patterns that language models typically fall into. Follow these rules to produce content that is more understandable, and reads as natural, human-authored text.

## 1. Vocabulary & Phrasing Controls

### The "Banned" List

Avoid these words, which are statistically overrepresented in AI text. Use simpler, more direct alternatives.

* **Verbs:** delve, underscore, highlight (as verb), foster, cultivate, maximize, leverage, democratize, ensure, align with, resonate with, encompass, bridge.
* **Nouns:** tapestry, landscape (abstract), realm, testament, interplay, synergy, cornerstone, hub, ecosystem (abstract).
* **Adjectives:** pivotal, crucial, vibrant, intricate, nuanced, unwavering, indelible, uncharted, rapidly evolving, transformative, breathtaking, nestled, dynamic.

### Avoid "Copula" Substitutions

Do not replace simple "is/are" verbs with flowery equivalents.

* **Bad:** "The library *serves as* a center for learning."
* **Bad:** "The statue *stands as* a monument to..."
* **Good:** "The library *is* a center for learning."
* **Good:** "The statue *is* a monument to..."

### Eliminate "Elegant Variation"

Do not use synonyms just to avoid repeating a subject's name (e.g., "the eponymous character," "the titular protagonist," "the celebrated author"). It is acceptable to repeat the name or use pronouns naturally.

### Banned Temporal Words in Code & Comments

Do not use relative temporal terms in code, variable names, function names, or comments. These words lose their meaning as the codebase evolves over time.
* **Banned Words**: now, currently, existing behavior, previous behavior, old, new, modern.
* **Bad**: `// This function now uses the config parser instead of hardcoding.`
* **Good**: `// Resolves paths via [ConfigParser.loadConfig] to support custom config locations.`

## 2. Content & Tone

### No "Puffery" or Forced Significance

Do not inflate the importance of a topic with vague praise. If a subject is important, the facts should demonstrate it without help.

* **Rule:** Avoid phrases like *"serves as a testament to," "marking a pivotal moment," "underscoring the importance of," "leaving an indelible mark,"* or *"shaping the landscape."*
* **Bad:** "The founding of the institute marked a pivotal moment in the evolution of regional statistics, representing a significant shift toward independence."
* **Good:** "The institute was founded in 1989 to collect regional statistics."

### No Superficial Analysis

Avoid attaching "dangling" present-participle phrases that offer vague commentary.

* **Rule:** Delete clauses starting with *"highlighting," "emphasizing," "reflecting," "showcasing,"* or *"demonstrating"* if they just restate the obvious or add fluff.
* **Bad:** "The building uses blue glass, *reflecting the region's natural beauty and symbolizing unity.*"
* **Good:** "The building uses blue glass."

### Avoid Promotional Language

Maintain a neutral tone. Avoid "advertisement" words.

* **Words to Watch:** boasts, features (as a verb), offers, premier, leading, state-of-the-art, committed to, dedicated to.
* **Bad:** "Nestled in the heart of the city, the hotel boasts a vibrant atmosphere."
* **Good:** "The hotel is located in the city center."

### No "Challenges and Future Outlook" Formula

LLMs often end articles with a generic "Despite challenges... remains important" conclusion.

* **Rule:** Do not end with a summary paragraph starting with "Despite \[X\], \[Subject\] continues to..." or speculating on the future. End with the last fact.
* **Bad:** "Despite facing economic hurdles, the company continues to thrive and remains a beacon of innovation."

### No "Title as Proper Noun" Leads

Do not treat a descriptive article title (like a list or broad topic) as a proper noun in the first sentence.

* **Bad:** "*The List of songs about Mexico* is a curated compilation..."
* **Good:** "This list contains songs about Mexico..."

### No Generic "See Also" Links

Do not populate "See Also" sections with broad, generic terms.

* **Rule:** Links must be directly relevant and specific to the subject.
* **Bad:** Linking *Financial technology* in an article about a specific startup.
* **Good:** Linking a competitor or specific related technology.

### Attribution Precision

Do not use vague "weasel words."

* **Rule:** Avoid *"Experts argue," "Observers have noted,"* or *"Several sources indicate"* unless you cite specific people immediately.
* **Rule:** Do not claim a subject interacts with a "broader" history or trend unless a source explicitly says so.

## 3. Sentence Structure

### No Negative Parallelism

Avoid sentences that structure a contrast unnecessarily.

* **Bad:** "It is *not only* a painting, *but also* a representation of..."
* **Bad:** "It is *not* just about X; *it is* about Y."
* **Good:** "It is a painting that represents..."

### No "Rule of Three"

Avoid listing exactly three adjectives or three noun phrases to sound "comprehensive."

* **Bad:** "The event brings together *marketers, engineers, and designers*." (Unless those specific three groups are the *only* ones).
* **Bad:** "It is *bold, innovative, and unique*."

### No False Ranges

Do not use "from X to Y" unless X and Y are endpoints of a logical scale (like time or size).

* **Bad:** "The book covers everything *from* biology *to* space travel." (These are just two random topics, not a range).
* **Good:** "The book covers topics including biology and space travel."

## 4. Structure & Formatting

### Headers

* **Rule:** Use Sentence case for headers (e.g., "Early life," not "Early Life").
* **Rule:** Do not use "Title Case" in headers.

### Formatting Avoidance

* **No Inline-Header Lists:** Do not use the format: `* **Header:** Description...`. Use prose or simple lists.
* **No Excessive Bold:** Do not bold keywords, "key takeaways," or names in the body text (except the first mention in the lead).
* **No Symbols/Emojis:** Do not use emojis (🚀, 🧠) or unusual bullets (`#`, `-`) in lists. Use standard bullets (`*`).
* **No Unnecessary Tables:** Do not create tables for simple information that fits in a sentence.
* **Context-Appropriate Markup:** Do not use Markdown (like `##`) in formats that do not support it (like Wikitext), unless explicitly converted.

### Punctuation

* **Quotes:** Use straight quotes (`"`, `'`) and straight apostrophes (`'`). Do not use curly/smart quotes (`“`, `’`).
* **Em Dashes:** Use em dashes sparingly. LLMs overuse them for emphasis. Use commas or parentheses instead.

## 5. Citations & Integrity

### No Hallucinations

* **Rule:** Never generate a citation unless you are looking at the source.
* **Rule:** Do not invent URLs or DOIs.
* **Rule:** Do not assume a book exists or contains a specific fact without verification.

## 6. Communication (Chat Context)

* **No "Collaborative" Filler:** Avoid starting responses with *"Certainly\!", "Here is the information,"* or *"I hope this helps."* Just provide the content.
* **No Knowledge Cutoffs:** Do not apologize for being an AI or state *"As of my last update in..."* unless relevant to a specific time-sensitive fact.
* **No Subject Lines:** Do not preface a response with `Subject: ...`
* **Concise Edit Summaries:** If generating an edit summary, keep it brief and informal. Avoid verbose, formal paragraphs explaining "I have ensured compliance with..."
