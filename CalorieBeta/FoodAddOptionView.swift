
import SwiftUI
import FirebaseFirestore

struct FoodAddOptionView: View {
    @Binding var showManualAdd: Bool
    @Binding var showSearch: Bool

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button(action: {
                    showManualAdd = true
                    dismiss()
                }) {
                    Text("Manually Add Food")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Button(action: {
                    showSearch = true
                    dismiss() 
                }) {
                    Text("Search for Food")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Add Food")
        }
    }
}
