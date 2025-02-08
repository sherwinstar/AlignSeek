import SwiftUI

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(width: 280)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
} 