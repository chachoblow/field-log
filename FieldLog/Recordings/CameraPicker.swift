import SwiftUI
import UIKit

/// The system camera, hosted inside the app. This is the project's one UIKit
/// view: SwiftUI has no camera view, and there is no way to send the user to
/// the Camera app and get the shot back. Stills only; the system picker
/// cannot capture Live Photos.
struct CameraPicker: UIViewControllerRepresentable {
    /// Called with the shot's JPEG bytes, full size and not yet downscaled.
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    /// True on a device with a camera once the camera usage string is set.
    /// Without the string the permission prompt would crash the app, so the
    /// button that presents this stays hidden until the developer adds it.
    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
            && Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (Data) -> Void
        private let dismiss: () -> Void

        init(onCapture: @escaping (Data) -> Void, dismiss: @escaping () -> Void) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.95) {
                onCapture(data)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
