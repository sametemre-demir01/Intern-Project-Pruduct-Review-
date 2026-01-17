import SwiftUI

struct ProductDetailView: View {
    let productId: Int
    @StateObject private var viewModel = ProductDetailViewModel()
    @State private var showingReviewSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Yükleniyor...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let product = viewModel.product {
                    // Product Image
                    AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Category
                        Text(product.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        // Name
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Rating & Reviews
                        HStack {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(product.averageRating.rounded()) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.subheadline)
                                }
                            }
                            
                            Text(String(format: "%.1f", product.averageRating))
                                .fontWeight(.medium)
                            
                            Text("(\(product.reviewCount) yorum)")
                                .foregroundColor(.secondary)
                        }
                        
                        // Price
                        Text(String(format: "₺%.2f", product.price))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Divider()
                        
                        // Description
                        Text("Ürün Açıklaması")
                            .font(.headline)
                        
                        Text(product.description)
                            .foregroundColor(.secondary)
                        
                        // AI Summary
                        if let aiSummary = product.aiSummary, !aiSummary.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                    Text("AI Özet")
                                        .font(.headline)
                                }
                                
                                Text(aiSummary)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                        
                        // Reviews Section
                        HStack {
                            Text("Yorumlar")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingReviewSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Yorum Yaz")
                                }
                                .font(.subheadline)
                            }
                        }
                        
                        if viewModel.reviews.isEmpty && !viewModel.isLoadingReviews {
                            Text("Henüz yorum yok. İlk yorumu siz yazın!")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            ForEach(viewModel.reviews) { review in
                                ReviewCardView(review: review)
                            }
                            
                            if viewModel.hasMoreReviews {
                                Button("Daha Fazla Yorum Yükle") {
                                    Task {
                                        await viewModel.loadMoreReviews(productId: productId)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        }
                        
                        if viewModel.isLoadingReviews {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProduct(id: productId)
            await viewModel.loadReviews(productId: productId, reset: true)
        }
        .sheet(isPresented: $showingReviewSheet) {
            AddReviewView(productId: productId, viewModel: viewModel, isPresented: $showingReviewSheet)
        }
    }
}

struct ReviewCardView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text(review.userName)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < review.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption2)
                        }
                    }
                }
                
                Spacer()
                
                Text(formatDate(review.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.comment)
                .font(.subheadline)
            
            HStack {
                Image(systemName: "hand.thumbsup")
                    .font(.caption)
                Text("\(review.helpfulCount) kişi faydalı buldu")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.locale = Locale(identifier: "tr_TR")
            return displayFormatter.string(from: date)
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.locale = Locale(identifier: "tr_TR")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct AddReviewView: View {
    let productId: Int
    @ObservedObject var viewModel: ProductDetailViewModel
    @Binding var isPresented: Bool
    
    @State private var userName = ""
    @State private var rating = 5
    @State private var comment = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bilgileriniz")) {
                    TextField("Adınız", text: $userName)
                }
                
                Section(header: Text("Puanınız")) {
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Button(action: {
                                rating = index
                            }) {
                                Image(systemName: index <= rating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("Yorumunuz")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: submitReview) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Yorumu Gönder")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(userName.isEmpty || comment.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Yorum Yaz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func submitReview() {
        isSubmitting = true
        Task {
            let success = await viewModel.submitReview(
                productId: productId,
                userName: userName,
                rating: rating,
                comment: comment
            )
            
            isSubmitting = false
            if success {
                isPresented = false
            }
        }
    }
}

#Preview {
    NavigationView {
        ProductDetailView(productId: 1)
    }
}
