# UIKit Example

This app-hosted example demonstrates Snap's experimental UIKit discovery,
rendering, and XCTest support. It also preserves the executable coverage used
to pass the UIKit feasibility gate in the repository roadmap.

The example requires iOS 26 because Xcode 26-generated `#Preview`
registries were not discoverable on an iOS 18.1 runtime. Legacy
`PreviewProvider` discovery did work there; the compatibility finding is
recorded in `ROADMAP.md`.

The example verifies that an iOS Simulator test host can:

1. discover linked `#Preview` declarations through Snap's runtime scanner;
2. render SwiftUI and `UIViewRepresentable` content through UIKit;
3. capture PNG data and `SnapPreferences` metadata; and
4. enumerate the previews as dynamic `SnapTest` XCTest cases.

Generate the local Xcode project and run the iPad Simulator tests:

```sh
xcodegen --spec Examples/UIKitExample/project.yml
xcodebuild test \
  -project Examples/UIKitExample/UIKitExample.xcodeproj \
  -scheme UIKitExample \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.4'
```

The generated `.xcodeproj` is intentionally ignored. `project.yml` is the
reviewable project source.
