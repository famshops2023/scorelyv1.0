# Scorely — Quick Match: Phase 1 Code & Database Audit

**Scope:** Quick Match only. Schedule Match must not change.
**Mode:** Read-only. No Flutter source, schema, RLS, backend function or production data was modified while producing this report.
**Date:** 14 Nov 2026
**Target backend:** InsForge project `Scorely_Live` (`https://ip53vj9s.ap-southeast.insforge.app`)
**Deliverable for:** Phase 2 implementation (Antigravity / Gemini)

> Note: the working tree already contained uncommitted changes before this audit. They were not touched. All line references below are against the current working tree.

---

## 0. Executive summary

The database already has the canonical lifecycle (`pending | live | completed`) and the Flutter app already has `MatchStatus`, `MatchLifecycleService`, `PendingMatchesNotifier` and association-based RLS. **The lifecycle infrastructure is not missing — Quick Match simply does not use it.**

Confirmed in code:

1. **Quick Match never writes a `pending_matches` row** during create-team, match setup, toss or opening lineup. `MatchSetupScreen._startMatch` quick branch only writes `QuickMatchStorage` (SharedPreferences) and navigates to Toss. Toss explicitly skips `addOrUpdateMatch` for quick matches. Opening Lineup explicitly skips `markLive` for quick matches.
2. The only server row for a Quick Match is created **later**, when the scoring screen calls `LiveScoringService.init(...)` and the first `_sendPatch` upserts `pending_matches` with `status = 'live'` — **and only when the user is signed in**. Guest quick matches never touch the server.
3. Therefore a signed-in quick match has **no server-side `pending` phase**: it is local-only, then jumps straight to server `live`, then to `completed`. Cross-device visibility, "Pending" list, and resume only exist after scoring has begun.
4. `_verifyActiveScorerAuthority()` **returns early for quick matches** (`scoring_screen.dart:505-513`), so the server-authoritative view-only lock never applies to Quick Match. Button visibility is the only control.
5. **Scorer handover is still live in Quick Match at two unguarded entry points** (innings break and the live "Change Scorer" menu). The accept RPC really does change `pending_matches.active_scorer_id`, but the original device never re-verifies authority and keeps writing locally, and the recipient device starts the 2nd innings with **zero score state** (state lives in `OngoingMatchService` on the original device only).
6. `markCompleted` reports success on a `204` even when RLS filtered the row out (0 rows updated). A non-authoritative device can therefore "complete" a match locally while the server row stays `live`.

**No schema rebuild is required.** Phase 2 can be delivered with additive migration(s), guards in 4 files, and reuse of the existing services. The main open questions are business-rule decisions, listed in §15.

---

## 1. How Quick Match and Schedule Match are differentiated

| Signal | Quick Match | Schedule Match | Where |
|---|---|---|---|
| `MatchSetupData.isQuickMatch` | `true` | `false` | `lib/features/match/match_setup_screen.dart:32,111,240` |
| Route extra `isQuickMatch` | passed on every hop | absent/false | `lib/routes/app_router.dart:211` |
| Setup entry | Home → `/create-team` (`isQuickMatch: true`) → `/match-setup` | Home → create/schedule → `/match-setup` | `home_screen.dart:286-444`; `create_team_screen.dart:387-425` |
| Persistence at setup | `QuickMatchStorage.saveQuickMatch` only | `pendingMatchesProvider.addOrUpdateMatch` | `match_setup_screen.dart:410-417` |
| Toss persistence | skipped | `addOrUpdateMatch` | `toss_screen.dart:130-134` |
| Toss handover request | skipped | sent when scorer ≠ creator | `toss_screen.dart:141-144` |
| `markLive` | skipped | required, server-verified | `opening_lineup_screen.dart:124-155` |
| Captain required in lineup | no | yes | `opening_lineup_screen.dart:90-102` |
| Server-authority re-check | bypassed | enforced | `scoring_screen.dart:504-559` |
| Live push | signed-in only; creates the row | expected, row already exists | `scoring_screen.dart:288-312`; `live_scoring_service.dart:147-199` |
| Completion sync | signed-in only | signed-in only | `sync_manager.dart:331-341` |

**Shared components (must remain backward compatible):** `MatchSetupData`, `OpeningLineupScreen`, `ScoringScreen`, `InningsBreakScreen`, `PendingMatchesNotifier`, `MatchLifecycleService`, `LiveScoringService`, `InsforgeSyncService`, `SyncManager`, `ScorerHandoverService`, `ScorerNotificationProvider`, `MatchResultPopupNotifier`, `pending_matches` and `matches` tables, and their RLS.

**Safe scoping rule for Phase 2:** every change must be either (a) gated by `isQuickMatch`, or (b) a strictly additive, behaviour-preserving enhancement of a shared service. No change may alter the scheduled-match branch of `_proceedToScore`, `markLive`, or the handover RPC semantics.

---

## 2. Flutter inspection — 18 required items

Legend: **DB** = database/server operations; **Gap** = missing or incomplete logic.

### 2.1 Quick Match entry point
- **File:** `lib/features/home/home_screen.dart`
- **Symbol:** `_handleQuickMatchTap` (286-446); also `lib/features/home/scorely_shell.dart:166,360`
- **Logic:** first tap shows a one-time warning (`seen_quick_match_warning`), then pushes `/create-team` with `extra: {'isQuickMatch': true}`.
- **DB:** none.
- **Validation:** warning acknowledgement only.
- **Gap:** none for entry; no lifecycle record is created here (by design today).

### 2.2 Match creation and setup
- **File:** `lib/features/match/create_team_screen.dart` → `lib/features/match/match_setup_screen.dart`
- **Symbols:** `_proceedToMatchSetup` (`create_team_screen.dart:387-425`); `_startMatch` (`match_setup_screen.dart:348`); quick branch 410-413.
- **Logic:** squads/captains are validated locally; `MatchSetupData` is built with `isQuickMatch: true`; quick branch sets `id: Uuid().v4()`, saves to `QuickMatchStorage`, then `proceedToToss`.
- **DB:** `QuickMatchStorage` → SharedPreferences key `quick_matches_history` (`lib/features/match/providers/quick_match_storage.dart`). **No `pending_matches` write.**
- **Validation:** both teams non-empty; captain on both sides (`create_team_screen.dart:391-409`).
- **Gap:** **G1** — no server `pending` row, so the match is invisible to other devices and to the Home "Pending" section until scoring starts.

