import SwiftUI
import FirebaseFirestore
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onFoodItemDetected: (FoodItem) -> Void

    private let fatSecretService = FatSecretFoodAPIService()

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarcodeScannerView

        init(parent: BarcodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first,
               let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let barcode = readableObject.stringValue {

                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.parent.presentationMode.wrappedValue.dismiss()
                    self.fetchFromFatSecret(barcode: barcode)
                }
            }
        }

        private func fetchFromFatSecret(barcode: String) {
            parent.fatSecretService.fetchFoodByBarcode(barcode: barcode) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let foodItems):
                        if let firstFoodItem = foodItems.first {
                            print("✅ Navigating to FoodDetailView for: \(firstFoodItem.name)")
                            
                            // ✅ Pass full food item to handler
                            self.parent.onFoodItemDetected(firstFoodItem)
                        } else {
                            print("⚠️ No valid results found.")
                        }
                    case .failure(let error):
                        print("❌ No results found. Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// ✅ **Restored `ScannerViewController` to fix "Cannot find in scope" errors**
class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession?.canAddInput(videoInput) == true {
                captureSession?.addInput(videoInput)
            }
        } catch {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning() // ✅ **Moved to background to prevent UI freeze**
        }
    }

    func setupOverlay() {
        let overlayView = UIView()
        overlayView.layer.borderColor = UIColor.green.cgColor
        overlayView.layer.borderWidth = 3
        overlayView.backgroundColor = UIColor.clear
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            overlayView.heightAnchor.constraint(equalTo: overlayView.widthAnchor, multiplier: 0.5)
        ])
    }
}
