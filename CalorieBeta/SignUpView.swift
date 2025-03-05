import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var signUpError = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Header with Background Image and Close Button
            ZStack {
                // Background Image with Blur and Dark Overlay
                Image("salad")
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .overlay(Color.black.opacity(0.65))

                // Text Content Centered Vertically
                VStack(spacing: 10) {
                    Text("Create Your Account!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // Close Button in Top-Right Corner
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                .position(x: UIScreen.main.bounds.width - 25, y: 60) // Position the button - hardcoded unfortunately
            }
            .frame(height: 200) // Set fixed height for the header

            // Join Now and Form Section
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    RoundedTextField(placeholder: "Username", text: $username)
                    RoundedTextField(placeholder: "Email", text: $email,                    isEmail: true
                    )
                    RoundedSecureField(placeholder: "Password", text: $password)
                    RoundedSecureField(placeholder: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal)

                // Error Message
                if !signUpError.isEmpty {
                    Text(signUpError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }
                Spacer()
                
                // Submit Button
                Button(action: signUpUser) {
                    Text("Join Now")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(30)
                }
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .background(
                Color.white
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 30)) // Round only the top corners of white block
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    private func signUpUser() {
        guard !username.isEmpty else {
            signUpError = "Username is required"
            return
        }

        guard password == confirmPassword else {
            signUpError = "Passwords do not match"
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                signUpError = error.localizedDescription
                return
            }
            
            if let user = authResult?.user {
                saveUserData(user: user)
            }
        }
    }

    private func saveUserData(user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "userID": user.uid,
            "username": username, // Adding username here
            "goals": [
                "calories": 2000,
                "protein": 150,
                "fats": 70,
                "carbs": 250
            ],
            "weight": 150.0
        ]
        
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                db.collection("users").document(user.uid).collection("calorieHistory").addDocument(data: [
                        "date": Timestamp(date: Date()),
                        "calories": 0.0
                    ]) { historyError in
                        if let historyError = historyError {
                            print("Error initializing calorie history: \(historyError.localizedDescription)")
                        } else {
                            print("Calorie history initialized for user \(user.uid).")
                        }
                    }
                }
            }
        }
    }


// Custom Shape for Rounded Corners
struct CustomCorners: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Reusable Components
struct RoundedTextField: View {
    var placeholder: String
    @Binding var text: String
    var isEmail: Bool = false

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(isEmail ? .emailAddress : .default)
            .padding()
            .background(Color(.white))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.black, lineWidth: 1)
            )
    }
}

struct RoundedSecureField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .padding()
            .background(Color(.white))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.black, lineWidth: 1)
            )
    }
}

