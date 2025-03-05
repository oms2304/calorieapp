import SwiftUI

struct SetHeightView: View {
    @EnvironmentObject var goalSettings: GoalSettings // Use EnvironmentObject to access GoalSettings
    @State private var feet: String = ""
    @State private var inches: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Your Height")
                .font(.title)
                .padding(.bottom)

            HStack {
                VStack {
                    TextField("Feet", text: $feet)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(width: 100)
                }
                Text("'")
                VStack {
                    TextField("Inches", text: $inches)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(width: 100)
                }
                Text("\"")
            }

            Button(action: saveHeight) {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 16)

            Spacer()
        }
        .padding()
        .onAppear {
            let height = goalSettings.getHeightInFeetAndInches() // ✅ Now properly recognized
            feet = "\(height.feet)"
            inches = "\(height.inches)"
        }
    }

    private func saveHeight() {
        if let feetValue = Int(feet), let inchesValue = Int(inches), feetValue >= 0, inchesValue >= 0, inchesValue < 12 {
            goalSettings.setHeight(feet: feetValue, inches: inchesValue) // ✅ Now properly recognized
        }
    }
}
