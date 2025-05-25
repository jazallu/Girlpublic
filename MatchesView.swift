//
//  MatchesView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/3/25.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI
import UserNotifications
struct MatchesView: View {
    @State private var likedUsers: [Match] = []
    @State private var messageRequests: [Match] = []
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var errorMessage: String? = nil
    @State private var lastRefreshTime = Date()
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showNotificationPermission = false
    @AppStorage("hasPromptedForNotifications") private var hasPromptedForNotifications = false
    @State private var messageRequestsListener: ListenerRegistration?
    
    var body: some View {
        NavigationStack {
            VStack {
                headerView
                // Tab selector (Matches vs. Requests)
                Picker("", selection: $selectedTab) {
                    Text("Matches").tag(0)
                    Text("Requests").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                // Debug info for testing
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                // Show Liked Users or Requests based on selected tab
                if selectedTab == 0 {
                    likedUsersContentView
                } else {
                    requestsContentView
                }
            }
            .background(backgroundView)
            .navigationBarHidden(true)
            .onAppear {
                fetchLikedUsersAndRequests()
                setupMessageRequestsListener()
                
                // Check if we should show the notification permission dialog
                if !hasPromptedForNotifications {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showNotificationPermission = true
                    }
                }
            }
            .onDisappear {
                // Clean up listener to prevent memory leaks
                messageRequestsListener?.remove()
            }
            .sheet(isPresented: $showNotificationPermission, onDismiss: {
               
                hasPromptedForNotifications = true
            }) {
                NotificationPermissionView()
            }
            .refreshable {
                await fetchLikedUsersAndRequestsAsync()
            }
        }
    }
    private var headerView: some View {
        HStack {
            Text("Messages")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.pink)
            
            Spacer()
            
            Button(action: {
                fetchLikedUsersAndRequests()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(.pink)
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    private var likedUsersContentView: some View {
        Group {
            if isLoading {
                ProgressView("Loading Matches...")
                    .foregroundColor(.pink)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.pink.opacity(0.05))
            } else if likedUsers.isEmpty {
                Text("No Matches Yet")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.pink.opacity(0.05))
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(likedUsers, id: \.id) { user in
                            matchRow(for: user)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    private var requestsContentView: some View {
        Group {
            if isLoading {
                ProgressView("Loading Requests...")
                    .foregroundColor(.pink)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.pink.opacity(0.05))
            } else if messageRequests.isEmpty {
                Text("No Message Requests")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.pink.opacity(0.05))
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(messageRequests, id: \.id) { user in
                            requestRow(for: user)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    // New method for setting up real-time listener
    private func setupMessageRequestsListener() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        print("🔥 Setting up real-time listener for message requests")
        
        // Create a real-time listener for the user document to detect new requests
        messageRequestsListener = db.collection("users").document(userID)
            .addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("❌ Error listening for message requests: \(error.localizedDescription)")
                    return
                }
                
                guard let document = documentSnapshot, document.exists else {
                    print("❌ User document doesn't exist in listener")
                    return
                }
                
                // Get current message requests
                let currentRequestIDs = document.data()?["messageRequests"] as? [String] ?? []
                
                // Calculate new requests by comparing with our current list
                let existingRequestIDs = Set(self.messageRequests.map { $0.id })
                let newRequestIDs = Set(currentRequestIDs).subtracting(existingRequestIDs)
                
                if !newRequestIDs.isEmpty {
                    print("🔔 Detected \(newRequestIDs.count) new message requests")
                    
                    // For each new request, schedule a notification
                    for requestID in newRequestIDs {
                        // Get the sender's name
                        db.collection("users").document(requestID).getDocument { senderDoc, error in
                            if let error = error {
                                print("❌ Error getting sender info: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let senderDoc = senderDoc, senderDoc.exists else { return }
                            let senderName = senderDoc.data()?["name"] as? String ?? "Someone"
                            
                            // Create the chat ID
                            let chatID = [userID, requestID].sorted().joined(separator: "_")
                            
                            // Schedule the notification
                            self.notificationManager.scheduleRequestNotification(
                                senderName: senderName,
                                chatId: chatID
                            )
                            
                            print("✅ Scheduled notification for request from: \(senderName)")
                        }
                    }
                    
                    // Refresh the UI to show the new requests
                    self.fetchLikedUsersAndRequests()
                }
            }
    }
    private func matchRow(for user: Match) -> some View {
        NavigationLink(destination: ChatView(matchName: user.name, matchId: user.id)) {
            HStack(spacing: 15) {
                if !user.imageURL.isEmpty {
                    WebImage(url: URL(string: user.imageURL))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.name)
                            .font(.headline)
                            .foregroundColor(.pink)
                        
                        // Simplified unread indicator - just a dot
                        if user.hasUnread {
                            Circle()
                                .fill(Color.pink)
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    if !user.lastMessage.isEmpty {
                        Text(user.lastMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "message.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.pink)
                    .clipShape(Circle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
            )
        }
    }
    private func requestRow(for user: Match) -> some View {
        VStack {
            HStack(spacing: 15) {
                if !user.imageURL.isEmpty {
                    WebImage(url: URL(string: user.imageURL))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.pink)
                    Text("Wants to chat with you")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button(action: { declineRequest(user.id) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                    NavigationLink(destination: ChatView(matchName: user.name, matchId: user.id)) {
                        Image(systemName: "eye")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    Button(action: { approveRequest(user.id) }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.pink)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
            )
        }
    }
    private var backgroundView: some View {
        Color.pink.opacity(0.05).edgesIgnoringSafeArea(.all)
    }
    private func fetchLikedUsersAndRequestsAsync() async {
        return await withCheckedContinuation { continuation in
            fetchLikedUsersAndRequests {
                continuation.resume()
            }
        }
    }
    private func fetchLikedUsersAndRequests(completion: (() -> Void)? = nil) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID available")
            errorMessage = "Authentication error. Please sign in again."
            isLoading = false
            completion?()
            return
        }
        let db = Firestore.firestore()
        isLoading = true
        errorMessage = nil
        
        print("Fetching data for user ID: \(userID)")
        db.collection("users").document(userID).getDocument { documentSnapshot, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                errorMessage = "Failed to load data: \(error.localizedDescription)"
                isLoading = false
                completion?()
                return
            }
            guard let document = documentSnapshot, document.exists, let data = document.data() else {
                print("User document does not exist or has no data")
                errorMessage = "User profile not found"
                isLoading = false
                completion?()
                return
            }
            // Debug print
            print("User document data: \(data)")
            
            // Create dispatch group to track fetches
            let group = DispatchGroup()
            
            // Fetch Liked Users with chat info
            let likedUserIDs = data["likedUsers"] as? [String] ?? []
            print("Found \(likedUserIDs.count) liked user IDs: \(likedUserIDs)")
            
            if likedUserIDs.isEmpty {
                self.likedUsers = []
            } else {
                group.enter()
                fetchMatchesWithChatInfo(userID: userID, matchIDs: likedUserIDs) { users in
                    // Sort by lastUpdated timestamp (most recent first)
                    self.likedUsers = users.sorted(by: { $0.lastUpdated > $1.lastUpdated })
                    print("Processed \(users.count) liked users")
                    group.leave()
                }
            }
            // Fetch Message Requests
            let requestIDs = data["messageRequests"] as? [String] ?? []
            print("Found \(requestIDs.count) request IDs: \(requestIDs)")
            
            if requestIDs.isEmpty {
                self.messageRequests = []
            } else {
                group.enter()
                fetchUserDetails(from: db, with: requestIDs) { users in
                    self.messageRequests = users
                    print("Processed \(users.count) message requests")
                    group.leave()
                }
            }
            
            // When both fetches complete
            group.notify(queue: .main) {
                self.isLoading = false
                self.lastRefreshTime = Date()
                print("Data loading complete - \(self.likedUsers.count) matches, \(self.messageRequests.count) requests")
                completion?()
            }
            
            // Also check actual chats collection for any requests we might have missed
            checkChatsForRequests(userID: userID)
        }
    }
    
    // Simplified method to fetch matches with chat info
    private func fetchMatchesWithChatInfo(userID: String, matchIDs: [String], completion: @escaping ([Match]) -> Void) {
        if matchIDs.isEmpty {
            completion([])
            return
        }
        
        let db = Firestore.firestore()
        
        // First get user details
        fetchUserDetails(from: db, with: matchIDs) { basicUsers in
            let group = DispatchGroup()
            var enrichedMatches = basicUsers
            
            // For each match, fetch chat info
            for (index, match) in basicUsers.enumerated() {
                group.enter()
                
                // Get chat document
                let chatID = [userID, match.id].sorted().joined(separator: "_")
                db.collection("chats").document(chatID).getDocument { chatDoc, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error fetching chat info: \(error)")
                        return
                    }
                    
                    guard let chatDoc = chatDoc, chatDoc.exists, let chatData = chatDoc.data() else {
                        print("No chat document for: \(chatID)")
                        return
                    }
                    
                    // Get last updated timestamp (for sorting)
                    let lastUpdated = (chatData["lastUpdated"] as? Timestamp)?.dateValue() ?? Date(timeIntervalSince1970: 0)
                    enrichedMatches[index].lastUpdated = lastUpdated
                    
                    // Get user's last read timestamp
                    let lastRead = (chatData["lastRead"] as? [String: Timestamp])?[userID]?.dateValue() ?? Date(timeIntervalSince1970: 0)
                    
                    // Get the last message
                    db.collection("chats").document(chatID).collection("messages")
                        .order(by: "timestamp", descending: true)
                        .limit(to: 1)
                        .getDocuments { msgSnapshot, msgError in
                            if let error = msgError {
                                print("Error fetching last message: \(error)")
                                return
                            }
                            
                            if let lastMsg = msgSnapshot?.documents.first {
                                // Update last message preview
                                let lastMessage = lastMsg.data()["text"] as? String ?? ""
                                enrichedMatches[index].lastMessage = lastMessage
                                
                                // Simple unread check - if last message is from the other person
                                // and was sent after user's last read time
                                let senderID = lastMsg.data()["senderID"] as? String
                                let msgTimestamp = (lastMsg.data()["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                                
                                if senderID != userID && msgTimestamp > lastRead {
                                    enrichedMatches[index].hasUnread = true
                                }
                            }
                        }
                }
            }
            
            // When all chats have been processed
            group.notify(queue: .main) {
                // Sort again before returning
                let sortedMatches = enrichedMatches.sorted(by: { $0.lastUpdated > $1.lastUpdated })
                completion(sortedMatches)
            }
        }
    }
    
    // Check for missing chat requests
    private func checkChatsForRequests(userID: String) {
        let db = Firestore.firestore()
        
        db.collection("chats")
            .whereField("participants", arrayContains: userID)
            .whereField("status", isEqualTo: "request")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching chat requests: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No chat requests found")
                    return
                }
                
                print("Found \(documents.count) chat requests in chats collection")
                
                // Process each chat request
                for document in documents {
                    guard let participants = document.data()["participants"] as? [String],
                          let requestSenderID = document.data()["requestSenderID"] as? String else {
                        continue
                    }
                    
                    // If we are not the sender, this is an incoming request
                    if requestSenderID != userID {
                        // Add to messageRequests if not already there
                        db.collection("users").document(userID).getDocument { userDoc, error in
                            if let error = error {
                                print("Error fetching user document: \(error)")
                                return
                            }
                            
                            guard let userDoc = userDoc, userDoc.exists else { return }
                            
                            var messageRequests = userDoc.data()?["messageRequests"] as? [String] ?? []
                            
                            if !messageRequests.contains(requestSenderID) {
                                print("Adding missing request from \(requestSenderID) to user's messageRequests")
                                messageRequests.append(requestSenderID)
                                
                                // Update the user's messageRequests array
                                db.collection("users").document(userID).updateData([
                                    "messageRequests": messageRequests
                                ]) { error in
                                    if let error = error {
                                        print("Error updating message requests: \(error)")
                                    } else {
                                        print("Successfully added missing request")
                                        // Refresh the view
                                        self.fetchLikedUsersAndRequests()
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }
    private func fetchUserDetails(from db: Firestore, with userIDs: [String], completion: @escaping ([Match]) -> Void) {
        if userIDs.isEmpty {
            completion([])
            return
        }
        
        // Handle the case where we have more than 10 user IDs (Firestore 'in' query limit)
        let chunks = stride(from: 0, to: userIDs.count, by: 10).map {
            Array(userIDs[$0..<min($0 + 10, userIDs.count)])
        }
        
        var allUsers: [Match] = []
        let group = DispatchGroup()
        
        for chunk in chunks {
            group.enter()
            db.collection("users").whereField(FieldPath.documentID(), in: chunk).getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching user details: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("No documents found for users in chunk")
                    return
                }
                let fetchedUsers = documents.map { doc -> Match in
                    let data = doc.data()
                    let imageURLs = data["imageURLs"] as? [String] ?? []
                    return Match(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "Unknown",
                        bio: data["bio"] as? String ?? "",
                        imageURL: imageURLs.first ?? "",
                        lastMessage: "",
                        lastUpdated: Date(),
                        hasUnread: false
                    )
                }
                
                allUsers.append(contentsOf: fetchedUsers)
            }
        }
        
        group.notify(queue: .main) {
            completion(allUsers)
        }
    }
    private func approveRequest(_ userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUserId)
        
        print("Approving request from user: \(userId)")
        // Update user document to move user from requests to liked users
        userRef.updateData([
            "messageRequests": FieldValue.arrayRemove([userId]),
            "likedUsers": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error approving request: \(error.localizedDescription)")
                errorMessage = "Failed to approve request"
                return
            }
            
            // Update chat status if exists
            let chatID = [currentUserId, userId].sorted().joined(separator: "_")
            db.collection("chats").document(chatID).updateData([
                "status": "approved",
                "lastUpdated": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Error updating chat status: \(error)")
                    return
                }
                
                // Update all pending messages to approved
                db.collection("chats").document(chatID).collection("messages")
                    .whereField("status", isEqualTo: "request")
                    .getDocuments { msgSnapshot, msgError in
                        if let error = msgError {
                            print("Error fetching messages: \(error)")
                            return
                        }
                        
                        guard let documents = msgSnapshot?.documents, !documents.isEmpty else {
                            print("No messages to approve")
                            // Refresh the UI regardless
                            self.fetchLikedUsersAndRequests()
                            return
                        }
                        
                        let batch = db.batch()
                        for doc in documents {
                            let msgRef = db.collection("chats").document(chatID).collection("messages").document(doc.documentID)
                            batch.updateData(["status": "approved"], forDocument: msgRef)
                        }
                        
                        batch.commit { error in
                            if let error = error {
                                print("Error approving messages: \(error)")
                            } else {
                                print("Successfully approved \(documents.count) messages")
                            }
                            
                            // Refresh the UI
                            self.fetchLikedUsersAndRequests()
                        }
                    }
            }
        }
    }
    private func declineRequest(_ userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        print("Declining request from user: \(userId)")
        
        db.collection("users").document(currentUserId)
            .updateData(["messageRequests": FieldValue.arrayRemove([userId])]) { error in
                if let error = error {
                    print("Error declining request: \(error.localizedDescription)")
                    errorMessage = "Failed to decline request"
                    return
                }
                
                // Mark chat as declined if it exists
                let chatID = [currentUserId, userId].sorted().joined(separator: "_")
                db.collection("chats").document(chatID).updateData([
                    "status": "declined",
                    "lastUpdated": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("Error updating chat status: \(error)")
                        // If chat doesn't exist, create it with declined status
                        if (error as NSError).domain == FirestoreErrorDomain &&
                           (error as NSError).code == FirestoreErrorCode.notFound.rawValue {
                            
                            db.collection("chats").document(chatID).setData([
                                "participants": [currentUserId, userId],
                                "status": "declined",
                                "lastUpdated": FieldValue.serverTimestamp(),
                                "requestSenderID": userId
                            ])
                        }
                    }
                    
                    // Refresh the UI
                    self.fetchLikedUsersAndRequests()
                }
            }
    }
}
// Updated Match struct with simplified unread indicator
struct Match: Identifiable {
    let id: String
    let name: String
    let bio: String
    let imageURL: String
    var lastMessage: String = ""
    var lastUpdated: Date = Date()
    var hasUnread: Bool = false
}
