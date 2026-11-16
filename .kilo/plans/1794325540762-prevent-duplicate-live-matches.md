# Plan: Prevent duplicate live match entries on Home screen by Match id

## Goal
Before creating/rendering a live match entry on the Home screen, check if a match with the same Match id (`matchAppId`, e.g. SM-10001) already exists. If it does, do not create a duplicate entry.

## Context

### What "Match id" means
`matchAppId` — the sequential `SM-10001`, `SM-10002`, … column recently added to:
- Local SQLite `matches` table (`lib/services/database.dart:30`)
- InsForge `matches` table (manually added by user)

### Current duplicate-risk flow
1. User starts a Quick Match → MatchSetupScreen → TossScreen
2. `TossScreen._startScoring()` (toss_screen.dart:33) generates a new UUID (`setupData.id` or `Uuid().v4()`), pushes a live record to InsForge `pending_matches` via `LiveScoringService`, then navigates to opening lineup.
3. Home screen (`home_screen.dart`) renders live matches from `liveMatchInsforgeProvider` and pending matches from `pendingMatchesProvider`.
4. Both providers already dedup by **UUID** (`match.id` / `m.id`), but NOT by `matchAppId`. If two different UUIDs represent the same match (same teams), both appear as separate entries.
5. `matchAppId` is currently only assigned **after** the match completes and syncs (insforge_sync_service.dart:76-77, 118-119) or when pulling remote matches (sync_manager.dart:172-176). It is **null** while a match is live, so it cannot be used for dedup at creation time today.

## Design decisions

| Decision | Rationale |
|---|---|
| Assign `matchAppId` at match creation time (toss) | So it's available for dedup while the match is live, not just after completion |
| Use `matchAppId` (not `matchCode`) as the dedup key | `matchAppId` is the globally sequential id the user asked for; `matchCode` is a per-match hash-derived value |
| Store `matchAppId` in InsForge `pending_matches` via `match_data` JSON | The `pending_matches` table may not have a `match_app_id` column; `match_data` JSON is flexible |
| Dedup in providers as safety net | Even if creation-time check passes, providers should dedup by `matchAppId` before rendering |

## Files affected

1. `lib/features/match/match_setup_screen.dart` — Add `matchAppId` field to `MatchSetupData` (nullable String), include in `toJson()`/`fromJson()`/`copyWith()`
2. `lib/features/match/toss_screen.dart` — In `_startScoring()`, compute `matchAppId` via `db.nextMatchAppId()`, check for existing match with same `matchAppId` before creating; if exists, navigate to existing match instead
3. `lib/services/database.dart` — Add `getMatchByMatchAppId(String matchAppId)` helper to query local matches by `matchAppId`
4. `lib/features/home/providers/live_match_insforge_provider.dart` — In `_fetch()`, after building `matchMap`, dedup by `matchAppId` extracted from row data as a safety net
5. `lib/features/match/providers/pending_matches_provider.dart` — In `addOrUpdateMatch()`, check for existing match by `matchAppId` before adding a new entry

## Detailed tasks

### Task 1: Add `getMatchByMatchAppId` to database.dart
Add a method to `AppDatabase`:
```dart
Future<CricketMatch?> getMatchByMatchAppId(String matchAppId) async {
  return (select(matches)..where((m) => m.matchAppId.equals(matchAppId))).getSingleOrNull();
}
```

### Task 2: Add `matchAppId` to `MatchSetupData`
Add `final String? matchAppId` field to `MatchSetupData` class. Update:
- Constructor
- `toJson()` — include `'matchAppId': matchAppId`
- `fromJson()` — read `json['matchAppId']`
- `copyWith()` — include `matchAppId` parameter

### Task 3: Assign and check `matchAppId` at toss time
In `TossScreen._startScoring()`:
1. Before generating a new matchId, compute `nextMatchAppId = await db.nextMatchAppId()`
2. Check `db.getMatchByMatchAppId(nextMatchAppId)` — should be null since it's the next number
3. More importantly: check if a live match with the same teams already exists (query local DB by teamAName + teamBName where isCompleted == false)
4. If an existing live match is found, navigate to it instead of creating a new one
5. Set `matchAppId` on `updatedData` before pushing to InsForge

### Task 4: Store `matchAppId` in InsForge pending_matches
In `toss_screen.dart` `_startScoring()`, add `'match_app_id': matchAppId` to the `blob` map sent to `LiveScoringService.pushLiveUpdate()`.

### Task 5: Dedup by `matchAppId` in `liveMatchInsforgeProvider`
In `_fetch()`, after the existing UUID-based dedup (`matchMap[match.id] = match`), add a second pass that dedups by `matchAppId` extracted from `row['match_app_id']` or `match_data['matchAppId']`. Keep the first occurrence, drop subsequent duplicates.

### Task 6: Dedup by `matchAppId` in `pending_matches_provider`
In `addOrUpdateMatch()`, in addition to the existing `m.id` check, also check `state.any((m) => m.matchAppId == match.matchAppId)`. If found, update the existing entry instead of appending.

## Edge cases
- `matchAppId` is null for matches created before this feature — treat as no dedup key, fall back to UUID dedup
- Two matches with same teams but different `matchAppId` are different matches (e.g. rematch) — should NOT be deduped
- Same `matchAppId` with different UUID — should be deduped (same match, duplicate row)

## Validation
- `dart analyze` on all modified files reports no issues
- Build runner regenerates `database.g.dart` if schema changes (it won't — column already exists)
- Manual test: create two quick matches with same teams; verify only one live entry appears on Home screen

## Out of scope
- Migrating existing matches' `matchAppId` (null until they sync/complete)
- InsForge `pending_matches` table schema change (store `match_app_id` in `match_data` JSON instead)