### 2.3 Start Match button
- **File:** `lib/features/match/match_setup_screen.dart`
- **Symbol:** `_startMatch` (348); button at 541-557 (`START MATCH` vs `SCHEDULE MATCH`).
- **Logic:** quick path never awaits the network; scheduled path awaits `addOrUpdateMatch` (417).
- **DB:** local only for quick.
- **Gap:** none functionally; contributes to G1.

### 2.4 Proceed to Toss
- **File:** `lib/features/match/match_setup_screen.dart`
- **Symbol:** `proceedToToss(context, ref, data)` (413)
- **Logic:** navigates to `/toss` with the setup.
- **DB:** none.
- **Gap:** none.

### 2.5 Toss selection and result storage
- **File:** `lib/features/match/toss_screen.dart`
- **Symbols:** `_startScoring` (49-149); `_requestOpeningLineupHandover` (153+); guards at 130 and 141.
- **Logic:** official scorer is mandatory (`_officialScorer == null` → dialog, 50-55). `matchAppId` assigned (69-75). Duplicate live match by team names is detected (83-93). Toss **never** marks live (95-99). Writes `teamAScorerId/Name`, `activeScorerId`, `creatorProfileId` and adds the scorer to `playerProfileIds` (97-120).
- **DB:** quick → nothing (guard 130); scheduled → `addOrUpdateMatch`.
- **Validation:** scorer required; duplicate live match redirects to `/opening-lineup`.
- **Gap:** **G2** — for quick matches the selected "official scorer" is recorded locally but no request is sent (guard 141) and no server row exists, so selecting someone else as scorer has no effect on who actually scores. **G3** — `teamAScorerId` may be the literal `'scorer_myself'` (non-UUID).

### 2.6 Opening Lineup screen
- **File:** `lib/features/match/opening_lineup_screen.dart`
- **Symbols:** `_isReady` (90-102), `_proceedToScore` (104-190), `_selectPlayer` (213+), official scorer section (`lib/features/match/widgets/official_scorer_section.dart:56-73`).
- **Logic:** quick match skips the captain requirement; quick match skips the signed-in/scorer gate and `markLive` entirely (124-155); second-innings handover mode goes straight to `/scoring` (157-175).
- **DB:** scheduled → `markLive` (server-verified); quick → none.
- **Validation:** opening batters, bowler, keeper, official scorer required; captain required only for scheduled.
- **Gap:** **G1/G2** — quick match never performs a server transition, so the "only place a match becomes live" invariant is violated for quick matches.

### 2.7 Player selection and validation
- **File:** `lib/features/match/opening_lineup_screen.dart:213-248`; `lib/features/teams/team_squad_screen.dart:62-80`
- **Logic:** quick match builds an ephemeral `TeamData(id: 'quick_match_team')` from the setup; single-selection returns a `TeamMember`.
- **DB:** none (no team/player rows written until match completion).
- **Validation:** `signedUpOnly: true` for official scorer selection (`official_scorer_section.dart:65`); players may be unsigned.
- **Gap:** **G3** — quick-match `TeamMember.id` is regenerated (`Uuid().v4()` in `team_squad_screen.dart:74`), while `profileId` may be null for unsigned players; scorer identity handling relies on string sentinels.

### 2.8 Scorer selection and assignment (toss / lineup)
- **Files:** `toss_screen.dart:50-55,104-120`; `official_scorer_section.dart:56-73`; `opening_lineup_screen.dart:116-155`
- **Logic:** guest → forced "Myself" with a snackbar (`official_scorer_section.dart:40-54`); signed-in → can pick another signed-up player; selection is stored in `teamAScorerId`/`activeScorerId`.
- **DB:** quick → local only. Scheduled → `pending_matches.active_scorer_id` via `markLive`.
- **Validation:** scorer mandatory; signed-up only for non-self selection.
- **Gap:** **G2/G4** — no server record means "selected scorer" is decorative for quick matches; the device that holds the setup can always score.

### 2.9 Proceed to Score
- **File:** `lib/features/match/opening_lineup_screen.dart`
- **Symbol:** `_proceedToScore` (104)
- **Logic:** builds `OpeningLineupResult`, then scheduled-only authority gate + `markLive` (124-155); navigates to `/scoring` (or directly in handover mode).
- **DB:** `markLive` for scheduled; none for quick.
- **Gap:** **G1/G2**.

### 2.10 Scoring screen and scoring permissions
- **File:** `lib/features/scoring/scoring_screen.dart`
- **Symbols:** `initState` (143-316), `_liveService.init` (296-312), `_verifyActiveScorerAuthority` (504-559), `_pushLiveUpdate` (619+), `_isViewOnly` gate (620, 1038, 1661), `_commitState` (328-355).
- **Logic:** signed-in + non-empty id → `LiveScoringService.init(...)` then `_verifyActiveScorerAuthority`. For quick matches that method sets `_authorityVerified = true` and returns, pushing a live update if signed in. Every ball commits local state and pushes a blob.
- **DB:** upsert `pending_matches` (`live_scoring_service.dart:147-199`) with `status: live`, `created_by_profile_id`, `active_scorer_id`, `player_profile_ids`, `match_data`, `live_score_data`.
- **Validation:** `_isViewOnly` blocks scoring, ending and pushes — but for quick matches it is only ever set by the in-memory handover path.
- **Gap:** **G4** — no server-authoritative lock for quick matches. **G5** — if `active_scorer_id` is a different user than the authenticated device, the first insert succeeds (creator branch) but later updates are filtered by the UPDATE policy, returning `204` with 0 rows, which the app treats as success.

### 2.11 First innings completion
- **File:** `lib/features/scoring/scoring_screen.dart`
- **Symbol:** innings-end flow → `/innings-break` with `InningsBreakData`.
- **Logic:** local state is snapshotted to `OngoingMatchService` (`saveSnapshot`, 396) under `ongoing_match_v1_<matchId>`; navigation to `InningsBreakScreen`.
- **DB:** local SharedPreferences only.
- **Gap:** none for 1st innings; the snapshot is **device-local**, which becomes G7 at handover.

### 2.12 Second innings initialization
- **File:** `lib/features/scoring/innings_break_screen.dart` (`_handleContinueAsScorer`, 399+) → `opening_lineup_screen.dart` (`isSecondInnings: true`) → `scoring_screen.dart`
- **Logic:** same device restores state from `OngoingMatchService` (`_restoreOngoingMatchIfAny`, 286) and continues.
- **DB:** local.
- **Gap:** **G7** — no hydration from server `live_score_data`; a different device cannot continue.

