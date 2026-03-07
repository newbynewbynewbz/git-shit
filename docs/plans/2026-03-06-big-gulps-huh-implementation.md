# Big Gulps Huh — Repo Split Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split git-shit and big-gulps-huh into two independent repos. Create the new big-gulps-huh repo with onboarding-first design, enhanced /learn with preloaded course packs, and inlined git hook logic.

**Architecture:** Two fully independent GitHub repos. big-gulps-huh inlines all git hook logic (no cross-repo dependency). /learn uses an engine + course pack model where courses are standalone markdown files discovered at runtime. The onboarding flow adapts teaching depth based on user experience level.

**Tech Stack:** Bash (git hooks, check scripts), Markdown (skills, courses, docs), JSON (settings.local.json, progress tracking), GitHub CLI (repo creation)

---

### Task 1: Create big-gulps-huh repo and directory structure

**Files:**
- Create: `/Users/pecchenino/Desktop/big-gulps-huh/` (local directory)
- Create: GitHub repo `newbynewbynewbz/big-gulps-huh`

**Step 1: Create the GitHub repo**

```bash
gh repo create newbynewbynewbz/big-gulps-huh --public --description "Complete Claude Code collaboration setup — onboarding, skills, hooks, courses. Drop in and go." --clone --license mit
```

Expected: Repo created, cloned to `/Users/pecchenino/Desktop/big-gulps-huh/`

If `--clone` puts it elsewhere, navigate to Desktop:
```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
```

**Step 2: Create the full directory tree**

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
mkdir -p .claude/commands
mkdir -p template/scripts
mkdir -p template/.claude/commands
mkdir -p template/docs/courses/claude-code-basics
mkdir -p template/docs/courses/terminal-basics
mkdir -p template/docs/courses/git-fundamentals
mkdir -p template/.github
```

**Step 3: Verify structure**

```bash
find . -type d | grep -v '.git/' | sort
```

Expected:
```
.
./.claude
./.claude/commands
./template
./template/.claude
./template/.claude/commands
./template/.github
./template/docs
./template/docs/courses
./template/docs/courses/claude-code-basics
./template/docs/courses/git-fundamentals
./template/docs/courses/terminal-basics
./template/scripts
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: create directory structure for big-gulps-huh"
```

---

### Task 2: Write the 3 preloaded course packs

These are the curriculum files that /learn discovers and teaches from. Each follows the course pack format from the design doc.

**Files:**
- Create: `template/docs/courses/claude-code-basics/course.md`
- Create: `template/docs/courses/terminal-basics/course.md`
- Create: `template/docs/courses/git-fundamentals/course.md`

**Step 1: Write Claude Code Basics course**

Create `template/docs/courses/claude-code-basics/course.md`:

```markdown
---
name: Claude Code Basics
description: Learn how Claude Code works — skills, CLAUDE.md, hooks, and how to work with AI effectively
difficulty: beginner
estimated_sessions: 2-3
prerequisites: []
---

# Claude Code Basics

## Module 1: What Is Claude Code?

### Concept: Your AI Pair Programmer
Claude Code is an AI assistant that lives in your terminal. It can read your files, write code, run commands, and help you build things. Think of it as a really smart collaborator who knows a lot about programming but needs YOU to tell it what to build.

**Predict:** When you type a message to Claude Code, what do you think it can see about your project?

**Reveal:** Claude Code can:
- Read any file in your project
- See your git history (what changed and when)
- Run terminal commands
- Read CLAUDE.md for project-specific context
- But it CANNOT see your browser, your email, or anything outside your project folder

**Key insight:** Claude Code is powerful but not magic. It works best when you're specific about what you want.

### Exercise: Your First Interaction
Try these commands and observe what happens:
1. Ask Claude: "What files are in this project?"
2. Ask Claude: "What does CLAUDE.md say?"
3. Ask Claude: "What branch am I on?"

Notice how Claude reads real files and runs real commands — it's not guessing.

## Module 2: Skills (Slash Commands)

### Concept: What Are Skills?
Skills are pre-written instructions that tell Claude HOW to do something specific. Instead of explaining what you want every time, you type a slash command.

**Predict:** What do you think happens when you type `/health`?

**Reveal:** `/health` runs 6 checks on your project in parallel — types, tests, dependencies, TODOs, file sizes, and code stats — then gives you a report card. Without the skill, you'd have to ask Claude to do each of those things separately.

**Think of skills like recipes.** You could describe how to make a sandwich every time, or you could just say "make me a sandwich" and the recipe handles the details.

### Concept: Your Available Skills
| Skill | What It Does | When to Use It |
|-------|-------------|----------------|
| `/health` | Project health report | "Is everything working?" |
| `/preflight` | Pre-push checks | Before pushing code |
| `/code-review` | AI code review | Before making a PR |
| `/learn` | This! Interactive tutor | Anytime you want to learn |
| `/vibes` | Focus & motivation | Start of a session |
| `/retro` | Session retrospective | End of a session |

### Exercise: Try a Skill
Run `/health` right now. Read the output. Then ask Claude: "What does the grade mean?"

