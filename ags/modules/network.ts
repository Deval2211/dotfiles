import { createPoll } from "ags/time"

let prevRx = 0
let prevTx = 0

// Returns download speed in KB/s
export const netSpeed = createPoll({ down: 0, up: 0, iface: "" }, 2000, async () => {
    const { execAsync } = await import("ags/process")

    // Get active interface
    const iface = (await execAsync("bash -c \"ip route | awk '/default/ {print $5; exit}'\"").catch(() => "")).trim()
    if (!iface) return { down: 0, up: 0, iface: "" }

    const stats = await execAsync(`bash -c "cat /proc/net/dev | grep '${iface}'"`)
        .catch(() => "")

    const parts = stats.trim().split(/\s+/)
    const rx = parseInt(parts[1]) || 0
    const tx = parseInt(parts[9]) || 0

    const down = Math.max(0, Math.round((rx - prevRx) / 1024 / 2))
    const up   = Math.max(0, Math.round((tx - prevTx) / 1024 / 2))

    prevRx = rx
    prevTx = tx

    return { down, up, iface }
})

// Returns wifi SSID
export const wifiSSID = createPoll("", 10000, async () => {
    const { execAsync } = await import("ags/process")
    return execAsync("bash -c \"iwgetid -r 2>/dev/null || echo 'No WiFi'\"")
        .then(s => s.trim())
        .catch(() => "No WiFi")
})
