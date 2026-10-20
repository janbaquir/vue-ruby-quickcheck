<script setup lang="ts">
import { LogOutIcon, RotateCwIcon } from '@lucide/vue'
import { computed, ref, watch } from 'vue'
import { ApiError, errorMessage } from '@/api/client'
import { staffApi } from '@/api/staff'
import type { ArrivalsSummary, IntegrationEvent, Reservation } from '@/api/types'
import CheckInStatusBadge from '@/components/CheckInStatusBadge.vue'
import FormField from '@/components/FormField.vue'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Table, TableBody, TableCell, TableEmpty, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { usePolling } from '@/composables/usePolling'
import { useStaffSession } from '@/composables/useStaffSession'
import { formatDate, formatTime } from '@/lib/format'
import { cn } from '@/lib/utils'

const REFRESH_INTERVAL_MS = 3000

const staff = useStaffSession()
const tokenInput = ref('')
const date = ref('')
const summary = ref<ArrivalsSummary>({ total: 0 })
const arrivals = ref<Reservation[]>([])
const events = ref<IntegrationEvent[]>([])
const error = ref('')
const retrying = ref(new Set<number>())

const stats = computed(() => [
  { label: 'Arrivals today', value: summary.value.total },
  { label: 'Checked in', value: summary.value.key_issued ?? 0 },
  { label: 'In progress', value: (summary.value.pending ?? 0) + (summary.value.pms_synced ?? 0) },
  { label: 'Needs attention', value: summary.value.failed ?? 0, alert: true },
])

async function load() {
  const [arrivalsResponse, eventsResponse] = await Promise.all([
    staffApi.arrivals(staff.token.value),
    staffApi.integrationEvents(staff.token.value),
  ])
  date.value = arrivalsResponse.date
  summary.value = arrivalsResponse.summary
  arrivals.value = arrivalsResponse.arrivals
  events.value = eventsResponse.events
}

const polling = usePolling(async () => {
  try {
    await load()
    error.value = ''
  } catch (e) {
    if (e instanceof ApiError && e.status === 401) {
      staff.signOut()
      tokenInput.value = ''
    }
    error.value = errorMessage(e)
  }
}, REFRESH_INTERVAL_MS)

watch(staff.isSignedIn, (signedIn) => (signedIn ? polling.start() : polling.stop()), { immediate: true })

function signIn() {
  staff.token.value = tokenInput.value.trim()
}

async function retry(checkInId: number) {
  retrying.value.add(checkInId)
  try {
    await staffApi.retryCheckIn(staff.token.value, checkInId)
    await load()
  } catch (e) {
    error.value = errorMessage(e)
  } finally {
    retrying.value.delete(checkInId)
  }
}

const OUTCOME_VARIANTS = { success: 'secondary', transient_failure: 'outline', permanent_failure: 'destructive' } as const
</script>