### 2.13 Second innings scorer handover
- **Files/Symbols:**
  - `innings_break_screen.dart` `_handleAssignScorer` (216-395), request at **325-353**, UI row at **616-643**
  - `scoring_screen.dart` `_handleChangeScorer` (2435-2518), request at **2474**, menu item at **2564-2590**
  - `toss_screen.dart:141` (correctly guarded)
  - Recipient: `lib/providers/scorer_notification_provider.dart:87-140`, `lib/features/home/widgets/in_app_requests_sheet.dart:52-110`
- **Logic:** guest → forced "Myself" path; signed-in → `ScorerHandoverService.createRequest(...)` with `payload.type = 'innings_break_handover'` and the full `setupData`; waiting sheet; recipient accepts → RPC `accept_scorer_assignment` → navigates to `/opening-lineup` with `isHandoverMode: true`.
- **DB:** insert `scorer_assignment_requests`; RPC updates `pending_matches.active_scorer_id` and `live_score_data.scorer_id` (migration `20261112090000`, lines 327-350).
- **Validation:** none for `isQuickMatch` on either entry point or on the recipient routing.
- **Gap:** **G5/G6/G7** — see §6. This is the single largest correctness problem.

### 2.14 Match completion workflow
- **File:** `lib/features/scoring/scoring_screen.dart`
- **Symbol:** `_endMatch` (1660-1990)
- **Logic:** builds result text; writes teams/players/match/balls into local Drift in a transaction (`isQuickMatch`, `isCompleted: true`, `syncPending: isAuth`); prunes storage; refreshes providers; `syncManager.onMatchCompleted(...)` (1899-1904) for signed-in only; clears the ongoing snapshot (1911); `_liveService.markMatchCompleted(...)` (1917); `pendingMatchesProvider.markCompleted(...)` (1925) and suppresses the popup for the scorer (1931).
- **DB:** Drift `matches`/`teams`/`players`/`ballEvents`; `pending_matches` PATCH to `completed`; `matches` upsert via `InsforgeSyncService.trySyncMatch` with `status: completed`.
- **Validation:** `if (_isViewOnly) return;` (1661) — ineffective for quick matches.
- **Gap:** **G8** — `MatchLifecycleService.markCompleted` treats `204` as success without verifying the row (`match_lifecycle_service.dart:276-287`), so a non-authoritative device can complete locally while the server row stays `live`. **G9** — guest completion still calls `markCompleted`, which PATCHes with anon headers, fails RLS and enqueues an unflushable completion (`_enqueueCompletion`, 173-196).

### 2.15 Result popup
- **File:** `lib/providers/match_result_popup_provider.dart`
- **Symbol:** `checkNow` (73-129); query at 81-93.
- **Logic:** polls `pending_matches` where `status=eq.completed`, `completed_at not null`, and caller is creator/active scorer/associated player; dedupes via `seen_completed_match_ids`.
- **DB:** read-only.
- **Validation:** signed-in only (`if (!profile.isLoggedIn ...) return;` line 75).
- **Gap:** **G10** — guest quick matches never show the popup (no server row). Signed-in quick matches do, provided the row exists and the association columns are populated. `completed_at` is the device clock.

### 2.16 Matches section
- **File:** `lib/features/home/home_screen.dart` (sections built from `liveMatchInsforgeProvider` and `pendingMatchesProvider`, 85-89)
- **Logic:** live cards come from `pending_matches` + `matches` where `status=eq.live` (`lib/features/home/providers/live_match_insforge_provider.dart:60-67`); pending cards from `pending_matches` with `status in (pending, live)` filtered to the association (`pending_matches_provider.dart:47-63`).
- **DB:** server read.
- **Gap:** **G1** — quick matches never appear as pending; **G10** — guests never appear at all.

### 2.17 Recent Matches
- **Files:** `lib/providers/history_provider.dart`, `lib/features/history/history_screen.dart`, `lib/services/sync_manager.dart:100-135`
- **Logic:** local Drift `matches` (all completed local matches, quick included) drives Recent Matches; signed-in devices also pull server rows via `pullCompletedMatchesFromRemote` using `creator_id/active_scorer_id/player_profile_ids`.
- **DB:** Drift + `matches` read.
- **Gap:** **G10** — guest quick matches are device-local only; they disappear if the device is reset and never appear on another device.

### 2.18 Resume Match
- **File:** `lib/features/home/home_screen.dart:995-1029`
- **Logic:** only for `isScorer`; looks up `pendingMatchesProvider` by id; if absent, fabricates a `MatchSetupData` with **empty player lists** and hardcoded `overs: 20`, `ballType: 'Tennis'`, then pushes `/scoring`.
- **DB:** `pendingMatchesProvider` (server + prefs cache).
- **Validation:** none on the fallback.
- **Gap:** **G11** — no resume path for a guest quick match, and no resume for a quick match that has not yet entered scoring. The fallback object is structurally valid but semantically wrong (empty squads), which risks corrupt scoring if used.

---

## 3. Database / InsForge audit

### 3.1 Relevant tables

| Table | Purpose | Key / relations | Notes |
|---|---|---|---|
| `pending_matches` | Live lifecycle + live score blob | `id UUID PK`; `created_by_profile_id`, `active_scorer_id` (no FK) | Holds `match_data`, `live_score_data`, `result_summary`, `winner`, `completed_at` |
| `matches` | Completed/synced match record | `id UUID PK`; `creator_id`, `active_scorer_id` | Status check from `initial_schema.sql`: `scheduled, live, completed, abandoned`; app writes only `completed` |
| `scorer_assignment_requests` | Handover workflow | `match_id` (FK dropped), `requested_by_user_id`, `requested_scorer_user_id`, `current_scorer_user_id` (FKs to profiles) | `status in (pending, accepted, declined, cancelled, expired)`, `expires_at`, `version`, `payload JSONB` |
| `innings` | Innings metadata | `match_id` FK | `active_scorer_id` added |
| `balls` / `ball_events` | Ball-by-ball | `match_id`, `innings_id` | Local Drift mirrors this as `ball_events` |
| `player_match_stats` | Aggregated player stats | `match_id`, `player_id` | Used by ratings/stats |
| `profiles` / `teams` / `players` | Identity + squads | `profiles.id → auth.users`; `players.profile_id` | `players.profile_id` is used by the handover RPC fallback |
| Notifications | Local notifications only | — | No notification table is used for handover; `notification_id` is a string column on requests |

### 3.2 `pending_matches.status` — the seven required checks

