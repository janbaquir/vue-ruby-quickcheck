<script setup lang="ts">
import { computed } from 'vue'
import type { CheckInStatus } from '@/api/types'
import { Badge, type BadgeVariants } from '@/components/ui/badge'

const props = defineProps<{ status: CheckInStatus | null }>()

const DISPLAY: Record<CheckInStatus | 'not_started', { label: string; variant: BadgeVariants['variant']; class?: string }> = {
  not_started: { label: 'Not started', variant: 'outline' },
  pending: { label: 'Syncing to PMS', variant: 'secondary' },
  pms_synced: { label: 'Issuing key', variant: 'secondary' },
  key_issued: { label: 'Checked in', variant: 'default', class: 'bg-emerald-600 text-white' },
  failed: { label: 'Needs attention', variant: 'destructive' },
}

const display = computed(() => DISPLAY[props.status ?? 'not_started'])
</script>

<template>
  <Badge :variant="display.variant" :class="display.class">{{ display.label }}</Badge>
</template>
