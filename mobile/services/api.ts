// const BASE_URL = "https://product-review-app-solarityai-a391ad53d79a.herokuapp.com"; 
const BASE_URL = "http://localhost:8080";
// const BASE_URL = "http://10.22.225.172:8080";

export type Page<T> = {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number; // page index
  size: number;
  last: boolean;
};

export type ApiProduct = {
  id: number;
  name: string;
  description: string;
  category: string;
  price: number;
  averageRating?: number;
  reviewCount?: number;
  ratingBreakdown?: Record<number, number>;
  imageUrl?: string;
  aiSummary?: string; // ✨ Added aiSummary field
};

export type ApiReview = {
  id?: number;
  reviewerName?: string;
  rating: number;
  comment: string;
  helpfulCount?: number;
  createdAt?: string;
};

async function request<T>(url: string, options?: RequestInit): Promise<T> {
  const res = await fetch(url, options);
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`${res.status} ${res.statusText} - ${text}`);
  }
  return res.json() as Promise<T>;
}

export function getProducts(params?: { 
  page?: number; 
  size?: number; 
  sort?: string; 
  category?: string;
  minPrice?: number;
  maxPrice?: number;
  minRating?: number;
}) {
  const q = new URLSearchParams({
    page: String(params?.page ?? 0),
    size: String(params?.size ?? 10),
    sort: params?.sort ?? "name,asc",
  });
  
  if (params?.category && params.category !== 'All') {
    q.append('category', params.category);
  }
  
  if (params?.minPrice !== undefined) {
    q.append('minPrice', String(params.minPrice));
  }
  
  if (params?.maxPrice !== undefined) {
    q.append('maxPrice', String(params.maxPrice));
  }
  
  if (params?.minRating !== undefined) {
    q.append('minRating', String(params.minRating));
  }
  
  return request<Page<ApiProduct>>(`${BASE_URL}/api/products/filter?${q.toString()}`);
}

export function getProduct(id: number | string) {
  return request<ApiProduct>(`${BASE_URL}/api/products/${id}`);
}

export function getReviews(productId: number | string, params?: { page?: number; size?: number; sort?: string; rating?: number | null }) {
  const q = new URLSearchParams({
    page: String(params?.page ?? 0),
    size: String(params?.size ?? 10),
    sort: params?.sort ?? "createdAt,desc",
  });
  
  if (params?.rating) {
    q.append('rating', String(params.rating));
  }
  
  return request<Page<ApiReview>>(`${BASE_URL}/api/products/${productId}/reviews?${q.toString()}`);
}

export function postReview(productId: number | string, body: ApiReview) {
  return request<ApiReview>(`${BASE_URL}/api/products/${productId}/reviews`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

export function markReviewAsHelpful(reviewId: number | string) {
  return request<ApiReview>(`${BASE_URL}/api/products/reviews/${reviewId}/helpful`, {
    method: "PUT",
  });
}

export function compareProducts(ids: number[]) {
  const idsStr = ids.join(',');
  return request<ApiProduct[]>(`${BASE_URL}/api/products/compare?ids=${idsStr}`);
}

export function compareWithAI(productIds: number[]) {
  return request<{ products: ApiProduct[]; analysis: string }>(`${BASE_URL}/api/ai/compare`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ productIds }),
  });
}

export type PriceDrop = {
  productId: number;
  productName: string;
  oldPrice: number;
  newPrice: number;
  changePercent: number;
  changedAt: string;
};

export function getPriceDrops() {
  return request<PriceDrop[]>(`${BASE_URL}/api/price-alerts/drops`);
}
