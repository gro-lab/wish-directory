// src/stores/wishlist.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { WishlistItem } from '@/types'

export const useWishlistStore = defineStore('wishlist', () => {
  const items = ref<WishlistItem[]>([])
  
  const addItem = (item: WishlistItem) => {
    items.value.push(item)
  }
  
  const removeItem = (id: string) => {
    const index = items.value.findIndex(item => item.id === id)
    if (index > -1) {
      items.value.splice(index, 1)
    }
  }
  
  const getItem = (id: string) => {
    return items.value.find(item => item.id === id)
  }
  
  return {
    items,
    addItem,
    removeItem,
    getItem
  }
})
