# Orbit for iOS

Native SwiftUI app for Orbit, the job-search coach that already ships on web and Windows
(`iamishfaq07/ishai`). It talks to the same FastAPI backend (`apps/api`) and follows the same design language
(Route green, serif titles, "the next step first").

## Status

Foundation slice: sign-in (including 2FA), keychain session, Today, Jobs tracker (read-only), and placeholder
Prepare / My Career tabs. See [docs/PLAN.md](docs/PLAN.md) for the roadmap.

## Build

Requires macOS with Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate   # creates Orbit.xcodeproj from project.yml
open Orbit.xcodeproj
```

The API base URL is `ORBIT_API_URL` in `project.yml` (default `https://api.orbitanswer.com`).
The bundle id `com.orbit.ios` and the signing team are placeholders; set your own before shipping.
