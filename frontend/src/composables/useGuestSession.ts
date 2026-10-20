import { useSessionStorage } from '@vueuse/core'
import { computed, ref } from 'vue'
import type { Reservation } from '@/api/types'

const token = useSessionStorage('quickcheck.guest-token', '')
const reservation = ref<Reservation | null>(null)

export function useGuestSession() {
  return {
    token,
    reservation,
    isSignedIn: computed(() => token.value !== ''),
    signIn(newToken: string, newReservation: Reservation) {
      token.value = newToken
      reservation.value = newReservation
    },
    signOut() {
      token.value = ''
      reservation.value = null
    },
  }
}
