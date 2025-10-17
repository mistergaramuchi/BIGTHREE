# THE BIG THREE — FLUTTER BATTLEPLAN (v2)
_Last updated: 2025-10-17_

---

## 📝 Action Log
- 2025-10-17 14:45Z — Initialized Codex action log and reviewed existing battleplan to sync context.
- 2025-10-17 14:45Z — Checked repository/global Git user identity; no name/email configured.
- 2025-10-17 14:48Z — Staged all project files and created `Initial commit` on `main` for the new repository baseline.

---

## 🎯 GOAL
Build a functional prototype that lets users:
1. Log **main lift + support exercises** (100+ catalog)
2. Compute **e1RM + volume** for the main lift
3. Get **AI coach feedback** (Arnie / Hafþór / Ronnie) via Cloud Function
4. Persist sessions & show history
5. Guide users with an onboarding flow that captures **goals, experience, constraints**

---

## ⚙️ STACK
- Flutter + Dart
- State management: Riverpod
- Backend: Firebase Auth (anonymous), Firestore, Firebase Functions (Node.js)
- Packages:
  ```
  firebase_core, firebase_auth, cloud_firestore, firebase_functions,
  flutter_riverpod, go_router, freezed, json_serializable,
  uuid, intl, fl_chart
  ```

---

## 🧭 PRODUCT FLOW
### 1️⃣ Onboarding (PROJECT PHYS style)
Guided questions:
- Goal: strength / hypertrophy / powerbuilding / unsure  
- Experience: novice / intermediate / advanced  
- Days per week: 2–6  
- Constraints: injuries / equipment / time  
- Main focus: Squat / Bench / Deadlift

Store → `/users/{uid}/profile`

If info is missing, coaches may ask **one** clarifying question; never invent.

### 2️⃣ Logging
- Choose **Main Lift** (S / B / D)
- Add sets: kg, reps, RIR (optional)
- Add support exercises from 100+ catalog

### 3️⃣ Summary
- Show e1RM (main lift) + total volume
- Button: **Get Coach Feedback**

### 4️⃣ History
- List of sessions → detail view (sets, metrics, feedback)

---

## 🧱 DATA MODELS

### Profile
```json
/users/{uid}/profile {
  "goal": "strength" | "hypertrophy" | "powerbuilding" | "unsure",
  "experience": "novice" | "intermediate" | "advanced",
  "daysPerWeek": 2,
  "constraints": "optional string",
  "focus": "squat" | "bench" | "deadlift"
}
```

### Session
```json
/users/{uid}/sessions/{sessionId} {
  "startedAt": <Timestamp>,
  "endedAt": <Timestamp?>,
  "mode": "arnie" | "hafthor" | "ronnie",
  "mainLift": "squat" | "bench" | "deadlift",
  "mainLiftSets": [{ "kg": 150, "reps": 5, "rir": 1, "ts": 123456 }],
  "supports": [
    { "exerciseId": "barbell_row", "sets": [{ "kg": 80, "reps": 10 }] }
  ],
  "metrics": { "e1rmMain": 175.0, "volumeKg": 12450 },
  "coachFeedback": "text"
}
```

### Exercise Catalog
```json
/catalog/exercises/{exerciseId} {
  "name": "Barbell Back Squat (High-Bar)",
  "type": "compound",
  "modality": "barbell",
  "primary": ["quadriceps","glutes"],
  "secondary": ["core","spinal_erectors"],
  "tags": ["squat","barbell","compound"],
  "isMainLift": true,
  "equipment": ["rack","barbell","plates"],
  "defaultRepRange": [3,8]
}
```

---

## 📐 CALCULATIONS
- **Epley Formula:** `e1RM = kg × (1 + reps / 30)`
- **e1RM (main)** = max Epley across mainLiftSets  
- **Volume** = sum of (kg × reps) for main + supports

---

## 🔒 FIRESTORE SECURITY (Rules)
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /catalog/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 🧠 AI COACH FUNCTION (`functions/coach`)
Callable Cloud Function: `coach`
- **Input:** `{ sessionId, mode }`
- **Auth required**
- Reads `/profile` + `/session`
- Summarizes ONLY existing data
- Sends prompt to OpenAI
- Saves `coachFeedback` → Firestore

