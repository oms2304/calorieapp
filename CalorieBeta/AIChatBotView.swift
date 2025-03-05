
import SwiftUI
import FirebaseFirestore

struct AIChatbotView: View {
    @State private var userMessage = ""
    @State private var chatMessages: [ChatMessage] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack {
               
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(chatMessages) { message in
                            ChatBubble(message: message)
                        }
                    }
                }
                .padding()

               
                HStack {
                    TextField("Ask for a healthy recipe...", text: $userMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .padding()
                    }
                    .disabled(isLoading || userMessage.isEmpty)
                }
                .padding()
            }
            .navigationTitle("AI Recipe Bot")
        }
    }

    
    func sendMessage() {
        guard !userMessage.isEmpty else { return }

        
        let userChatMessage = ChatMessage(id: UUID(), text: userMessage, isUser: true)
        chatMessages.append(userChatMessage)

       
        userMessage = ""

       
        isLoading = true

       
        fetchGPT3Response(for: userChatMessage.text) { aiResponseText in
          
            let aiChatMessage = ChatMessage(id: UUID(), text: aiResponseText, isUser: false)
            chatMessages.append(aiChatMessage)

         
            isLoading = false
        }
    }


    func fetchGPT3Response(for message: String, completion: @escaping (String) -> Void) {
     
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!


        let apiKey = "add_api_key"

     
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

     
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that provides healthy and nutritious recipes."],
                ["role": "user", "content": message]
            ],
            "max_tokens": 700,
            "temperature": 0.7
        ]

      
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Error serializing JSON for GPT-3.5 request.")
            completion("Sorry, something went wrong when preparing the request.")
            return
        }

     
        request.httpBody = bodyData

     
        print("Sending request to GPT-3.5: \(String(data: bodyData, encoding: .utf8)!)")

        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error calling GPT-3.5 API: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion("Sorry, I couldn't fetch a recipe at the moment. Please try again.")
                }
                return
            }

           
            guard let data = data else {
                print("No data returned from GPT-3.5 API")
                DispatchQueue.main.async {
                    completion("Sorry, no recipe available at the moment.")
                }
                return
            }

      
            if let responseString = String(data: data, encoding: .utf8) {
                print("GPT-3.5 Response: \(responseString)")
            }

       
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Parsed JSON: \(json)")  // Log the parsed JSON

                    if let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let text = message["content"] as? String {
                        DispatchQueue.main.async {
                            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    } else {
                        print("Invalid or missing 'choices' in JSON response")
                        DispatchQueue.main.async {
                            completion("Sorry, I couldn't understand that. Try asking again.")
                        }
                    }
                } else {
                    print("Invalid JSON structure")
                    DispatchQueue.main.async {
                        completion("Sorry, I couldn't process the response. Try again.")
                    }
                }
            } catch {
                print("Error parsing GPT-3.5 response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion("Sorry, I couldn't understand that. Please try again.")
                }
            }
        }.resume()
    }
}


struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
}


struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            Text(message.text)
                .padding()
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(12)
                .foregroundColor(message.isUser ? .white : .black)
                .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
        .padding(message.isUser ? .leading : .trailing, 40)  
    }
}
