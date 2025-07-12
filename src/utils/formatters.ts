// src/utils/formatters.ts
export const formatPrice = (price: number, currency = 'USD'): string => {
  if (price === 0) return 'Free'
  
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency
  }).format(price)
}

export const formatDate = (dateString: string): string => {
  return new Date(dateString).toLocaleDateString()
}
