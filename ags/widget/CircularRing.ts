import { Gtk } from "ags/gtk3"

interface CircularProps {
    value: number       // 0-100
    label: string       // center label e.g. "72%"
    sublabel: string    // bottom label e.g. "CPU"
    color: string       // CSS color string
    size?: number
}

export default function CircularRing({ value, label, sublabel, color, size = 110 }: CircularProps) {
    const drawingArea = new Gtk.DrawingArea()
    drawingArea.set_size_request(size, size)

    drawingArea.connect("draw", (_, cr) => {
        const cx = size / 2
        const cy = size / 2
        const radius = size / 2 - 10
        const lineWidth = 8
        const startAngle = -Math.PI / 2
        const endAngle = startAngle + (2 * Math.PI * Math.min(value, 100) / 100)

        // Background ring
        cr.setLineWidth(lineWidth)
        cr.setSourceRGBA(1, 1, 1, 0.08)
        cr.arc(cx, cy, radius, 0, 2 * Math.PI)
        cr.stroke()

        // Foreground ring
        cr.setLineWidth(lineWidth)

        // Parse color from CSS variable fallback to accent blue
        const r = color === "cpu"  ? 0.69 : color === "mem" ? 0.56 : 0.38
        const g = color === "cpu"  ? 0.78 : color === "mem" ? 0.73 : 0.73
        const b = color === "cpu"  ? 1.0  : color === "mem" ? 0.87 : 1.0

        cr.setSourceRGBA(r, g, b, 0.9)
        cr.setLineCap(1) // round caps
        cr.arc(cx, cy, radius, startAngle, endAngle)
        cr.stroke()

        // Center label
        cr.setSourceRGBA(0.89, 0.89, 0.91, 1)
        cr.selectFontFace("JetBrainsMono Nerd Font", 0, 1)
        cr.setFontSize(size * 0.16)
        const ext = cr.textExtents(label)
        cr.moveTo(cx - ext.width / 2, cy + ext.height / 2)
        cr.showText(label)

        // Sub label
        cr.setSourceRGBA(0.77, 0.77, 0.82, 0.8)
        cr.selectFontFace("JetBrainsMono Nerd Font", 0, 0)
        cr.setFontSize(size * 0.11)
        const ext2 = cr.textExtents(sublabel)
        cr.moveTo(cx - ext2.width / 2, cy + size * 0.28)
        cr.showText(sublabel)

        return false
    })

    return drawingArea
}
