<!-- src/pages/Search/Search.vue -->
<template>
  <div class="search">
    <h2>🔍 Search iOS Apps</h2>
    
    <div class="search-form">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="Search for iOS apps..."
        class="search-input"
        @keyup.enter="searchApps"
      />
      <button @click="searchApps" class="search-button">Search</button>
    </div>
    
    <div v-if="loading" class="loading">
      Searching apps...
    </div>
    
    <div v-if="apps.length > 0" class="results">
      <h3>Found {{ apps.length }} apps</h3>
      <div class="app-grid">
        <div v-for="app in apps" :key="app.trackId" class="app-card">
          <img :src="app.artworkUrl100" :alt="app.trackName" />
          <h4>{{ app.trackName }}</h4>
          <p>{{ app.sellerName }}</p>
          <p class="price">{{ app.formattedPrice }}</p>
          <button @click="addToWishlist(app)" class="add-button">
            Add to Wishlist
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useWishlistStore } from '@/stores/wishlist'
import type { ITunesApp, WishlistItem } from '@/types'
import { itunesAPI } from '@/services/api/itunesAPI'

const searchQuery = ref('')
const loading = ref(false)
const apps = ref<ITunesApp[]>([])  // ✅ Fixed: Added type annotation

const wishlistStore = useWishlistStore()

const searchApps = async () => {
  if (!searchQuery.value.trim()) return
  
  loading.value = true
  try {
    // ✅ Fixed: Pass string directly to searchApps
    apps.value = await itunesAPI.searchApps(searchQuery.value)
    console.log(`Found ${apps.value.length} apps`)
  } catch (error) {
    console.error('Search error:', error)
    apps.value = []
    // TODO: Show error notification
  } finally {
    loading.value = false
  }
}

const addToWishlist = (app: ITunesApp) => {
  // ✅ Fixed: Convert ITunesApp to WishlistItem
  const wishlistItem: WishlistItem = {
    ...app,
    id: String(app.trackId),
    addedDate: new Date().toISOString(),
    notes: '',
    priority: 'medium'
  }
  
  // Check if item already exists
  const exists = wishlistStore.items.some(item => item.id === wishlistItem.id)
  
  if (exists) {
    console.log('Already in wishlist:', app.trackName)
    // TODO: Show already exists notification
  } else {
    wishlistStore.addItem(wishlistItem)
    console.log('Added to wishlist:', app.trackName)
    // TODO: Show success notification
  }
}
</script>

<style scoped>
.search {
  max-width: 1200px;
  margin: 0 auto;
}

.search-form {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
}

.search-input {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.search-button {
  background: #005fcc;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  cursor: pointer;
}

.app-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1rem;
}

.app-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1rem;
  text-align: center;
}

.app-card img {
  width: 80px;
  height: 80px;
  border-radius: 8px;
}

.price {
  font-weight: bold;
  color: #005fcc;
}

.add-button {
  background: #28a745;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
}
</style>