<template>
  <Card v-if="!staff.isSignedIn.value" class="mx-auto w-full max-w-sm">
    <CardHeader>
      <CardTitle>Front desk sign in</CardTitle>
      <CardDescription>Use the demo staff token: <code>demo-staff-token</code></CardDescription>
    </CardHeader>
    <form @submit.prevent="signIn">
      <CardContent class="grid gap-4">
        <Alert v-if="error" variant="destructive">
          <AlertDescription>{{ error }}</AlertDescription>
        </Alert>
        <FormField id="staff-token" label="Staff token">
          <Input id="staff-token" v-model="tokenInput" type="password" autocomplete="off" required />
        </FormField>
      </CardContent>
      <CardFooter class="mt-6">
        <Button type="submit" class="w-full">Sign in</Button>
      </CardFooter>
    </form>
  </Card>

  <div v-else class="grid gap-6">
    <div class="flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold">Today's arrivals</h1>
        <p class="text-sm text-muted-foreground">
          {{ date ? formatDate(date) : '…' }} · refreshes every {{ REFRESH_INTERVAL_MS / 1000 }}s
        </p>
      </div>
      <Button variant="outline" size="sm" @click="staff.signOut"><LogOutIcon /> Sign out</Button>
    </div>

    <Alert v-if="error" variant="destructive">
      <AlertDescription>{{ error }}</AlertDescription>
    </Alert>

    <div class="grid grid-cols-2 gap-4 lg:grid-cols-4">
      <Card v-for="stat in stats" :key="stat.label" size="sm">
        <CardHeader>
          <CardDescription>{{ stat.label }}</CardDescription>
          <CardTitle :class="cn('text-3xl tabular-nums', stat.alert && stat.value > 0 && 'text-destructive')">
            {{ stat.value }}
          </CardTitle>
        </CardHeader>
      </Card>
    </div>

    <Card>
      <CardHeader>
        <CardTitle>Check-ins</CardTitle>
        <CardDescription>Failed check-ins resume from the step that failed when retried.</CardDescription>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Room</TableHead>
              <TableHead>Guest</TableHead>
              <TableHead>Booking</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Door code</TableHead>
              <TableHead>Issue</TableHead>
              <TableHead class="text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="arrival in arrivals" :key="arrival.id">
              <TableCell class="font-medium">{{ arrival.room.number }}</TableCell>
              <TableCell>{{ arrival.guest.first_name }} {{ arrival.guest.last_name }}</TableCell>
              <TableCell class="font-mono text-xs">{{ arrival.confirmation_code }}</TableCell>
              <TableCell><CheckInStatusBadge :status="arrival.check_in?.status ?? null" /></TableCell>
              <TableCell class="font-mono">{{ arrival.check_in?.digital_key?.access_code ?? '—' }}</TableCell>
              <TableCell class="max-w-64 truncate text-xs text-muted-foreground" :title="arrival.check_in?.last_error ?? ''">
                {{ arrival.check_in?.last_error ?? '' }}
              </TableCell>
              <TableCell class="text-right">
                <Button
                  v-if="arrival.check_in?.status === 'failed'"
                  size="sm"
                  variant="outline"
                  :disabled="retrying.has(arrival.check_in.id)"
                  @click="retry(arrival.check_in.id)"
                >
                  <RotateCwIcon :class="retrying.has(arrival.check_in.id) && 'animate-spin'" /> Retry
                </Button>
              </TableCell>
            </TableRow>
            <TableEmpty v-if="arrivals.length === 0" :colspan="7">No arrivals today.</TableEmpty>
          </TableBody>
        </Table>
      </CardContent>
    </Card>

    <Card>
      <CardHeader>
        <CardTitle>Integration log</CardTitle>
        <CardDescription>Latest calls to the PMS and smart-lock provider.</CardDescription>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Time</TableHead>
              <TableHead>Booking</TableHead>
              <TableHead>Call</TableHead>
              <TableHead>Outcome</TableHead>
              <TableHead class="text-right">HTTP</TableHead>
              <TableHead class="text-right">Duration</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="event in events" :key="event.id">
              <TableCell class="tabular-nums">{{ formatTime(event.created_at) }}</TableCell>
              <TableCell class="font-mono text-xs">{{ event.confirmation_code ?? '—' }}</TableCell>
              <TableCell>{{ event.provider }} · {{ event.operation }}</TableCell>
              <TableCell>
                <Badge :variant="OUTCOME_VARIANTS[event.outcome]">{{ event.outcome.replace('_', ' ') }}</Badge>
              </TableCell>
              <TableCell class="text-right tabular-nums">{{ event.http_status ?? '—' }}</TableCell>
              <TableCell class="text-right tabular-nums">{{ event.duration_ms ?? '—' }} ms</TableCell>
            </TableRow>
            <TableEmpty v-if="events.length === 0" :colspan="6">No integration calls yet.</TableEmpty>
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  </div>
</template>
