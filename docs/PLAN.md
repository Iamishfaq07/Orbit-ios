# iOS roadmap

## Contract with the backend
- Auth: `POST /v1/auth/login` (returns `access_token` to non-browser callers, i.e. no `Origin` header), `/v1/auth/login/2fa`,
  `GET /v1/auth/me`, `POST /v1/auth/logout`. Token lives in the keychain and is sent as `Authorization: Bearer`.
- Bearer requests skip the cookie CSRF check, so no CSRF handling is needed.
- Jobs: `GET /v1/jobs/tracker`, `/v1/jobs/feed`, `/v1/jobs/listings/{id}`, `PATCH /v1/jobs/tracker/{id}`.

## Phases
1. **Foundation (this PR):** project, API client, keychain session, sign-in + 2FA, Today, tracker list, tests, CI.
2. **Jobs:** Discover feed with match score, job page (requirements, resume, interviews, offer), status changes, save from share sheet.
3. **Prepare:** mock interview (voice), aptitude, STAR, coding.
4. **My Career:** resume, stories, LinkedIn, contacts, offers.
5. **Native extras:** push notifications for due stops, Sign in with Apple / Google, passkeys, widgets, Live Activities, Dynamic Type + reduced-motion settings parity.
6. **Live Copilot:** decide scope (iOS cannot capture other apps' audio; likely a companion view only).

## Open decisions
- Bundle id / Apple team / App Store listing.
- Sign in with Apple is required by App Review if Google sign-in is offered.
- Billing: UPI/Razorpay packs on web vs. StoreKit rules for digital goods.
