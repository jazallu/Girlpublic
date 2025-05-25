//
//  ProfilePhotoUploadView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/18/25.
//
import SwiftUI
import FirebaseStorage
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct ProfilePhotoUploadView: View {
    @Binding var step: Int
    @Binding var profilePhotos: [UIImage?]
    @Binding var uploadedImageURLs: [String]
    @Binding var imagePickerPresented: Bool
    @Binding var selectedPhotoIndex: Int?
    @Binding var isLoggedIn: Bool
    var onSave: ([String]) -> Void

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isUploading = false
    @State private var currentPhotoIndex = 0
    @State private var currentProgress: Double? = nil
    @State private var uploadStatus = "Ready"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @AppStorage("uploadComplete") private var uploadComplete = false
    @AppStorage("hasUploadedPhotos") private var hasUploadedPhotos: Bool = false

    @State private var profileCompletionInProgress = false
    @State private var uploadQueue: [Int] = []

    private let totalSteps = 7

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: geometry.size.height * 0.03) {
                    VStack {
                        Text("Step \(step) of \(totalSteps)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: geometry.size.width * 0.04, weight: .medium))
                        ProgressBar(progress: CGFloat(step) / CGFloat(totalSteps))
                            .frame(width: geometry.size.width * 0.75, height: 6)
                    }
                    .padding(.top, geometry.size.height * 0.04)

                    Text("Upload Your Photos")
                        .font(.system(size: geometry.size.width * 0.07, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Please upload at least one photo to continue")
                        .font(.system(size: geometry.size.width * 0.04))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)

                    HStack(spacing: geometry.size.width * 0.03) {
                        ForEach(0..<4, id: \.self) { index in
                            PhotosPicker(selection: Binding(
                                get: { selectedItem },
                                set: { newItem in
                                    selectedItem = newItem
                                    selectedPhotoIndex = index
                                    loadImage(for: index)
                                }
                            ), matching: .images) {
                                ZStack {
                                    if let image = profilePhotos[index] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width * 0.22, height: geometry.size.width * 0.22)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.3), lineWidth: 2))

                                        if isUploading && currentPhotoIndex == index, let progress = currentProgress {
                                            ZStack {
                                                Color.black.opacity(0.5)
                                                    .clipShape(RoundedRectangle(cornerRadius: 15))

                                                VStack(spacing: 4) {
                                                    ProgressView(value: progress, total: 1.0)
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                        .scaleEffect(0.7)

                                                    Text("\(Int(progress * 100))%")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 12, weight: .bold))
                                                }
                                            }
                                        }

                                        if index < uploadedImageURLs.count && !uploadedImageURLs[index].isEmpty {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 22))
                                                        .shadow(color: .black, radius: 2)
                                                        .padding(6)
                                                }
                                            }
                                        }
                                    } else {
                                        RoundedRectangle(cornerRadius: 15)
                                            .frame(width: geometry.size.width * 0.22, height: geometry.size.width * 0.22)
                                            .foregroundColor(.white.opacity(0.1))
                                            .overlay(
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.white.opacity(0.7))
                                            )
                                    }
                                }
                            }
                            .disabled(isUploading || profileCompletionInProgress)
                        }
                    }
                    .padding(.horizontal, 25)

                    // Upload status
                    if isUploading {
                        VStack(spacing: 6) {
                            Text("Uploading photo \(currentPhotoIndex + 1)")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))

                            if let progress = currentProgress {
                                HStack {
                                    ProgressView(value: progress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                                        .frame(width: geometry.size.width * 0.6)

                                    Text("\(Int(progress * 100))%")
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.system(size: 14, weight: .bold))
                                        .frame(width: 50, alignment: .trailing)
                                }
                            }

                            Text(uploadStatus)
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 14))
                                .padding(.top, 2)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .padding(.top, 15)
                    }
                    
                    // Profile completion status
                    if profileCompletionInProgress {
                        VStack(spacing: 6) {
                            Text("Completing your profile...")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                                .padding(.vertical, 8)
                            
                            Text("Please wait, this may take a moment")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .padding(.top, 15)
                    }

                    Spacer()

                    Button(action: {
                        if isUploading || profileCompletionInProgress {
                            return
                        } else if uploadComplete || allPhotosUploaded {
                            completeProfileProcess()
                        } else if hasAtLeastOnePhoto {
                            prepareAndStartUpload()
                        } else {
                            alertMessage = "Please select at least one photo before continuing"
                            showAlert = true
                        }
                    }) {
                        VStack {
                            Text(buttonText)
                                .frame(width: geometry.size.width * 0.8, height: 65)
                                .background(isButtonEnabled ? Color.pink : Color.gray)
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .bold))
                                .cornerRadius(15)

                            if isUploading {
                                Text("Please wait until all photos are uploaded")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.caption)
                                    .padding(.top, 5)
                            }
                        }
                    }
                    .disabled(!isButtonEnabled)
                    .padding(.bottom, geometry.size.height * 0.06)
                }
            }
        }
        .onAppear {
            print("🏞 PhotoUploadView appeared")
            initializeView()
            checkUploadStatus()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Upload Info"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonText: String {
        if isUploading {
            return "Uploading..."
        } else if profileCompletionInProgress {
            return "Completing Profile..."
        } else {
            return "Continue"
        }
    }
    
    private var isButtonEnabled: Bool {
        return (hasAtLeastOnePhoto && !isUploading && !profileCompletionInProgress)
    }
    
    private var hasAtLeastOnePhoto: Bool {
        return profilePhotos.contains { $0 != nil }
    }

    private var allPhotosUploaded: Bool {
        let photoCount = profilePhotos.compactMap { $0 }.count
        let uploadedCount = uploadedImageURLs.filter { !$0.isEmpty }.count
        return photoCount > 0 && photoCount == uploadedCount
    }

    // MARK: - Helper Functions
    
    private func initializeView() {
        // Initialize arrays
        while profilePhotos.count < 4 {
            profilePhotos.append(nil)
        }

        while uploadedImageURLs.count < 4 {
            uploadedImageURLs.append("")
        }
    }

    private func checkUploadStatus() {
        let photoCount = profilePhotos.compactMap { $0 }.count
        let uploadedCount = uploadedImageURLs.filter { !$0.isEmpty }.count

        // If all photos are uploaded, mark as complete
        if photoCount > 0 && uploadedCount == photoCount {
            uploadComplete = true
        }
    }
    
    // MARK: - Core Functionality
    
    private func completeProfileProcess() {
        guard !profileCompletionInProgress else { return }
        
        profileCompletionInProgress = true
        
        print("📱 Completing profile with photos")
        
        // Filter out empty URLs
        let filteredURLs = uploadedImageURLs.filter { !$0.isEmpty }
        
        // Update Firestore with image URLs
        guard let userID = Auth.auth().currentUser?.uid else {
            profileCompletionInProgress = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Update Firestore with the photo URLs and mark step as complete
        db.collection("users").document(userID).setData([
            "imageURLs": filteredURLs,
            "profilePhotos": filteredURLs,
            "lastUpdateTime": FieldValue.serverTimestamp(),
            "hasUploadedPhotos": true,
            "profileStep": 8,  // Directly set to step 8 (rather than 7)
            "hasCompletedProfile": true  // Mark profile as complete
        ], merge: true) { error in
            if let error = error {
                print("❌ Error updating photo URLs: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.profileCompletionInProgress = false
                    self.alertMessage = "There was a problem saving your photos. Please try again."
                    self.showAlert = true
                }
            } else {
                print("✅ Photos saved successfully to Firestore")
                
                DispatchQueue.main.async {
                    // Set local state and UserDefaults
                    self.hasUploadedPhotos = true
                    UserDefaults.standard.set(true, forKey: "hasUploadedPhotos")
                    UserDefaults.standard.set(true, forKey: "hasCompletedProfile")
                    UserDefaults.standard.set(8, forKey: "profileStep")
                    
                    // Notify via notifications
                    NotificationCenter.default.post(name: NSNotification.Name("PhotosUploaded"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("ForceContentViewRefresh"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("StepEightReached"), object: nil)
                    
                    // Call the onSave callback to update the parent view
                    self.onSave(filteredURLs)
                    
                    // Move to step 8 directly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.step = 8
                        self.profileCompletionInProgress = false
                    }
                }
            }
        }
    }

    private func loadImage(for index: Int) {
        guard let selectedItem = selectedItem else { return }

        Task {
            do {
                if let imageData = try await selectedItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: imageData) {
                    await MainActor.run {
                        // Update the photos array
                        while profilePhotos.count <= index {
                            profilePhotos.append(nil)
                        }

                        while uploadedImageURLs.count <= index {
                            uploadedImageURLs.append("")
                        }

                        profilePhotos[index] = uiImage

                        // Mark URL as empty when image is updated
                        uploadedImageURLs[index] = ""
                        uploadComplete = false

                        // Reset selection state
                        self.selectedItem = nil
                    }
                }
            } catch {
                print("❌ Error loading image: \(error.localizedDescription)")
            }
        }
    }

    private func prepareAndStartUpload() {
        guard let userID = Auth.auth().currentUser?.uid else {
            alertMessage = "Unable to identify user. Please try logging out and back in."
            showAlert = true
            return
        }

        // Create upload queue
        uploadQueue = []
        for i in 0..<profilePhotos.count {
            if profilePhotos[i] != nil && (i >= uploadedImageURLs.count || uploadedImageURLs[i].isEmpty) {
                uploadQueue.append(i)
            }
        }

        // If nothing to upload, we're done
        if uploadQueue.isEmpty {
            if hasAtLeastOnePhoto {
                uploadComplete = true
                completeProfileProcess()
            }
            return
        }

        // Start uploads
        isUploading = true
        uploadNextPhoto(userID: userID)
    }

    private func uploadNextPhoto(userID: String) {
        // If queue is empty, we're done
        if uploadQueue.isEmpty {
            isUploading = false
            currentProgress = nil
            uploadStatus = "Upload complete"
            uploadComplete = true
            
            // Complete the profile
            completeProfileProcess()
            return
        }

        currentPhotoIndex = uploadQueue.removeFirst()
        currentProgress = 0
        uploadStatus = "Preparing photo..."

        // Ensure the photo exists
        guard let image = profilePhotos[currentPhotoIndex] else {
            // Skip this photo and move to next
            uploadNextPhoto(userID: userID)
            return
        }

        // Compress the image
        guard let compressedData = compressImage(image) else {
            // Failed to compress, skip this photo
            uploadStatus = "Failed to prepare photo"
            uploadNextPhoto(userID: userID)
            return
        }

        // Create a Firebase Storage reference
        let storage = Storage.storage().reference()
        let timestamp = Int(Date().timeIntervalSince1970)
        let photoRef = storage.child("profile_photos/\(userID)/\(userID)_\(timestamp)_\(currentPhotoIndex).jpg")

        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Start upload with progress monitoring
        uploadStatus = "Uploading..."
        let uploadTask = photoRef.putData(compressedData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Error uploading photo: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.uploadStatus = "Error: \(error.localizedDescription)"
                    // Continue with next photo after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.uploadNextPhoto(userID: userID)
                    }
                }
                return
            }

            // Get download URL
            photoRef.downloadURL { url, error in
                if let url = url {
                    // Success - update the URL
                    DispatchQueue.main.async {
                        // Ensure arrays are large enough
                        while self.uploadedImageURLs.count <= self.currentPhotoIndex {
                            self.uploadedImageURLs.append("")
                        }

                        // Store the URL
                        self.uploadedImageURLs[self.currentPhotoIndex] = url.absoluteString

                        // Update Firestore with the individual URL
                        self.updateFirestore(userID: userID)

                        // Show success momentarily
                        self.uploadStatus = "Photo \(self.currentPhotoIndex + 1) uploaded successfully"

                        // Continue with next photo after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            self.uploadNextPhoto(userID: userID)
                        }
                    }
                } else {
                    // Failed to get URL
                    print("❌ Failed to get download URL: \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        self.uploadStatus = "Error getting download URL"
                        // Continue with next photo
                        self.uploadNextPhoto(userID: userID)
                    }
                }
            }
        }

        // Monitor upload progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }

            DispatchQueue.main.async {
                self.currentProgress = progress.fractionCompleted

                // Update status with percentage occasionally
                if Int(progress.fractionCompleted * 100) % 10 == 0 {
                    self.uploadStatus = "Uploading photo \(self.currentPhotoIndex + 1)..."
                }
            }
        }
    }

    private func updateFirestore(userID: String) {
        // Update Firestore with the latest URLs
        let db = Firestore.firestore()

        db.collection("users").document(userID).setData([
            "imageURLs": uploadedImageURLs,
            "profilePhotos": uploadedImageURLs.filter { !$0.isEmpty },
            "lastUpdateTime": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("❌ Error updating Firestore: \(error.localizedDescription)")
            }
        }
    }

    // Helper function to compress images for upload
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize large images
        var finalImage = image
        let maxDimension: CGFloat = 1200

        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                finalImage = resizedImage
            }
            UIGraphicsEndImageContext()
        }

        // Compress with medium quality
        return finalImage.jpegData(compressionQuality: 0.7)
    }
}
