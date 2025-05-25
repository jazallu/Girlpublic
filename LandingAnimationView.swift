import SwiftUI

struct LandingAnimationView: View {
    @State private var scaleLogo = false
    @State private var navigateToSignIn = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("G I R L")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.systemPink))
                    .scaleEffect(scaleLogo ? 1.0 : 0.5) // Logo "pop" effect
                    .animation(.easeIn(duration: 1.0), value: scaleLogo)
            }
        }
        .onAppear {
            // Make the logo pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                scaleLogo = true
            }
            
            // Transition to the sign-in page after the logo animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                navigateToSignIn = true
            }
        }
        .fullScreenCover(isPresented: $navigateToSignIn) {
            LandingView()
        }
    }
}

struct LandingAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        LandingAnimationView()
    }
}