## Module 3: CLAUDE.md — The Project Constitution

### Concept: Why CLAUDE.md Matters
CLAUDE.md is a file at the root of your project that Claude reads at the START of every conversation. It tells Claude about YOUR specific project — the tech stack, file structure, coding patterns, and common gotchas.

**Predict:** If two different projects both use TypeScript, would Claude behave the same way in both?

**Reveal:** Without CLAUDE.md, yes — Claude gives generic TypeScript advice. WITH CLAUDE.md, Claude knows that Project A uses React with Zustand state management and Project B uses Vue with Pinia. It writes code that matches YOUR patterns, not generic patterns.

**Analogy:** CLAUDE.md is like onboarding docs for a new hire, except the new hire is an AI that reads really fast and starts with zero institutional knowledge.

### Exercise: Read Your CLAUDE.md
Open CLAUDE.md in your project. Find the TODO sections. Pick ONE and fill it in (Tech Stack is the easiest to start with). Then start a new Claude Code conversation and notice how Claude uses that information.

## Module 4: Hooks — Your Safety Net

### Concept: What Are Hooks?
Hooks are automatic checks that run when Claude does certain things. Some hooks block dangerous actions (like editing .env files). Others warn you about potential issues (like leaving debug statements in code).

**Predict:** Why would you want to BLOCK Claude from editing .env files?

**Reveal:** .env files contain secrets — API keys, database passwords, authentication tokens. If Claude edits them, those secrets appear in your conversation history. If that history is logged or shared, your secrets are exposed. The hook makes it physically impossible for Claude to touch .env files.

### Concept: Hook Types
| Type | What Happens | Example |
|------|-------------|---------|
| **Blocking** | Prevents the action entirely | .env file protection |
| **Warning** | Shows a message but lets it through | "You left a console.log" |
| **Info** | Just shows information | Session greeting with branch name |

### Exercise: See Hooks in Action
Ask Claude to "add a console.log to any file." After it edits the file, watch for the warning message. That's the console sentinel hook doing its job.

## Module 5: Working With Claude Effectively

### Concept: How to Ask for What You Want
Claude works best when you're specific. Compare:
- Vague: "Make the app better" — Claude doesn't know what "better" means to you
- Specific: "Add a loading spinner to the login button while the API call is in progress" — Claude knows exactly what to build

**Predict:** Which request gets better results: "Fix the bug" or "The login form submits twice when I click fast — add debouncing to prevent double submission"?

**Reveal:** The second one, every time. Claude can't see your screen or reproduce your bugs. The more context you give about WHAT is happening and WHAT should happen instead, the better the result.

### Concept: The Workflow Loop
1. **Ask** — tell Claude what you want to build or fix
2. **Review** — read what Claude wrote before accepting
3. **Test** — run the code and verify it works
4. **Commit** — save your work with a descriptive message

Never let Claude write 500 lines without reviewing. Small steps, frequent checks.

### Exercise: Build Something Small
Pick something tiny — rename a variable, add a comment, create a placeholder file. Go through the full loop: ask Claude, review the change, test it, commit it. This is the rhythm of working with AI.
```

**Step 2: Write Terminal Basics course**

Create `template/docs/courses/terminal-basics/course.md`:

```markdown
---
name: Terminal Basics
description: Navigate your computer from the command line — the environment where Claude Code lives
difficulty: beginner
estimated_sessions: 2-3
prerequisites: ["claude-code-basics"]
---

# Terminal Basics

## Module 1: Where Am I?

### Concept: The File System
Your computer organizes everything in folders (directories) and files, like a filing cabinet. The terminal lets you navigate this structure by typing commands instead of clicking.

**Predict:** When you open a terminal, where do you start? How would you find out?

**Reveal:** You start in your "home directory" — usually `/Users/yourname` on Mac. The command `pwd` (print working directory) tells you exactly where you are.

```bash
pwd
# Output: /Users/yourname
```

Think of `pwd` as asking "where am I right now?"

### Exercise: Find Yourself
Run these commands one at a time:
```bash
pwd              # Where am I?
ls               # What's here?
ls -la           # What's here, including hidden files?
```

Notice files starting with `.` (like `.claude/`, `.git/`) — these are hidden files that configure your tools. Claude Code and git both use hidden directories.

## Module 2: Moving Around

### Concept: Navigating Directories
`cd` (change directory) moves you between folders. Think of it like double-clicking a folder, but with typing.

**Predict:** If you're in `/Users/yourname` and you type `cd Desktop`, where are you now?

**Reveal:** You're in `/Users/yourname/Desktop`. You moved one folder deeper.

Key commands:
```bash
cd foldername    # Go into a folder
cd ..            # Go back up one level
cd ~             # Go home (your home directory)
cd -             # Go back to where you just were
```

### Exercise: Navigate Your Project
```bash
cd ~/Desktop          # Go to Desktop
ls                    # See your projects
cd your-project       # Enter your project
ls                    # See what's inside
cd src                # Go into source code (if it exists)
cd ..                 # Come back up
pwd                   # Confirm where you are
```