| # | Question | Finding |
|---|---|---|
| 1 | Pending only, or all lifecycle? | **All lifecycle.** Migration `20261112090000` creates/extends it as the lifecycle table; Home, live view, result popup and resume all read it. |
| 2 | Does `Status` already exist? | **Yes.** `status TEXT NOT NULL DEFAULT 'pending'` (migration lines 22, 76-78). |
| 3 | Existing values / naming | Canonical lowercase `pending`, `live`, `completed`, enforced by `pending_matches_status_check` (lines 82-87). Legacy values normalised: `draft/created/scheduled/waiting_for_*/ready_for_toss/setup → pending`; `in_progress/scoring/started → live`; `finished/complete/abandoned → completed` (lines 51-73). |
| 4 | Case sensitivity | **Yes.** `CHECK` is case-sensitive; the migration lowercases existing rows (51-53). Flutter also normalises via `MatchStatus.normalize` (`lib/models/match_status.dart:33-38`). |
| 5 | NULL / empty / other | Normalised to `pending` and `status` set `NOT NULL` (71-78). Unknown values become `pending`, never `live`. |
| 6 | Queries filtering on status | `pending_matches_provider.dart:61,71` (`in.(pending,live)`); `live_match_insforge_provider.dart:61` (`eq.live`); `match_result_popup_provider.dart:83-86` (`eq.completed` + `completed_at not null`); `sync_manager.dart` pulls completed from `matches`. |
| 7 | Policies | Association-based RLS, `TO authenticated`, detailed in §3.3. |

### 3.3 Final RLS state (effective)

`pending_matches` (migration `20261112090000`, 172-223):

- **SELECT** `TO authenticated` — `created_by_profile_id = auth.uid() OR active_scorer_id = auth.uid() OR player_profile_ids @> to_jsonb(auth.uid()::text)`.
- **INSERT** `TO authenticated` — `(created_by_profile_id = auth.uid() OR active_scorer_id = auth.uid()) AND (active_scorer_id IS NULL OR active_scorer_id = auth.uid() OR player_profile_ids @> to_jsonb(active_scorer_id::text))`.
- **UPDATE** `TO authenticated` — `USING (status <> 'completed' AND ((status='pending' AND created_by_profile_id = auth.uid()) OR active_scorer_id = auth.uid()))`; same expression as `WITH CHECK`.
- **DELETE** `TO authenticated` — `created_by_profile_id = auth.uid()`.

`matches` (migration `20261107153500`, 178-204):

- **SELECT** `TO public` — `deleted_at IS NULL` (**all matches readable by anyone**, including anon).
- **INSERT/UPDATE** `TO authenticated` — `creator_id = auth.uid() OR active_scorer_id = auth.uid()`.
- **DELETE** — creator only.

`scorer_assignment_requests`: hardened association-based policies `TO authenticated` in `20261107090000` / `20261107153500`; `20261107233000` grants `ALL` to `authenticated` **and `anon`** (grants alone do not bypass RLS, but the anon grant is unnecessary and should be revoked in a future migration).

`innings`, `balls`, `player_match_stats`: scorer/creator-scoped writes, public or association-scoped reads (see migrations). The RPCs are `SECURITY DEFINER`-style atomic operations and validate `auth.uid()` themselves (`accept_scorer_assignment`, lines 240-249, 306-325).

**Key consequence:** guests (anon) can never read or write `pending_matches` because every policy is `TO authenticated`. Any Quick Match server behaviour is therefore inherently signed-in-only unless RLS is changed.

### 3.4 Actual lifecycle flows today

**Scheduled Match**
```
setup -> pending_matches(pending)
toss   -> pending_matches(pending)
lineup -> markLive -> pending_matches(live)  [server-verified]
scoring-> live_score_data patches (active scorer only)
end    -> pending_matches(completed) + matches(completed)
```

**Quick Match (signed in)**
```
setup  -> SharedPreferences only
toss   -> SharedPreferences only
lineup -> no server call
scoring entry -> LiveScoringService upsert -> pending_matches(live)   <-- first server row
scoring -> live_score_data patches (RLS may silently drop them)
end    -> pending_matches(completed) + matches(completed)
```

**Quick Match (guest)**
```
everything local (SharedPreferences + Drift); no server row at any point
```

---

## 4. Security and authorization audit

| Control | Scheduled | Quick Match | Verdict |
|---|---|---|---|
| Creator identification | `created_by_profile_id` written from `creatorProfileId` or caller | same, but client-supplied | ⚠️ client-supplied on first insert |
| Associated player visibility | `player_profile_ids` populated from squads + scorer | same, but only when the live row is created | ⚠️ no row before scoring |
| Active scorer authorization | `markLive` verified by re-read; screen re-checks and locks view-only | bypassed (`scoring_screen.dart:505`) | ❌ no enforcement |
| Previous scorer revocation | server `active_scorer_id` + re-check on entry | RPC changes the server value, but the old device never re-checks | ❌ split-brain |
| Handover acceptance | atomic RPC, locks match then request, revokes competing requests | RPC works, but no quick-match UX guard | ⚠️ works, but wrong state |
| Match completion permission | UPDATE policy allows active scorer; `_endMatch` gated by view-only | view-only ineffective; `markCompleted` accepts 204 as success | ❌ false success |
| Unauthorized score modification | RLS UPDATE requires `active_scorer_id = auth.uid()` | RLS still blocks, but **silently** (0 rows / 204) and the app keeps scoring locally | ⚠️ server safe, client inconsistent |
| Creator spoofing on new rows | possible: `created_by_profile_id` is a client value; INSERT allows `active_scorer_id = auth.uid()` with any creator | same | ⚠️ medium |

**Important nuance:** for an upsert into an existing row, Postgres evaluates the INSERT policy for the proposed row and the UPDATE policy for the conflicting row. Because the UPDATE policy requires `active_scorer_id = auth.uid()`, a non-scorer cannot hijack an existing row's score. The residual issue is client-side false confidence, not a direct write bypass.

**Do not rely on UI hiding.** `_isViewOnly` is the only barrier in quick match and it is set from local memory, not from the server.

---

## 5. Gap analysis report (required table)

