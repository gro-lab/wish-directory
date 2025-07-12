<!-- src/pages/Home/Home.vue -->
<template>
  <div class="home">
    <h1>🍎 iOS App Wishlist Tracker</h1>
    <p class="subtitle">Track your favorite app prices and never miss a sale!</p>
    
    <div class="features">
      <div class="feature">
        <h3>🔍 Search Apps</h3>
        <p>Find iOS apps using the iTunes API</p>
      </div>
      <div class="feature">
        <h3>💝 Create Wishlist</h3>
        <p>Save apps you want to buy later</p>
      </div>
      <div class="feature">
        <h3>📊 Track Prices</h3>
        <p>Monitor price changes and get alerts</p>
      </div>
    </div>
    
    <router-link to="/search" class="cta-button">
      Start Searching Apps →
    </router-link>
  </div>
</template>

<script setup lang="ts">
// src/pages/Home/Home.vue
</script>

<style scoped>
.home {
  text-align: center;
  max-width: 800px;
  margin: 0 auto;
}

.subtitle {
  font-size: 1.2rem;
  color: #666;
  margin-bottom: 3rem;
}

.features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
  margin: 3rem 0;
}

.feature {
  padding: 2rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: #f9f9f9;
}

.cta-button {
  display: inline-block;
  background: #005fcc;
  color: white;
  padding: 1rem 2rem;
  text-decoration: none;
  border-radius: 8px;
  font-weight: 600;
  margin-top: 2rem;
}

.cta-button:hover {
  background: #0056b3;
}
</style>
