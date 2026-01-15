import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel: ProductDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    init(product: Product) {
        self.product = product
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productId: product.id))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Ürün Resmi
                if let imageUrl = product.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 300)
                    .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Başlık ve Fiyat
                    Text(product.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(String(format: "₺%.2f", product.price))
                            .font(.title3)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", product.averageRating))
                                .fontWeight(.semibold)
                            Text("(\(product.reviewCount) yorum)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider()
                    
                    // Kategori
                    HStack {
                        Text("Kategori:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(product.category)
                            .foregroundColor(.gray)
                    }
                    
                    // Açıklama
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Açıklama")
                            .font(.headline)
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    // AI Özeti (varsa)
                    if let aiSummary = product.aiSummary, !aiSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("AI Özeti")
                                    .font(.headline)
                            }
                            Text(aiSummary)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Yorum Puanı Dağılımı
                    if let ratingBreakdown = product.ratingBreakdown {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Puan Dağılımı")
                                .font(.headline)
                            
                            ForEach(Array([5, 4, 3, 2, 1]), id: \.self) { rating in
                                if let count = ratingBreakdown[String(rating)] {
                                    HStack(spacing: 8) {
                                        Text("\(rating)★")
                                            .frame(width: 30)
                                        ProgressView(value: Double(count), total: Double(product.reviewCount))
                                        Text("\(count)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
                .padding()
                
                // Yorumlar Bölümü
                VStack(alignment: .leading, spacing: 12) {
                    Text("Müşteri Yorumları")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoadingReviews && viewModel.reviews.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if viewModel.reviews.isEmpty {
                        Text("Henüz yorum yok")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.reviews) { review in
                                ReviewCardView(review: review)
                                
                                if viewModel.reviews.last?.id == review.id && viewModel.hasMoreReviews {
                                    ProgressView()
                                        .onAppear {
                                            Task {
                                                await viewModel.loadMoreReviews()
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Yorum Ekleme Formu
                VStack(alignment: .leading, spacing: 12) {
                    Text("Yorum Yazın")
                        .font(.headline)
                    
                    // Ad
                    TextField("Adınız", text: $viewModel.reviewerName)
                        .textFieldStyle(.roundedBorder)
                    
                    // Puan Seçimi
                    VStack(alignment: .leading) {
                        Text("Puanınız: \(viewModel.selectedRating)★")
                            .font(.subheadline)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { rating in
                                Button(action: {
                                    viewModel.selectedRating = rating
                                }) {
                                    Image(systemName: rating <= viewModel.selectedRating ? "star.fill" : "star")
                                        .font(.title3)
                                        .foregroundColor(rating <= viewModel.selectedRating ? .yellow : .gray)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    // Yorum Metni
                    TextEditor(text: $viewModel.reviewComment)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    // Hata Mesajı
                    if let error = viewModel.error {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Gönder Butonu
                    Button(action: {
                        Task {
                            await viewModel.submitReview()
                        }
                    }) {
                        HStack {
                            if viewModel.isSubmittingReview {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Yorumu Gönder")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isSubmittingReview || viewModel.reviewerName.isEmpty || viewModel.reviewComment.isEmpty)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding()
            }
        }
        .navigationTitle("Ürün Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchProductDetail()
            await viewModel.fetchReviews()
        }
    }
}

struct ReviewCardView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.reviewerName)
                        .fontWeight(.semibold)
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(star <= review.rating ? .yellow : .gray)
                        }
                    }
                }
                Spacer()
                Text(review.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Text(review.comment)
                .font(.body)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "hand.thumbsup")
                    .font(.caption)
                Text("\(review.helpfulCount)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    let sampleProduct = Product(
        id: 1,
        name: "Örnek Ürün",
        description: "Bu bir örnek ürün tanımlamasıdır",
        category: "Elektronik",
        price: 299.99,
        imageUrl: nil,
        averageRating: 4.5,
        reviewCount: 10,
        ratingBreakdown: nil,
        aiSummary: nil
    )
    ProductDetailView(product: sampleProduct)
}
