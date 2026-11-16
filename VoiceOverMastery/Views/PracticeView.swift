import SwiftUI

struct PracticeView: View {
    @Namespace private var rotorNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.strongContrast) private var strong
    @State private var sliderValue = 5.0
    @State private var status = "Nothing activated yet."
    @State private var selectedRows: Set<String> = []

    private let rows = ["Apples", "Bread", "Milk"]
    private var emphasize: Bool { strong || contrast == .increased }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CopySections(sections: PracticeCopy.sections)
                } header: {
                    SectionHeader("Practice")
                }
                Section {
                    Button {
                        status = "Sample button activated."
                        AccessibilityNotification.Announcement(status).post()
                    } label: {
                        Text("Sample button")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("practiceButton")
                    .accessibilityLabel("Sample button")
                    .accessibilityHint("A practice button in this app. Custom actions are available.")
                    .accessibilityRotorEntry(id: "button", in: rotorNamespace)
                    .accessibilityActions {
                        Button("Reset practice status") {
                            status = "Practice status reset."
                            AccessibilityNotification.Announcement(status).post()
                        }
                        Button("Read practice status") {
                            AccessibilityNotification.Announcement(status).post()
                        }
                    }
                    .overlay {
                        if emphasize {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary, lineWidth: 2)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Practice slider")
                            .font(.body.weight(.semibold))
                            .accessibilityHidden(true)
                        Slider(value: $sliderValue, in: 0...10, step: 1)
                            .accessibilityIdentifier("practiceSlider")
                            .accessibilityLabel("Practice slider")
                            .accessibilityValue("\(Int(sliderValue)) of 10")
                            .accessibilityHint("An adjustable practice slider. Chapter 1.3 describes adjusting a slider.")
                            .accessibilityRotorEntry(id: "slider", in: rotorNamespace)
                        Text("Value \(Int(sliderValue)) of 10")
                            .font(.body)
                            .accessibilityHidden(true)
                    }
                    .transaction { transaction in
                        transaction.disablesAnimations = reduceMotion
                    }

                    Text(status)
                        .font(.body)
                        .accessibilityIdentifier("practiceStatus")
                        .accessibilityLabel("Practice status. \(status)")
                        .accessibilityRotorEntry(id: "status", in: rotorNamespace)
                } header: {
                    SectionHeader("Sample controls")
                }
                Section {
                    ForEach(rows, id: \.self) { row in
                        Button {
                            if selectedRows.contains(row) {
                                selectedRows.remove(row)
                            } else {
                                selectedRows.insert(row)
                            }
                        } label: {
                            HStack {
                                Text(row)
                                    .font(.body)
                                Spacer()
                                if selectedRows.contains(row) {
                                    Image(systemName: "checkmark")
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(minHeight: 44)
                        }
                        .accessibilityLabel(row)
                        .accessibilityHint("Practice list item.")
                        .accessibilityAddTraits(selectedRows.contains(row) ? .isSelected : [])
                        .accessibilityRotorEntry(id: row, in: rotorNamespace)
                    }
                } header: {
                    SectionHeader("Sample list")
                }
            }
            .navigationTitle("Practice")
            .accessibilityRotor("Practice") {
                AccessibilityRotorEntry(Text("Sample button"), id: "button", in: rotorNamespace)
                AccessibilityRotorEntry(Text("Practice slider"), id: "slider", in: rotorNamespace)
                AccessibilityRotorEntry(Text("Practice status"), id: "status", in: rotorNamespace)
                AccessibilityRotorEntry(Text("Apples"), id: "Apples", in: rotorNamespace)
                AccessibilityRotorEntry(Text("Bread"), id: "Bread", in: rotorNamespace)
                AccessibilityRotorEntry(Text("Milk"), id: "Milk", in: rotorNamespace)
            }
        }
    }
}
