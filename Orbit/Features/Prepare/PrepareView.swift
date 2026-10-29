import SwiftUI

struct PrepareView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Prepare", systemImage: "text.bubble",
                                   description: Text("Mock interviews, aptitude and STAR practice are coming next."))
                .navigationTitle("Prepare")
        }
    }
}
