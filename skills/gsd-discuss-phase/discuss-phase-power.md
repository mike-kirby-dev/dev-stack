<purpose>
Power user mode for discuss-phase. Generates ALL questions upfront into a JSON state file and an HTML companion UI, then waits for the user to answer at their own pace. When the user signals readiness, processes all answers in one pass and generates CONTEXT.md.

**When to use:** Large phases with many gray areas, or when users prefer to answer questions offline / asynchronously rather than interactively in the chat session.
</purpose>

<trigger>
This workflow executes when `--power` flag is present in ARGUMENTS to `/gsd-discuss-phase`.

The caller (discuss-phase.md) has already:
- Validated the phase exists
- Provided init context: `phase_dir`, `padded_phase`, `phase_number`, `phase_name`, `phase_slug`

Begin at **Step 1** immediately.
</trigger>

<step name="analyze">
Run the same gray area identification as standard discuss-phase mode.

1. Load prior context (PROJECT.md, REQUIREMENTS.md, STATE.md, prior CONTEXT.md files)
2. Scout codebase for reusable assets and patterns relevant to this phase
3. Read the phase goal from ROADMAP.md
4. Identify ALL gray areas — specific implementation decisions the user should weigh in on
5. For each gray area, generate 2–4 concrete options with tradeoff descriptions

Group questions by topic into sections (e.g., "Visual Style", "Data Model", "Interactions", "Error Handling"). Each section should have 2–6 questions.

Do NOT ask the user anything at this stage. Capture everything internally, then proceed to generate.
</step>

<step name="generate_json">
Write all questions to:

```
{phase_dir}/{padded_phase}-QUESTIONS.json
```

**JSON structure:**

```json
{
  "phase": "{padded_phase}-{phase_slug}",
  "generated_at": "ISO-8601 timestamp",
  "stats": {
    "total": 0,
    "answered": 0,
    "chat_more": 0,
    "remaining": 0
  },
  "sections": [
    {
      "id": "section-slug",
      "title": "Section Title",
      "questions": [
        {
          "id": "Q-01",
          "title": "Short question title",
          "context": "Codebase info, prior decisions, or constraints relevant to this question",
          "options": [
            {
              "id": "a",
              "label": "Option label",
              "description": "Tradeoff or elaboration for this option"
            },
            {
              "id": "b",
              "label": "Another option",
              "description": "Tradeoff or elaboration"
            },
            {
              "id": "c",
              "label": "Custom",
              "description": ""
            }
          ],
          "answer": null,
          "chat_more": "",
          "status": "unanswered"
        }
      ]
    }
  ]
}
```

**Field rules:**
- `stats.total`: count of all questions across all sections
- `stats.answered`: count where `answer` is not null and not empty string
- `stats.chat_more`: count where `chat_more` has content
- `stats.remaining`: `total - answered`
- `question.id`: sequential across all sections — Q-01, Q-02, Q-03, ...
- `question.context`: concrete codebase or prior-decision annotation (not generic)
- `question.answer`: null until user sets it; once answered, the selected option id or free-text
- `question.status`: "unanswered" | "answered" | "chat-more" (has chat_more but no answer yet)
</step>

<step name="generate_html">
Write a self-contained HTML companion file to:

```
{phase_dir}/{padded_phase}-QUESTIONS.html
```

The file must be a single self-contained HTML file with inline CSS and JavaScript. No external dependencies.

**Layout:**

```
┌─────────────────────────────────────────────────────┐
│  Phase {N}: {phase_name} — Discussion Questions      │
│  ┌──────────────────────────────────────────────┐   │
│  │  12 total  |  3 answered  |  9 remaining     │   │
│  └──────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│  ▼ Visual Style (3 questions)                        │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│   │ Q-01     │ │ Q-02     │ │ Q-03     │            │
│   │ Layout   │ │ Density  │ │ Colors   │            │
│   │ ...      │ │ ...      │ │ ...      │            │
│   └──────────┘ └──────────┘ └──────────┘            │
│  ▼ Data Model (2 questions)                          │
│   ...                                                │
└─────────────────────────────────────────────────────┘
```

