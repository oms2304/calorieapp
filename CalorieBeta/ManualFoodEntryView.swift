import SwiftUI
import FirebaseFirestore

struct ManualFoodEntryView: View {
    var barcode: String

    @State private var name = ""
    @State private var calories = ""

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text("Add New Food")
                .font(.headline)

            TextField("Food Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Calories", text: $calories)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Save") {
                saveToFirestore()
                dismiss()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }

    private func saveToFirestore() {
        let db = Firestore.firestore()
        db.collection("barcodes").document(barcode).setData([
            "name": name,
            "calories": Double(calories) ?? 0
        ])
    }
}
