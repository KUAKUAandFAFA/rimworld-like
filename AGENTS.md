# Project Agent Rules

## Development Scope

- When the user asks for development work, work on exactly one numbered goal from `docs/requirements/05_development_goals.md`.
- Do not implement multiple goals in a single development pass.
- If a request appears to span multiple goals, stop and ask which single goal should be handled first.
- At the start of development work, state the active goal using `Current goal: Gxx - Goal Name`.

## Completion and Commit

- After completing development work, commit only the files changed for that single goal.
- Do not mix unrelated dirty workspace changes into the commit.
- The final report must include the goal completed, the commit hash, and the exact manual test items for the user to run.
- The user performs gameplay/manual testing personally; provide clear steps and expected results.

## Godot Verification

- Do not run screenshot, visual, or gameplay interaction tests unless the user explicitly asks.
- Do not run the full game as a default verification step unless needed to diagnose a specific issue.
- Prefer fast compile/parse checks for Godot script errors.
- If a change needs manual playtesting, describe the exact steps for the user to try in Godot instead of doing it automatically.
- When Godot reports a parse error, fix the reported file and line first before doing any other validation.
