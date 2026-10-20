<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ApiError, errorMessage, type FieldErrors } from '@/api/client'
import { guestApi } from '@/api/guest'
import type { GuestRegistration, Reservation } from '@/api/types'
import FormField from '@/components/FormField.vue'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { Separator } from '@/components/ui/separator'
import { Skeleton } from '@/components/ui/skeleton'
import { useGuestReservation } from '@/composables/useGuestReservation'
import { useGuestSession } from '@/composables/useGuestSession'
import { COUNTRIES } from '@/lib/countries'
import { formatDate } from '@/lib/format'

const router = useRouter()
const session = useGuestSession()
const { reservation, loadError, refresh, handleUnauthorized } = useGuestReservation()

const form = reactive<GuestRegistration>({
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  nationality: '',
  passport_number: '',
  address: '',
})
const fieldErrors = ref<FieldErrors>({})
const formError = ref('')
const submitting = ref(false)

const requiresPassport = computed(() => form.nationality !== '' && form.nationality !== 'JP')

function prefill({ guest }: Reservation) {
  Object.assign(form, {
    first_name: guest.first_name,
    last_name: guest.last_name,
    email: guest.email ?? '',
    phone: guest.phone ?? '',
    nationality: guest.nationality ?? '',
    address: guest.address ?? '',
  })
}

onMounted(async () => {
  const current = reservation.value ?? (await refresh())
  if (!current) return
  if (current.check_in) return router.replace({ name: 'guest-status' })
  prefill(current)
})

async function submit() {
  submitting.value = true
  fieldErrors.value = {}
  formError.value = ''
  try {
    const payload = { ...form, passport_number: requiresPassport.value ? form.passport_number : '' }
    const { reservation: updated } = await guestApi.checkIn(session.token.value, payload)
    reservation.value = updated
    await router.push({ name: 'guest-status' })
  } catch (e) {
    if (await handleUnauthorized(e)) return
    formError.value = errorMessage(e)
    if (e instanceof ApiError) fieldErrors.value = e.details
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <Card class="mx-auto w-full max-w-2xl">
    <CardHeader>
      <CardTitle class="text-xl">Guest registration</CardTitle>
      <CardDescription>Required by Japanese law for every guest staying at the property.</CardDescription>
    </CardHeader>

    <CardContent v-if="!reservation" class="grid gap-3">
      <Alert v-if="loadError" variant="destructive">
        <AlertDescription>{{ loadError }}</AlertDescription>
      </Alert>
      <template v-else>
        <Skeleton class="h-16 w-full" />
        <Skeleton class="h-40 w-full" />
      </template>
    </CardContent>

    <form v-else @submit.prevent="submit">
      <CardContent class="grid gap-6">
        <dl class="grid grid-cols-2 gap-4 rounded-lg bg-muted p-4 text-sm sm:grid-cols-4">
          <div>
            <dt class="text-muted-foreground">Property</dt>
            <dd class="font-medium">{{ reservation.property.name }}</dd>
          </div>
          <div>
            <dt class="text-muted-foreground">Room</dt>
            <dd class="font-medium">{{ reservation.room.number }}</dd>
          </div>
          <div>
            <dt class="text-muted-foreground">Arrival</dt>
            <dd class="font-medium">{{ formatDate(reservation.arrival_date) }}</dd>
          </div>
          <div>
            <dt class="text-muted-foreground">Departure</dt>
            <dd class="font-medium">{{ formatDate(reservation.departure_date) }}</dd>
          </div>
        </dl>

        <Alert v-if="!reservation.check_in_open">
          <AlertDescription>
            Online check-in opens on {{ formatDate(reservation.arrival_date) }}. Please come back then.
          </AlertDescription>
        </Alert>
        <Alert v-if="formError" variant="destructive">
          <AlertDescription>{{ formError }}</AlertDescription>
        </Alert>

        <Separator />

        <div class="grid gap-4 sm:grid-cols-2">
          <FormField id="first-name" label="First name" :errors="fieldErrors.first_name">
            <Input id="first-name" v-model="form.first_name" autocomplete="given-name" :aria-invalid="!!fieldErrors.first_name" required />
          </FormField>
          <FormField id="last-name" label="Last name" :errors="fieldErrors.last_name">
            <Input id="last-name" v-model="form.last_name" autocomplete="family-name" :aria-invalid="!!fieldErrors.last_name" required />
          </FormField>
          <FormField id="email" label="Email" :errors="fieldErrors.email">
            <Input id="email" v-model="form.email" type="email" autocomplete="email" :aria-invalid="!!fieldErrors.email" required />
          </FormField>
          <FormField id="phone" label="Phone (optional)" :errors="fieldErrors.phone">
            <Input id="phone" v-model="form.phone" type="tel" autocomplete="tel" />
          </FormField>
          <FormField id="nationality" label="Nationality" :errors="fieldErrors.nationality">
            <NativeSelect id="nationality" v-model="form.nationality" class="w-full" :aria-invalid="!!fieldErrors.nationality" required>
              <NativeSelectOption value="" disabled>Select a country</NativeSelectOption>
              <NativeSelectOption v-for="country in COUNTRIES" :key="country.code" :value="country.code">
                {{ country.name }}
              </NativeSelectOption>
            </NativeSelect>
          </FormField>
          <FormField v-if="requiresPassport" id="passport-number" label="Passport number" :errors="fieldErrors.passport_number">
            <Input id="passport-number" v-model="form.passport_number" autocomplete="off" :aria-invalid="!!fieldErrors.passport_number" required />
          </FormField>
          <FormField id="address" label="Home address" :errors="fieldErrors.address" class="sm:col-span-2">
            <Input id="address" v-model="form.address" autocomplete="street-address" :aria-invalid="!!fieldErrors.address" required />
          </FormField>
        </div>
      </CardContent>
      <CardFooter class="mt-6 justify-end">
        <Button type="submit" size="lg" :disabled="submitting || !reservation.check_in_open">
          {{ submitting ? 'Checking you in…' : 'Check in' }}
        </Button>
      </CardFooter>
    </form>
  </Card>
</template>
