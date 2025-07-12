// src/main.ts
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import './style.css'
import App from './App.vue'

// Import pages
import Home from './pages/Home/Home.vue'
import Search from './pages/Search/Search.vue'
import Wishlist from './pages/Wishlist/Wishlist.vue'
import AppDetails from './pages/AppDetails/AppDetails.vue'
import Privacy from './pages/Privacy/Privacy.vue'
import NotFound from './pages/NotFound/NotFound.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: Home },
    { path: '/search', component: Search },
    { path: '/wishlist', component: Wishlist },
    { path: '/app/:id', component: AppDetails },
    { path: '/privacy', component: Privacy },
    { path: '/:pathMatch(.*)*', component: NotFound }
  ]
})

const pinia = createPinia()
const app = createApp(App)

app.use(pinia)
app.use(router)
app.mount('#app')
