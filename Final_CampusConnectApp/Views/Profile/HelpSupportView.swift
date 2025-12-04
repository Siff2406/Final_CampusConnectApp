import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                 
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.swuRed)
                    
                    Text("How can we help?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("If you have any questions or run into issues, please contact us.")
                        .font(.body)
                        .foregroundColor(.swuTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                 
                VStack(spacing: 16) {
                    ContactCard(icon: "phone.fill", title: "Call Us", detail: "02-649-5000")
                    ContactCard(icon: "envelope.fill", title: "Email Us", detail: "pr@g.swu.ac.th")
                    ContactCard(icon: "mappin.circle.fill", title: "Visit Us", detail: "Srinakharinwirot University\n114 Sukhumvit 23, Bangkok 10110")
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle("Help & Support")
        .background(Color.swuBackground)
    }
}

struct ContactCard: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.swuRed)
                .frame(width: 40, height: 40)
                .background(Color.swuRed.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.swuTextPrimary)
                
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.swuTextSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
