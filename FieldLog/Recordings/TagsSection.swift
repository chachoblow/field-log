import SwiftData
import SwiftUI

/// Recording form section: applied tags as removable chips, plus an entry
/// field that suggests existing tags while typing and reuses or creates on submit.
struct TagsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var draft = ""

    private var applied: [Tag] {
        (recording.tags ?? []).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var suggestions: [Tag] {
        TagResolver.suggestions(matching: draft, excluding: applied, from: allTags)
    }

    var body: some View {
        Section("Tags") {
            if !applied.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(applied) { tag in
                            TagChip(name: tag.name) { remove(tag) }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            TextField("Add tag", text: $draft)
                .textInputAutocapitalization(.never)
                .onSubmit(addDraft)
            ForEach(suggestions) { tag in
                Button {
                    add(tag)
                } label: {
                    Label(tag.name, systemImage: "tag")
                }
            }
        }
    }

    private func addDraft() {
        guard let tag = try? TagResolver.resolve(name: draft, in: modelContext) else { return }
        add(tag)
    }

    private func add(_ tag: Tag) {
        if !(recording.tags ?? []).contains(tag) {
            recording.tags = (recording.tags ?? []) + [tag]
        }
        draft = ""
    }

    private func remove(_ tag: Tag) {
        recording.tags?.removeAll { $0 == tag }
    }
}

private struct TagChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
            Button("Remove \(name)", systemImage: "xmark.circle.fill", action: onRemove)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.tint.opacity(0.12), in: Capsule())
    }
}
