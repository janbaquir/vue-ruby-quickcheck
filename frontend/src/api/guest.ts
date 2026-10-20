import { request } from './client'
import type { GuestRegistration, Reservation } from './types'

const auth = (token: string) => ({ Authorization: `Bearer ${token}` })

export const guestApi = {
  createSession(confirmationCode: string, lastName: string) {
    return request<{ token: string; reservation: Reservation }>('/guest/session', {
      method: 'POST',
      body: { confirmation_code: confirmationCode, last_name: lastName },
    })
  },

  getReservation(token: string) {
    return request<{ reservation: Reservation }>('/guest/reservation', { headers: auth(token) })
  },

  checkIn(token: string, guest: GuestRegistration) {
    return request<{ reservation: Reservation }>('/guest/check_in', {
      method: 'POST',
      body: { guest },
      headers: auth(token),
    })
  },
}
