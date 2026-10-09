# Loom Script — FDE Inspection Tracker (5 min)

A 5-minute Loom with face cam and live screen demo, written for an FDE hiring panel. It shows requirements discovery, end-to-end shipping, security and production rigor, and AI-leveraged engineering. The talk track runs about 650 words, about 130 words a minute.

A narrated explainer version of the same story is in this folder: [FDE-Inspection-Tracker-Explainer.mp4](FDE-Inspection-Tracker-Explainer.mp4) (4:58, 1080p).

## Before you record

Open these 6 browser tabs in this order, so each segment is one tab switch away.

| Tab | URL or location | Used in |
| --- | --- | --- |
| 1 | [Facility search portal](https://orgfarm-24624b149c-dev-ed.develop.my.site.com/inspections) (incognito window) | Live demo |
| 2 | [National Insights](https://orgfarm-24624b149c-dev-ed.develop.my.site.com/inspections/insights) (same incognito window) | Live demo |
| 3 | Salesforce org → Inspection Tracker app → one facility with a Scheduled inspection | Under the hood |
| 4 | [docs/Project-Documentation.md](../docs/Project-Documentation.md), scrolled to “Decisions made” | Discovery |
| 5 | [docs/Solution-Architecture.md](../docs/Solution-Architecture.md), scrolled to the system landscape diagram | Architecture |
| 6 | [GitHub repository](https://github.com/psiforce/inspection-tracker) | Rigor and close |

- [ ] **Check the facility search map.** In an automated screenshot the map area was grey, with no markers. If it's still blank in a real browser, skip pointing at it and say “results list and filters” instead.
- [ ] **Pick a demo inspection.** In tab 3, find one Scheduled inspection to mark Passed live. Note its facility name.
- [ ] **Reset after a dry run.** If you rehearse the Passed step, run `sf apex run --file scripts/apex/seedData.apex` to restore the demo data.
- [ ] **Loom settings:** Screen + Camera, camera bubble bottom-left, 1080p, browser zoom 110% so text is readable.
- [ ] **Close distractions:** notifications off, bookmarks bar hidden, no personal tabs visible.

## Run of show

The live demo and under-the-hood segments take 1:45 of the 5 minutes; they carry the proof that the work is real.

| # | Segment | Time | Length |
| --- | --- | --- | --- |
| 1 | Hook | 0:00–0:20 | 20 s |
| 2 | Customer problem | 0:20–0:45 | 25 s |
| 3 | Discovery and planning | 0:45–1:30 | 45 s |
| 4 | **Live demo: portal** | 1:30–2:30 | 60 s |
| 5 | **Under the hood** | 2:30–3:15 | 45 s |
| 6 | Production rigor | 3:15–3:55 | 40 s |
| 7 | How I used AI | 3:55–4:35 | 40 s |
| 8 | Close | 4:35–5:00 | 25 s |

## Full script

Each segment lists what's on screen, what to click, and the words to say. The words are a guide; say them in your own voice.

### 1. Hook — 0:00 to 0:20

**Show:** face cam large (Loom “camera only” or a big bubble) over tab 1.

**Say:** “Hi, I'm Punit. In the next five minutes I'll walk you through a project I built as a Forward Deployed Engineer exercise. It's a Salesforce app, with a public website, that tracks yearly inspections of medical facilities across the US. I'll show how I scope with a customer, ship end to end, build for production, and use AI without giving up judgment.”

### 2. The customer problem — 0:20 to 0:45

**Show:** tab 1, the portal home page. Shrink the camera bubble.

**Say:** “The problem: every licensed medical facility has to be inspected once a year. Regulators need to schedule and assign those inspections. And the public needs a simple way to check whether a facility passed. The request I started from was one paragraph: build it in Salesforce, with a public portal and a US map.”

### 3. Discovery and planning — 0:45 to 1:30

**Show:** tab 4, the “Decisions made” table. Scroll slowly through it.

**Say:** “I didn't start with code. I started with discovery. In planning mode, I turned that paragraph into fourteen decisions: who can access the portal, how the map works, the data model, the status lifecycle, automation, and how inspectors get assigned. Each one came with a recommendation and a trade-off, the way I'd run a scoping call.

Then I reviewed the plan and sent it back twice, to add architecture diagrams and a solution architecture document. Changing a plan costs minutes. Changing a built system costs days.”

### 4. Live demo: the public portal — 1:30 to 2:30

**Do, in tab 1:**
1. Type **Austin** in the search box. Point at the result and its status pill.
2. Clear it. Set **Inspection status = Overdue**. Point at the count changing.
3. Click a facility. Show the detail panel and its inspection history.

**Say:** “This is live, with no login. Anyone can search by name, city or ZIP, and filter by state, status and type. Click a facility and you see its latest result and full inspection history.”

**Do, in tab 2:** scroll from the key findings to the state map. Click **Wyoming**; it opens search filtered to Wyoming.

**Say:** “When the customer asked for dashboards, I hit a platform limit: Salesforce dashboards can't be shown to logged-out users. So I proposed four dashboards, got sign-off, and built them as custom components. The page even writes its own findings. In this demo data, the fail rate rose from 9.2 to 16.8 percent this year, and infection control is the most-cited problem.”

### 5. Under the hood — 2:30 to 3:15

**Show:** tab 5, the system landscape diagram, for 10 seconds. Then tab 3.

**Do, in tab 3:** open the Scheduled inspection you picked. Set **Status = Passed** and save. Go back to the facility and show the new inspection scheduled a year out, already assigned.

**Say:** “Between the users and the data sit two read-only APIs and one trigger. Watch: I mark this inspection Passed. The trigger stamps the completed date, updates the facility's status, and schedules next year's inspection, assigned to the inspector for that state. A failure would schedule a re-inspection in 30 days.

Because the portal is public, security was designed in: a guest sharing rule, a field-limited permission set, user-mode queries, and APIs that never return inspector names or internal notes. I proved it by calling the live API as a guest.”

### 6. Production rigor — 3:15 to 3:55

**Show:** tab 6, the GitHub repo. Open `force-app/main/default/classes` and point at the test classes.

**Say:** “Shipping meant iterating against the real platform. The first deploy hit thirteen errors; the third hit none. Tests went from four failing to zero, and I root-caused each one. One only failed inside tests, so I wrote a temporary diagnostic test to find the exact field. Today it's 41 passing tests at 94 percent coverage, with color-blind-safe charts and screen-reader tables.”

### 7. How I used AI — 3:55 to 4:35

**Show:** face cam larger again, over the repo's commit history.

**Say:** “Claude Code wrote most of this code. But I owned the decisions. I set the requirements, reviewed and redirected the plan, approved the irreversible steps, like enabling Digital Experiences and making the repo public, and I insisted on verification. AI made me faster. Engineering judgment is what made it production grade.”

### 8. Close — 4:35 to 5:00

**Show:** face cam large. End on tab 1.

**Say:** “That's what I bring as a Forward Deployed Engineer: understand the customer's real problem, design the solution with them, ship something that works, and make it safe to put in front of the public. The live portal and the code are linked below. Thanks for watching.”

## Delivery tips for an FDE panel

- **Lead with the customer, not the tech.** Panels listen for problem framing first. Keep segment 2 crisp.
- **Say “I decided”.** Every time you mention Claude, follow it with what you decided, reviewed or verified.
- **Show one live action.** Marking the inspection Passed and watching the follow-up appear is the most convincing 20 seconds in the video. Rehearse it once.
- **Name trade-offs out loud.** “Dashboards can't be shown to guests, so I built custom components” shows judgment better than a feature list.
- **Keep numbers few and exact:** 14 decisions, 13 → 0 errors, 41 tests, 94% coverage.
- **Pace:** about 130 words a minute. If you run long, cut the Wyoming click in segment 4 first.
- **Loom description:** paste the portal and GitHub links, plus one line: “Built with Claude Code; requirements, design decisions and verification are mine.”