### System Prompts
**Arnie**
```
You are Arnie Mode: charming, upbeat, precise.
Output 80–120 words, 2–4 punchy lines, max one witty line.
Include:
1) Technique cue for today’s main lift  
2) Progression suggestion for next session  
3) Accessory suggestion only if supported by logged data  
NEVER INVENT DATA. If critical info is missing, ask ONE short question.
```

**Hafþór (Viking)**
```
You are Hafþór Júlíus Björnsson Mode: stoic, minimal, battle-tested.
Output exactly 3 bullets:
1) Technique cue (main lift)
2) Precise load or set/rep adjustment for next session
3) Optional accessory or recovery advice (if justified)
NEVER INVENT DATA. If key info missing, add ONE short question as 4th bullet.
```

**Ronnie**
```
You are Ronnie Mode: high-energy and actionable.
Output 3 bullets:
– Technique + load/progression guidance  
– 1 hype line  
Keep ≤120 words. NEVER INVENT DATA. If something crucial is missing, end with ONE clarifying question.
```

---

## 📲 SCREENS

| Screen | Description |
|--------|--------------|
| **OnboardingScreen** | Guided setup → writes `/profile` |
| **LogScreen** | Choose main lift, add sets, add support exercises via picker |
| **ExercisePicker** | Search + tag filters (e.g. bench_accessory, posterior_chain) |
| **SummaryScreen** | Shows e1RM (main), volume, supports count + "Get Coach Feedback" button |
| **HistoryScreen** | Lists sessions with metrics → detail view with feedback |

---

## 📅 DEV CHECKLIST
- [ ] `flutterfire configure`
- [ ] Anonymous Auth on startup
- [ ] Onboarding flow → profile
- [ ] SessionDraft provider + addSet actions
- [ ] e1RM + volume calculations
- [ ] Finish Session → Firestore save
- [ ] History list + detail view
- [ ] Functions: `coach` (NEVER INVENT DATA)
- [ ] ExercisePicker (search + tags)
- [ ] Mode selector (Arnie / Hafþór / Ronnie)
- [ ] Polish UI (theme, large buttons, numeric keyboards)

---

## 🗂️ FOLDER STRUCTURE (Recommended)
```
lib/
  main.dart
  app_router.dart
  core/
  data/
    models/
    repos/
  features/
    log/
    summary/
    history/
    onboarding/
    settings/
  services/
  widgets/
assets/
  exercises.json
functions/
  index.ts
docs/
  plan.md
```

---

## 🏋️‍♂️ EXERCISE CATEGORIES (110+)
**Main Lifts:** Back/Front Squat, Bench, Deadlift (variants)  
**Squat Variants:** Safety Bar, Box, Pause, Tempo, Split Squat, Lunge, Leg Press, etc.  
**Bench Variants:** Close/Wide, Incline/Decline, Spoto, DB Press, Push-Up, Fly, Triceps work.  
**Deadlift Variants:** Sumo, Conventional, RDL, Rack/Block, Good Morning, Hip Thrust, etc.  
**Overhead:** OHP, Seated/Arnold/Push/Z-Press, Raises, Rear Delt.  
**Pulls/Rows:** Barbell/Dumbbell/T-Bar/Lat Pulldown/Pull-Ups.  
**Arms:** Curls (all types), Triceps extensions, Forearm curls.  
**Core:** Planks, Rollouts, Hanging Leg Raise, Pallof, Dead Bug, Bird Dog.  
_Total ≈110 entries in `exercises.json`._

---

## 🧭 NOTES
- NEVER INVENT DATA → baked into all prompts.
- Coaches may ask max ONE clarifying question.
- Keep OpenAI key server-side only.
- Start with `gpt-4o-mini` or equivalent model.
- Summarize sessions (<1.5k tokens) before sending to OpenAI.
- Prioritize logging flow + feedback loop before visual polish.