## Module 3: Looking at Files

### Concept: Reading Without Editing
Sometimes you just want to see what's in a file without opening an editor.

**Predict:** If a file is 10,000 lines long, would you want to see all of it at once?

**Reveal:** Probably not. That's why there are different commands for different situations:

```bash
cat file.txt         # Show the ENTIRE file (good for short files)
head -20 file.txt    # Show first 20 lines
tail -20 file.txt    # Show last 20 lines
less file.txt        # Scrollable view (press q to quit)
wc -l file.txt       # Just count the lines
```

### Exercise: Explore a File
Find a file in your project and try each command:
```bash
cat README.md
head -5 README.md
wc -l README.md
```

Pro tip: You don't need to memorize all this. You can always ask Claude: "How do I see the first 10 lines of a file?"

## Module 4: Finding Things

### Concept: Search Commands
Two essential search commands:
- `find` — searches for FILES by name
- `grep` — searches for TEXT inside files

**Predict:** You remember writing the word "TODO" somewhere in your code but can't remember which file. How would you find it?

**Reveal:**
```bash
grep -r "TODO" .                    # Search all files for "TODO"
grep -rn "TODO" --include="*.ts" .  # Search only .ts files, show line numbers
```

And to find a file by name:
```bash
find . -name "*.md"                 # Find all markdown files
find . -name "README*"              # Find files starting with README
```

### Exercise: Search Your Project
```bash
grep -rn "TODO" . --include="*.md"   # Find TODOs in markdown files
find . -name "*.md" | head -10       # Find first 10 markdown files
```

## Module 5: Creating and Moving Things

### Concept: File Operations
```bash
mkdir my-folder           # Create a directory
touch my-file.txt         # Create an empty file
cp file.txt copy.txt      # Copy a file
mv old.txt new.txt        # Rename (or move) a file
rm file.txt               # Delete a file (careful — no undo!)
rm -r folder/             # Delete a folder and everything in it
```

**Predict:** What's the difference between `mv` and `cp`?

**Reveal:** `cp` creates a duplicate — the original stays. `mv` moves or renames — the original is gone. Think of `cp` as photocopying and `mv` as physically picking something up and putting it somewhere else.

### Exercise: Practice File Operations
```bash
mkdir practice
cd practice
touch hello.txt
echo "Hello world" > hello.txt
cat hello.txt
cp hello.txt goodbye.txt
cat goodbye.txt
mv goodbye.txt see-ya.txt
ls
cd ..
rm -r practice
```

## Module 6: Pipes and Redirection

### Concept: Connecting Commands
The `|` (pipe) character sends the output of one command INTO another command. This is one of the most powerful ideas in the terminal.

**Predict:** What would `ls | wc -l` do?

**Reveal:** `ls` lists files, then `|` sends that list to `wc -l` which counts lines. Result: the number of files in your directory. You combined two simple commands into something useful.

More examples:
```bash
cat file.txt | grep "error"       # Show only lines containing "error"
ls | head -5                      # Show first 5 files
history | grep "git"              # Find git commands you've run before
```

### Exercise: Pipe Some Commands
```bash
ls -la | wc -l                       # How many items in this directory?
find . -name "*.md" | wc -l          # How many markdown files?
cat CLAUDE.md | grep -i "todo"       # Find TODOs in CLAUDE.md
```

## Module 7: You Don't Need to Memorize This

### Concept: Claude Is Your Terminal Tutor
Here's the secret: you're using Claude Code. You can always ask:
- "How do I find all files modified in the last day?"
- "What command shows disk usage?"
- "How do I compress a folder?"

Claude will give you the exact command. Over time, the common ones become muscle memory. The uncommon ones? Just ask.

### Exercise: Ask Claude
Think of something you'd want to do in the terminal. Ask Claude how. Try it. That's the workflow.
```

**Step 3: Write Git Fundamentals course**

Create `template/docs/courses/git-fundamentals/course.md`:

```markdown
---
name: Git Fundamentals
description: Version control from zero — branches, commits, PRs, and the hooks that protect you
difficulty: beginner
estimated_sessions: 3-4
prerequisites: ["terminal-basics"]
---

# Git Fundamentals

## Module 1: What Is Git?

### Concept: Version Control
Git tracks every change you make to your project over time. Think of it as unlimited undo — not just for one file, but for your ENTIRE project.

**Predict:** You make a change that breaks everything. Without git, what are your options?

**Reveal:** Without git: panic, try to remember what you changed, maybe cry. WITH git: type one command and you're back to the working version. Git saves snapshots of your project at every commit. You can go back to any snapshot.

**Analogy:** Git is like a save system in a video game. You save before a boss fight. If you die, you reload. Commits are your save points.

### Exercise: See Git in Action
```bash
git log --oneline -5     # See last 5 saves (commits)
git status               # See what's changed since last save
```

## Module 2: Making Changes (The Stage-Commit Flow)

### Concept: Two Steps to Save
Git doesn't auto-save. You choose what to save and when. It's a two-step process:

