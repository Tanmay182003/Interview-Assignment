# NeverGone Take‑Home Assignment

This repository is a **starter shell** for the NeverGone take‑home assignment.  
You will fork this repo, implement your solution, and submit **a link to your public GitHub repository**.

Please read this README fully before starting.

---

## Goal

Build a **small but complete demo** of NeverGone that runs **locally** and demonstrates:

- A **SwiftUI iOS app**
- A **Supabase backend** (Edge Functions + Postgres)
- **Streaming chat**
- **Auth + persistence**
- **Basic long‑term memory capture**

We care about **engineering judgment, correctness, and clarity** — not polish.

⏱️ **Expected time:** 4–6 hours

---

## What You Will Deliver

- A forked GitHub repo containing:
  - SwiftUI iOS app
  - Supabase backend (Edge Functions + migrations)
- Clear setup instructions
- Clean commit history
- A working local demo

You will submit **only a GitHub repo link**.

---

## Repository Structure (Recommended)

You may adjust this if needed, but keep things understandable.

```
nevergone-takehome/
├── ios/                     # SwiftUI app
│   ├── NeverGoneDemo.xcodeproj
│   └── README.md
├── backend/
│   ├── supabase/
│   │   ├── functions/
│   │   │   ├── chat_stream/
│   │   │   └── summarize_memory/
│   │   └── migrations/
│   └── README.md
└── README.md                # this file
```

---

## Core Requirements

### iOS App (SwiftUI)

Your app must:

- Use **Supabase email/password auth**
- Allow creating and listing chat sessions
- Include a chat screen that:
  - sends user messages
  - renders **streaming assistant responses**
  - allows cancelling an in‑progress stream
- Use a **view‑model driven** architecture
- Use **Swift Concurrency (`async/await`)**

UI can be simple — focus on correctness.

---

### Backend (Supabase)

Implement two **Supabase Edge Functions**:

#### `chat_stream`
- Accepts: `session_id`, `message`
- Persists the user message
- Streams an assistant response (SSE or chunked text)
- Persists the assistant message when complete

#### `summarize_memory`
- Accepts: `session_id`
- Produces a short summary
- Inserts into a `memories` table

You may:
- Stub the LLM
- Fake responses
- Use a real provider (optional)

Architecture matters more than model quality.

---

### Database

You should include migrations for:

- `profiles`
- `chat_sessions`
- `chat_messages`
- `memories`

Requirements:
- Row Level Security (RLS) enabled
- Users may only access their own data
- No hard‑coded user IDs

---

### Streaming Requirements

- Must use **true streaming** (SSE or chunked response)
- Client must render text progressively
- Cancelling the stream must stop backend work

Polling is **not acceptable**.

---

### Tests (Minimal)

- **iOS:** at least one XCTest (e.g., streaming logic via a mocked stream)
- **Backend:** at least one Deno test for a helper or utility

Tests can be small — they must be real.

---

## Running Locally

**Before You Start**: Check the detailed instructions in [backend/README.md](./backend/README.md) and [ios/README.md](./ios/README.md).

> **Note**: I have **hosted a Supabase instance** for this project to make testing easier for you. The iOS app is pre-configured to connect to it, so you don't *need* to run the backend locally unless you want to test the Edge Functions in a local environment.

### Backend (Supabase)

```bash
cd backend
supabase start
supabase db reset
supabase functions serve
```

This will start the local Supabase stack. 
- **Auth**: Handled by Supabase Auth locally. Check emails at `http://localhost:54324`.
- **Environment**: Keys are auto-configured by the CLI.

### iOS App

1. **Configure**: Update `Config.swift` with the URL and Anon Key printed by `supabase start`.
2. **Run**: Open `ios/NeverGoneDemo.xcodeproj`, pick a Simulator, and run (`Cmd + R`).
3. **Sign Up**: Create an account. Check Inbucket for the confirmation code.
4. **Chat**: Send a message like "Hello" to trigger a streaming response.

---

## Tests

### iOS Tests
Located in `ios/NeverGoneDemo/Tests/`.
- `StreamingServiceTests.swift`: Tests the logic for parsing SSE chunks.
- To run: Add these files to a Test Target in Xcode `Cmd + U`.

### Backend Tests
Located in `backend/supabase/functions/_shared/`.
- `utils_test.ts`: Tests utility functions for the Edge Functions.
- To run:
  ```bash
  cd backend/supabase/functions
  deno test --allow-all
  ```

---

## Technical Decisions & Tradeoffs

- **Architecture:** MVVM was chosen for clean separation of view and logic. `StreamingService` handles the complex async stream ensuring the View remains simple.
- **Data Persistence:** Messages are stored locally in the view model for immediate rendering but persisted to Supabase by the Edge Function to ensure truth.
- **Safety**: `verify_jwt` is handled manually in Edge Functions to ensure secure access.
- **Polish**: Dynamic chat titles and confirming passwords added for better UX.

---

## Optional Extensions (Pick Up to 2)

You do **not** need to complete these.

- Prompt versioning
- pgvector memory retrieval (stub embeddings allowed)
- Offline‑safe send queue
- Proper JWT verification (no `--no-verify-jwt`)
- Simple admin UI (SwiftUI or web)

---

## What We’re Evaluating

- Correctness and reliability
- Async and streaming reasoning
- Data modeling and RLS usage
- Code clarity and structure
- Ability to explain tradeoffs

### Red Flags

- No real streaming
- No RLS or broken RLS
- Hard‑coded secrets
- Over‑engineering
- Cannot run locally

---

## Submission

When finished:

1. Push all changes to your fork
2. Ensure the repo is **public**
3. Send us **only the GitHub link**

Do **not** deploy anything publicly.

---

## Notes

- Ask questions if something is unclear
- Make reasonable assumptions and document them
- If you run out of time, explain what you would do next

Good luck — we’re excited to see how you think.