| Requirement | Existing implementation | Missing functionality | Recommended change |
|---|---|---|---|
| **Pending status** | Canonical `pending` exists in DB + `MatchStatus`; scheduled matches write it at setup/toss | Quick Match never writes a pending row; no Home pending card; no pre-live visibility | **Decision needed (§15 Q1).** Recommended: write a `pending` row at Toss for signed-in quick matches via the existing `PendingMatchesNotifier.addOrUpdateMatch`, reusing the scheduled path; keep guest matches local. |
| **Live status** | `markLive` server-verified for scheduled; quick match upserts `live` on scoring entry via `LiveScoringService` | Quick match "live" is a side effect of the first score push; no verified transition; `markLive` skipped; no guard against an unauthorised device becoming live | **Decision needed (§15 Q1/Q2).** Recommended: introduce a single `startQuickMatch` path that (a) ensures the row exists, (b) sets `active_scorer_id` to the authenticated scorer, (c) verifies the write, then initialises `LiveScoringService`. Reuse `MatchLifecycleService.markLive` semantics; do not duplicate it. |
| **Completed status** | `markCompleted` + `markMatchCompleted` + `InsforgeSyncService` writes `completed`, `result_summary`, `winner`, `completed_at` | No verification of the completion write; `204` on 0 rows is treated as success; guest completions enqueue forever; no idempotency guard | Add a verified completion path (re-read the row, or an RPC returning the row). Skip server completion entirely for guests. Add a `completed_at` idempotency check. |
| **Creator authorization** | `creatorProfileId` captured at toss; `created_by_profile_id` written on insert; RLS checks it | Client supplies the creator; no FK; no freeze on update; quick match creator may differ from the scoring device | Freeze `created_by_profile_id` with a `BEFORE UPDATE` trigger; reject inserts where the creator is neither the caller nor a known associated profile (or document the handover-recipient exception). Never infer creator from a client payload on update. |
| **Associated player visibility** | `player_profile_ids` built from squads + scorer; RLS `@>` check; Home queries use the association filter | Quick match rows only exist after scoring; unsigned players are invisible; `player_profile_ids` is rewritten on every live push | Keep the mechanism. Populate at the pending stage (if Q1 = yes) and make the live push merge, not replace, the list. Add a GIN index (already present, line 167). |
| **Active scorer authorization** | Scheduled: server `active_scorer_id` + re-read + view-only lock. Quick: bypassed | No quick-match authority check; old device keeps scoring locally; non-scorer can open `/scoring` and diverge | Remove the quick-match early return in `_verifyActiveScorerAuthority`; for quick matches, if no row exists yet, create/verify it first. Keep an offline fallback only when the device is the recorded scorer and the network is unavailable (explicit, time-boxed). |
| **Scorer handover** | Full scheduled handover: request → notification → accept RPC → new active scorer → 2nd innings lineup | Quick match: two unguarded entry points; recipient device has no state; old device never re-verifies; `teamBScorer*` local-only | **Decision needed (§15 Q4/Q5).** Recommended for Phase 2: disable handover UI for quick matches (guard both entry points + reject quick payloads on receipt), and keep "Myself" as the only quick-match path. If handover is required, implement state hydration from `live_score_data` and server re-verification before enabling the UI. |
| **RLS security** | Association-based `pending_matches` policies; scorer-scoped `matches` writes; atomic handover RPCs | `matches` SELECT is public; `anon` grant on `scorer_assignment_requests`; creator not frozen; completed rows can be re-opened by a creator while `status='pending'` only (safe) but no status-regression guard | Additive migration: revoke the anon grant, freeze immutable columns, add a status-transition trigger (`pending→live→completed` only, no regression), consider restricting `matches` SELECT to authenticated. Do not drop existing policies without review. |
| **Result popup** | `matchResultPopupProvider` polls completed rows with `completed_at`, association-filtered, deduped | Guests never see it; no popup if the row/association is missing; device-clock timestamp | Show a local popup for guest quick matches from local Drift; keep the server popup for signed-in. Consider server-side `completed_at` (RPC) to avoid clock skew. |
| **Recent Matches** | Local Drift `matches` for all completed matches; server pull for signed-in | Guests are device-only; no server row means no cross-device recent match; `matches` rows are public-readable | Keep local-first. For signed-in quick matches, ensure the `matches` upsert always succeeds (it currently depends on `syncPending`/`isAuth`). Document guest limitation or add an explicit "sign in to save to cloud" prompt. |

---

## 6. Confirmed defects (implementation checklist)

| ID | Severity | Defect | Evidence | Minimal fix |
|---|---|---|---|---|
| **G1** | High | Quick Match has no server `pending` phase; invisible until scoring starts | `match_setup_screen.dart:410-413`; `toss_screen.dart:130-134`; `opening_lineup_screen.dart:124` | If approved, write a pending row at toss for signed-in users (reuse `addOrUpdateMatch`), or accept local-only pending and document it. |
| **G2** | High | `markLive` skipped for quick match; "live" happens as a side effect of the first score push | `opening_lineup_screen.dart:124-155`; `scoring_screen.dart:296-312` | Route quick matches through the same verified transition (ensure row → verify active scorer → live), then start `LiveScoringService`. |
| **G3** | Medium | Non-UUID scorer sentinel `'scorer_myself'` can reach UUID columns | `opening_lineup_screen.dart:80`; `live_scoring_service.dart:159-160`; `scoring_screen.dart:151-158` | Never send sentinels to server columns; map to `null`/caller id. |
| **G4** | High | No server-authoritative scoring lock for quick matches | `scoring_screen.dart:505-513` | Remove the early return; verify authority for quick matches too, with an explicit offline fallback. |
| **G5** | Critical | Quick-match handover changes server `active_scorer_id` while the old device stays writable; recipient has no state | `innings_break_screen.dart:325-353`; `scoring_screen.dart:2474`; `migrations/20261112090000:327-350` | Disable handover for quick matches (guard both entry points + recipient routing), or implement full state hydration and re-verification. |
| **G6** | High | Live "Change Scorer" menu item is unguarded | `scoring_screen.dart:2564-2590` | Gate the `ListTile` and `_handleChangeScorer` on `!_setup.isQuickMatch`. |
| **G7** | High | Recipient device starts 2nd innings with zero state; `live_score_data` is never read back | `ongoing_match_service.dart:15-46`; `scoring_screen.dart:286` | If handover stays: hydrate from `pending_matches.live_score_data` (and innings summaries) before scoring. |
| **G8** | High | `markCompleted` treats `204`/0 rows as success; no verification | `match_lifecycle_service.dart:147-168,276-287` | Re-read the row (like `markLive`) or use an RPC that returns the updated row. |
| **G9** | Low | Guest completion enqueues an unflushable completion | `match_lifecycle_service.dart:153-196`; `scoring_screen.dart:1925` | Skip `markCompleted` when not signed in; clear any queued entry for the id. |
| **G10** | Medium | Guest quick matches have no popup / no live card / no cross-device recent match | `match_result_popup_provider.dart:75`; `live_match_insforge_provider.dart:56` | Local result popup for guests; document cloud limitation. |
| **G11** | Medium | No resume for guest/in-progress quick matches; fallback setup has empty squads | `home_screen.dart:995-1029` | Add a local ongoing-match resume entry (from `OngoingMatchService`/`QuickMatchStorage`) and remove the degenerate fallback or populate it from the snapshot. |
| **G12** | Low | `teamBScorer*` written locally for quick matches but never persisted server-side | `scoring_screen.dart:241-246`; `innings_break_screen.dart:226-228` | Do not write `teamBScorer*` when `isQuickMatch` unless handover is actually implemented. |