1. **Stage** — pick which changes to include (`git add`)
2. **Commit** — save them with a description (`git commit`)

**Predict:** Why would git make you choose which files to include instead of just saving everything?

**Reveal:** Because you might be working on two different things at once. Maybe you fixed a bug AND started a new feature. Those should be TWO separate saves (commits), not one jumbled mess. Staging lets you control exactly what goes into each commit.

```bash
git add src/login.tsx           # Stage one file
git add src/login.tsx src/api.ts  # Stage two files
git commit -m "feat: add login form validation"
```

### Concept: Conventional Commit Messages
This project uses conventional commits — every message starts with a type:

| Type | When to Use | Example |
|------|-------------|---------|
| `feat:` | Adding something new | `feat: add search bar` |
| `fix:` | Fixing something broken | `fix: cart total was wrong` |
| `docs:` | Documentation changes | `docs: update setup guide` |
| `refactor:` | Reorganizing code (no behavior change) | `refactor: extract login logic` |
| `test:` | Adding or fixing tests | `test: add login validation tests` |
| `chore:` | Maintenance tasks | `chore: update dependencies` |

The commit-msg hook enforces this — if you forget the prefix, it'll remind you.

### Exercise: Make a Commit
```bash
# Make a tiny change (add a comment to any file)
git status                              # See the change
git add <filename>                      # Stage it
git commit -m "docs: add clarifying comment"   # Save it
git log --oneline -3                    # See your commit
```

## Module 3: Branches

### Concept: Working in Parallel
A branch is a copy of your project where you can make changes without affecting the main version. When you're done, you merge your branch back.

**Predict:** What happens if two people edit the same file on different branches?

**Reveal:** When they try to merge, git detects the conflict and asks a human to decide which changes to keep. This is called a "merge conflict." It sounds scary but it's just git saying "I found two different edits to the same place — which one wins?"

```bash
git checkout -b feature/my-thing    # Create a new branch and switch to it
# ... make changes, commit them ...
git push -u origin feature/my-thing  # Push to remote
```

### Concept: Why We Never Work on Main
The `main` branch is the "real" version — the one that's deployed, the one everyone trusts. If you break main, you break it for everyone.

That's why the pre-push hook blocks direct pushes to main. Every change goes:
1. Create a branch
2. Make changes on the branch
3. Push the branch
4. Open a Pull Request (PR)
5. Get it reviewed and merged

### Exercise: Create Your First Branch
```bash
git checkout -b practice/my-first-branch  # Create + switch
git branch                                 # See all branches (* = current)
# Make a small change, commit it
git checkout main                          # Switch back to main
git branch                                 # Notice your branch still exists
```

## Module 4: Pull Requests

### Concept: Code Review Before Merge
A Pull Request (PR) is how you say "I made changes on my branch, please review and merge them into main." It's a conversation — reviewers can comment, suggest changes, or approve.

**Predict:** Why not just merge directly without a PR?

**Reveal:** Because everyone makes mistakes. A second pair of eyes catches bugs, security issues, and design problems before they hit production. PRs also create a searchable record of WHY changes were made.

```bash
git push -u origin feature/my-thing   # Push branch
gh pr create --fill                    # Open a PR (fills from commit messages)
```

After approval:
```bash
gh pr merge --squash --delete-branch   # Merge + clean up
```

### Exercise: The Full Workflow
```bash
git checkout -b practice/full-workflow
# Make a small change
git add <file>
git commit -m "feat: practice the full PR workflow"
git push -u origin practice/full-workflow
gh pr create --title "Practice: full workflow" --body "Testing the PR flow"
# Then go to GitHub and look at your PR!
```

## Module 5: When Things Go Wrong

### Concept: Common Recovery Commands
Things will go wrong. Here's your emergency kit:

```bash
git status              # What's going on right now?
git diff                # What exactly changed?
git stash               # Temporarily hide my changes (get them back with git stash pop)
git checkout -- <file>  # Undo changes to one file (back to last commit)
git log --oneline -10   # What happened recently?
```

**Predict:** You made changes you want to keep, but need to switch branches to look at something. What do you do?

**Reveal:** `git stash` — it hides your changes temporarily. Switch branches, look at what you need, switch back, then `git stash pop` to bring your changes back.

### Concept: Just Ask Claude
For anything beyond basics:
- "I committed to the wrong branch, how do I fix it?"
- "I need to undo my last commit but keep the changes"
- "How do I resolve this merge conflict?"

Claude can see your git state and give you the exact commands. You don't need to memorize recovery procedures.

### Exercise: Practice Recovery
```bash
# Make a change but DON'T commit
echo "temporary" >> README.md
git status                    # See the change
git stash                     # Hide it
git status                    # Clean again
git stash pop                 # Bring it back
git checkout -- README.md     # Undo it for real
git status                    # Clean
```

## Module 6: The Hooks That Protect You

### Concept: Automatic Safety
This project has git hooks — scripts that run automatically before certain git actions. They catch mistakes before they become problems.

