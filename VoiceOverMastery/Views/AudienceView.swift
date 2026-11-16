import SwiftUI

struct AudienceView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("VoiceOver Mastery")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                    Text("An offline guide to VoiceOver on iPhone, iPad, Mac, Apple Watch, Apple TV, and Apple Vision Pro. Choose the introduction that fits you. You can change this later in More.")
                        .font(.body)
                    VStack(alignment: .leading, spacing: 12) {
                        Button("I use VoiceOver") {
                            progress.choose(.voiceOver)
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("audienceVoiceOver")
                        .accessibilityHint("Opens the guide. Skips the sighted orientation.")

                        Button("I'm sighted and learning VoiceOver") {
                            progress.choose(.sighted)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("audienceSighted")
                        .accessibilityHint("Shows a short orientation about turning VoiceOver on and off, then opens the guide.")
                    }
                }
                .readableWidth()
                .padding()
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OrientationView: View {
    var isGate: Bool
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        if isGate {
            NavigationStack { orientationContent }
        } else {
            orientationContent
        }
    }

    private var orientationContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Orientation for sighted learners")
                    .font(.largeTitle.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h1)
                    .accessibilityIdentifier("orientationTitle")
                CopySections(sections: OrientationCopy.sections)
                if isGate {
                    Button("Continue to the guide") {
                        progress.completeOrientation()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityIdentifier("orientationContinue")
                    .accessibilityHint("Opens the guide. You can read this orientation again from More.")
                }
            }
            .readableWidth()
            .padding()
        }
        .navigationTitle("Orientation")
        .navigationBarTitleDisplayMode(.inline)
    }
}
