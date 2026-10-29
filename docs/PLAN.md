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

## Decisions (29 Oct 2026)
- **Bundle id:** `com.orbitanswer.ios`. Apple team still to be set in Xcode / CI signing.
- **Sign-in:** email + password (done), Google and Sign in with Apple. Apple is mandatory once Google is offered.
  Backend work needed: the API only has the browser Google redirect flow (`/v1/auth/google/*`); native needs endpoints that
  accept a Google ID token and an Apple identity token and return the same `access_token` as `/login`.
- **Payments:** the app sells credit packs and plans with **StoreKit (in-app purchase)**. Apple Pay is not a way around this:
  App Review requires IAP for digital goods used in the app, and "Apple Pay" itself is for physical goods/services.
  UPI/Razorpay stays on the web app. Credits are account-wide, so a pack bought on the web works in the app. The app
  does not link out to web checkout or mention it. Backend work: verify App Store transactions server-side
  (App Store Server API / notifications) and grant credits like the Razorpay webhook does.
