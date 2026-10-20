export function formatDate(date: string) {
  return new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium', timeZone: 'UTC' }).format(new Date(date))
}

export function formatDateTime(dateTime: string, timeZone?: string) {
  return new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium', timeStyle: 'short', timeZone }).format(
    new Date(dateTime),
  )
}

export function formatTime(dateTime: string) {
  return new Intl.DateTimeFormat('en-GB', { timeStyle: 'medium' }).format(new Date(dateTime))
}
