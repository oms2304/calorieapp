import SwiftUI
import UIKit
import AVFoundation // Added for AVCaptureDevice

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss // Use dismiss for iOS 15+; fall back to presentationMode if needed
    @Environment(\.presentationMode) private var presentationMode // Fallback for iOS 14
    var sourceType: UIImagePickerController.SourceType = .camera // Default to camera
    var onImagePicked: (UIImage) -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            if #available(iOS 15.0, *) {
                parent.dismiss()
            } else {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            if #available(iOS 15.0, *) {
                parent.dismiss()
            } else {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType

        // Check camera availability and authorization
        if sourceType == .camera {
            let status = AVCaptureDevice.authorizationStatus(for: .video) // Fixed syntax
            switch status {
            case .denied, .restricted:
                print("❌ Camera access denied or restricted")
                // Optionally, show an alert or handle this in the parent view
                return picker
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if !granted {
                        print("❌ Camera access not granted")
                    }
                }
            case .authorized:
                break
            @unknown default:
                print("❌ Unknown camera authorization status")
            }
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = false // Optional: Disable editing if not needed
        }
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
