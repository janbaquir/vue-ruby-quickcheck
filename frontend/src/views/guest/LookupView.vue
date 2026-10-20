<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { errorMessage } from '@/api/client'
import { guestApi } from '@/api/guest'
import FormField from '@/components/FormField.vue'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { useGuestSession } from '@/composables/useGuestSession'

const route = useRoute()
const router = useRouter()
const session = useGuestSession()

const form = reactive({ confirmationCode: '', lastName: '' })
const submitting = ref(false)
const error = ref(route.query.expired ? 'Your session expired. Please look up your booking again.' : '')

async function submit() {
  submitting.value = true
  error.value = ''
  try {
    const { token, reservation } = await guestApi.createSession(form.confirmationCode, form.lastName)
    session.signIn(token, reservation)
    await router.push({ name: reservation.check_in ? 'guest-status' : 'guest-registration' })
  } catch (e) {
    error.value = errorMessage(e)
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <Card class="mx-auto w-full max-w-md">
    <CardHeader>
      <CardTitle class="text-xl">Online check-in</CardTitle>
      <CardDescription>Skip the front desk. Enter your booking details to get your digital room key.</CardDescription>
    </CardHeader>
    <form @submit.prevent="submit">
      <CardContent class="grid gap-4">
        <Alert v-if="error" variant="destructive">
          <AlertDescription>{{ error }}</AlertDescription>
        </Alert>
        <FormField id="confirmation-code" label="Booking code">
          <Input
            id="confirmation-code"
            v-model="form.confirmationCode"
            placeholder="QC1002"
            autocapitalize="characters"
            autocomplete="off"
            required
          />
        </FormField>
        <FormField id="last-name" label="Last name">
          <Input id="last-name" v-model="form.lastName" placeholder="Smith" autocomplete="family-name" required />
        </FormField>
      </CardContent>
      <CardFooter class="mt-6 flex-col items-stretch gap-3">
        <Button type="submit" size="lg" :disabled="submitting">
          {{ submitting ? 'Finding your booking…' : 'Find my booking' }}
        </Button>
        <p class="text-center text-xs text-muted-foreground">
          Demo bookings: QC1001 Tanaka · QC1002 Smith · QC1003 Santos · QC1004 Kim · QC1005 Brown
        </p>
      </CardFooter>
    </form>
  </Card>
</template>
