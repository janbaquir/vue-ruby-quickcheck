import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import type { CheckIn } from '@/api/types'
import CheckInProgress from './CheckInProgress.vue'

function checkIn(overrides: Partial<CheckIn>): CheckIn {
  return {
    id: 1,
    status: 'pending',
    terminal: false,
    pms_synced_at: null,
    key_issued_at: null,
    failed_at: null,
    digital_key: null,
    ...overrides,
  }
}

const states = (wrapper: ReturnType<typeof mount>) => wrapper.findAll('li').map((li) => li.attributes('data-state'))

describe('CheckInProgress', () => {
  it('shows the PMS step in progress for a new check-in', () => {
    expect(states(mount(CheckInProgress, { props: { checkIn: checkIn({}) } }))).toEqual(['done', 'active', 'waiting'])
  })

  it('marks the key step as failed when the PMS step had already succeeded', () => {
    const props = { checkIn: checkIn({ status: 'failed', pms_synced_at: '2026-10-20T10:00:00Z' }) }
    expect(states(mount(CheckInProgress, { props }))).toEqual(['done', 'done', 'failed'])
  })
})
