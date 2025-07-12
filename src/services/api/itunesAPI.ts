// src/services/api/itunesAPI.ts
import axios from 'axios'
import type { ITunesApp } from '@/types'

const API_BASE_URL = 'https://itunes.apple.com'

export class ITunesAPI {
  async searchApps(query: string, limit = 50): Promise<ITunesApp[]> {
    try {
      const response = await axios.get(`${API_BASE_URL}/search`, {
        params: {
          term: query,
          media: 'software',
          entity: 'software',
          limit
        }
      })
      
      return response.data.results
    } catch (error) {
      console.error('iTunes API error:', error)
      return []
    }
  }
  
  async getApp(id: string): Promise<ITunesApp | null> {
    try {
      const response = await axios.get(`${API_BASE_URL}/lookup`, {
        params: {
          id,
          entity: 'software'
        }
      })
      
      return response.data.results[0] || null
    } catch (error) {
      console.error('iTunes API error:', error)
      return null
    }
  }
}

export const itunesAPI = new ITunesAPI()
