export type CheckInStatus = 'pending' | 'pms_synced' | 'key_issued' | 'failed'

export interface DigitalKey {
  access_code: string
  valid_from: string
  valid_until: string
}

export interface CheckIn {
  id: number
  status: CheckInStatus
  terminal: boolean
  pms_synced_at: string | null
  key_issued_at: string | null
  failed_at: string | null
  last_error?: string | null
  digital_key: DigitalKey | null
}

export interface Guest {
  first_name: string
  last_name: string
  email: string | null
  phone: string | null
  nationality: string | null
  address: string | null
  passport_number: string | null
}

export interface Reservation {
  id: number
  confirmation_code: string
  status: 'booked' | 'checked_in' | 'cancelled'
  arrival_date: string
  departure_date: string
  adults: number
  check_in_open: boolean
  property: { name: string; timezone: string }
  room: { number: string }
  guest: Guest
  check_in: CheckIn | null
}

export interface GuestRegistration {
  first_name: string
  last_name: string
  email: string
  phone: string
  nationality: string
  passport_number: string
  address: string
}

export interface ArrivalsSummary {
  total: number
  not_started?: number
  pending?: number
  pms_synced?: number
  key_issued?: number
  failed?: number
}

export interface IntegrationEvent {
  id: number
  provider: string
  operation: string
  outcome: 'success' | 'transient_failure' | 'permanent_failure'
  http_status: number | null
  duration_ms: number | null
  error_message: string | null
  created_at: string
  confirmation_code: string | null
}
