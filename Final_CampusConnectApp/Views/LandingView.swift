import SwiftUI

struct LandingView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color.swuBackground
                    .ignoresSafeArea()
                
                VStack {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.swuRed)
                    
                    Text("Campus Connect")
                        .font(.system(size: 26, weight: .bold)) 
                        .foregroundColor(.swuTextPrimary)
                        .padding(.top, 8)
                    
                    Text("Srinakharinwirot University")
                        .font(.caption)
                        .foregroundColor(.swuTextSecondary)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