**Stats bar:**
- Total questions, answered count, remaining count
- A simple CSS progress bar (green fill = answered / total)

**Section headers:**
- Collapsible via click — show/hide questions in the section
- Show answered count for the section (e.g., "2/4 answered")

**Question cards (3-column grid):**
Each card contains:
- Question ID badge (e.g., "Q-01") and title
- Context annotation (gray italic text)
- Option list: radio buttons with bold label + description text
- Chat more textarea (orange border when content present)
- Card highlighted green when answered

**JavaScript behavior:**
- On radio button select: mark question as answered in page state; update stats bar
- On textarea input: update chat_more content in page state; show orange border if content present
- "Save answers" button at top and bottom: serializes page state back to the JSON file path

**Mobile responsive (REQUIRED — DEVMGMT-341):**

Mike answers questions from his phone as often as his laptop. The HTML MUST
include the viewport meta tag AND a `@media (max-width: 768px)` block that
collapses the 3-column grid to single-column and bumps font/touch sizes.
This is NOT optional and NOT cosmetic — it's a load-bearing UX requirement.

Required in `<head>` (alongside the discuss-write-* meta tags from Step 1):

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

Required in the inline `<style>`:

```css
@media (max-width: 768px) {
  body { padding: 16px; font-size: 16px; }
  h1 { font-size: 24px; }
  h2 { font-size: 19px; }
  /* collapse question-card grid to single column */
  .cards, .questions, .grid { grid-template-columns: 1fr !important; }
  /* roomier touch targets */
  .card { padding: 18px; }
  .qtitle { font-size: 17px; }
  .option-label { font-size: 16px; }
  textarea { font-size: 16px; min-height: 80px; }
  button { font-size: 16px; padding: 12px 18px; }
}
```

Adjust the selector names in the `@media` block to whatever the rest of the
inline CSS actually uses (e.g. if the grid container is `.question-grid`,
use that name) — what matters is that the 3-column grid collapses to 1fr
on `max-width: 768px`. Test the generated HTML at iPhone width before
finalising the file.

**Save mechanism (POST-first, DEVMGMT-342):**

The Save button POSTs the updated JSON to a server-side write-back endpoint
first. If the POST fails (no endpoint configured, network down, server
unreachable, auth mismatch), it falls back through the legacy chain:
File System Access API → blob download → clipboard. The localStorage backup
runs on every save regardless.

**Step 1 — emit meta tags at HTML-generation time:**

Before writing the `<body>`, the generator MUST emit these two `<meta>` tags
inside `<head>`:

```html
<meta name="discuss-write-endpoint" content="/api/save/<URL_PATH>">
<meta name="discuss-write-secret"   content="<SECRET>">
```

- `<URL_PATH>` is the `.json` companion of the HTML URL. The HTML lives at
  `{phase_dir}/{padded_phase}-QUESTIONS.html` and the URL path is
  `<ns>/<proj>/<phase_slug>/{padded_phase}-QUESTIONS.html`. The endpoint
  is the same path with `.html` → `.json`.
- `<SECRET>` is read from `/root/komodo/stacks/discuss-static/.env` at
  generation time. Specifically: open the file, find the
  `DISCUSS_WRITE_SECRET=` line, take everything after the `=`, trim
  whitespace, and inject it as the `content` value.
- **Fail gracefully:** if `/root/komodo/stacks/discuss-static/.env` is
  unreadable, doesn't contain `DISCUSS_WRITE_SECRET=`, or the value is
  empty, OMIT both meta tags entirely. The HTML's `saveAnswers()` will
  detect missing tags and skip straight to the fallback chain.
- **NEVER hardcode the secret value in this skill prompt** — read it
  fresh from disk on each generation.

**Step 2 — saveAnswers() JS shape:**

