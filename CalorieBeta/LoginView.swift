import SwiftUI
import FirebaseAuth
import Firebase

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var loginError = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Header with Background Image and Close Button
            ZStack {
                // Background Image with Blur and Dark Overlay
                Image("healthy") // Replace with your background image name
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .overlay(Color.black.opacity(0.65))
                    .blur(radius: 6)

                // Text Content Centered Vertically
                VStack(spacing: 10) {
                    Text("Welcome Back!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 200) // Set fixed height for the header

            // Login Form Section
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    RoundedTextField(placeholder: "Enter your email", text: $email, isEmail: true)
                    RoundedSecureField(placeholder: "Enter your password", text: $password)
                }
                .padding(.horizontal)

                // Error Message
                if !loginError.isEmpty {
                    Text(loginError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }
                Spacer()

                // Buttons Section
                VStack(spacing: 10) {
                    Button(action: loginUser) {
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal)

                    Button(action: clearFields) {
                        Text("Clear")
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.black)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
            .background(
                Color.white
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 30))
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                loginError = error.localizedDescription
                return
            }

            if let user = authResult?.user {
                fetchUserData(user: user)
            }
        }
    }

    private func fetchUserData(user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data() {
                    print("User data: \(data)")
                }
            } else {
                loginError = "User data not found."
            }
        }
    }

    private func clearFields() {
        email = ""
        password = ""
        loginError = ""
    }
}