| Hook | When It Runs | What It Does |
|------|-------------|--------------|
| pre-push | Before `git push` | Blocks pushes to main — use PRs |
| pre-commit | Before `git commit` | Warns if commit is 200+ lines |
| commit-msg | After writing commit message | Requires feat:/fix:/docs: prefix |

**Predict:** If you try `git push` while on the main branch, what happens?

**Reveal:** The pre-push hook blocks it and tells you to use a branch + PR instead. It even shows you the exact commands. This isn't punishment — it's protection. Every team has stories about someone pushing broken code to main at 2am.

### Exercise: Test the Hooks
```bash
# Test commit-msg hook
git checkout -b test/hooks
echo "test" >> test-file.txt
git add test-file.txt
git commit -m "test"              # Should be rejected! No prefix.
git commit -m "test: verify hooks"  # Should work!
git checkout main
git branch -D test/hooks          # Clean up
```
```

**Step 4: Commit course packs**

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
git add template/docs/courses/
git commit -m "feat: add 3 preloaded course packs — Claude Code, Terminal, Git"
```

---

### Task 3: Write the enhanced /learn skill

**Files:**
- Create: `template/.claude/commands/learn.md`

**Step 1: Write the enhanced learn.md**

Create `template/.claude/commands/learn.md` with the course pack engine. This replaces the old learn.md. Key changes from original:
- Discovers course packs from `docs/courses/` directory
- Shows built-in courses + dynamic project topics
- Adds `contribute` argument
- Adds adaptive behavior based on project maturity
- Preserves mentor personalities, predict-then-reveal, progress tracking, quiz mode

```markdown
---
name: learn
description: Interactive tutor — built-in courses (Claude Code, Terminal, Git) + codebase exploration. Start here if you're new.
argument: "[topic|quiz|progress|contribute]"
model-hint: opus
---

# Learn — Interactive Tutor

An interactive tutor that teaches through Socratic questioning and hands-on exploration. Ships with built-in courses and discovers project-specific topics as your codebase grows.

## Arguments

| Input | Action |
|-------|--------|
| *(empty)* | Show menu: built-in courses + project topics |
| `<topic>` | Start or continue a learning session on that topic |
| `quiz` | Quick quiz on previously covered material |
| `progress` | Show learning progress across all courses/topics |
| `contribute` | Guide for creating a new course pack |

## Step 1: Discover Available Content

### Built-in Courses
Scan `docs/courses/` for directories containing `course.md`. Read the YAML frontmatter of each to get name, description, difficulty, and prerequisites.

Expected built-in courses:
1. Claude Code Basics (no prerequisites)
2. Terminal Basics (prerequisite: claude-code-basics)
3. Git Fundamentals (prerequisite: terminal-basics)

### Project Topics (Dynamic)
Count source files (exclude node_modules, .git, docs, scripts, .claude):
```bash
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.js" -o -name "*.jsx" \) | grep -v node_modules | grep -v .git | wc -l
```

| File Count | Behavior |
|------------|----------|
| 0-5 | Show built-in courses only. Message: "Build some features and I'll find things to explore here." |
| 6-20 | Add "Recent changes" topic. Analyze `git log --oneline -10` for teachable areas. |
| 20+ | Analyze project structure. Identify 3-5 major areas (by directory grouping, imports, or module boundaries). Add as topics. |

### Check Progress
For each course/topic, check for `docs/courses/<name>/progress.json`. Show completion status:
- Not started
- In progress (N/M sessions)
- Completed

## Step 2: Present Menu

### If no argument provided:

```
Welcome to /learn! Here's what I can teach you:

  Built-in courses:
    1. Claude Code Basics     [status]    <- Start here
    2. Terminal Basics         [status]
    3. Git Fundamentals        [status]

  Project topics:                          <- appears when codebase has substance
    4. [topic name]            (path/to/area/)
    5. [topic name]            (path/to/area/)
    ...

Pick a number, name a topic, or type 'surprise me'
```

Use AskUserQuestion with course names as options.

### If `quiz` argument: Skip to Step 6.
### If `progress` argument: Skip to Step 7.
### If `contribute` argument: Skip to Step 8.
### If topic name provided: Skip to Step 3 with that topic.

## Step 3: Session Setup

### For built-in courses:
Read the full `docs/courses/<name>/course.md`. This contains all modules, concepts, predict-then-reveal prompts, and exercises. Follow the course content as written — it IS the curriculum.

### For project topics:
Read the relevant source files. Identify 3-5 teachable concepts in that area (patterns, architecture decisions, data flow, error handling, etc.).

### Pick a Mentor

Use AskUserQuestion:

```
Pick your mentor style for this session:

  1. The Professor — structured, builds from fundamentals
     "Let's understand WHY before HOW"

  2. The Practitioner — hands-on, example-driven
     "Let me show you what happens when..."

  3. The Philosopher — Socratic, explores trade-offs
     "What would happen if we chose differently?"
