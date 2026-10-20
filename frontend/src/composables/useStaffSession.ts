import { useSessionStorage } from '@vueuse/core'
import { computed } from 'vue'

const token = useSessionStorage('quickcheck.staff-token', '')

export function useStaffSession() {
  return {
    token,
    isSignedIn: computed(() => token.value !== ''),
    signOut() {
      token.value = ''
    },
  }
}
