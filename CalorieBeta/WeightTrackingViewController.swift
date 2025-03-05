import UIKit
import SwiftUI
import DGCharts
import FirebaseAuth
import FirebaseFirestore

class WeightTrackingViewController: UIViewController {
    var weightHistory: [(date: Date, weight: Double)] = [] // ✅ Store weight history locally
    var hostingController: UIHostingController<WeightChartView>? // ✅ Keep reference to avoid reloading issues

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupSwiftUIChart()
        loadWeightData() // ✅ Fetch actual user weight data
    }

    private func setupSwiftUIChart() {
        // ✅ Ensure chart updates dynamically
        let chartView = UIHostingController(rootView: WeightChartView(weightHistory: weightHistory))
        addChild(chartView)
        chartView.view.frame = view.bounds
        chartView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(chartView.view)
        chartView.didMove(toParent: self)

        hostingController = chartView // ✅ Store reference for later updates
    }

    private func loadWeightData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userID).collection("weightHistory")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching weight history: \(error.localizedDescription)")
                    return
                }

                self.weightHistory = snapshot?.documents.compactMap { doc in
                    if let weight = doc.data()["weight"] as? Double,
                       let timestamp = doc.data()["timestamp"] as? Timestamp {
                        return (timestamp.dateValue(), weight)
                    }
                    return nil
                } ?? []

                DispatchQueue.main.async {
                    self.updateChart()
                }
            }
    }

    private func updateChart() {
        // ✅ Ensure chart updates dynamically when weight data changes
        hostingController?.rootView = WeightChartView(weightHistory: weightHistory)
    }
}
