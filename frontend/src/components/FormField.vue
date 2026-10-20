<script setup lang="ts">
import { Label } from '@/components/ui/label'

defineProps<{ id: string; label: string; errors?: string[] }>()
</script>

<template>
  <div class="grid gap-2">
    <Label :for="id">{{ label }}</Label>
    <slot />
    <p v-if="errors?.length" :id="`${id}-error`" class="text-sm text-destructive first-letter:uppercase">
      {{ errors[0] }}
    </p>
  </div>
</template>
