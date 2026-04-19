import { createPoll } from "ags/time"

// Returns CPU usage percentage 0-100
export const cpuUsage = createPoll(0, 2000, async () => {
    const out = await import("ags/process").then(m =>
        m.execAsync("bash -c \"grep -m1 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {printf \\\"%d\\\", usage}'\"")
    )
    return parseInt(out) || 0
})
