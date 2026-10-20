<script setup lang="ts">
import { BedDoubleIcon } from '@lucide/vue'
import { RouterLink, RouterView } from 'vue-router'

const NAV = [
  { to: { name: 'guest-lookup' }, label: 'Guest check-in' },
  { to: { name: 'staff-dashboard' }, label: 'Front desk' },
]
</script>

<template>
  <div class="min-h-svh bg-muted/40">
    <header class="border-b bg-background">
      <div class="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
        <RouterLink to="/" class="flex items-center gap-2 font-semibold">
          <BedDoubleIcon class="size-5" /> QuickCheck
        </RouterLink>
        <nav class="flex gap-1 text-sm">
          <RouterLink
            v-for="item in NAV"
            :key="item.label"
            :to="item.to"
            class="rounded-md px-3 py-1.5 text-muted-foreground transition-colors hover:text-foreground"
            exact-active-class="bg-muted text-foreground"
          >
            {{ item.label }}
          </RouterLink>
        </nav>
      </div>
    </header>
    <main class="mx-auto max-w-6xl px-4 py-10">
      <RouterView />
    </main>
  </div>
</template>
