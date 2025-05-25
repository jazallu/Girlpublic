//
//  EditProfileView.swift
//  GirlApp
//
//  Created by Jasmitha Allu on 2/25/25.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

struct EditProfileView: View {
    @Binding var isEditingProfile: Bool // To close view
    @State private var name: String = ""
    @State private var birthMonth: String = ""
    @State private var birthDay: String = ""
    @State private var birthYear: String = ""
    @State private var snapchat: String = ""
    @State private var instagram: String = ""
    @State private var selectedColleges: [String] = []
    @State private var selectedMode: String = ""
    @State private var personalityTraits: [String] = []
    @State private var interests: [String] = []
    @State private var profilePhotos: [UIImage?] = Array(repeating: nil, count: 4)
    @State private var uploadedImageURLs: [String] = Array(repeating: "", count: 4)
    @State private var selectedPhotoIndex: Int? = nil
    @State private var imagePickerPresented = false
    @State private var showingCollegeSelector = false
    @State private var searchText: String = ""
    @State private var isLoadingPhotos = true
    
    // All your existing arrays and collections remain unchanged
    let allTraits = ["Tidy", "Messy", "Introvert", "Extrovert", "Night Owl", "Morning Person"]
    let allInterests = ["🎨 Art", "🎧 Music", "🏋️ Fitness", "🍕 Foodie", "✈️ Travel"]
    let allColleges: [String] = [
            "Auburn University", "University of Alabama", "University of Alabama at Birmingham",
                "University of Alaska Fairbanks", "University of Alaska Anchorage", "Alaska Pacific University",
                "Arizona State University", "University of Arizona", "Northern Arizona University",
                "University of Arkansas", "University of Central Arkansas", "Arkansas State University",
                "Stanford University", "University of California, Berkeley", "California Institute of Technology (Caltech)",
                "University of Colorado Boulder", "Colorado State University", "University of Denver",
                "Yale University", "University of Connecticut", "Wesleyan University",
                "University of Delaware", "Delaware State University", "Wilmington University",
                "University of Florida", "University of Miami", "Florida State University",
                "Georgia Institute of Technology", "Emory University", "University of Georgia",
                "University of Hawaiʻi at Mānoa", "Hawaii Pacific University", "Brigham Young University–Hawaii",
                "University of Idaho", "Boise State University", "Idaho State University",
                "University of Chicago", "Northwestern University", "University of Illinois Urbana-Champaign",
                "Purdue University", "University of Notre Dame", "Indiana University Bloomington",
                "University of Iowa", "Iowa State University", "Drake University",
                "University of Kansas", "Kansas State University", "Wichita State University",
                "University of Kentucky", "University of Louisville", "Western Kentucky University",
                "Tulane University", "Louisiana State University", "University of Louisiana at Lafayette",
                "University of Maine", "Bowdoin College", "Bates College",
                "Johns Hopkins University", "University of Maryland, College Park", "University of Maryland, Baltimore County",
                "Massachusetts Institute of Technology (MIT)", "Harvard University", "Tufts University",
                "University of Michigan, Ann Arbor", "Michigan State University", "Wayne State University",
                "University of Minnesota Twin Cities", "University of St. Thomas", "Carleton College",
                "Mississippi State University", "University of Mississippi", "University of Southern Mississippi",
                "Washington University in St. Louis", "University of Missouri", "Missouri University of Science and Technology",
                "University of Montana", "Montana State University", "Carroll College",
                "University of Nebraska-Lincoln", "Creighton University", "University of Nebraska at Omaha",
                "University of Nevada, Reno", "University of Nevada, Las Vegas", "Nevada State College",
                "Dartmouth College", "University of New Hampshire", "Keene State College",
                "Princeton University", "Rutgers University", "Stevens Institute of Technology",
                "University of New Mexico", "New Mexico State University", "New Mexico Institute of Mining and Technology",
                "Columbia University", "New York University (NYU)", "Cornell University",
                "Duke University", "University of North Carolina at Chapel Hill", "North Carolina State University",
                "University of North Dakota", "North Dakota State University", "Minot State University",
                "Ohio State University", "Case Western Reserve University", "University of Cincinnati",
                "University of Oklahoma", "Oklahoma State University", "University of Tulsa",
                "University of Oregon", "Oregon State University", "Portland State University",
                "University of Pennsylvania", "Carnegie Mellon University", "Penn State University",
                "Brown University", "University of Rhode Island", "Providence College",
                "Clemson University", "University of South Carolina", "Furman University",
                "University of South Dakota", "South Dakota State University", "Augustana University",
                "Vanderbilt University", "University of Tennessee, Knoxville", "Belmont University",
                "University of Texas at Austin", "Texas A&M University", "Rice University",
                "University of Utah", "Brigham Young University", "Utah State University",
                "University of Vermont", "Middlebury College", "Norwich University",
                "University of Virginia", "Virginia Tech", "College of William & Mary",
                "University of Washington", "Washington State University", "Gonzaga University",
                "West Virginia University", "Marshall University", "Shepherd University",
                "University of Wisconsin-Madison", "Marquette University", "University of Wisconsin-Milwaukee",
                "University of Wyoming", "Casper College", "Sheridan College", "University of California, Los Angeles (UCLA)",
                "University of California, San Diego","University of California, Irvine","University of California, Santa Barbara",
                "University of California, Riverside","University of California, Santa Cruz","University of California, Merced",
                "San Diego State University", "San Jose State University", "California State University, Fullerton",
                "California State University, Long Beach",
                "California State University, Northridge",
                "California State University, Los Angeles",
                "California State Polytechnic University, Pomona",
                "California Polytechnic State University, San Luis Obispo",
             
                "University of Houston",
                "University of Texas at Dallas",
                "University of Texas at Arlington",
                "University of Texas at San Antonio",
                "University of Texas at El Paso",
                "Texas State University",
                "Texas Tech University",
                "University of North Texas",
                "Sam Houston State University",
                // FLORIDA
                "University of Central Florida",
                "Florida International University",
                "University of South Florida",
                "Florida Atlantic University",
                "University of North Florida",
                "Florida Gulf Coast University",
                // NEW YORK
                "Syracuse University",
                "University at Buffalo (SUNY Buffalo)",
                "Stony Brook University (SUNY)",
                "Binghamton University (SUNY)",
                "University at Albany (SUNY)",
                "Fordham University",
                "Rochester Institute of Technology",
                // PENNSYLVANIA
                "Temple University",
                "Drexel University",
                "West Chester University",
                "Villanova University",
                "Lehigh University",
                // OHIO
                "Kent State University",
                "Miami University (Ohio)",
                "University of Akron",
                "University of Toledo",
                "Bowling Green State University",
                // NORTH CAROLINA
                "University of North Carolina at Charlotte",
                "University of North Carolina at Greensboro",
                "East Carolina University",
                "Appalachian State University",
                "UNC Wilmington",
                // GEORGIA
                "Georgia State University",
                "Kennesaw State University",
                "Georgia Southern University",
                // ILLINOIS
                "University of Illinois Chicago",
                "DePaul University",
                "Loyola University Chicago",
                "Northern Illinois University",
                "Illinois State University",
                // MICHIGAN
                "Western Michigan University",
                "Eastern Michigan University",
                "Central Michigan University",
                "Grand Valley State University",
                "Oakland University",
                // WASHINGTON
                "Western Washington University",
                "Eastern Washington University",
                // MASSACHUSETTS
                "Boston University",
                "Boston College",
                "Northeastern University",
                "UMass Amherst",
                // TENNESSEE
                "University of Tennessee at Chattanooga",
                "University of Memphis",
                "Middle Tennessee State University",
        ]

    
    var filteredColleges: [String] {
        searchText.isEmpty ? allColleges : allColleges.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ✅ Enhanced Profile Photo Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Edit Photos")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                        
                        if isLoadingPhotos {
                            // Show loading indicator while images are loading
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                                .scaleEffect(1.5)
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 12) {
                                ForEach(0..<4, id: \.self) { index in
                                    ZStack {
                                        if let imageURL = URL(string: uploadedImageURLs[index]), !uploadedImageURLs[index].isEmpty {
                                            AsyncImage(url: imageURL) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.pink.opacity(0.7), lineWidth: 2)
                                            )
                                        } else {
                                            Color.gray.opacity(0.3)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .overlay(
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                        Image(systemName: "plus")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.white)
                                                    }
                                                )
                                        }
                                    }
                                    .onTapGesture {
                                        selectedPhotoIndex = index
                                        imagePickerPresented.toggle()
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // ✅ IMPROVED: Name & Basic Info Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Basic Info")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                            .padding(.horizontal)
                        
                        // Enhanced Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.pink)
                                    .font(.system(size: 20))
                                    .frame(width: 24)
                                TextField("Your name", text: $name)
                                    .foregroundColor(.white)
                                    .font(.system(size: 17))
                            }
                            .padding()
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        .onChange(of: name) { _ in saveUserProfile() }
                        
                        // Enhanced Social Media Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Social Media")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            // Snapchat Field with Custom Design
                            HStack {
                                Text("👻")
                                    .font(.system(size: 24))
                                    .frame(width: 30)
                                
                                TextField("Snapchat username", text: $snapchat)
                                    .foregroundColor(.white)
                                    .font(.system(size: 17))
                            }
                            .padding()
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        .onChange(of: snapchat) { _ in saveUserProfile() }
                        
                        // Instagram Field with Custom Design
                        HStack {
                            Text("📸")
                                .font(.system(size: 24))
                                .frame(width: 30)
                            
                            TextField("Instagram username", text: $instagram)
                                .foregroundColor(.white)
                                .font(.system(size: 17))
                        }
                        .padding()
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LinearGradient(
                                    gradient: Gradient(colors: [.purple, .pink, .orange, .yellow]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .onChange(of: instagram) { _ in saveUserProfile() }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // ✅ College Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Colleges")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                        
                        if selectedColleges.isEmpty {
                            Text("No colleges selected")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(selectedColleges, id: \.self) { college in
                                HStack {
                                    Text(college)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button(action: {
                                        removeCollege(college)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Add College Button
                        Button(action: {
                            showingCollegeSelector = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(selectedColleges.isEmpty ? "Add Colleges" :
                                        selectedColleges.count < 3 ? "Add Another College" : "Change Colleges")
                            }
                            .foregroundColor(.pink)
                            .padding(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.pink, lineWidth: 1)
                            )
                        }
                        .disabled(selectedColleges.count >= 3)
                        .opacity(selectedColleges.count >= 3 ? 0.6 : 1)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // ✅ NEW SECTION: Mode Selection (added after college selection)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Looking for")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                        
                        VStack(spacing: 15) {
                            // Find a Roommate Button
                            Button(action: {
                                selectedMode = "Find a Roommate"
                                saveUserProfile()
                            }) {
                                HStack {
                                    Text("Find a Roommate")
                                        .foregroundColor(.white)
                                        .font(.system(size: 22))
                                    Spacer()
                                    if selectedMode == "Find a Roommate" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .padding()
                                .frame(height: 75)
                                .background(selectedMode == "Find a Roommate" ? Color.pink.opacity(0.3) : Color.white.opacity(0.15))
                                .cornerRadius(18)
                            }
                            
                            // Find Friends Button
                            Button(action: {
                                selectedMode = "Find Friends"
                                saveUserProfile()
                            }) {
                                HStack {
                                    Text("Find Friends")
                                        .foregroundColor(.white)
                                        .font(.system(size: 22))
                                    Spacer()
                                    if selectedMode == "Find Friends" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.pink)
                                    }
                                }
                                .padding()
                                .frame(height: 75)
                                .background(selectedMode == "Find Friends" ? Color.pink.opacity(0.3) : Color.white.opacity(0.15))
                                .cornerRadius(18)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // ✅ Personality Traits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personality Traits")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(allTraits, id: \.self) { trait in
                                Button(action: {
                                    toggleTrait(trait)
                                }) {
                                    Text(trait)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(personalityTraits.contains(trait) ? Color.pink : Color.gray.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // ✅ Interests
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(allInterests, id: \.self) { interest in
                                Button(action: {
                                    toggleInterest(interest)
                                }) {
                                    Text(interest)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(interests.contains(interest) ? Color.pink : Color.gray.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                        .frame(height: 20)
                }
                .padding(.vertical)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onAppear {
                fetchUserProfile()
            }
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    isEditingProfile = false
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundColor(.pink)
                }
            )
            .sheet(isPresented: $showingCollegeSelector) {
                CollegeSelectorSheet(
                    selectedColleges: $selectedColleges,
                    searchText: $searchText,
                    filteredColleges: filteredColleges,
                    onSave: {
                        showingCollegeSelector = false
                        saveUserProfile()
                    }
                )
            }
            .sheet(isPresented: $imagePickerPresented) {
                PhotoPicker(selectedIndex: selectedPhotoIndex ?? 0) { index, image in
                    if let image = image {
                        profilePhotos[index] = image
                        uploadPhoto(image, at: index)
                    }
                }
            }
        }
    }
    
    // Fetch Profile Data from Firestore
    private func fetchUserProfile() {
        isLoadingPhotos = true
        
        guard let userID = Auth.auth().currentUser?.uid else {
            isLoadingPhotos = false
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                DispatchQueue.main.async {
                    self.name = data?["name"] as? String ?? ""
                    self.snapchat = data?["snapchat"] as? String ?? ""
                    self.instagram = data?["instagram"] as? String ?? ""
                    self.selectedColleges = data?["colleges"] as? [String] ?? []
                    self.personalityTraits = data?["personalityTraits"] as? [String] ?? []
                    self.interests = data?["interests"] as? [String] ?? []
                    self.selectedMode = data?["mode"] as? String ?? "" // Added for mode selection
                    
                    // First try "profilePhotos" (used by the new background uploader)
                    if let imageURLs = data?["profilePhotos"] as? [String], !imageURLs.isEmpty {
                        self.uploadedImageURLs = imageURLs
                    }
                    // Fall back to "imageURLs" (the field name in original code)
                    else if let imageURLs = data?["imageURLs"] as? [String], !imageURLs.isEmpty {
                        self.uploadedImageURLs = imageURLs
                    }
                    
                    // Ensure we have 4 elements
                    while self.uploadedImageURLs.count < 4 {
                        self.uploadedImageURLs.append("")
                    }
                    
                    // Stop loading indicator
                    self.isLoadingPhotos = false
                }
            } else {
                self.isLoadingPhotos = false
            }
        }
    }
    
    // Save to Firestore instantly when user makes changes
    private func saveUserProfile() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "name": name,
            "snapchat": snapchat,
            "instagram": instagram,
            "colleges": selectedColleges,
            "personalityTraits": personalityTraits,
            "interests": interests,
            "imageURLs": uploadedImageURLs,
            "profilePhotos": uploadedImageURLs, // Save under both keys for compatibility
            "mode": selectedMode // Added for mode selection
        ]
        
        db.collection("users").document(userID).setData(userData, merge: true)
    }
    
    // Add photo upload function
    private func uploadPhoto(_ image: UIImage, at index: Int) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        isLoadingPhotos = true
        
        let storageRef = Storage.storage().reference().child("profile_photos/\(userID)/photo_\(index).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            isLoadingPhotos = false
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("❌ Error uploading photo: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingPhotos = false
                }
            } else {
                storageRef.downloadURL { url, error in
                    DispatchQueue.main.async {
                        if let url = url {
                            self.uploadedImageURLs[index] = url.absoluteString
                            self.saveUserProfile()
                        }
                        self.isLoadingPhotos = false
                    }
                }
            }
        }
    }
    
    private func removeCollege(_ college: String) {
        selectedColleges.removeAll { $0 == college }
        saveUserProfile()
    }
    
    private func toggleTrait(_ trait: String) {
        if personalityTraits.contains(trait) {
            personalityTraits.removeAll { $0 == trait }
        } else {
            personalityTraits.append(trait)
        }
        saveUserProfile()
    }
    
    private func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            interests.removeAll { $0 == interest }
        } else {
            interests.append(interest)
        }
        saveUserProfile()
    }
}