```

Load existing progress from `docs/courses/<topic>/progress.json` if it exists. Resume from where they left off.

## Step 4: Teaching Session (3-5 Rounds)

### For built-in courses:
Follow the modules in course.md sequentially. Each module has:
- **Concept** sections with predict-then-reveal prompts
- **Exercise** sections with hands-on tasks

Present one concept at a time. Use AskUserQuestion for predictions. Reveal answers, then connect to broader patterns.

### For project topics:
Use the predict-then-reveal method with actual project code:
1. **Set up:** Show a code snippet from the project
2. **Predict:** Ask what they think it does or why it's written this way
3. **Reveal:** Explain the actual behavior and reasoning
4. **Connect:** Link to broader patterns in the codebase
5. **Challenge:** Pose a "what if" variation

### Difficulty Scaling
- Correct predictions → increase difficulty (more complex code, deeper concepts)
- Incorrect predictions → simplify (break down further, more context)

### Mentor Voice
Adapt presentation style to the chosen mentor:
- **Professor:** Structured explanations, analogies, "the reason this matters is..."
- **Practitioner:** "Watch what happens when...", debugging scenarios, real examples
- **Philosopher:** Questions back at them, trade-off exploration, "but what if..."

## Step 5: Wrap-Up

After 3-5 rounds:

1. **Hands-on challenge** — small coding task related to what was covered. Use real project files. Guide with hints, not solutions.

2. **Key takeaways** — 3-5 bullet points summarizing what was learned.

3. **Update progress** — Write `docs/courses/<topic>/progress.json`:
```json
{
  "topic": "claude-code-basics",
  "sessions": 1,
  "lastSession": "2026-03-06",
  "modulesCompleted": ["what-is-claude-code", "skills"],
  "modulesTotal": 5,
  "questionsCorrect": 8,
  "questionsTotal": 10,
  "difficulty": "beginner",
  "nextModule": "claude-md",
  "mentor": "professor"
}
```

4. **Suggest next** — Based on what was learned, suggest the next course or topic.

5. **Review questions** — Generate 2-3 questions to revisit next session.

## Step 6: Quiz Mode

When `quiz` argument is passed:

1. Scan all progress.json files for completed or in-progress courses
2. Generate 5 questions mixing:
   - **Recall** — "What does `git stash` do?"
   - **Application** — Show a code snippet, ask what command to run
   - **Analysis** — "Why does this project use conventional commits?"
3. Use actual project code where possible (for project topics)
4. Score and identify weak areas
5. Suggest review sessions for low-scoring topics

If no progress exists: "You haven't started any courses yet. Try `/learn` to begin with Claude Code Basics."

## Step 7: Progress Dashboard

When `progress` argument is passed:

```
Learning Progress
==================

Built-in Courses:
  Claude Code Basics    ████████░░  4/5 modules | 80% accuracy
  Terminal Basics        ██████░░░░  3/5 modules | 90% accuracy
  Git Fundamentals       ░░░░░░░░░░  Not started

Project Topics:
  Authentication flow    ██░░░░░░░░  1 session | 60% accuracy
  State management       ░░░░░░░░░░  Not started

Total sessions: 8 | Overall accuracy: 78%

Suggestion: Continue Terminal Basics (2 modules remaining)
```

## Step 8: Contribute a Course

When `contribute` argument is passed:

1. Show the course pack template:
```
Want to create a course? Here's how:

  1. Create a folder: docs/courses/your-topic/
  2. Create course.md with this template:
     [show frontmatter + module structure]
  3. Your course appears in /learn automatically

Tips:
  - Use predict-then-reveal format for concepts
  - Include hands-on exercises with real commands
  - Keep modules focused — one concept each
  - Add prerequisites if your course builds on others
```

2. Auto-suggest course ideas based on the codebase:
   - Complex areas with high cyclomatic complexity
   - Areas with low or no test coverage
   - Recently refactored code worth documenting
   - Patterns that appear in multiple places
```

**Step 2: Commit**

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
git add template/.claude/commands/learn.md
git commit -m "feat: add enhanced /learn skill with course pack engine"
```

---

### Task 4: Copy unchanged skills to new repo

**Files:**
- Create: `template/.claude/commands/health.md`
- Create: `template/.claude/commands/preflight.md`
- Create: `template/.claude/commands/code-review.md`
- Create: `template/.claude/commands/deep-review.md`
- Create: `template/.claude/commands/retro.md`
- Create: `template/.claude/commands/future-feature.md`
- Create: `template/.claude/commands/ready-to-commit.md`
- Create: `template/.claude/commands/vibes.md`

**Step 1: Copy all 8 unchanged skill files**

Copy each skill file from git-shit's template to big-gulps-huh's template. These are exact copies — no modifications needed:

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
for skill in health preflight code-review deep-review retro future-feature ready-to-commit vibes; do
  cp /Users/pecchenino/Desktop/git-shit/template/.claude/commands/${skill}.md template/.claude/commands/
done
```

**Step 2: Verify all 9 skills are present (8 copied + learn.md from Task 3)**

```bash
ls -1 template/.claude/commands/
```

Expected:
```
code-review.md
deep-review.md
future-feature.md
health.md
learn.md
preflight.md
ready-to-commit.md
retro.md
vibes.md
```

