import { onScopeDispose, readonly, ref } from 'vue'

/**
 * Runs `task` every `intervalMs` until it resolves `true` or `stop()` is called.
 * A failing task does not end polling; the latest error is exposed instead.
 */
export function usePolling(task: () => Promise<boolean | void>, intervalMs: number) {
  const isActive = ref(false)
  const error = ref<unknown>(null)
  let timer: ReturnType<typeof setTimeout> | undefined

  async function tick() {
    try {
      const done = await task()
      error.value = null
      if (done === true) return stop()
    } catch (e) {
      error.value = e
    }
    if (isActive.value) timer = setTimeout(tick, intervalMs)
  }

  function start() {
    if (isActive.value) return
    isActive.value = true
    void tick()
  }

  function stop() {
    isActive.value = false
    clearTimeout(timer)
  }

  onScopeDispose(stop)

  return { isActive: readonly(isActive), error: readonly(error), start, stop }
}