---

## 7. Existing schema and proposed schema changes

### 7.1 Existing (effective, no changes required)

`pending_matches`: `id, status, match_data, live_score_data, created_by_profile_id, active_scorer_id, player_profile_ids, result_summary, winner, completed_at, created_at, updated_at`.

`matches`: `id, creator_id, active_scorer_id, player_profile_ids, status ('scheduled','live','completed','abandoned'), match_result_summary, deleted_at, ...`.

`scorer_assignment_requests`: `id, match_id, innings_id, requested_by_user_id, requested_scorer_user_id, current_scorer_user_id, status, response_reason, notification_id, version, created_at, expires_at, responded_at, requested_by_name, requested_scorer_name, requested_scorer_email, match_title, payload`.

### 7.2 Proposed changes (additive only — no drops, no renames)

> Only apply what the answers to §15 require. None of these are needed to fix G4/G6/G8/G9.

1. **`pending_matches.is_quick_match BOOLEAN NOT NULL DEFAULT false`** — makes quick-match rows filterable/indexable without parsing `match_data`. Backfill: `(match_data->>'isQuickMatch')::boolean` guarded by a regex/`jsonb_typeof` check.
2. **`pending_matches.completed_by_profile_id UUID`** — audit trail for who completed; populated by the completion path. Additive, nullable.
3. **Status-transition trigger** — reject `completed → live/pending`, and reject `live → pending`. Enforces the lifecycle independently of clients.
4. **Immutability trigger** — reject changes to `id` and `created_by_profile_id` on UPDATE; allow `active_scorer_id` changes only when `status <> 'completed'`.
5. **Optional RPC `start_match(p_match_id UUID)`** — verifies caller is creator or recorded scorer, ensures the row exists, sets `status='live'`, `active_scorer_id=auth.uid()`, returns the row. Replaces the client-side "upsert as live" for both flows (scheduled can keep its current path initially).
6. **Optional RPC `complete_match(p_match_id UUID, p_result_summary TEXT, p_winner TEXT)`** — verifies caller is creator/active scorer, requires `status <> 'completed'` (idempotent), sets `completed_at = NOW()` server-side, returns the row. Fixes G8 and clock skew.
7. **Index** — `CREATE INDEX IF NOT EXISTS idx_pending_matches_status_updated ON public.pending_matches (status, updated_at DESC);` for the live/pending lists.
8. **Revoke** `anon` privileges on `scorer_assignment_requests` (from `20261107233000`).
9. **Optional** `matches.is_quick_match BOOLEAN DEFAULT false` for server-side analytics (not needed for correctness).

**Explicitly not recommended:** renaming `status`, creating a new `matches_v2`, a separate quick-match table, a parallel scorer-assignment table, or a new notification table.

---

## 8. Existing files that need modification

| File | Change | Guard |
|---|---|---|
| `lib/features/match/opening_lineup_screen.dart` | Quick-match start path: ensure row + verified live transition (or keep skip if Q1/Q2 = no) | `isQuickMatch` branch only |
| `lib/features/match/toss_screen.dart` | Optionally persist the pending quick match; map `'scorer_myself'` to `null` | `isQuickMatch` branch only |
| `lib/features/scoring/scoring_screen.dart` | Remove quick bypass in `_verifyActiveScorerAuthority`; guard `_handleChangeScorer` and the "Change Scorer" tile; verified completion; skip completion for guests; optional state hydration | `isQuickMatch` checks |
| `lib/features/scoring/innings_break_screen.dart` | Guard `_handleAssignScorer` for quick match; stop writing `teamBScorer*` for quick | `setup.isQuickMatch` |
| `lib/features/home/home_screen.dart` | Local resume entry for guest/in-progress quick matches; fix degenerate fallback | new local path only |
| `lib/providers/scorer_notification_provider.dart` | Reject quick-match handover payloads if handover is disabled | payload `setupData.isQuickMatch` |
| `lib/features/home/widgets/in_app_requests_sheet.dart` | Same rejection | payload check |
| `lib/services/match_lifecycle_service.dart` | Verified completion + server timestamp + guest guard | additive, all callers |
| `lib/services/live_scoring_service.dart` | Never send non-UUID scorer ids; optionally merge `player_profile_ids`; optionally hydrate from server | additive |
| `lib/features/match/providers/pending_matches_provider.dart` | No structural change expected; ensure quick rows round-trip `isQuickMatch` if a column is added | additive |
| `lib/services/sync_manager.dart` | Optional: include quick matches in the completed pull consistently | additive |
| `lib/features/match/providers/quick_match_storage.dart` | Optional: expose "latest ongoing" for resume | additive |

**Do not touch:** the scheduled branch of `_proceedToScore`, `markLive` semantics, the handover RPCs' scheduled behaviour, scoring calculations, or the Drift schema unless a new local field is unavoidable.

---

## 9. New files required

Likely **none**. Optional, only if it keeps `scoring_screen.dart` from growing:

| Proposed file | Purpose | Replaces |
|---|---|---|
| `lib/services/quick_match_lifecycle_service.dart` | Thin wrapper: `ensurePending`, `start`, `complete` for quick matches, delegating to `MatchLifecycleService`/`PendingMatchesNotifier` | Inline quick branches in screens |
| `lib/features/scoring/quick_match_state_hydrator.dart` | Reads `pending_matches.live_score_data` and rebuilds `MatchState` (only if handover is implemented) | Nothing today |
| `migrations/2026XXXXXXXXXX_quick_match_lifecycle.sql` | Additive schema/trigger/RPC changes from §7.2 | — |

Prefer extending existing services over creating a parallel lifecycle layer.

---

## 10. Existing functions that can be reused

