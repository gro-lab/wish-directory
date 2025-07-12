<!-- src/App.vue -->
<template>
  <div id="app">
    <header class="header">
      <nav class="nav">
        <router-link to="/" class="nav-link">🏠 Home</router-link>
        <router-link to="/search" class="nav-link">🔍 Search</router-link>
        <router-link to="/wishlist" class="nav-link">💝 Wishlist</router-link>
      </nav>
    </header>
    
    <main class="main">
      <router-view />
    </main>
    
    <footer class="footer">
      <p>&copy; 2025 iOS App Wishlist Tracker</p>
    </footer>
  </div>
</template>

<script setup lang="ts">
// src/App.vue
</script>

<style scoped>
.header {
  background: #005fcc;
  color: white;
  padding: 1rem;
}

.nav {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

.nav-link {
  color: white;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.nav-link:hover,
.nav-link.router-link-active {
  background-color: rgba(255, 255, 255, 0.2);
}

.main {
  min-height: calc(100vh - 200px);
  padding: 2rem;
}

.footer {
  background: #f5f5f5;
  padding: 1rem;
  text-align: center;
  color: #666;
}
</style>
