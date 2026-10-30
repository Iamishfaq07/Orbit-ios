# Orbit for iOS

Native SwiftUI app for Orbit, the job-search coach that already ships on web and Windows
(`iamishfaq07/ishai`). It talks to the same FastAPI backend (`apps/api`) and follows the same design language
(Route green, serif titles, "the next step first").

## Status

Built and merged (compiled and unit-tested by CI; not yet run by a person on a device):

- **Sign-in:** email and password with the 2FA step, plus Sign in with Apple and Google. The Apple and Google
  buttons appear only when the server reports them on (`GET /v1/auth/config`), which needs the API change in
  `ishai#538` deployed. Session token lives in the Keychain.
- **Today:** the next stop and one row per active route.
- **Jobs:** Discover feed with match scores and job detail (save, mark applied), and a Tracker where you can move a
  job's stage, set its next date and edit notes.
- **Reminders:** an on-device notification an hour before each next stop. Permission is asked when you first set a date.
- **My Career (read-only):** resumes, offers, stories, contacts.
- **Prepare:** the practice queue (read-only).

Not built yet: mock interviews (voice), aptitude/coding/STAR practice, LinkedIn tools, in-app purchase, editing of
resumes/offers/stories/contacts. See [docs/PLAN.md](docs/PLAN.md).

## Before this can ship

Things only the account owner can do:

1. **Apple developer team and signing.** Set the team in Xcode (or `DEVELOPMENT_TEAM` in `project.yml`) and enable the
   *Sign in with Apple* capability for `com.orbitanswer.ios`.
2. **Google iOS client.** Create an iOS OAuth client in Google Cloud, then set `GOOGLE_IOS_CLIENT_ID` and
   `GOOGLE_REVERSED_CLIENT_ID` (`com.googleusercontent.apps.<id>`) in `project.yml`.
3. **Server.** Merge and deploy `ishai#538`, then set `ORBIT_APPLE_BUNDLE_ID=com.orbitanswer.ios` and
   `ORBIT_GOOGLE_IOS_CLIENT_ID` on the API.
4. **Billing decision.** In-app purchase (StoreKit) is the plan; it needs a go-ahead and server-side receipt checks.
5. **A person runs it.** Everything so far is checked by the compiler and unit tests only: layout, Dynamic Type,
   dark mode and the real sign-in flows need eyes on a device.

## Build

Requires macOS with Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate   # creates Orbit.xcodeproj from project.yml
open Orbit.xcodeproj
```

The API base URL is `ORBIT_API_URL` in `project.yml` (default `https://api.orbitanswer.com`).
The bundle id is `com.orbitanswer.ios`. CI builds unsigned (`CODE_SIGNING_ALLOWED=NO`).