| Function | Location | Reuse for |
|---|---|---|
| `MatchLifecycleService.markLive` | `lib/services/match_lifecycle_service.dart:70-125` | Verified `pending → live` (already re-reads and verifies) |
| `MatchLifecycleService.markCompleted` | `:132-169` | Completion (needs verification added) |
| `MatchLifecycleService.fetchRow` / `fetchActiveScorerId` / `fetchStatus` / `isActiveScorer` | `:23-64` | Authority checks, resume, popup |
| `MatchLifecycleService.flushPendingCompletions` | `:231-274` | Offline completion retry (skip guests) |
| `PendingMatchesNotifier.addOrUpdateMatch` | `lib/features/match/providers/pending_matches_provider.dart:150-228` | Creating the pending row (already handles local + server + dedup) |
| `PendingMatchesNotifier.markLive` / `markCompleted` | `:244-286` | Local state + server transition |
| `PendingMatchesNotifier._associationFilter` | `:47-50` | Consistent RLS-aligned queries |
| `LiveScoringService.init` / `pushLiveUpdate` / `markMatchCompleted` / `setActiveScorer` | `lib/services/live_scoring_service.dart:32-118` | Live blob transport, offline queue |
| `InsforgeSyncService.trySyncMatch` | `lib/services/insforge_sync_service.dart:21+` | Completed match upsert with scorer attribution |
| `SyncManager.onMatchCompleted` / `pullCompletedMatchesFromRemote` | `lib/services/sync_manager.dart:100-135,331-363` | Recent Matches / stats |
| `ScorerHandoverService.createRequest` / `getPendingRequestsForUser` | `lib/services/scorer_handover_service.dart` | Handover (scheduled; disable for quick) |
| `OngoingMatchService.saveSnapshot` / `getSnapshot` / `clearSnapshot` | `lib/services/ongoing_match_service.dart` | Local resume; **not** cross-device |
| `MatchStatus.normalize` / `isPending` / `isLive` / `isCompleted` | `lib/models/match_status.dart` | All status comparisons |
| `accept_scorer_assignment` RPC | `migrations/20261112090000:228-380` | Atomic handover (do not reimplement) |
| `MatchResultPopupNotifier.markResultSeen` | `lib/providers/match_result_popup_provider.dart:55-71` | Popup dedupe |

---

## 11. Potential impact on Schedule Match

| Shared area | Risk | Mitigation |
|---|---|---|
| `_verifyActiveScorerAuthority` | Removing the quick early-return must not alter the scheduled branch | Keep the scheduled code path byte-for-byte; add an `if (isQuickMatch) { ... }` branch that performs the same checks |
| `markLive` | Adding an "ensure row exists" step could change scheduled behaviour | Do not modify `markLive`; add a separate `ensureRow`/`startQuickMatch` that calls it |
| `markCompleted` | Verification/`completed_by` additions affect both | Additive fields only; scheduled already has a row, so re-read succeeds |
| `pending_matches` schema | New columns/triggers affect both | All new columns nullable/defaulted; triggers must allow the scheduled transitions (`pending→live→completed`) |
| RLS | Tightening `matches` SELECT affects public sharing | Treat as a separate, explicitly approved change; do not bundle with Quick Match |
| `InningsBreakScreen` | Adding a quick guard must not remove the scheduled handover row | Hide only when `isQuickMatch`; keep `_handleContinueAsScorer` for both |
| `ScoringScreen` menu | Hiding "Change Scorer" for quick matches only | Condition on `!_setup.isQuickMatch`; scheduled menu unchanged |
| `LiveScoringService` | Scorer-id sanitisation could affect scheduled handovers | Sanitise only non-UUID sentinels; scheduled ids are UUIDs |
| Result popup / Recent Matches | Local guest popup must not duplicate the server popup | Dedupe by match id via `seen_completed_match_ids` |
| Toss | Adding a quick pending write changes what other devices see | Gate on `isQuickMatch && signed-in`; scheduled path untouched |

---

## 12. Migration requirements

1. **New additive migration** (timestamped after `20261112090000`), containing only what §15 approves:
   - `is_quick_match` / `completed_by_profile_id` columns + backfill (guarded casts).
   - Status-transition and immutability triggers.
   - Optional `start_match` / `complete_match` RPCs with `GRANT EXECUTE TO authenticated`.
   - Index on `(status, updated_at)`.
   - `REVOKE ALL ON public.scorer_assignment_requests FROM anon;`
2. **No destructive statements.** No `DROP COLUMN`, no renames, no policy drops without an immediate `CREATE POLICY` replacement in the same transaction.
3. **RLS must be re-verified after the migration** with a signed-in creator, active scorer, associated player and unrelated user.
4. **Backward compatibility:** old app builds must keep working. New columns must be nullable/defaulted; new RPCs optional; no client may be required to send a new field.
5. **Rollback plan:** the migration should be reversible by dropping only the newly added objects; no data rewrite of `status` is needed (already normalised).
6. **Local Drift:** no migration expected. If a new local field is added (e.g. `completedByProfileId`), bump the Drift schema version and add a migration; avoid it if possible.

---

## 13. Risks

### 13.1 Security
- **Client-supplied creator** on the first insert can misattribute a new quick match. Freeze on update and validate on insert.
- **Public `matches` SELECT** exposes every completed match (including quick matches) to any client, including anon. Consider restricting to authenticated + association; needs product approval because it may break public scorecards.
- **Anon grant** on `scorer_assignment_requests` is unnecessary; revoke.
- **Silent RLS failures** (`204` on 0 rows) make unauthorised writes look successful. Always verify writes that change authority or lifecycle.
- **Guest device is fully trusted locally**; this is acceptable for an offline-first product but must be stated, not implied.

### 13.2 Concurrency
- Two devices scoring the same quick match: RLS keeps the server consistent, but both UIs diverge. Need a single authoritative scorer + re-check on resume/focus.
- Handover race: old scorer submits a ball while the recipient accepts. The RPC locks the match row, but the old client's next PATCH is silently dropped. Add a "you are no longer the scorer" detection on the next write (re-read on failure or periodic re-check).
- Double completion: two devices call `markCompleted`. Idempotency via `status <> 'completed'` in an RPC; client-side, check `completed_at` before writing.
- Upsert vs. update: the first live push creates the row; if two devices race, the `ON CONFLICT DO UPDATE` path requires the UPDATE policy, so the loser cannot overwrite. Verify the returned representation to detect the loss.
- Offline queues: `LiveScoringService` keeps only the latest blob per match; `flushPendingCompletions` is bounded at 50. Ensure a stale blob from a revoked scorer is discarded, not replayed.

### 13.3 Backward compatibility
- Existing quick matches in `quick_matches_history` and local Drift must remain readable; do not change `MatchSetupData` JSON keys.
- Existing `pending_matches` rows may have `created_by_profile_id = NULL` or non-UUID scorer text; treat them as legacy and do not crash.
- Older builds will not send `is_quick_match`; the column must default to `false` and queries must not depend on it exclusively.
- The scheduled flow must keep working if the new RPCs are unavailable (offline/first-run). Feature-detect and fall back.
- `'scorer_myself'` may exist in stored setups; sanitise at the boundary, not by rewriting stored data.

---

## 14. Testing scenarios

