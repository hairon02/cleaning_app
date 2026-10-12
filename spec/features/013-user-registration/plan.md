# Plan — 013 · Server-side User Registration

## Approach

Keep the app's stable device UUID and add an idempotent backend registration endpoint that upserts the display name. The Flutter registration step calls this endpoint before persisting the completed local profile and entering the app. On later launches, the app syncs an existing local profile before opening Challenges.

## Technical decisions

- **API:** `POST /api/users` with JSON `{ "id": "<device UUID>", "display_name": "<name>" }`; return the canonical user ID and display name.
- **Persistence:** SQLite `INSERT ... ON CONFLICT(id) DO UPDATE` so retries and name edits do not duplicate users.
- **Related data:** keep current foreign-key model. `photos`, `cells`, and `points_ledger` get the registered user's ID only when those activity rows are created; registration must not fabricate empty activity.
- **Failure handling:** registration screen stays open and presents retry on error. Startup sync presents a retry state rather than entering with an unregistered local profile.
