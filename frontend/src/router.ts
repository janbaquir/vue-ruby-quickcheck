import { createRouter, createWebHistory } from 'vue-router'
import { useGuestSession } from '@/composables/useGuestSession'
import LookupView from '@/views/guest/LookupView.vue'

declare module 'vue-router' {
  interface RouteMeta {
    requiresGuest?: boolean
  }
}

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', name: 'guest-lookup', component: LookupView },
    {
      path: '/check-in',
      name: 'guest-registration',
      component: () => import('@/views/guest/RegistrationView.vue'),
      meta: { requiresGuest: true },
    },
    {
      path: '/check-in/status',
      name: 'guest-status',
      component: () => import('@/views/guest/StatusView.vue'),
      meta: { requiresGuest: true },
    },
    { path: '/staff', name: 'staff-dashboard', component: () => import('@/views/staff/StaffDashboardView.vue') },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

router.beforeEach((to) => {
  if (to.meta.requiresGuest && !useGuestSession().isSignedIn.value) return { name: 'guest-lookup' }
})
