# Goal-Based Development Workflow

This project develops against the final product requirements in `docs/requirements/`, not only against the current prototype.

Every implementation pass must name the active development goal before changing code.

## Required Turn Header

Use this format at the start of implementation work:

```text
Current goal: Gxx - Goal Name
```

Do not use a multi-goal batch header for development work. If the user asks for a batch, ask which single goal should be completed first.

## Scope Rules

- Work on exactly one numbered goal at a time.
- Do not implement multiple goals in one development pass.
- If the requested work spans multiple goals, stop and ask the user which single goal should be handled first.
- If a goal needs a missing prerequisite, stop and re-plan instead of silently expanding scope.
- Every code change must trace back to `docs/requirements/05_development_goals.md`.
- Keep prototype convenience code separate from final-product infrastructure.
- Do not introduce a new top-level module unless the active goal requires it.

## Completion Report

Each completed goal must report:

- Goal number and name.
- Delivered behavior or document.
- Main files or modules changed.
- Verification performed.
- Commit hash.
- Manual test items for the user to run, with expected results.
- Remaining risks or follow-up goals.

## Code Structure Rules

Current gameplay modules:

- `scripts/app`: scene orchestration and player input routing.
- `scripts/world`: map, terrain, resources, pathfinding, and world drawing.
- `scripts/pawns`: pawn movement and carried-item state.
- `scripts/jobs`: runtime jobs and job drivers.
- `scripts/items`: item definitions and stockpile accounting.
- `scripts/ui`: HUD and presentation logic.

Modules introduced by baseline goals:

- `scripts/data`: static definition loading and lookup.
- `scripts/debug`: development-only inspection helpers.
- `tools`: local verification scripts.

Future modules should follow final product domains from the requirements: buildings, zones, save, events, needs, research, production, combat.

## Verification Rules

Minimum verification before considering a goal complete:

```powershell
D:\codes\Godot\Godot_v4.6.1-stable_win64.exe --headless --path . --quit
git diff --check
```

Manual gameplay verification is required when behavior changes player controls, UI, simulation, or rendering. Follow `AGENTS.md` if it is present in the workspace: prefer targeted checks and do not run full gameplay automation unless explicitly requested.

The agent should provide the manual test checklist instead of running gameplay, screenshot, or visual interaction tests by default. The user is responsible for personally running those manual checks in Godot.

## Commit Rules

- Commit requirements/docs separately from gameplay implementation when practical.
- Commit the completed goal before giving the final report.
- Commit messages should include the goal number when a commit satisfies a goal.
- Do not mix unrelated workspace changes into a goal commit.
- If the worktree has pre-existing dirty files, state which files were intentionally left untouched.
