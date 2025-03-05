import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommunityHubView: View {
    @EnvironmentObject var groupService: GroupService
    @State private var posts: [CommunityPost] = []
    @State private var showingCreatePostView = false
    @State private var showingJoinConfirmation = false
    @State private var selectedGroup: CommunityGroup?
    @State private var groups: [CommunityGroup] = []
    @State private var isMemberOfSelectedGroup = false
    
    let presetGroups = [
        CommunityGroup(id: "1", name: "Health & Wellness", description: "Discuss health tips and wellness strategies", creatorID: "preset", isPreset: true),
        CommunityGroup(id: "2", name: "Recipes & Cooking", description: "Share your favorite recipes and cooking tips", creatorID: "preset", isPreset: true),
        CommunityGroup(id: "3", name: "Fitness", description: "Talk about workouts, fitness goals, and more", creatorID: "preset", isPreset: true)
    ]
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    Text("Groups")
                        .font(.headline)
                        .padding([.top, .leading])
                    List(presetGroups) { group in
                        Button(action: {
                            selectedGroup = group
                            checkGroupMembership(group: group)
                        }) {
                            Text(group.name)
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                    }
                    .listStyle(PlainListStyle())
                    .frame(width: UIScreen.main.bounds.width * 0.2)
                    .background(Color(.systemGray6))
                }

                Divider()
                
                VStack {
                    if let group = selectedGroup {
                        Text("Viewing posts in \(group.name)")
                            .font(.title2)
                            .padding()
                        
                        if isMemberOfSelectedGroup {
                            Button(action: { showingCreatePostView = true }) {
                                Text("Create Post")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding()
                            .sheet(isPresented: $showingCreatePostView) {
                                CreatePostView(groupID: group.id) { newPost in
                                    savePostToFirebase(post: newPost)
                                }
                            }
                            
                            List(posts) { post in
                                PostRowView(post: post)
                                    .padding(.vertical, 4)
                            }
                        } else {
                            Button("Join \(group.name) Group") {
                                showingJoinConfirmation = true
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .alert(isPresented: $showingJoinConfirmation) {
                                Alert(
                                    title: Text("Join Group"),
                                    message: Text("Would you like to join \(group.name)?"),
                                    primaryButton: .default(Text("Join")) {
                                        joinGroup(group)
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    } else {
                        Text("Select a group to view posts")
                            .font(.title2)
                            .padding()
                    }
                }
            }
        }
    }

    private func checkGroupMembership(group: CommunityGroup) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let membershipID = "\(userID)_\(group.id)"
        Firestore.firestore().collection("groupMemberships").document(membershipID).getDocument { document, error in
            if let error = error {
                print("Error checking group membership: \(error.localizedDescription)")
                return
            }
            if document?.exists == true {
                isMemberOfSelectedGroup = true
                fetchPostsForGroup(group: group)
            } else {
                isMemberOfSelectedGroup = false
            }
        }
    }

    private func fetchPostsForGroup(group: CommunityGroup) {
        let db = Firestore.firestore()
        db.collection("posts")
            .whereField("groupID", isEqualTo: group.id)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching posts for group: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.posts = documents.compactMap { doc -> CommunityPost? in
                    try? doc.data(as: CommunityPost.self)
                }
            }
    }

    private func savePostToFirebase(post: CommunityPost) {
        let db = Firestore.firestore()
        guard let postId = post.id else {
            print("Post ID is nil; cannot save post.")
            return
        }
        do {
            try db.collection("posts").document(postId).setData(from: post)
        } catch {
            print("Error saving post: \(error)")
        }
    }

    private func joinGroup(_ group: CommunityGroup) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        groupService.joinGroup(userID: userID, groupID: group.id) { error in
            if let error = error {
                print("Error joining group: \(error.localizedDescription)")
            } else {
                isMemberOfSelectedGroup = true
                fetchPostsForGroup(group: group)
            }
        }
    }
}
