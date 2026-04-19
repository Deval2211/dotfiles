import { createPoll } from "ags/time"

// Returns memory usage percentage 0-100
export const memUsage = createPoll(0, 3000, async () => {
    const out = await import("ags/process").then(m =>
        m.execAsync("bash -c \"free | awk '/Mem:/ {printf \\\"%d\\\", $3/$2*100}'\"")
    )
    return parseInt(out) || 0
})

// Returns used/total as string e.g. "6.2 / 16 GB"
export const memLabel = createPoll("", 3000, async () => {
    const out = await import("ags/process").then(m =>
        m.execAsync("bash -c \"free -h | awk '/Mem:/ {print $3\\\" / \\\"$2}'\"")
    )
    return out.trim()
})
