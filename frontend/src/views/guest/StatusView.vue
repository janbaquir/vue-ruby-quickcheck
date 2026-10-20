<script setup lang="ts">
import { KeyRoundIcon } from '@lucide/vue'
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import CheckInProgress from '@/components/CheckInProgress.vue'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { useGuestReservation } from '@/composables/useGuestReservation'
import { useGuestSession } from '@/composables/useGuestSession'
import { usePolling } from '@/composables/usePolling'
import { formatDateTime } from '@/lib/format'

const router = useRouter()
const session = useGuestSession()
const { reservation, loadError, refresh } = useGuestReservation()

const checkIn = computed(() => reservation.value?.check_in ?? null)
const digitalKey = computed(() => checkIn.value?.digital_key ?? null)

const polling = usePolling(async () => {
  const current = await refresh()
  if (current && !current.check_in) {
    await router.replace({ name: 'guest-registration' })
    return true
  }
  return current?.check_in?.terminal ?? false
}, 2000)

onMounted(polling.start)

function startOver() {
  session.signOut()
  router.push({ name: 'guest-lookup' })
}
</script>

<template>
  <Card class="mx-auto w-full max-w-md">
    <template v-if="digitalKey && reservation">
      <CardHeader>
        <CardTitle class="text-xl">You're checked in</CardTitle>
        <CardDescription>Welcome to {{ reservation.property.name }}, {{ reservation.guest.first_name }}.</CardDescription>
      </CardHeader>
      <CardContent class="grid gap-4">
        <div class="rounded-xl bg-primary p-6 text-center text-primary-foreground">
          <KeyRoundIcon class="mx-auto mb-2 size-6 opacity-80" />
          <p class="text-sm opacity-80">Room {{ reservation.room.number }} door code</p>
          <p class="font-mono text-4xl font-semibold tracking-[0.3em]" data-testid="access-code">
            {{ digitalKey.access_code }}
          </p>
        </div>
        <p class="text-center text-sm text-muted-foreground">
          Valid until {{ formatDateTime(digitalKey.valid_until, reservation.property.timezone) }}
        </p>
      </CardContent>
    </template>

    <template v-else>
      <CardHeader>
        <CardTitle class="text-xl">Finishing your check-in</CardTitle>
        <CardDescription>This usually takes a few seconds. You can keep this page open.</CardDescription>
      </CardHeader>
      <CardContent class="grid gap-6">
        <Alert v-if="checkIn?.status === 'failed'" variant="destructive">
          <AlertTitle>We couldn't finish your check-in automatically</AlertTitle>
          <AlertDescription>Our front desk has been notified. Please visit reception and we'll sort it out right away.</AlertDescription>
        </Alert>
        <Alert v-else-if="loadError" variant="destructive">
          <AlertDescription>{{ loadError }} Retrying…</AlertDescription>
        </Alert>
        <CheckInProgress v-if="checkIn" :check-in="checkIn" />
      </CardContent>
    </template>

    <CardFooter class="mt-2 justify-center">
      <Button variant="ghost" size="sm" @click="startOver">Look up another booking</Button>
    </CardFooter>
  </Card>
</template>
