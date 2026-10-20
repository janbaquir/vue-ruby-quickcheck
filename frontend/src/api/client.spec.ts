import { afterEach, describe, expect, it, vi } from 'vitest'
import { ApiError, request } from './client'

function mockFetch(response: Partial<Response> | Error) {
  const fetchMock = response instanceof Error ? vi.fn().mockRejectedValue(response) : vi.fn().mockResolvedValue(response)
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

describe('request', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('sends JSON and returns the parsed body', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200, json: () => Promise.resolve({ token: 'abc' }) })

    await expect(request('/guest/session', { method: 'POST', body: { last_name: 'Smith' } })).resolves.toEqual({ token: 'abc' })
    expect(fetchMock).toHaveBeenCalledWith('/api/v1/guest/session', expect.objectContaining({
      method: 'POST',
      body: JSON.stringify({ last_name: 'Smith' }),
      headers: expect.objectContaining({ 'Content-Type': 'application/json' }),
    }))
  })

  it('maps API errors, including field details', async () => {
    mockFetch({
      ok: false,
      status: 422,
      json: () => Promise.resolve({
        error: { code: 'validation_failed', message: 'Please check the highlighted fields.', details: { email: ["can't be blank"] } },
      }),
    })

    const error = await request('/guest/check_in').catch((e: unknown) => e)

    expect(error).toBeInstanceOf(ApiError)
    expect(error).toMatchObject({ status: 422, code: 'validation_failed', details: { email: ["can't be blank"] } })
  })

  it('reports network failures as a network error', async () => {
    mockFetch(new TypeError('Failed to fetch'))

    await expect(request('/guest/reservation')).rejects.toMatchObject({ status: 0, code: 'network_error' })
  })
})
