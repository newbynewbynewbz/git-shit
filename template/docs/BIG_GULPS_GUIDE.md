# The Big Gulps Guide

> "Big gulps, huh? Welp, see ya later!" — Lloyd Christmas, professional optimist

*A sarcastic but genuinely helpful guide to not breaking things.*

---

## What Just Happened

You (or someone who cares about you) just ran `/big-gulps-huh` and scaffolded a complete Claude Code collaboration setup into this project. That means git hooks, AI guardrails, portable skills, and a CLAUDE.md constitution. You now have more safety nets than a Cirque du Soleil performer.

---

## The Rules

### 1. Never Push to Main

The `pre-push` hook will block you. Main is sacred. It's where working code lives. You work on branches, you make PRs, you get them merged. This is not negotiable.

**DYOR:** [Git branching strategies](https://docs.github.com/en/get-started/quickstart/github-flow)

### 2. Conventional Commits or Go Home

Every commit message needs a prefix: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, etc. The `commit-msg` hook enforces this. "fixed stuff" is not a commit message, it's a cry for help.

**DYOR:** [Conventional Commits spec](https://www.conventionalcommits.org/)

### 3. Keep Commits Small

The `pre-commit` hook warns you at 200+ lines. If your commit touches 47 files, that's not a commit, that's a hostage situation. One logical change per commit.

**DYOR:** [Atomic commits](https://www.pauline-vos.nl/atomic-commits/)

### 4. Don't Touch .env Files Through Claude

The `.env` blocker hook will physically prevent it. Credentials in AI chat history is how you end up on Hacker News for the wrong reasons.

**DYOR:** [12-Factor App — Config](https://12factor.net/config)

---

## The Skills (Your New Superpowers)

| Skill | What It Does | When to Use It |
|-------|-------------|----------------|
| `/health` | Runs types, tests, deps, TODOs, file sizes | "Is everything still working?" |
| `/preflight` | Pre-push verification suite | Before every push. Every. Single. One. |
| `/code-review` | Multi-agent code review | After finishing a feature, before PR |
| `/deep-review` | 5-agent parallel deep review | For important changes or new architecture |
| `/retro` | Post-session retrospective | End of a work session — captures lessons |
| `/future-feature` | Extract & prioritize feature ideas | After reviews, user feedback, brainstorms |
| `/ready-to-commit` | Smart commit prep with category detection | When you're ready to commit (duh) |
| `/learn` | Interactive codebase tutor | When you're new or exploring unfamiliar code |
| `/vibes` | Daily motivation & focus helper | When you need a productivity boost |

**Pro tip:** The minimum viable workflow is `/preflight` before pushing and `/health` when things feel off. Everything else is bonus XP.

---

## The Hooks (Things That Yell at You)

| Hook | What It Checks | Why It Exists (Because Someone Did This) |
|------|---------------|------------------------------------------|
| pre-push | Direct pushes to main | Pushed untested code to main at 2am. Production went down. |
| pre-commit | Commit size > 200 lines | Made a 3,000-line commit called "updates". Nobody could review it. Ever. |
| commit-msg | Conventional commit prefix | Wrote "asdf" as a commit message. Six months later, needed to find that change. |
| .env blocker | .env file edits via Claude | AI assistant helpfully committed AWS keys to a public repo. |
| Console sentinel | console.log in prod code | Left `console.log("here")` in production. Users saw it. |
| Type assertion detector | `as any` usage | Cast everything to `any` to "fix" type errors. Created 47 runtime errors. |
| Async safety | Unguarded promises | Forgot `.catch()`. App silently failed. Users saw a blank screen for 3 days. |
| File size | Files over 500 lines | Created a 2,400-line "utils.ts". It's still haunted. |
| Session greeting | Branch + uncommitted files | Started coding on main. Didn't notice for 2 hours. |

---

## The CLAUDE.md (Your Project's Constitution)

The `CLAUDE.md` file has TODO markers. **Fill them in.** This is not optional busywork — it's what makes Claude actually useful for your specific project instead of giving you generic Stack Overflow answers.

The sections that matter most:
1. **Tech Stack** — so Claude knows what you're working with
2. **File Structure** — so Claude finds things without asking
3. **Code Patterns** — so Claude writes code that looks like yours
4. **Common Gotchas** — so Claude doesn't repeat your past mistakes

Think of it as onboarding docs, except the new hire is an AI that reads really fast and has zero institutional knowledge.

---

## Quick Start

1. **Read this guide** *(you're doing it, gold star)*
2. **Fill in CLAUDE.md TODOs** — Tech Stack, File Structure, Code Patterns at minimum
3. **Run `bash scripts/setup-hooks.sh`** to verify hooks are installed
4. **Try `/health`** to see your project's current status
5. **Make a test branch:** `git checkout -b test/my-first-branch`
6. **Make a small change and commit:** `git commit -m "test: verify hook setup"`
7. **Run `/preflight`** before pushing

If all 7 steps work, you're ready. Welcome to the guardrail life.

---

## FAQ

**Q: Can I push to main?**
A: No.

**Q: But what if—**
A: No.

**Q: What if it's really small and I promise it's fine?**
A: `git push --no-verify` exists for genuine emergencies. If you use it for convenience, the hooks will judge you silently.

**Q: I got a commit message error. What do I do?**
A: Start your message with a type: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `style:`, `perf:`, `ci:`, `build:`, or `revert:`. That's it. That's the whole thing.

**Q: Claude keeps warning me about console.log. Is it broken?**
A: It's working perfectly. Remove your console.log statements. Use a proper logger.

**Q: What's `/vibes` actually for?**
A: Productivity science disguised as fun. Try it on a Monday morning.

**Q: This is a lot of setup. Is it worth it?**
A: You'll thank us the first time a hook catches something at 2am that would have been a production incident at 8am.

---

## One More Thing

This setup is a starting point, not a straitjacket. As your project grows:
- Add project-specific hooks (design token enforcement, API validation, etc.)
- Create custom skills for repetitive workflows
- Update CLAUDE.md as patterns evolve
- Run `/retro` regularly to capture what you've learned

The goal isn't perfection — it's fewer "oh no" moments and more "oh nice" moments.

---

*Generated by `/big-gulps-huh` — your friendly neighborhood scaffolder.*
*DYOR: Do Your Own Research. The links above are starting points, not gospel.*
