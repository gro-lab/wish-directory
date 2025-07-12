<!-- src/components/common/AppCard.vue -->
<template>
  <div class="app-card">
    <img :src="app.artworkUrl100" :alt="app.trackName" class="app-icon" />
    <div class="app-info">
      <h3 class="app-name">{{ app.trackName }}</h3>
      <p class="app-developer">{{ app.sellerName }}</p>
      <p class="app-price">{{ app.formattedPrice }}</p>
    </div>
    <div class="app-actions">
      <slot name="actions"></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
// src/components/common/AppCard.vue
import type { ITunesApp } from '@/types'

defineProps<{
  app: ITunesApp
}>()
</script>

<style scoped>
.app-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: white;
  transition: box-shadow 0.2s;
}

.app-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.app-icon {
  width: 60px;
  height: 60px;
  border-radius: 8px;
}

.app-info {
  flex: 1;
}

.app-name {
  margin: 0 0 0.5rem 0;
  font-size: 1.1rem;
}

.app-developer {
  margin: 0 0 0.5rem 0;
  color: #666;
}

.app-price {
  margin: 0;
  font-weight: bold;
  color: #005fcc;
}
</style>