```js
async function saveAnswers() {
  const state = serializeState();            // build the full JSON object
  const json = JSON.stringify(state, null, 2);

  // Backup to localStorage on every save (belt-and-braces).
  try { localStorage.setItem('discuss-state-' + PHASE_KEY, json); } catch (_) {}

  // POST-first save path.
  const ep = document.querySelector('meta[name="discuss-write-endpoint"]')?.content;
  const secret = document.querySelector('meta[name="discuss-write-secret"]')?.content;
  if (ep && secret) {
    try {
      const r = await fetch(ep, {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + secret,
          'Content-Type': 'application/json'
        },
        body: json
      });
      if (r.ok) {
        showToast('Saved to server ✓ — say "finalize" in chat');
        return;
      }
      // 4xx/5xx → fall through to fallback chain
      console.warn('POST save failed:', r.status, await r.text());
    } catch (err) {
      console.warn('POST save errored:', err);
    }
  }

  // Fallback chain (existing behaviour — DO NOT remove):
  //   1. showSaveFilePicker (File System Access API) if available
  //   2. blob URL + download attribute
  //   3. clipboard copy + modal with instructions
  await saveViaFallbackChain(json);
}
```

`saveViaFallbackChain` keeps the pre-DEVMGMT-342 behaviour. The toast
shown by the success branch tells the user the file is already written
server-side — no need to paste back to Claude.

Include clear instructions in the UI for both happy and fallback paths:

```
Click "Save answers". If you see "Saved to server ✓", you're done — say
"finalize" in chat. If the save falls back to a download or clipboard,
follow those instructions instead.
```

**Answered question styling:**
- Card border: `2px solid #22c55e` (green)
- Card background: `#f0fdf4` (light green tint)

**Unanswered question styling:**
- Card border: `1px solid #e2e8f0` (gray)
- Card background: `white`

**Chat more textarea:**
- Placeholder: "Add context, nuance, or clarification for this question..."
- Normal border: `1px solid #e2e8f0`
- Active (has content) border: `2px solid #f97316` (orange)
</step>

<step name="notify_user">
After writing both files, print this message to the user:

```
Questions ready for Phase {N}: {phase_name}

  HTML (open in browser/IDE):   {phase_dir}/{padded_phase}-QUESTIONS.html
  JSON (state file):            {phase_dir}/{padded_phase}-QUESTIONS.json

  {total} questions across {section_count} topics.

Open the HTML file, answer the questions at your own pace, then save.

When ready, tell me:
  "refresh"   — process your answers and update the file
  "finalize"  — generate CONTEXT.md from all answered questions
  "explain Q-05"   — elaborate on a specific question
  "exit power mode" — return to standard one-by-one discussion (answers carry over)
```
</step>

<step name="wait_loop">
Enter wait mode. Claude listens for user commands and handles each:

---

**"refresh"** (or "process answers", "update", "re-read"):

1. Read `{phase_dir}/{padded_phase}-QUESTIONS.json`
2. Recalculate stats: count answered, chat_more, remaining
3. Write updated stats back to the JSON
4. Re-generate the HTML file with the updated state (answered cards highlighted green, progress bar updated)
5. Report to user:

```
Refreshed. Updated state:
  Answered:  {answered} / {total}
  Remaining: {remaining}
  Chat-more: {chat_more}

  {phase_dir}/{padded_phase}-QUESTIONS.html updated.

Answer more questions, then say "refresh" again, or say "finalize" when done.
```

---

**"finalize"** (or "done", "generate context", "write context"):

Proceed to the **finalize** step.

---

**"explain Q-{N}"** (or "more info on Q-{N}", "elaborate Q-{N}"):

1. Find the question by ID in the JSON
2. Provide a detailed explanation: why this decision matters, how it affects the downstream plan, what additional context from the codebase is relevant
3. Return to wait mode

---

**"exit power mode"** (or "switch to interactive"):

