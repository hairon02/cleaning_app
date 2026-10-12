# 013 · Server-side User Registration

## What it does

When a person finishes onboarding with a display name, Clearing registers their existing device ID and name in the backend `users` table before opening the app. Their ID is then used by photo, cleared-cell, and points-ledger records created by later activity.

## Why it exists

The current onboarding saves the profile only on the device. The backend creates a `Guest` row lazily during the first upload, so the chosen name is absent from the server and the user does not exist until they take a photo.

## Acceptance criteria

- [x] `POST /api/users` accepts a non-empty display name and a stable device user ID.
- [x] Repeating registration for the same ID is safe and updates the display name without creating a second user.
- [x] Flutter completes server registration before entering Challenges; a network/server failure is shown with a retry action.
- [x] Existing locally saved profiles are synchronized to the backend when the app starts.
- [x] The same `user_id` is used in future `photos`, `cells`, and `points_ledger` records through existing foreign keys.
- [x] Registration does not create placeholder rows in activity tables.