**Step 3: Commit**

```bash
git add template/.claude/commands/
git commit -m "feat: add 8 portable skills (health, preflight, code-review, deep-review, retro, future-feature, ready-to-commit, vibes)"
```

---

### Task 5: Copy check scripts, template files, and docs

**Files:**
- Create: `template/scripts/setup-hooks.sh`
- Create: `template/scripts/check-console-log.sh`
- Create: `template/scripts/check-as-any.sh`
- Create: `template/scripts/check-async-safety.sh`
- Create: `template/scripts/check-file-size.sh`
- Create: `template/.gitattributes`
- Create: `template/.github/pull_request_template.md`
- Create: `template/CLAUDE.md`
- Create: `template/docs/BIG_GULPS_GUIDE.md`

**Step 1: Copy check scripts**

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
for script in check-console-log.sh check-as-any.sh check-async-safety.sh check-file-size.sh; do
  cp /Users/pecchenino/Desktop/git-shit/template/scripts/${script} template/scripts/
done
cp /Users/pecchenino/Desktop/git-shit/template/scripts/setup-hooks.sh template/scripts/
```

**Step 2: Copy template files**

```bash
cp /Users/pecchenino/Desktop/git-shit/template/.gitattributes template/
cp /Users/pecchenino/Desktop/git-shit/template/.github/pull_request_template.md template/.github/
cp /Users/pecchenino/Desktop/git-shit/template/CLAUDE.md template/
cp /Users/pecchenino/Desktop/git-shit/template/docs/BIG_GULPS_GUIDE.md template/docs/
```

**Step 3: Verify**

```bash
ls template/scripts/
ls template/.github/
ls template/docs/
cat template/.gitattributes | head -3
```

**Step 4: Commit**

```bash
git add template/scripts/ template/.gitattributes template/.github/ template/CLAUDE.md template/docs/BIG_GULPS_GUIDE.md
git commit -m "feat: add check scripts, template files, and documentation"
```

---

### Task 6: Rewrite big-gulps-huh.md with new onboarding flow

This is the biggest task — the complete rewrite of the scaffolder skill with:
- Experience detection ("Have you used Claude Code before?")
- Auto-detect stack from project files
- Teaching calibrated to experience level
- Dial-back check that reads the room
- Inlined git hook logic (no git-shit dependency)
- Landing with /learn nudge
- Session greeting evolution

**Files:**
- Create: `.claude/commands/big-gulps-huh.md`

**Step 1: Write the new big-gulps-huh.md**

Create `.claude/commands/big-gulps-huh.md`. This is a complete rewrite of the original. The full content follows — write it as a single file.

The skill must contain:
1. **YAML frontmatter** — name, description, argument, model-hint: opus
2. **Step 1: Experience Detection** — "Have you used Claude Code before?" with 3 options mapping to $EXPERIENCE (new/some/experienced)
3. **Step 2: Detect Context & Idempotency** — same scan logic as original but behavior varies by $EXPERIENCE
4. **Step 3: Auto-Detect Stack** — scan for package.json/pyproject.toml/go.mod/Cargo.toml. For new: explain in plain language. For some: confirm. For experienced: list + offer override. Fall back to asking if nothing found.
5. **Step 4: Git Protection (Inlined)** — write 3 hooks to .git/hooks/ directly (pre-push, pre-commit, commit-msg), create .gitattributes, setup-hooks.sh, .gitignore. Use the exact hook content from git-shit's template files. Teaching after: short explanation of what each hook does, calibrated to $EXPERIENCE.
6. **Step 5: Claude Code Hooks** — write .claude/settings.local.json with permissions and hooks. Same content as original Step 4. Teaching after.
7. **Step 6: Check Scripts** — write the 4 check scripts to scripts/. Same content as original Step 5. Teaching after.
8. **Step 7: Scaffold Skills** — copy 9 skills to .claude/commands/. Same content as original Step 6 BUT also scaffold the 3 course pack directories under docs/courses/. Teaching after.
9. **Step 8: Dial-Back Check** — fires after layer 3 for new users, layer 2 for some. AskUserQuestion: "Want me to keep explaining things, or just finish setting up?" If "just finish", set $TEACHING=false for remaining layers.
10. **Step 9: Generate CLAUDE.md** — same as original Step 7 but with $EXPERIENCE-calibrated TODO hints
11. **Step 10: Generate Big Gulps Guide** — same 3 tone templates as original Step 8
12. **Step 11: Landing** — hands-on "try this now" moment calibrated to $EXPERIENCE. For new: strong /learn nudge. For some: medium nudge. For experienced: /health nudge.
13. **Tutorial mode** — removed as a separate mode. Teaching is now woven into the flow via $EXPERIENCE, not a boolean toggle.
14. **Session greeting evolution** — the SessionStart hook should include tip rotation logic based on session count and course progress

The exact hook content to inline (pre-push, pre-commit, commit-msg) comes from `/Users/pecchenino/Desktop/git-shit/template/git-hooks/`. Use those verbatim, with $DEFAULT_BRANCH replaced at write time.

The exact check script content comes from `/Users/pecchenino/Desktop/git-shit/template/scripts/check-*.sh`. Use those verbatim.

The exact settings.local.json structure, Big Gulps Guide templates, and CLAUDE.md template come from the original big-gulps-huh.md. Adapt but don't fundamentally change.

**Key differences from original:**
- Opens with experience question, not stack questions
- Auto-detect replaces asking (for new/some users)
- Teaching is woven in, not bolted on via tutorial mode
- Dial-back check reads the room
- Landing has a hands-on moment + /learn nudge
- Session greeting rotates tips based on progress
- Git hooks are inlined directly, no /git-shit dependency
- Course pack directories are scaffolded alongside skills

**Step 2: Commit**

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
git add .claude/commands/big-gulps-huh.md
git commit -m "feat: add big-gulps-huh skill with onboarding-first design"
```

