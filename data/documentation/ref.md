---

# 🏋️ EXERCISE GROUPS (REFERENCE TABLES)

### 🧱 MAIN LIFTS
| Category | Exercises |
|-----------|------------|
| Squat | Back (High-Bar / Low-Bar), Front |
| Bench | Competition, Close-Grip, Wide-Grip |
| Deadlift | Conventional, Sumo |

---

### ⚙️ SQUAT-FOCUSED VARIANTS
| Compound | Accessories | Isolation |
|-----------|--------------|------------|
| Safety Bar Squat • Box Squat • Pause • Tempo • Goblet • Split / Bulgarian / Lunge (Fwd/Rev) | Step-Up • Leg Press • Hack Squat • Front-Foot-Elevated Split • Walking Lunge • Wall Sit | Leg Extension • Seated / Lying Leg Curl • Standing / Seated Calf Raise |

---

### 🛠️ BENCH-FOCUSED VARIANTS
| Compound | Accessories | Isolation |
|-----------|--------------|------------|
| Close-Grip • Wide-Grip • Spoto • Paused • Incline / Decline (Barbell / Dumbbell) | Dumbbell Floor Press • Machine Chest Press • Push-Ups (Weighted) • Dumbbell Pullover | Cable / Dumbbell Fly • Pec Deck • Triceps Pushdown • Overhead Ext. • Skull Crushers • Dips |

---

### ⚔️ DEADLIFT-FOCUSED VARIANTS
| Compound | Accessories | Isolation |
|-----------|--------------|------------|
| RDL • Deficit • Paused • Rack / Block • Stiff-Leg • Trap Bar • Snatch-Grip | Good Morning • Hip Thrust • Glute Bridge • Back Extension • Reverse Hyper • Cable Pull-Through • Kettlebell Swing | Glute Kickback (Cable) |

---

### 🦍 OVERHEAD / UPPER PRESS
| Compound | Accessories / Isolation |
|-----------|-------------------------|
| Overhead Press (Standing/Seated) • Push Press • Z Press • Arnold Press | Lateral / Front / Rear Raises • Machine Shoulder Press • Reverse Pec Deck |

---

### 🐉 ROWS / PULLS / BACK
| Compound | Accessories |
|-----------|-------------|
| Barbell / Pendlay Row | Dumbbell / Chest-Supported / Cable / T-Bar / Inverted Row / Lat Pulldown (Wide/Close) / Pull-Ups / Chin-Ups / Band-Assisted Pull-Ups |

---

### 🐍 BICEPS / FOREARMS
| Biceps | Forearms |
|--------|-----------|
| Barbell • Dumbbell • Hammer • Preacher • Concentration • Cable Curl | Reverse Curl (EZ Bar) • Wrist Curl • Reverse Wrist Curl |

---

### 🧠 CORE / STABILITY
| Core | Anti-Rotation / Stability |
|------|----------------------------|
| Plank • Side Plank • Ab Wheel • Hanging Leg Raise • Weighted Sit-Up • Cable Crunch | Pallof Press • Dead Bug • Bird Dog |

---

_Total: ≈110 exercises across all groups._

---

# 💬 CODEX HELPER USAGE NOTE

**File:** `/docs/plan.md`  
**Purpose:** Provide full project context to the VS Code ChatGPT / Codex Helper agent.

## How to activate
1. Open VS Code sidebar → ChatGPT panel.  
2. Run:  
   ```
   @ChatGPT open docs/plan.md
   ```  
   or right-click the file → **“Add to chat context.”**
3. The Codex Helper now understands:  
   - The project stack (Flutter + Firebase)  
   - Data models and Firestore structure  
   - Coach prompt rules (NEVER INVENT DATA)  
   - The complete exercise taxonomy

## Best practices
- Keep this file under ~10 k tokens to preserve context budget.  
- When starting a new chat session, re-add this file to context.  
- Use clear prompts, e.g.  
  ```
  @ChatGPT generate ExercisePicker.dart based on plan.md context
  @ChatGPT implement coach Function per docs/plan.md spec
  @ChatGPT scaffold FirestoreService using Session model
  ```
- When the token count grows near 260 k, start a new chat and re-load this file.

---

_This reference section ensures the Codex Helper can autocomplete and code-generate within the same context you and I designed here, Boss._