1. Read all currently answered questions from JSON
2. Load answers into the internal accumulator as if they were answered interactively
3. Continue with standard `discuss_areas` step from discuss-phase.md for any unanswered questions
4. Generate CONTEXT.md as normal

---

**Any other message:**
Respond helpfully, then remind the user of available commands:
```
(Power mode active — say "refresh", "finalize", "explain Q-N", or "exit power mode")
```
</step>

<step name="finalize">
Process all answered questions from the JSON file and generate CONTEXT.md.

1. Read `{phase_dir}/{padded_phase}-QUESTIONS.json`
2. Filter to questions where `answer` is not null/empty
3. Group decisions by section
4. For each answered question, format as a decision entry:
   - Decision: the selected option label (or custom text if free-form answer)
   - Rationale: the option description, plus `chat_more` content if present
   - Status: "Decided" if fully answered, "Needs clarification" if only chat_more with no option selected

5. Write CONTEXT.md using the standard context template format:
   - `<decisions>` section with all answered questions grouped by section
   - `<deferred_ideas>` section for unanswered questions (carry forward for future discussion)
   - `<specifics>` section for any chat_more content that adds nuance
   - `<code_context>` section with reusable assets found during analysis
   - `<canonical_refs>` section (MANDATORY — paths to relevant specs/docs)

6. If fewer than 50% of questions were answered, warn the user:
```
Warning: Only {answered}/{total} questions answered ({pct}%).
CONTEXT.md generated with available decisions. Unanswered questions listed as deferred.
Consider running /gsd-discuss-phase {N} again to refine before planning.
```

7. Print completion message:
```
CONTEXT.md written: {phase_dir}/{padded_phase}-CONTEXT.md

  Decisions captured: {answered}
  Deferred:          {remaining}

Next step: /gsd-plan-phase {N}
```
</step>

<step name="git_commit_power">
**MANDATORY — commit discuss artifacts immediately after finalize.**

If a spawn dies between finalize and the next stage (plan-phase), uncommitted
QUESTIONS.json and CONTEXT.md are permanently lost. This commit makes answers
durable before any stage transition (WAITING.json) can occur.

Also generate DISCUSSION-LOG.md from the QUESTIONS.json answers (same format
as the interactive mode's `git_commit` step in discuss-phase.md — one table
per section, options presented vs selected, chat_more notes).

**File location:** `${phase_dir}/${padded_phase}-DISCUSSION-LOG.md`

Write the file, then commit all three artifacts:

```bash
gsd-sdk query commit \
  "docs(${padded_phase}): finalize phase discuss answers [power mode]" \
  "${phase_dir}/${padded_phase}-QUESTIONS.json" \
  "${phase_dir}/${padded_phase}-CONTEXT.md" \
  "${phase_dir}/${padded_phase}-DISCUSSION-LOG.md"
```

Confirm: "Committed discuss artifacts — answers are durable."

**Then update STATE.md** (same as interactive mode):

```bash
gsd-sdk query state.record-session \
  --stopped-at "Phase ${PHASE} context gathered (power mode)" \
  --resume-file "${phase_dir}/${padded_phase}-CONTEXT.md"
```

```bash
gsd-sdk query commit "docs(state): record phase ${PHASE} context session" .planning/STATE.md
```
</step>

<success_criteria>
- Questions generated into well-structured JSON covering all identified gray areas
- HTML companion file is self-contained and usable without a server
- Stats bar accurately reflects answered/remaining counts after each refresh
- Answered questions highlighted green in HTML
- CONTEXT.md generated in the same format as standard discuss-phase output
- Unanswered questions preserved as deferred items (not silently dropped)
- `canonical_refs` section always present in CONTEXT.md (MANDATORY)
- QUESTIONS.json + CONTEXT.md + DISCUSSION-LOG.md committed to git after finalize (answers survive spawn death)
- STATE.md updated and committed after finalize
- User knows how to refresh, finalize, explain, or exit power mode
</success_criteria>
