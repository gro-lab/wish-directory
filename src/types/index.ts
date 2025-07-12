// src/types/index.ts
export interface ITunesApp {
  trackId: number
  trackName: string
  sellerName: string
  artworkUrl100: string
  formattedPrice: string
  price: number
  currency: string
  description: string
  averageUserRating: number
  userRatingCount: number
  primaryGenreName: string
  releaseDate: string
  currentVersionReleaseDate: string
}

export interface WishlistItem extends ITunesApp {
  id: string
  addedDate: string
  notes?: string
  priority?: 'low' | 'medium' | 'high'
}
