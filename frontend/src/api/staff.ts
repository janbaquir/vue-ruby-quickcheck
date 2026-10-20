import { request } from './client'
import type { ArrivalsSummary, IntegrationEvent, Reservation } from './types'

const auth = (token: string) => ({ 'X-Staff-Token': token })

export const staffApi = {
  arrivals(token: string) {
    return request<{ date: string; summary: ArrivalsSummary; arrivals: Reservation[] }>('/staff/arrivals', {
      headers: auth(token),
    })
  },

  integrationEvents(token: string) {
    return request<{ events: IntegrationEvent[] }>('/staff/integration_events', { headers: auth(token) })
  },

  retryCheckIn(token: string, checkInId: number) {
    return request<{ reservation: Reservation }>(`/staff/check_ins/${checkInId}/retry`, {
      method: 'POST',
      headers: auth(token),
    })
  },
}
