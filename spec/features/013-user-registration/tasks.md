# Tasks — 013 · Server-side User Registration

## Backend

- [x] Add `POST /api/users` with request validation and an idempotent upsert into `users`.
- [x] Return the persisted ID and display name.

## Flutter

- [x] Add API client registration call using the stable local device ID.
- [x] Register before saving the completed local profile and navigating into Clearing.
- [x] Show a clear retry state when registration fails.
- [x] Synchronize a previously saved local profile on app launch.

## Data integrity

- [x] Confirm existing `photos`, `cells`, and `points_ledger` writes use the registered `user_id` through their foreign keys.
- [x] Do not insert placeholder rows into activity tables at registration time.

## Tests

- [ ] Add and run backend tests for new registration, idempotent re-registration/name update, and invalid IDs/names.
