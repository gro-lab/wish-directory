<!-- src/pages/NotFound/NotFound.vue -->
<template>
  <div class="not-found">
    <h2>❌ Page Not Found</h2>
    <p>The page you're looking for doesn't exist.</p>
    <router-link to="/" class="home-link">Go Home</router-link>
  </div>
</template>

<script setup lang="ts">
// src/pages/NotFound/NotFound.vue
</script>

<style scoped>
.not-found {
  text-align: center;
  padding: 3rem;
}

.home-link {
  color: #005fcc;
  text-decoration: none;
  font-weight: 600;
}
</style>
