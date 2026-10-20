import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { effectScope } from 'vue'
import { usePolling } from './usePolling'

describe('usePolling', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => vi.useRealTimers())

  it('polls until the task reports completion', async () => {
    const task = vi.fn().mockResolvedValueOnce(false).mockResolvedValueOnce(false).mockResolvedValueOnce(true)
    const polling = usePolling(task, 1000)

    polling.start()
    await vi.advanceTimersByTimeAsync(5000)

    expect(task).toHaveBeenCalledTimes(3)
    expect(polling.isActive.value).toBe(false)
  })

  it('keeps polling after a failure and exposes the error', async () => {
    const failure = new Error('network down')
    const task = vi.fn().mockRejectedValueOnce(failure).mockResolvedValue(false)
    const polling = usePolling(task, 1000)

    polling.start()
    await vi.advanceTimersByTimeAsync(0)
    expect(polling.error.value).toBe(failure)

    await vi.advanceTimersByTimeAsync(1000)
    expect(task).toHaveBeenCalledTimes(2)
    expect(polling.error.value).toBeNull()
    polling.stop()
  })

  it('stops when its effect scope is disposed', async () => {
    const task = vi.fn().mockResolvedValue(false)
    const scope = effectScope()
    const polling = scope.run(() => usePolling(task, 1000))!

    polling.start()
    await vi.advanceTimersByTimeAsync(0)
    scope.stop()
    await vi.advanceTimersByTimeAsync(5000)

    expect(task).toHaveBeenCalledTimes(1)
  })
})
