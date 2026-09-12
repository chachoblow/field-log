import SwiftUI

/// Sample rate and bit depth pickers shared by the recording form and the recorder defaults form.
struct SampleRatePicker: View {
    @Binding var selection: Int?

    private static let rates = [44_100, 48_000, 96_000]

    var body: some View {
        Picker("Sample rate", selection: $selection) {
            Text("None").tag(Int?.none)
            ForEach(Self.rates, id: \.self) { rate in
                Text("\(Double(rate) / 1000, format: .number) kHz").tag(Int?.some(rate))
            }
        }
    }
}

struct BitDepthPicker: View {
    @Binding var selection: String?

    private static let depths = ["32-bit float", "24-bit", "16-bit"]

    var body: some View {
        Picker("Bit depth", selection: $selection) {
            Text("None").tag(String?.none)
            ForEach(Self.depths, id: \.self) { depth in
                Text(depth).tag(String?.some(depth))
            }
        }
    }
}
