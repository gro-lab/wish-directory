// src/composables/useSearch.ts
import { ref } from 'vue'
import { itunesAPI } from '@/services/api/itunesAPI'
import type { ITunesApp } from '@/types'

export function useSearch() {
  const results = ref<ITunesApp[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  
  const search = async (query: string) => {
    if (!query.trim()) return
    
    loading.value = true
    error.value = null
    
    try {
      results.value = await itunesAPI.searchApps(query)
    } catch (err) {
      error.value = 'Search failed. Please try again.'
      console.error('Search error:', err)
    } finally {
      loading.value = false
    }
  }
  
  const clearResults = () => {
    results.value = []
    error.value = null
  }
  
  return {
    results,
    loading,
    error,
    search,
    clearResults
  }
}
