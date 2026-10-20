<script setup lang="ts">
import { CheckIcon, CircleIcon, LoaderCircleIcon, XIcon } from '@lucide/vue'
import { computed } from 'vue'
import type { CheckIn } from '@/api/types'
import { cn } from '@/lib/utils'

type StepState = 'done' | 'active' | 'failed' | 'waiting'

const props = defineProps<{ checkIn: CheckIn }>()

function stepState(completedAt: string | null, isCurrent: boolean): StepState {
  if (completedAt) return 'done'
  if (!isCurrent) return 'waiting'
  return props.checkIn.status === 'failed' ? 'failed' : 'active'
}

const steps = computed(() => {
  const { pms_synced_at, key_issued_at } = props.checkIn
  return [
    { label: 'Registration received', state: 'done' as StepState },
    { label: 'Hotel system updated', state: stepState(pms_synced_at, !pms_synced_at) },
    { label: 'Digital key issued', state: stepState(key_issued_at, !!pms_synced_at) },
  ]
})

const ICONS = { done: CheckIcon, active: LoaderCircleIcon, failed: XIcon, waiting: CircleIcon }
</script>

<template>
  <ol class="space-y-3">
    <li v-for="step in steps" :key="step.label" class="flex items-center gap-3" :data-state="step.state">
      <span
        :class="
          cn(
            'flex size-7 items-center justify-center rounded-full border',
            step.state === 'done' && 'border-emerald-600 bg-emerald-600 text-white',
            step.state === 'active' && 'border-primary text-primary',
            step.state === 'failed' && 'border-destructive bg-destructive text-white',
            step.state === 'waiting' && 'text-muted-foreground',
          )
        "
      >
        <component :is="ICONS[step.state]" :class="cn('size-4', step.state === 'active' && 'animate-spin')" />
      </span>
      <span :class="step.state === 'waiting' ? 'text-muted-foreground' : 'font-medium'">{{ step.label }}</span>
    </li>
  </ol>
</template>