---

### Task 7: Write big-gulps-huh README

**Files:**
- Create/overwrite: `README.md`

**Step 1: Write README**

Write `README.md` for the big-gulps-huh repo. Target audience: friends, family, new devs. Tone: warm, encouraging, practical.

Content:
1. **Header** — name, one-line description
2. **What This Does** — plain language explanation of the 5 layers (git hooks, Claude hooks, check scripts, skills + courses, documentation)
3. **Quick Start** — copy the skill file, run `/big-gulps-huh`
4. **What You Get** — file tree showing what gets created
5. **The Skills** — table of all 9 skills with one-line descriptions
6. **The Courses** — table of 3 built-in courses with descriptions
7. **For Experienced Devs** — "If you just want git hooks without Claude Code, check out [git-shit](https://github.com/newbynewbynewbz/git-shit)"
8. **Contributing Courses** — brief note about `/learn contribute`
9. **Why This Exists** — same origin story from current README (Pahu Hau, friends & family)
10. **License** — MIT

**Step 2: Commit**

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
git add README.md
git commit -m "docs: add README with onboarding-focused documentation"
```

---

### Task 8: Clean up git-shit repo

**Files:**
- Delete: `.claude/commands/big-gulps-huh.md`
- Delete: `template/.claude/commands/` (entire directory)
- Delete: `template/scripts/check-console-log.sh`
- Delete: `template/scripts/check-as-any.sh`
- Delete: `template/scripts/check-async-safety.sh`
- Delete: `template/scripts/check-file-size.sh`
- Delete: `template/CLAUDE.md`
- Delete: `template/docs/` (entire directory)
- Modify: `README.md`

**Step 1: Delete big-gulps-huh content**

```bash
cd /Users/pecchenino/Desktop/git-shit
rm .claude/commands/big-gulps-huh.md
rm -r template/.claude/commands/
rm template/scripts/check-console-log.sh
rm template/scripts/check-as-any.sh
rm template/scripts/check-async-safety.sh
rm template/scripts/check-file-size.sh
rm template/CLAUDE.md
rm -r template/docs/
```

**Step 2: Verify what remains**

```bash
find template/ -type f | sort
```

Expected:
```
template/.gitattributes
template/.github/pull_request_template.md
template/git-hooks/commit-msg
template/git-hooks/pre-commit
template/git-hooks/pre-push
template/scripts/setup-hooks.sh
```

```bash
ls .claude/commands/
```

Expected: `git-shit.md` only

**Step 3: Rewrite README.md**

Rewrite to be git-only. Structure:
1. Header: "git-shit — Level up any repo's git setup in 60 seconds"
2. What you get: hooks, conventional commits, PR template, .gitattributes, setup script
3. Quick Start with Claude Code: copy skill, run `/git-shit`
4. Quick Start without Claude Code: copy files manually
5. What's in the box: file tree (slim, git-only)
6. Audit mode
7. Link to big-gulps-huh: "Want the full Claude Code collaboration setup? Check out [big-gulps-huh](https://github.com/newbynewbynewbz/big-gulps-huh)."
8. License

**Step 4: Commit**

```bash
cd /Users/pecchenino/Desktop/git-shit
git add -A
git commit -m "refactor: remove big-gulps-huh content, focus repo on git tooling only"
```

---

### Task 9: Push both repos

**Step 1: Push big-gulps-huh**

```bash
cd /Users/pecchenino/Desktop/big-gulps-huh
git push -u origin main
```

**Step 2: Push git-shit**

```bash
cd /Users/pecchenino/Desktop/git-shit
git push origin main
```

**Step 3: Verify both repos on GitHub**

```bash
gh repo view newbynewbynewbz/big-gulps-huh --json name,description
gh repo view newbynewbynewbz/git-shit --json name,description
```

---

### Task 10: Update auto-memory

**Step 1: Update memory with new project structure**

Record in auto-memory:
- git-shit and big-gulps-huh are now separate repos
- big-gulps-huh inlines git hook logic
- /learn has course pack architecture with 3 preloaded courses
- big-gulps-huh uses experience-level detection for onboarding
- Course order: Claude Code -> Terminal -> Git