| # | Scenario | Expected |
|---|---|---|
| 1 | Guest creates a quick match, scores, completes | Fully local; no server calls; local result screen + local recent match; no popup loop; no unflushable queue |
| 2 | Signed-in creator scores own quick match | `pending_matches` row created at the approved point; status transitions `pending→live→completed`; `active_scorer_id = creator`; live card visible on a second signed-in device |
| 3 | Signed-in creator selects another signed-in player as scorer, then scores on the creator's device | Either blocked with a clear message, or `active_scorer_id` is set to the actual device user — never a silent 0-row update |
| 4 | Associated player (not scorer) opens `/scoring` for a live quick match | View-only; no pushes; clear "not the scorer" state |
| 5 | Previous scorer after a handover tries to score | Blocked on next write; UI flips to view-only after re-check |
| 6 | Innings break on a signed-in quick match | Handover row hidden/disabled (if approved); "Myself" continues to 2nd innings with state intact |
| 7 | Live "Change Scorer" on a quick match | Hidden/disabled; no request row created; no notification sent |
| 8 | Recipient receives a stale quick-match handover request | Ignored/rejected; no navigation into a broken 2nd innings |
| 9 | Two devices score simultaneously | Server accepts only the active scorer; the other device detects and stops |
| 10 | Complete the match twice (double tap / retry) | Idempotent; one `completed_at`; no duplicate recent match |
| 11 | Complete while offline (signed-in) | Queued; flushed on reconnect; popup appears once |
| 12 | Complete while offline (guest) | No queue entry; local completion only |
| 13 | Resume a signed-in quick match after app kill | Full setup + score restored (local snapshot and/or server row) |
| 14 | Resume a guest quick match after app kill | Restored from local snapshot; no server dependency |
| 15 | Second device views a live quick match | Live card with correct score, association-based visibility only |
| 16 | Unrelated signed-in user queries `pending_matches` | No rows (RLS) |
| 17 | Anon queries `pending_matches` / `scorer_assignment_requests` | No rows / denied |
| 18 | Legacy row with `status = 'in_progress'` / `'finished'` | Normalised to `live` / `completed`; no crash |
| 19 | Legacy row with non-UUID `active_scorer_id` text | Ignored/sanitised; no UUID cast error |
| 20 | Scheduled match full flow (regression) | Unchanged: pending → live via lineup → handover → completed |
| 21 | Scheduled handover (regression) | Request → accept RPC → new scorer → 2nd innings; old scorer locked out |
| 22 | Result popup for creator/scorer/player | Shown once per match per device |
| 23 | Recent Matches after completion | Present locally; present cross-device for signed-in |
| 24 | `matches` upsert failure | Local match still saved; retried by sync manager; no data loss |

---

## 15. Clarifications required before implementation

These decisions change the implementation materially. Please answer before Phase 2.

1. **Should a signed-in Quick Match write a `pending_matches` row at Toss (status `pending`), or stay local until scoring starts?**
   - (a) Write at Toss (recommended): Home pending card, cross-device visibility, resume before scoring.
   - (b) Keep local until scoring: minimal change, but no pending phase.

2. **Should Quick Match use the same verified `pending → live` transition as Schedule Match?**
   - Recommended yes: ensure row → verify active scorer → `live` → start live pushes. This is the only way to make `active_scorer_id` meaningful for quick matches.

3. **Guest (not signed in) behaviour:** is a fully offline quick match acceptable?
   - Recommended: yes, offline-only, with handover UI hidden and a local result popup. Confirm that guests should never be prompted to sign in mid-match.

4. **Scorer handover in Quick Match:** disable it, or implement it properly?
   - (a) Disable (recommended for Phase 2): guard both entry points, reject quick payloads, keep "Myself".
   - (b) Implement: requires server state hydration, re-verification, and a UX decision for the old device.

5. **If handover is implemented:** must the recipient device continue the 2nd innings from the server state (`live_score_data` + innings summary), or is same-device handover only acceptable? Cross-device continuation is currently impossible without new hydration code.

6. **Who owns a Quick Match?** Today `created_by_profile_id` = creator and `active_scorer_id` = selected scorer. For quick matches the creator can select another scorer at toss but no request is sent. Should quick matches force `active_scorer_id` = the device user, or support a real pre-live handover?

7. **Who may complete or abandon a match?** Active scorer only, creator too, or either? Should an abandoned match be `completed` with `winner = 'Abandoned'` (current behaviour) or a distinct status (not recommended: the DB constraint only allows three values)?

8. **What should happen when the scoring device is not `active_scorer_id`?** Options: block with an explicit message; auto-claim the scorer role on first score (dangerous); or allow offline scoring and reconcile later (current silent behaviour — not recommended).

9. **Result popup for guests:** local popup from Drift (recommended), or no popup for guests?

10. **Completed quick matches:** keep the `pending_matches` row forever (current), delete it after syncing to `matches`, or archive it? Retention affects the live/result queries and storage.

11. **Server timestamps:** should `completed_at` be set by the server (RPC) instead of the device clock? Recommended yes.

12. **Concurrency model for ball updates:** is last-write-wins acceptable, or do you want optimistic concurrency (a `version` column + conditional PATCH)? The latter is safer but touches every push.

13. **Public visibility of `matches`:** keep public SELECT (current) or restrict to authenticated + association? Restricting is safer but may break shared scorecards.

14. **`scorer_assignment_requests` anon grant:** confirm it can be revoked.

15. **Resume UX:** should the Home "Pending" section include local guest quick matches (recommended), and should the resume fallback with empty squads be removed?

---

## 16. Suggested Phase 2 sequencing (after approval)

1. **Guards first (no schema):** G4 (authority), G6 (menu), G5 (innings break + recipient rejection), G9 (guest completion), G12 (`teamBScorer*`). These are low-risk and stop the split-brain immediately.
2. **Verified lifecycle:** G2/G8 (ensure row → verified live → verified completion), reusing `markLive`/`markCompleted`; add `completed_by_profile_id` and server timestamp if approved.
3. **Pending phase + resume:** G1/G11, if Q1 = yes.
4. **Handover (only if Q4 = b):** hydration + re-verification + tests; otherwise keep disabled and document.
5. **Guest parity:** G10 local popup + local resume.
6. **Migration + RLS hardening:** additive only, with regression tests for Schedule Match.
7. **Regression pass:** all 24 scenarios in §14, especially scheduled flow and scheduled handover.

---

## Approval gate

Phase 1 is complete and read-only. **No Flutter source, schema, RLS policy, backend function or production data has been changed.**

Phase 2 must not start until:
1. The questions in §15 are answered, and
2. You explicitly approve the scope and the migration plan in §7 and §12.