// Simple PhotoPicker component
struct PhotoPicker: UIViewControllerRepresentable {
    let selectedIndex: Int
    let onImagePicked: (Int, UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else {
                parent.onImagePicked(parent.selectedIndex, nil)
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.onImagePicked(self.parent.selectedIndex, image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.parent.onImagePicked(self.parent.selectedIndex, nil)
                    }
                }
            }
        }
    }
}

// College Selector Sheet Component
struct CollegeSelectorSheet: View {
    @Binding var selectedColleges: [String]
    @Binding var searchText: String
    var filteredColleges: [String]
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search colleges...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Selection info text
                Text("Select 1-3 colleges")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                
                // Colleges List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredColleges, id: \.self) { college in
                            Button(action: {
                                toggleSelection(for: college)
                            }) {
                                HStack {
                                    Text(college)
                                        .foregroundColor(selectedColleges.contains(college) ? .white : .pink)
                                    Spacer()
                                    if selectedColleges.contains(college) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(selectedColleges.contains(college) ? Color.pink : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            }
                            .disabled(selectedColleges.count >= 3 && !selectedColleges.contains(college))
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Save Button
                Button(action: onSave) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedColleges.count > 0 ? Color.pink : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                .disabled(selectedColleges.isEmpty)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Select Colleges", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                onSave()
            })
        }
    }
    
    private func toggleSelection(for college: String) {
        if selectedColleges.contains(college) {
            selectedColleges.removeAll { $0 == college }
        } else if selectedColleges.count < 3 {
            selectedColleges.append(college)
        }
    }
}

// For preview in SwiftUI Canvas
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(isEditingProfile: .constant(true))
    }
}
