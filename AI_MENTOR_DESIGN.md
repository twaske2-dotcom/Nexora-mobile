# Nexora — AI Mentor & Real-Time Interview Engine
### Design & Architecture Document
*Author: Tejas Sunil Waske · Version 1.0 · Sept 2026*

---

## 1. Goal

Add an AI-powered "training + assessment" module to Nexora that:

1. **Teaches** both freshers and experienced users, with heavy focus on **communication skills** and **technical skills**.
2. **Guides** users on *which* skills to prioritise (because most students don't know where to focus).
3. Runs **round-wise, real-time exams** across **3 difficulty stages**:
   - **Stage 1 — Startup level** (basic questions, new/early-stage companies)
   - **Stage 2 — Medium MNC level** (moderate difficulty)
   - **Stage 3 — Top-tier level** (Google, Microsoft, Amazon, JP Morgan, Adobe style)
4. Three rounds per attempt:
   - **Round 1 — Aptitude** (across the 3 stages)
   - **Round 2 — Technical** (programming languages, DSA, databases, core CS)
   - **Round 3 — AI Interview** (video call; observes confidence, communication, body language; reads resume and asks resume-based questions)
5. All questions are **generated in real time** (live via Gemini), not from a fixed static bank.

---

## 2. Honest feasibility summary

| Feature | Feasible? | How | Difficulty |
|---|---|---|---|
| AI Mentor (teach communication + tech) | ✅ Yes | Gemini chat/lessons | Easy |
| Personalised "what skills to focus on" | ✅ Yes | Gemini reads resume + goal | Easy |
| Round 1 Aptitude — 3 stages, real-time | ✅ Yes | Gemini generates MCQs live | Easy |
| Round 2 Technical (concept/MCQ) — 3 stages | ✅ Yes | Gemini generates live | Easy |
| Round 2 — actual DSA *coding* with auto-judge | ⚠️ Partial | Needs a code-runner (Judge0 API) | Medium |
| Round 3 — resume-based Q + answer scoring | ✅ Yes | Speech→text + Gemini | Medium |
| Round 3 — communication/fluency scoring | ✅ Yes (approx) | Transcript + Gemini rubric | Medium |
| Round 3 — video "confidence / posture / body language" | ⚠️ Hard & approximate | Computer vision (face/eye/pose) | Hard |
| Real "AI asks live on a video call & reacts" | ⚠️ Hard | TTS + streaming + turn-taking | Hard |

**Bottom line:** ~80% of what you described is very buildable right now with Gemini (which Nexora already uses). The genuinely hard, less-reliable part is the *video body-language analysis* in Round 3. That is real ML/computer-vision territory and its "confidence score" is only *indicative*, never accurate like a human. We build it in phases: text/voice interview first (works great), then layer basic video signals, and be honest to the user that body-language scores are approximate feedback, not a verdict.

---

## 3. High-level architecture

```
Flutter app  ──HTTPS──►  Spring Boot backend (Render)  ──►  Gemini API (question gen, scoring)
   │                          │
   │                          ├──►  Postgres (attempts, scores, question logs, roadmaps)
   │                          ├──►  Judge0 API      (optional: run/verify DSA code)   [Phase 3]
   │                          └──►  Speech-to-Text   (transcribe interview answers)     [Phase 4]
   │
   └── on-device: camera + mic capture, optional MediaPipe (face/eye/pose signals)     [Phase 5]
```

Design principle (matches Nexora's existing rule): **everything real-time**. Questions are generated fresh per attempt via Gemini and only *logged* afterward (so no two attempts feel identical, and we never ship a stale static bank). Scores are computed live.

---

## 4. The 3 difficulty stages (single source of truth)

We define each stage once, and pass it into every Gemini prompt so difficulty stays consistent across rounds.

- **Stage 1 · "Startup"** — fundamentals, single-concept questions, straightforward aptitude, basic language/DSA (arrays, strings, simple SQL). Goal: confidence + basics.
- **Stage 2 · "MNC (mid)"** — multi-step reasoning, moderate DSA (trees, hashing, two-pointer), normalization & joins in DB, time-complexity awareness.
- **Stage 3 · "Top-tier"** — Google/Microsoft/Amazon/JP Morgan/Adobe style: tricky aptitude, hard DSA (DP, graphs, design), deep DB (indexing, transactions, isolation), system-design lite, follow-up probing.

Backend keeps this as an enum `DifficultyStage { STARTUP, MNC, TOPTIER }` and a text descriptor block injected into prompts.

---

## 5. Feature modules

### 5.1 AI Mentor (teaching + skill roadmap)
- **Chat-based lessons** on communication (email writing, HR answers, "tell me about yourself", group discussion, spoken fluency drills) and technical topics.
- **Skill roadmap generator**: reads the user's latest resume + target role/company + experience level → returns a prioritised list: *"Focus on these 5 skills first, in this order, because…"*. Reuses Nexora's existing resume parsing.
- Output is structured (topic, why it matters, a mini action plan, practice prompt), so the UI can render cards, not a wall of text.

### 5.2 Round 1 — Aptitude (3 stages)
- Categories: quantitative, logical reasoning, verbal, data interpretation.
- Gemini returns a batch of MCQs as strict JSON (question, 4 options, correctIndex, explanation) for the chosen stage.
- Timer per question, auto-submit, instant explanation after submit, final score + weak-area summary.

### 5.3 Round 2 — Technical (3 stages)
- Sub-areas: chosen language(s), DSA, databases (SQL + concepts), core CS (OS/OOP/networks).
- Two question types:
  - **Conceptual / MCQ / short-answer** → Gemini generates + Gemini grades short answers against a rubric.
  - **Coding (DSA)** → prompt + starter signature; **Phase 3** adds Judge0 to actually run test cases. Until then, Gemini does a "read-and-review" evaluation of pasted code (approximate).

### 5.4 Round 3 — AI Interview
- **Flow:** app shows AI interviewer → asks a question (text + optional TTS voice) → user answers by **speaking** → speech-to-text → Gemini evaluates.
- **Resume-aware:** interviewer pulls the user's parsed resume and asks personalised questions ("You built Nexora — how did you handle the Render cold start?").
- **Scoring rubric (Gemini):** technical correctness, communication clarity, structure (STAR), confidence *language cues* (filler words, hedging), relevance.
- **Video layer (phased, honest):** camera on; basic signals via on-device ML — face present / looking at camera %, speaking pace, long pauses. These become *indicative* confidence/engagement hints. We clearly label them "approximate feedback," never a hard judgement. Deep posture/emotion analysis is a research-grade stretch goal, not a v1 promise.

### 5.4.1 Two-way conversational HR (talks like a real person)
The interviewer is not a one-way question machine — it behaves like a real HR on a video call:
- **Greetings & small talk:** if the student says "Good morning" / "Hi ma'am", the HR replies naturally ("Good morning, Tejas! Lovely to meet you — shall we begin?") before moving on.
- **Student can interrupt / ask:** mid-interview the student can ask a question ("Can you repeat that?", "Should I explain the architecture or the outcome?") and the HR answers it, then continues — real back-and-forth turn-taking, not a fixed script.
- **How:** every spoken turn (student STT text) is appended to the running conversation and sent to Gemini with an *interviewer persona* system prompt. Gemini decides whether to (a) respond to small talk / a question, (b) ask the next resume-based question, or (c) give a gentle follow-up probe. It returns `{"say":"...","expectingAnswer":true|false,"done":false}`; the app speaks `say` via TTS, then listens again.
- **Persona prompt (added):** "You are Nexa, a warm but professional AI interviewer for Nexora. Respond to greetings and questions naturally and briefly, keep the candidate at ease, then steer back to the interview. Never break character." 

### 5.4.2 Voice (female "ma'am" voice, selectable)
The HR speaks in a natural female Indian-English voice, and the student picks the voice before starting:
- **Voice selector UI** on the interview setup screen: a dropdown of named female voices with a ▶ preview button for each (tap to hear a one-line sample).
- **Voice sources (in priority of realism):**
  1. **Google Cloud TTS** en-IN female neural voices — `en-IN-Neural2-A`, `en-IN-Wavenet-A`, `en-IN-Chirp3-HD-*` (very natural; small per-char cost).
  2. **flutter_tts** on-device voices — free, offline, but robotic; good fallback.
  3. **ElevenLabs / Gemini TTS named voices** — most human-like (paid) for a premium tier.
- Backend returns a `ttsUrl` (audio) or the app synthesizes on-device, based on the selected voice id. Voice choice is stored per user in `shared_preferences`.

---

## 6. Data model (new DB entities)

All new tables are **additive** — they add nullable columns/new tables only, so Hibernate `ddl-auto: update` applies them without touching existing data. Nothing here changes the current jobs/resume/user schema.

**`mentor_attempt`** — one row per exam attempt (a full 3-round sitting, or a single round).
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | BIGINT FK → users | who attempted |
| round | VARCHAR | APTITUDE / TECHNICAL / INTERVIEW |
| stage | VARCHAR | STARTUP / MNC / TOPTIER |
| started_at | TIMESTAMP | |
| finished_at | TIMESTAMP | null while in progress |
| total_score | INT | 0–100, computed live |
| status | VARCHAR | IN_PROGRESS / DONE / ABANDONED |

**`mentor_question_log`** — every question actually served, logged *after* it was generated (audit + review, never a reusable bank).
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| attempt_id | BIGINT FK → mentor_attempt | |
| question_text | TEXT | |
| options_json | TEXT | null for open/coding Qs |
| correct_answer | TEXT | index or model answer |
| user_answer | TEXT | what the user gave |
| is_correct | BOOLEAN | null for graded-by-rubric |
| score | INT | per-question, for rubric grading |
| feedback | TEXT | Gemini's explanation |

**`mentor_roadmap`** — the personalised skill plan, so it survives across sessions.
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | BIGINT FK → users | |
| target_role | VARCHAR | e.g. "Backend Developer" |
| target_company | VARCHAR | nullable |
| plan_json | TEXT | ordered skills + why + action plan |
| created_at | TIMESTAMP | |

**`interview_session`** — Round 3 specifics (transcript + rubric breakdown).
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| attempt_id | BIGINT FK → mentor_attempt | |
| transcript_json | TEXT | Q/A turn list |
| rubric_json | TEXT | per-dimension scores |
| video_signals_json | TEXT | nullable, approx signals |

Suggested enums: `Round { APTITUDE, TECHNICAL, INTERVIEW }`, `DifficultyStage { STARTUP, MNC, TOPTIER }`, `AttemptStatus { IN_PROGRESS, DONE, ABANDONED }`.

---

## 7. REST API endpoints (new)

All under `/api/mentor`, all JWT-protected (same `Authorization: Bearer` header the app already sends). Questions are generated live per call.

**Mentor / roadmap**
```
POST /api/mentor/roadmap
  body: { targetRole, targetCompany?, experienceLevel }
  → reads latest resume, returns ordered skill plan (JSON cards)

POST /api/mentor/chat
  body: { message, topic? }   // topic = "communication" | "technical"
  → Gemini lesson/answer, structured
```

**Round 1 — Aptitude**
```
POST /api/mentor/aptitude/start
  body: { stage }             // STARTUP | MNC | TOPTIER
  → { attemptId, questions[] } // batch of MCQs (strict JSON)

POST /api/mentor/aptitude/submit
  body: { attemptId, answers[] }
  → { totalScore, perQuestion[], weakAreas[] }
```

**Round 2 — Technical**
```
POST /api/mentor/technical/start
  body: { stage, areas[] }    // e.g. ["dsa","databases","java"]
  → { attemptId, questions[] } // MCQ + short-answer + coding prompts

POST /api/mentor/technical/submit
  body: { attemptId, answers[] }
  → { totalScore, perQuestion[], feedback[] }
  // coding: Phase 3 runs Judge0; until then Gemini reviews pasted code
```

**Round 3 — AI Interview**
```
POST /api/mentor/interview/start
  body: { stage }
  → { sessionId, firstQuestion, ttsUrl? }  // resume-aware first Q

POST /api/mentor/interview/answer
  body: { sessionId, transcript }          // STT text of spoken answer
  → { nextQuestion?, done?, ttsUrl? }      // follow-up or end

POST /api/mentor/interview/finish
  body: { sessionId, videoSignals? }       // optional on-device signals
  → { rubric{}, overallScore, strengths[], improvements[] }
```

**History**
```
GET /api/mentor/attempts        → past attempts (score, round, stage, date)
GET /api/mentor/attempts/{id}   → full review (questions + feedback)
```

---

## 8. Frontend screens & flow (Flutter)

New entry point on the dashboard tools-grid: **"AI Mentor"** tile → `MentorHomeScreen`.

```
MentorHomeScreen
 ├─ "My skill roadmap"      → RoadmapScreen        (POST /roadmap, card list)
 ├─ "Learn"  (chat)         → MentorChatScreen     (comms + technical lessons)
 └─ "Practice / Exam"       → StageSelectScreen
        └─ pick Stage (Startup / MNC / Top-tier)
             └─ RoundSelectScreen
                  ├─ Round 1 Aptitude   → QuizScreen   (timer, MCQ, instant explain)
                  ├─ Round 2 Technical  → QuizScreen + CodeAnswerScreen
                  └─ Round 3 Interview  → InterviewScreen (camera + mic + TTS)
        └─ after any round → ResultScreen (score donut, weak areas, review)

MentorHistoryScreen  → past attempts (reuse History pattern)
```

Reusable widgets from the existing app: `AppBackground`, the donut `CustomPainter` from `match_detail_screen.dart` (score visual), the gradient button style, the dark theme colours (`0xFF0D0D14`, `0xFF7B5CF0`).

**InterviewScreen** specifics:
- **Interviewer face:** a real illustrated portrait bundled as a Flutter asset (`assets/hr_nexa.png`) shown full-frame as the "video feed" — looks like a real person on a call, not a cartoon. (Swappable per persona later.)
- **Voice selector** at the top: named female voices with ▶ preview; selection persisted.
- **Two-way conversation:** student greets/answers by voice → STT → Gemini persona replies (spoken via TTS) → listens again. The HR responds to greetings and mid-interview questions, then continues.
- `camera` plugin for the live self preview, `speech_to_text` for the mic → text, `flutter_tts` (or a backend `ttsUrl`) for the interviewer's voice.
- One turn at a time, a "Speaking… / Tap when done" control, a subtle "recording" indicator.
- Video signals (Phase 5) computed on-device via `google_mlkit_face_detection` — only a face-present % and look-at-camera %, clearly labelled *"approximate feedback."*

---

## 9. Real-time Gemini prompt patterns

One shared **stage descriptor block** is injected into every prompt so difficulty stays consistent. We always ask Gemini to return **strict JSON** and parse defensively (the backend already does this for analysis/cover-letter).

**Stage descriptor (injected):**
```
STARTUP: fundamentals, single-concept, straightforward. Confidence + basics.
MNC:     multi-step reasoning, moderate DSA (trees, hashing), joins/normalization, complexity.
TOPTIER: tricky aptitude, hard DSA (DP, graphs, design), deep DB (indexing, txn isolation),
         system-design lite, probing follow-ups. Google/Microsoft/Amazon/JPMC/Adobe style.
```

**Round 1 — Aptitude (generate):**
```
You are an aptitude exam setter. Difficulty = {STAGE_DESCRIPTOR}.
Generate {N} fresh multiple-choice questions across quantitative, logical,
verbal, data-interpretation. Return ONLY JSON:
{"questions":[{"q":"...","options":["","","",""],"correctIndex":0,"explanation":"..."}]}
No preamble, no markdown fences.
```

**Round 2 — Technical (generate):**
```
You are a technical interviewer. Difficulty = {STAGE_DESCRIPTOR}.
Areas = {AREAS}. Mix MCQ, short-answer, and one coding prompt.
For coding include a function signature and 2 sample cases.
Return ONLY JSON: {"questions":[{"type":"mcq|short|code","q":"...",
"options":[...]?, "correctIndex":?, "signature":"?", "samples":[...]?}]}
```

**Round 2 — short-answer / code grading:**
```
Grade this answer against the question. Difficulty = {STAGE_DESCRIPTOR}.
Return ONLY JSON: {"score":0-100,"correct":true|false,"feedback":"..."}
Question: {Q}   Answer: {USER_ANSWER}
```

**Round 3 — Interview (next question, resume-aware):**
```
You are conducting a {STAGE} mock interview. Here is the candidate's resume:
{RESUME_TEXT}. Conversation so far: {HISTORY}.
Ask ONE next question — resume-based or a natural follow-up to their last answer.
Return ONLY JSON: {"question":"...","done":false}. Set done:true after ~6-8 turns.
```

**Round 3 — final scoring:**
```
Evaluate this interview transcript. Difficulty = {STAGE_DESCRIPTOR}.
Score each dimension 0-100: technicalCorrectness, communicationClarity,
structure(STAR), confidenceLanguageCues, relevance.
Return ONLY JSON: {"dimensions":{...},"overall":0-100,
"strengths":[...],"improvements":[...]}.
Transcript: {TRANSCRIPT}
```

---

## 10. Phased build roadmap

Build in phases so each one ships something working before the hard parts.

**Phase 1 — Mentor + Roadmap (Easy, ~few days)**
Backend `/mentor/roadmap` + `/mentor/chat`; Flutter `MentorHomeScreen`, `RoadmapScreen`, `MentorChatScreen`. Pure Gemini, reuses resume parsing. Ships real value immediately.

**Phase 2 — Round 1 & 2, text-only (Easy–Medium)**
`aptitude/*` and `technical/*` endpoints, `mentor_attempt` + `mentor_question_log` tables, `StageSelectScreen` → `QuizScreen` → `ResultScreen`. Coding questions graded by Gemini review (no runner yet). This delivers the full 3-stage exam experience for two of three rounds.

**Phase 3 — Real code judging (Medium)**
Integrate **Judge0** (self-host or RapidAPI) so DSA answers actually run test cases. Swap the Gemini "review" for a real pass/fail + Gemini explanation on failure.

**Phase 4 — Round 3 text/voice interview (Medium)**
`interview/*` endpoints + `interview_session` table; `InterviewScreen` with `speech_to_text` and TTS. This is a genuinely great mock-interview even with **no video** — resume-aware questions, spoken answers, rubric scoring.

**Phase 5 — Video signals (Hard, honest, optional)**
On-device `google_mlkit_face_detection` for face-present % and look-at-camera %. Label everything *"approximate feedback."* No promise of real emotion/posture verdicts.

---

## 11. Cost, limits & honest caveats

**Gemini quota.** Every question batch, grade, and interview turn is an API call. On the free tier this is fine for one user testing, but a class of students hammering it will hit rate limits. Mitigation: generate a *batch* of questions per round (one call, not one-per-question), cache the roadmap, and keep interview turns to ~6–8.

**Render free tier.** Same cold-start behaviour as the rest of Nexora (~50s wake after idle). The mentor calls are longer-running (Gemini latency), so keep the frontend timeouts generous, and the uptime pinger on `/api/health` still helps.

**Real-time rule still holds.** Questions are generated fresh per attempt and only *logged* after — we never ship a static bank, so no two attempts feel identical. This matches Nexora's standing "everything real-time" rule.

**Coding judge.** Until Phase 3, "coding" scores are Gemini *reading* the code, which is approximate — it can miss edge cases a real runner would catch. Be honest to the user about this in the UI.

**Video body-language (the big honest one).** A phone camera + on-device ML can tell *roughly* whether a face is present and pointed at the screen. It **cannot** reliably measure "confidence," emotion, or "sitting manner" the way a human interviewer does. Any such number is *indicative feedback to practise with*, never an accurate verdict. We label it that way and never gate a score on it. Promising more than this would be dishonest to users.

**Speech-to-text accuracy.** On-device STT varies with accent and mic noise; the transcript Gemini scores may have errors. Show the transcript back to the user so they can see what was captured.

**Privacy.** Camera/mic run **on-device**; we send only the *text transcript* (and optionally a few numeric signals) to the backend — never raw video/audio. State this clearly in the UI before the first interview.

---

## 12. Summary

~80% of the vision — mentor, roadmap, and real-time 3-stage exams for Aptitude and Technical, plus a resume-aware text/voice AI interview — is fully buildable now with the Gemini setup Nexora already has, shipped safely in additive phases. The genuinely hard, approximate part is video body-language analysis, which we build last, label honestly, and never treat as a real verdict. Recommended path: **start with Phase 1 (Mentor + Roadmap)** — highest value, lowest effort — then move down the phases.









