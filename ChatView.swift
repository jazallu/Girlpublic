//
//  ChatView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/3/25.
//
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
struct ChatView: View {
    let matchName: String
    let matchId: String
    
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var isLoading = true
    @State private var chatStatus: ChatStatus = .unknown
    @State private var showRequestOverlay = false
    @State private var scrollToBottom = false
    @State private var localMessages: [Message] = [] // To store local messages before Firebase updates
    @State private var matchColleges: [String] = [] // Added for displaying colleges
    @State private var showReportView = false
    @State private var isUserBlocked = false // Added for block functionality
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    
    enum ChatStatus {
        case unknown
        case request
        case approved
        case declined
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Spacer()
                
                VStack(spacing: 2) {
                    Text(matchName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                    
                    if !matchColleges.isEmpty {
                        Text(matchColleges.joined(separator: " | "))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Add this button
                Button(action: {
                    showReportView = true
                }) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                        .foregroundColor(.pink)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Content based on chat status
            if isLoading {
                Spacer()
                ProgressView("Loading Chat...")
                    .foregroundColor(.pink)
                Spacer()
            } else if isUserBlocked {
                // Show blocked view if user is blocked
                Spacer()
                blockedView
                Spacer()
            } else if chatStatus == .declined {
                Spacer()
                declinedView
                Spacer()
            } else {
                // Chat view that scrolls to bottom when new messages arrive
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(spacing: 10) {
                            // Show all messages including local ones
                            let allMessages = combinedMessages()
                            ForEach(allMessages) { message in
                                messageRow(message)
                                    .id(message.id)
                                    .opacity(message.status == "approved" || message.status == "sending" ? 1.0 : 0.6) // Dim pending messages
                            }
                            // Invisible spacer at end to scroll to
                            Color.clear
                                .frame(height: 1)
                                .id("bottomID")
                        }
                        .padding()
                    }
                    .onChange(of: combinedMessages().count) { _ in
                        withAnimation {
                            scrollView.scrollTo("bottomID", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                scrollView.scrollTo("bottomID", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message input area (always shown unless chat is declined)
                if chatStatus != .declined {
                    messageInputArea
                }
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            fetchMessages()
            checkChatStatus()
            fetchMatchColleges() // Added to fetch match colleges
            checkBlockStatus() // Added to check block status
            
            // Reset badge count
            UNUserNotificationCenter.current().setBadgeCount(0)
            
            // Update last read timestamp
            updateLastReadTimestamp()
        }
        // If we get a request view overlay
        .overlay(
            Group {
                if chatStatus == .request && !isInitiator() {
                    // Only show request overlay if you're the receiver
                    Color.white.opacity(0.9).edgesIgnoringSafeArea(.all)
                    messageRequestView
                }
            }
        )
        .sheet(isPresented: $showReportView) {
            ReportContentView(userId: matchId, userName: matchName)
        }
    }
    
    // Helper to check if the current user is the chat initiator
    private func isInitiator() -> Bool {
        guard !messages.isEmpty else { return false } // Default to false if no messages
        
        if let firstMessage = messages.first {
            return firstMessage.isSentByCurrentUser
        }
        return false
    }
    
    // Helper to combine server messages with local messages
    private func combinedMessages() -> [Message] {
        var combined = messages
        
        // Add local messages that aren't already in the server messages
        for localMsg in localMessages {
            if !combined.contains(where: { $0.id == localMsg.id }) {
                combined.append(localMsg)
            }
        }
        
        // Sort by timestamp
        return combined.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    // Function to fetch match colleges
    private func fetchMatchColleges() {
        let db = Firestore.firestore()
        
        db.collection("users").document(matchId).getDocument { document, error in
            if let error = error {
                print("Error fetching match colleges: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                if let colleges = document.data()?["colleges"] as? [String] {
                    self.matchColleges = colleges
                    print("Fetched match colleges: \(colleges)")
                }
            }
        }
    }
    
    // Added function to check block status
    private func checkBlockStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Check if current user has blocked this match
        db.collection("users").document(currentUserId).getDocument { document, error in
            if let error = error {
                print("Error checking block status: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let blockedUsers = document.data()?["blockedUsers"] as? [String] ?? []
                self.isUserBlocked = blockedUsers.contains(self.matchId)
                
                if !self.isUserBlocked {
                    // Also check if the match has blocked the current user
                    db.collection("users").document(self.matchId).getDocument { matchDoc, matchError in
                        if let error = matchError {
                            print("Error checking if match blocked user: \(error.localizedDescription)")
                            return
                        }
                        
                        if let matchDoc = matchDoc, matchDoc.exists {
                            let matchBlockedUsers = matchDoc.data()?["blockedUsers"] as? [String] ?? []
                            self.isUserBlocked = matchBlockedUsers.contains(currentUserId)
                        }
                    }
                }
            }
        }
    }
    
    private var declinedView: some View {
        VStack {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            Text("This conversation was declined")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
        }
    }
    
    // Added blocked view
    private var blockedView: some View {
        VStack {
            Image(systemName: "slash.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            Text("This conversation has been blocked")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
                
            Button(action: unblockUser) {
                Text("Unblock User")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.pink)
                    .cornerRadius(20)
            }
            .padding(.top, 10)
        }
    }

    private func unblockUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Remove from current user's blockedUsers array
        db.collection("users").document(currentUserId).updateData([
            "blockedUsers": FieldValue.arrayRemove([matchId])
        ]) { error in
            if let error = error {
                print("Error unblocking user: \(error.localizedDescription)")
            } else {
                print("User unblocked successfully")
                // Reset the blocked status to refresh the view
                self.isUserBlocked = false
                // Refresh the check in case the other user has blocked this user
                self.checkBlockStatus()
            }
        }
    }
    
    private var messageRequestView: some View {
        VStack(spacing: 15) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)
                .padding(.bottom, 5)
                
            Text("Message Request")
                .font(.headline)
                .foregroundColor(.pink)
            
            Text("\(matchName) wants to chat with you")
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Show the first received message
            if let firstMessage = messages.first(where: { !$0.isSentByCurrentUser }) {
                Text(firstMessage.text)
                    .italic()
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            // Approve/Decline buttons
            HStack(spacing: 20) {
                Button(action: declineChat) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray)
                    .cornerRadius(20)
                }
                
                Button(action: approveChat) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.pink)
                    .cornerRadius(20)
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
    
    private func messageRow(_ message: Message) -> some View {
        HStack(alignment: .bottom, spacing: 5) {
            if message.isSentByCurrentUser {
                Spacer()
                
                // Time for sent message
                Text(formatMessageTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
                
                Text(message.text)
                    .padding()
                    .background(Color.pink.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(16)
                
                // Time for received message
                Text(formatMessageTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.8))
                
                Spacer()
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Updated message input area to handle blocked status
    private var messageInputArea: some View {
        if isUserBlocked {
            return AnyView(
                VStack {
                    Text("You can't send messages to this user")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                }
            )
        } else {
            return AnyView(
                HStack {
                    TextField("Type a message...", text: $newMessage)
                        .padding(10)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(20)
                        .padding(.leading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(newMessage.isEmpty ? Color.gray : Color.pink)
                            .cornerRadius(20)
                            .padding(.trailing)
                    }
                    .disabled(newMessage.isEmpty)
                }
                .padding(.vertical, 8)
            )
        }
    }
    
    // Method to update last read timestamp
    private func updateLastReadTimestamp() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let chatId = [userId, matchId].sorted().joined(separator: "_")
        
        db.collection("chats").document(chatId).updateData([
            "lastRead.\(userId)": FieldValue.serverTimestamp(),
            "lastUpdated": FieldValue.serverTimestamp() // Add this line to keep lastUpdated current
        ]) { error in
            if let error = error {
                print("Error updating last read timestamp: \(error)")
            }
        }
    }
    
    // Method to handle sending notifications for new messages
    private func sendNotificationForNewMessage(message: Message) {
        // Only send notifications for messages from the other user
        guard !message.isSentByCurrentUser,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Create the chat ID
        let chatID = [currentUserId, matchId].sorted().joined(separator: "_")
        
        // Schedule local notification
        notificationManager.scheduleMessageNotification(
            senderName: matchName,
            message: message.text,
            chatId: chatID
        )
    }
    
    private func fetchMessages() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID for chat fetch")
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let chatID = [userID, matchId].sorted().joined(separator: "_")
        
        print("Fetching messages for chat: \(chatID)")
        
        db.collection("chats").document(chatID).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No messages found for chatID: \(chatID)")
                    return
                }
                
                print("Found \(documents.count) messages")
                
                // Track if we have any new messages to notify about
                var newMessages: [Message] = []
                
                messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    
                    guard let text = data["text"] as? String,
                          let senderID = data["senderID"] as? String else {
                        print("Missing required fields in message")
                        return nil
                    }
                    
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let status = data["status"] as? String ?? "request"
                    
                    let message = Message(
                        id: doc.documentID,
                        text: text,
                        isSentByCurrentUser: senderID == userID,
                        timestamp: timestamp,
                        status: status
                    )
                    
                    // Check if this is a new message from the other person
                    if !message.isSentByCurrentUser &&
                       !self.messages.contains(where: { $0.id == message.id }) &&
                       message.status == "approved" {
                        newMessages.append(message)
                    }
                    
                    return message
                }
                
                // Send notifications for new messages if the app is not in foreground
                if UIApplication.shared.applicationState != .active {
                    for message in newMessages {
                        self.sendNotificationForNewMessage(message: message)
                    }
                }
                
                // Remove any local messages that are now in the server messages
                localMessages.removeAll { localMsg in
                    messages.contains { serverMsg in
                        serverMsg.text == localMsg.text && serverMsg.isSentByCurrentUser == localMsg.isSentByCurrentUser
                    }
                }
                
                updateChatStatus()
            }
    }
    
    private func updateChatStatus() {
        guard !messages.isEmpty else {
            chatStatus = .unknown
            return
        }
        
        if messages.contains(where: { $0.status == "approved" }) {
            chatStatus = .approved
            print("Chat status: Approved")
        } else if messages.contains(where: { $0.status == "declined" }) {
            chatStatus = .declined
            print("Chat status: Declined")
        } else if messages.contains(where: { $0.status == "request" }) {
            chatStatus = .request
            print("Chat status: Request")
        } else {
            chatStatus = .request // Default to request if there are messages but no clear status
            print("Chat status: Default to Request")
        }
    }
    
    private func checkChatStatus() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let chatID = [userID, matchId].sorted().joined(separator: "_")
        
        print("Checking chat status for: \(chatID)")
        
        db.collection("chats").document(chatID).getDocument { document, error in
            if let error = error {
                print("Error checking chat status: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                if let chatData = document.data(),
                   let status = chatData["status"] as? String {
                    
                    print("Found chat document with status: \(status)")
                    
                    switch status {
                    case "approved":
                        chatStatus = .approved
                    case "request":
                        chatStatus = .request
                    case "declined":
                        chatStatus = .declined
                    default:
                        chatStatus = .unknown
                    }
                } else {
                    print("Chat document exists but has no status")
                }
            } else {
                print("No chat document exists")
            }
        }
    }
    
    private func sendMessage() {
        // Check for blocked status before sending
        guard !isUserBlocked else {
            print("Cannot send message: user is blocked")
            return
        }
        
        guard let userID = Auth.auth().currentUser?.uid, !newMessage.isEmpty else {
            print("Cannot send message: empty message or no user ID")
            return
        }
        
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else {
            print("Message contains only whitespace")
            return
        }
        
        // Add message to local messages immediately
        let localMessage = Message(
            id: UUID().uuidString, // Temporary ID
            text: messageText,
            isSentByCurrentUser: true,
            timestamp: Date(),
            status: "sending" // Special status for local messages
        )
        localMessages.append(localMessage)
        
        // Clear the input field immediately for better UX
        self.newMessage = ""
        
        let db = Firestore.firestore()
        let chatID = [userID, matchId].sorted().joined(separator: "_")
        
        print("Sending message in chat: \(chatID)")
        print("Chat status: \(chatStatus)")
        
        // Determine message status based on chat status
        let messageStatus = chatStatus == .approved ? "approved" : "request"
        
        let messageData: [String: Any] = [
            "text": messageText,
            "senderID": userID,
            "timestamp": FieldValue.serverTimestamp(),
            "status": messageStatus
        ]
        
        // Check if chat document exists
        let chatRef = db.collection("chats").document(chatID)
        
        chatRef.getDocument { document, error in
            if let error = error {
                print("Error checking for existing chat: \(error)")
                return
            }
            
            let chatExists = document != nil && document!.exists
            
            // Step 1: Create or update chat document
            if !chatExists {
                print("Creating new chat document")
                let chatData: [String: Any] = [
                    "participants": [userID, self.matchId],
                    "status": "request",
                    "lastUpdated": FieldValue.serverTimestamp(),
                    "requestSenderID": userID
                ]
                
                chatRef.setData(chatData) { error in
                    if let error = error {
                        print("Error creating chat document: \(error)")
                        return
                    }
                    
                    print("Chat document created successfully")
                    
                    // Step 2: Add message to chat
                    self.addMessageToChat(chatID: chatID, messageData: messageData, localMessageId: localMessage.id)
                    
                    // Step 3: Update receiver's messageRequests
                    print("Updating receiver's message requests")
                    let receiverRef = db.collection("users").document(self.matchId)
                    
                    // First get the receiver's document to check current messageRequests
                    receiverRef.getDocument { document, error in
                        if let error = error {
                            print("Error getting receiver document: \(error)")
                            return
                        }
                        
                        guard let document = document, document.exists else {
                            print("Receiver document doesn't exist")
                            return
                        }
                        
                        // Check if messageRequests exists and is an array
                        if let messageRequests = document.data()?["messageRequests"] as? [String] {
                            // Only update if the user isn't already in the array
                            if !messageRequests.contains(userID) {
                                receiverRef.updateData([
                                    "messageRequests": FieldValue.arrayUnion([userID])
                                ]) { error in
                                    if let error = error {
                                        print("Error updating receiver's messageRequests: \(error)")
                                    } else {
                                        print("Successfully updated receiver's messageRequests")
                                    }
                                }
                            } else {
                                print("User already in messageRequests, no update needed")
                            }
                        } else {
                            // If messageRequests doesn't exist, create it
                            receiverRef.updateData([
                                "messageRequests": [userID]
                            ]) { error in
                                if let error = error {
                                    print("Error setting receiver's messageRequests: \(error)")
                                } else {
                                    print("Successfully set receiver's messageRequests")
                                }
                            }
                        }
                    }
                }
            } else {
                // Chat already exists, just add the message
                chatRef.updateData([
                    "lastUpdated": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("Error updating chat timestamp: \(error)")
                        return
                    }
                    
                    // Add message
                    self.addMessageToChat(chatID: chatID, messageData: messageData, localMessageId: localMessage.id)
                }
            }
        }
    }
    
    private func addMessageToChat(chatID: String, messageData: [String: Any], localMessageId: String) {
        let db = Firestore.firestore()
        db.collection("chats").document(chatID).collection("messages").addDocument(data: messageData) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                
                // Mark the local message as failed
                if let index = self.localMessages.firstIndex(where: { $0.id == localMessageId }) {
                    let failedMessage = Message(
                        id: self.localMessages[index].id,
                        text: self.localMessages[index].text,
                        isSentByCurrentUser: true,
                        timestamp: self.localMessages[index].timestamp,
                        status: "failed"
                    )
                    self.localMessages[index] = failedMessage
                }
            } else {
                print("Message sent successfully")
                
                // Send notification data to Firestore to trigger cloud function
                if self.chatStatus == .approved {
                    let notificationData: [String: Any] = [
                        "recipientId": self.matchId,
                        "senderId": Auth.auth().currentUser?.uid ?? "",
                        "senderName": "New message", // You might want to use the current user's name here
                        "messageText": messageData["text"] as? String ?? "",
                        "timestamp": FieldValue.serverTimestamp()
                    ]
                    
                    // Use a subcollection under the chat document instead of top-level notifications collection
                    db.collection("chats").document(chatID).collection("notifications").addDocument(data: notificationData) { error in
                        if let error = error {
                            print("Error sending notification data: \(error)")
                        } else {
                            print("Notification data added successfully")
                        }
                    }
                }
                
                // Remove the local message when the server confirms receipt
                // This will happen automatically when the listener gets the new message
            }
        }
    }
    
    private func approveChat() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let chatID = [userID, matchId].sorted().joined(separator: "_")
        
        print("Approving chat: \(chatID)")
        
        // Update chat status first
        db.collection("chats").document(chatID).updateData([
            "status": "approved",
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating chat status: \(error)")
                return
            }
            
            print("Chat status updated to approved")
            
            // Then update all messages
            db.collection("chats").document(chatID).collection("messages")
                .whereField("status", isEqualTo: "request")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching messages to approve: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("No message documents to approve")
                        // Still continue with user updates
                        self.updateUserCollections(userID: userID)
                        return
                    }
                    
                    print("Approving \(documents.count) messages")
                    
                    let batch = db.batch()
                    
                    for doc in documents {
                        let messageRef = db.collection("chats").document(chatID).collection("messages").document(doc.documentID)
                        batch.updateData(["status": "approved"], forDocument: messageRef)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            print("Error approving messages: \(error)")
                        } else {
                            print("Messages approved successfully")
                        }
                        
                        // Finally update user collections
                        self.updateUserCollections(userID: userID)
                    }
                }
        }
        
        // Set local status immediately for better UX
        chatStatus = .approved
    }
    
    private func updateUserCollections(userID: String) {
        let db = Firestore.firestore()
        
        // Move from messageRequests to likedUsers
        db.collection("users").document(userID).updateData([
            "messageRequests": FieldValue.arrayRemove([matchId]),
            "likedUsers": FieldValue.arrayUnion([matchId])
        ]) { error in
            if let error = error {
                print("Error updating user collections: \(error)")
            } else {
                print("User collections updated successfully")
            }
        }
    }
    
    private func declineChat() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let chatID = [userID, matchId].sorted().joined(separator: "_")
        
        print("Declining chat: \(chatID)")
        
        // Set the chat status to declined
        db.collection("chats").document(chatID).updateData([
            "status": "declined",
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating chat status to declined: \(error)")
                
                // If the document doesn't exist, create it with declined status
                if (error as NSError).domain == FirestoreErrorDomain &&
                   (error as NSError).code == FirestoreErrorCode.notFound.rawValue {
                    
                    db.collection("chats").document(chatID).setData([
                        "participants": [userID, self.matchId],
                        "status": "declined",
                        "lastUpdated": FieldValue.serverTimestamp()
                    ])
                }
            } else {
                print("Chat declined successfully")
            }
            
            // Remove from message requests
            db.collection("users").document(userID).updateData([
                "messageRequests": FieldValue.arrayRemove([self.matchId])
            ]) { error in
                if let error = error {
                    print("Error removing from message requests: \(error)")
                } else {
                    print("Removed from message requests successfully")
                }
            }
        }
        
        // Set local status immediately for better UX
        chatStatus = .declined
    }
}

struct Message: Identifiable, Equatable {
    let id: String
    let text: String
    let isSentByCurrentUser: Bool
    let timestamp: Date
    let status: String
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.isSentByCurrentUser == rhs.isSentByCurrentUser &&
               lhs.timestamp == rhs.timestamp &&
               lhs.status == rhs.status
    }
}

