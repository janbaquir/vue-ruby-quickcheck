// Mock PMS and smart-lock vendor with failure injection: random 503s, latency,
// and "ghost successes" (work done, 504 returned) to exercise idempotent retries.

const http = require('node:http')
const crypto = require('node:crypto')

const PORT = Number(process.env.PORT || 4000)
const API_KEY = process.env.MOCK_API_KEY || 'dev-mock-key'
const WEBHOOK_SECRET = process.env.PMS_WEBHOOK_SECRET || 'dev-webhook-secret'
const WEBHOOK_URL = process.env.API_WEBHOOK_URL || 'http://api:3000/api/v1/webhooks/pms'

const state = {
  outage: false,
  failureRate: Number(process.env.FAILURE_RATE ?? 0.3),
  maxLatencyMs: Number(process.env.MAX_LATENCY_MS ?? 800),
}

const idempotencyStore = new Map()
const checkIns = new Map()
const keys = new Map()

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify(body))
}

function readJson(req) {
  return new Promise((resolve) => {
    let raw = ''
    req.on('data', (chunk) => (raw += chunk))
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {})
      } catch {
        resolve(null)
      }
    })
  })
}

function log(...args) {
  console.log(new Date().toISOString(), ...args)
}

async function unreliable(req, res, name, handler) {
  if (req.headers.authorization !== `Bearer ${API_KEY}`) {
    return send(res, 401, { error: 'unauthorized' })
  }

  const idempotencyKey = req.headers['idempotency-key']
  if (!idempotencyKey) return send(res, 400, { error: 'Idempotency-Key header is required' })

  await sleep(Math.random() * state.maxLatencyMs)

  if (state.outage) {
    log(`[${name}] outage 503 ${idempotencyKey}`)
    return send(res, 503, { error: 'service unavailable' })
  }

  if (idempotencyStore.has(idempotencyKey)) {
    const stored = idempotencyStore.get(idempotencyKey)
    log(`[${name}] replay ${idempotencyKey} -> ${stored.status}`)
    res.setHeader('Idempotent-Replayed', 'true')
    return send(res, stored.status, stored.body)
  }

  const body = await readJson(req)
  if (body === null) return send(res, 400, { error: 'invalid JSON' })

  const roll = Math.random()
  if (roll < state.failureRate / 2) {
    log(`[${name}] injected 503 ${idempotencyKey}`)
    return send(res, 503, { error: 'service temporarily unavailable' })
  }

  const result = handler(body)
  if (result.status < 300) idempotencyStore.set(idempotencyKey, result)

  if (roll < state.failureRate && result.status < 300) {
    log(`[${name}] ghost success (work done, 504 returned) ${idempotencyKey}`)
    return send(res, 504, { error: 'gateway timeout' })
  }

  log(`[${name}] ${result.status} ${idempotencyKey}`)
  return send(res, result.status, result.body)
}

function pmsCheckIn(pmsReservationId, body) {
  if (!body.room_number || !body.guest?.last_name) {
    return { status: 422, body: { error: 'room_number and guest.last_name are required' } }
  }
  if (pmsReservationId.startsWith('CXL')) {
    return { status: 409, body: { error: 'reservation is cancelled in PMS' } }
  }
  const record = {
    pms_reservation_id: pmsReservationId,
    status: 'IN_HOUSE',
    room_number: body.room_number,
    checked_in_at: new Date().toISOString(),
  }
  checkIns.set(pmsReservationId, record)
  return { status: 200, body: record }
}

function issueKey(body) {
  if (!body.lock_device_id || !body.valid_from || !body.valid_until) {
    return { status: 422, body: { error: 'lock_device_id, valid_from and valid_until are required' } }
  }
  const key = {
    key_id: `key_${crypto.randomUUID()}`,
    lock_device_id: body.lock_device_id,
    access_code: String(crypto.randomInt(100000, 999999)),
    valid_from: body.valid_from,
    valid_until: body.valid_until,
  }
  keys.set(key.key_id, key)
  return { status: 201, body: key }
}

async function sendWebhook(res, body) {
  const event = {
    id: `evt_${crypto.randomUUID()}`,
    type: body.type || 'reservation.updated',
    created_at: new Date().toISOString(),
    data: body.data || {},
  }
  const payload = JSON.stringify(event)
  const timestamp = Math.floor(Date.now() / 1000)
  const signature = crypto.createHmac('sha256', WEBHOOK_SECRET).update(`${timestamp}.${payload}`).digest('hex')

  try {
    const response = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Pms-Timestamp': String(timestamp),
        'X-Pms-Signature': signature,
      },
      body: payload,
    })
    send(res, 200, { delivered: response.ok, api_status: response.status, event })
  } catch (error) {
    send(res, 502, { delivered: false, error: error.message, event })
  }
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`)
  const path = url.pathname

  if (req.method === 'GET' && path === '/health') return send(res, 200, { ok: true, ...state })

  let match
  if (req.method === 'POST' && (match = path.match(/^\/pms\/v1\/reservations\/([\w-]+)\/check_in$/))) {
    return unreliable(req, res, 'pms', (body) => pmsCheckIn(match[1], body))
  }

  if (req.method === 'POST' && path === '/locks/v1/keys') {
    return unreliable(req, res, 'lock', issueKey)
  }

  if (req.method === 'POST' && path === '/__control') {
    const body = (await readJson(req)) || {}
    if (body.outage !== undefined) state.outage = Boolean(body.outage)
    if (body.failure_rate !== undefined) state.failureRate = Number(body.failure_rate)
    if (body.max_latency_ms !== undefined) state.maxLatencyMs = Number(body.max_latency_ms)
    log('[control]', state)
    return send(res, 200, state)
  }

  if (req.method === 'POST' && path === '/__control/webhook') {
    return sendWebhook(res, (await readJson(req)) || {})
  }

  send(res, 404, { error: 'not found' })
})

server.listen(PORT, () => log(`mock services listening on :${PORT}`, state))
