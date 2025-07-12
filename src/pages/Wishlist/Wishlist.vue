<!-- src/pages/Wishlist/Wishlist.vue -->
<template>
  <div class="wishlist">
    <h2>💝 My Wishlist</h2>
    
    <div v-if="wishlistItems.length === 0" class="empty">
      <p>Your wishlist is empty</p>
      <router-link to="/search" class="search-link">
        Search for apps to add →
      </router-link>
    </div>
    
    <div v-else class="wishlist-grid">
      <div v-for="item in wishlistItems" :key="item.id" class="wishlist-item">
        <img :src="item.artworkUrl100" :alt="item.trackName" />
        <div class="item-info">
          <h3>{{ item.trackName }}</h3>
          <p>{{ item.sellerName }}</p>
          <p class="price">{{ item.formattedPrice }}</p>
          <p class="added-date">Added: {{ formatDate(item.addedDate) }}</p>
        </div>
        <div class="item-actions">
          <button @click="removeFromWishlist(item.id)" class="remove-button">
            Remove
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useWishlistStore } from '@/stores/wishlist'

const wishlistStore = useWishlistStore()

// ✅ Fixed: Use computed property from the store instead of ref([])
const wishlistItems = computed(() => wishlistStore.items)

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString()
}

const removeFromWishlist = (id: string) => {
  wishlistStore.removeItem(id)
  console.log('Removed from wishlist:', id)
  // TODO: Show success notification
}
</script>

<style scoped>
.wishlist {
  max-width: 1200px;
  margin: 0 auto;
}

.empty {
  text-align: center;
  padding: 3rem;
  color: #666;
}

.search-link {
  color: #005fcc;
  text-decoration: none;
  font-weight: 600;
}

.wishlist-grid {
  display: grid;
  gap: 1rem;
}

.wishlist-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
}

.wishlist-item img {
  width: 60px;
  height: 60px;
  border-radius: 8px;
}

.item-info {
  flex: 1;
}

.item-info h3 {
  margin: 0 0 0.5rem 0;
}

.item-info p {
  margin: 0.25rem 0;
  color: #666;
}

.price {
  color: #005fcc;
  font-weight: bold;
}

.remove-button {
  background: #dc3545;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
}
</style>