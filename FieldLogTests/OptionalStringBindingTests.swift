import SwiftUI
import Testing
@testable import FieldLog

@MainActor
struct OptionalStringBindingTests {
    private final class Holder {
        var value: String?
    }

    @Test func nilReadsAsEmptyText() {
        let holder = Holder()
        let binding = Binding(get: { holder.value }, set: { holder.value = $0 })
        #expect(binding.orEmpty.wrappedValue == "")
    }

    @Test func textWritesThrough() {
        let holder = Holder()
        let binding = Binding(get: { holder.value }, set: { holder.value = $0 })
        binding.orEmpty.wrappedValue = "ZOOM0001.WAV"
        #expect(holder.value == "ZOOM0001.WAV")
        #expect(binding.orEmpty.wrappedValue == "ZOOM0001.WAV")
    }

    @Test func clearingTextWritesNil() {
        let holder = Holder()
        holder.value = "ZOOM0001.WAV"
        let binding = Binding(get: { holder.value }, set: { holder.value = $0 })
        binding.orEmpty.wrappedValue = ""
        #expect(holder.value == nil)
    }
}
