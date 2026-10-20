import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ApiError, errorMessage } from '@/api/client'
import { guestApi } from '@/api/guest'
import type { Reservation } from '@/api/types'
import { useGuestSession } from './useGuestSession'

export function useGuestReservation() {
  const session = useGuestSession()
  const router = useRouter()
  const loadError = ref('')

  async function handleUnauthorized(error: unknown) {
    if (!(error instanceof ApiError) || error.status !== 401) return false

    session.signOut()
    await router.replace({ name: 'guest-lookup', query: { expired: '1' } })
    return true
  }

  async function refresh(): Promise<Reservation | null> {
    try {
      const { reservation } = await guestApi.getReservation(session.token.value)
      session.reservation.value = reservation
      loadError.value = ''
      return reservation
    } catch (error) {
      if (!(await handleUnauthorized(error))) loadError.value = errorMessage(error)
      return null
    }
  }

  return { reservation: session.reservation, loadError, refresh, handleUnauthorized }
}
