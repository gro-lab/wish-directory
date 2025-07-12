<!-- src/components/common/LoadingSpinner.vue -->
<template>
  <div class="spinner">
    <div class="spinner-circle"></div>
  </div>
</template>

<script setup lang="ts">
// src/components/common/LoadingSpinner.vue
</script>

<style scoped>
.spinner {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 2rem;
}

.spinner-circle {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #005fcc;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
