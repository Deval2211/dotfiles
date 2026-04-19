import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import { cpuUsage } from "../modules/cpu"
import { memUsage, memLabel } from "../modules/memory"
import { netSpeed, wifiSSID } from "../modules/network"

// ─── Helpers ────────────────────────────────────────────────────────────────

function label(text: string, cssClass: string) {
    const l = new Gtk.Label({ label: text })
    l.get_style_context().add_class(cssClass)
    return l
}

function box(orientation: Gtk.Orientation, spacing: number, children: Gtk.Widget[]) {
    const b = new Gtk.Box({ orientation, spacing })
    children.forEach(c => b.pack_start(c, false, false, 0))
    return b
}

// ─── Circular Ring (drawn via CSS + overlay label) ──────────────────────────

function StatRing(opts: {
    poll: ReturnType<typeof createPoll<number>>
    title: string
    sublabel?: ReturnType<typeof createPoll<string>>
    unit?: string
    cssClass: string
}) {
    const { poll, title, sublabel, unit = "%", cssClass } = opts

    // Progress bar styled as ring via CSS
    const bar = new Gtk.ProgressBar()
    bar.get_style_context().add_class("ring")
    bar.get_style_context().add_class(cssClass)
    bar.set_size_request(110, 110)

    const valueLabel = new Gtk.Label({ label: "0" + unit })
    valueLabel.get_style_context().add_class("ring-value")

    const subLabel = new Gtk.Label({ label: title })
    subLabel.get_style_context().add_class("ring-sub")

    // Update on poll change
    poll.subscribe((v: number) => {
        bar.set_fraction(v / 100)
        valueLabel.set_label(`${v}${unit}`)
    })

    if (sublabel) {
        sublabel.subscribe((s: string) => subLabel.set_label(s))
    }

    const inner = box(Gtk.Orientation.VERTICAL, 2, [valueLabel, subLabel])
    inner.set_valign(Gtk.Align.CENTER)
    inner.set_halign(Gtk.Align.CENTER)

    const overlay = new Gtk.Overlay()
    overlay.add(bar)
    overlay.add_overlay(inner)

    const container = box(Gtk.Orientation.VERTICAL, 6, [
        overlay,
        label(title, "ring-title"),
    ])
    container.set_halign(Gtk.Align.CENTER)
    container.get_style_context().add_class("stat-card")

    return container
}

// ─── Network Card ────────────────────────────────────────────────────────────

function NetCard() {
    const ssid = new Gtk.Label({ label: "..." })
    ssid.get_style_context().add_class("net-ssid")

    const down = new Gtk.Label({ label: "↓ 0 KB/s" })
    down.get_style_context().add_class("net-speed")

    const up = new Gtk.Label({ label: "↑ 0 KB/s" })
    up.get_style_context().add_class("net-speed")

    wifiSSID.subscribe((s: string) => ssid.set_label(`  ${s}`))
    netSpeed.subscribe((n: { down: number; up: number }) => {
        down.set_label(`↓ ${n.down} KB/s`)
        up.set_label(`↑ ${n.up} KB/s`)
    })

    const ring = new Gtk.ProgressBar()
    ring.get_style_context().add_class("ring")
    ring.get_style_context().add_class("ring-net")
    ring.set_size_request(110, 110)

    netSpeed.subscribe((n: { down: number }) => {
        // Scale: 0-1000 KB/s = 0-100%
        ring.set_fraction(Math.min(n.down / 1000, 1))
    })

    const speedBox = box(Gtk.Orientation.VERTICAL, 4, [ssid, down, up])
    speedBox.set_valign(Gtk.Align.CENTER)
    speedBox.set_halign(Gtk.Align.CENTER)

    const overlay = new Gtk.Overlay()
    overlay.add(ring)
    overlay.add_overlay(speedBox)

    const container = box(Gtk.Orientation.VERTICAL, 6, [
        overlay,
        label("Network", "ring-title"),
    ])
    container.set_halign(Gtk.Align.CENTER)
    container.get_style_context().add_class("stat-card")

    return container
}

// ─── Header ──────────────────────────────────────────────────────────────────

function Header() {
    const time = createPoll("", 1000, "date +'%H:%M'")
    const date = createPoll("", 60000, "date +'%A, %d %B'")

    const timeLabel = new Gtk.Label({ label: "" })
    timeLabel.get_style_context().add_class("dash-time")
    time.subscribe((t: string) => timeLabel.set_label(t.trim()))

    const dateLabel = new Gtk.Label({ label: "" })
    dateLabel.get_style_context().add_class("dash-date")
    date.subscribe((d: string) => dateLabel.set_label(d.trim()))

    const closeBtn = new Gtk.Button({ label: "✕" })
    closeBtn.get_style_context().add_class("close-btn")
    closeBtn.connect("clicked", () => {
        app.toggle_window("dashboard")
    })

    const left = box(Gtk.Orientation.VERTICAL, 2, [timeLabel, dateLabel])
    left.set_hexpand(true)

    const header = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 0 })
    header.pack_start(left, true, true, 0)
    header.pack_end(closeBtn, false, false, 0)
    header.get_style_context().add_class("dash-header")

    return header
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

function QuickActions() {
    const actions = [
        { icon: "", label: "Terminal", cmd: "kitty" },
        { icon: "", label: "Browser",  cmd: "brave-browser" },
        { icon: "󰍉", label: "Launcher", cmd: "rofi -show drun" },
        { icon: "󰌾", label: "Lock",     cmd: "hyprlock" },
        { icon: "󰐥", label: "Power",    cmd: "hyprctl dispatch exit" },
    ]

    const buttons = actions.map(({ icon, label: lbl, cmd }) => {
        const btn = new Gtk.Button()
        btn.get_style_context().add_class("quick-btn")

        const ico = new Gtk.Label({ label: icon })
        ico.get_style_context().add_class("quick-icon")

        const txt = new Gtk.Label({ label: lbl })
        txt.get_style_context().add_class("quick-label")

        const inner = box(Gtk.Orientation.VERTICAL, 4, [ico, txt])
        inner.set_halign(Gtk.Align.CENTER)
        btn.add(inner)

        btn.connect("clicked", () => {
            execAsync(["bash", "-c", cmd]).catch(console.error)
            app.toggle_window("dashboard")
        })

        return btn
    })

    const row = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 8 })
    row.get_style_context().add_class("quick-actions")
    buttons.forEach(b => row.pack_start(b, true, true, 0))

    return row
}

// ─── Dashboard Window ─────────────────────────────────────────────────────────

export default function Dashboard(gdkmonitor: Gdk.Monitor) {
    const cpuRing  = StatRing({ poll: cpuUsage,  title: "CPU",    cssClass: "ring-cpu", unit: "%" })
    const memRing  = StatRing({ poll: memUsage,  title: "Memory", cssClass: "ring-mem", unit: "%", sublabel: memLabel })
    const netCard  = NetCard()

    const rings = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 24 })
    rings.get_style_context().add_class("rings-row")
    rings.set_halign(Gtk.Align.CENTER)
    ;[cpuRing, memRing, netCard].forEach(r => rings.pack_start(r, false, false, 0))

    const content = box(Gtk.Orientation.VERTICAL, 20, [
        Header(),
        rings,
        QuickActions(),
    ])
    content.get_style_context().add_class("dash-content")

    return (
        <window
            name="dashboard"
            class="Dashboard"
            gdkmonitor={gdkmonitor}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
            margin_top={8}
            margin_right={8}
            layer={Astal.Layer.OVERLAY}
            visible={true}
            application={app}
        >
            {content}
        </window>
    ) as Gtk.Widget
}
