import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import { cpuUsage } from "../modules/cpu"
import { memUsage, memLabel } from "../modules/memory"
import { netSpeed, wifiSSID } from "../modules/network"

// ─── Helpers ────────────────────────────────────────────────────────────────

function box(orientation: Gtk.Orientation, spacing: number, children: Gtk.Widget[]) {
    const b = new Gtk.Box({ orientation, spacing })
    children.forEach(c => b.pack_start(c, false, false, 0))
    return b
}

// ─── Circular Ring ─────────────────────────────────────────────────────

function StatRing(opts: {
    poll: ReturnType<typeof createPoll<number>>
    title: string
    cssClass: string
}) {
    const label = new Gtk.Label({ label: opts.title })
    label.get_style_context().add_class("ring-title")

    const value = new Gtk.Label({ label: "0%" })
    value.get_style_context().add_class("ring-value")

    opts.poll.connect("changed", () => {
        value.set_label(`${Math.round(opts.poll.value)}%`)
    })

    const container = box(Gtk.Orientation.VERTICAL, 8, [value, label])
    container.get_style_context().add_class("stat-ring")
    container.get_style_context().add_class(opts.cssClass)
    container.set_halign(Gtk.Align.CENTER)

    return container
}

// ─── Network Card ─────────────────────────────────────────────────────

function NetCard() {
    const speed = new Gtk.Label({ label: "0 KB/s" })
    speed.get_style_context().add_class("net-speed")

    const ssid = new Gtk.Label({ label: "WiFi" })
    ssid.get_style_context().add_class("net-ssid")

    netSpeed.connect("changed", () => {
        speed.set_label(`${netSpeed.value} KB/s`)
    })

    wifiSSID.connect("changed", () => {
        ssid.set_label(wifiSSID.value)
    })

    const container = box(Gtk.Orientation.VERTICAL, 8, [speed, ssid])
    container.get_style_context().add_class("net-card")
    container.set_halign(Gtk.Align.CENTER)

    return container
}

// ─── Header ──────────────────────────────────────────────────────────────────

function Header() {
    const time = createPoll("", 1000, "date +'%H:%M'")
    const date = createPoll("", 60000, "date +'%A, %d %B'")

    const timeLabel = new Gtk.Label({ label: time.value })
    timeLabel.get_style_context().add_class("dash-time")

    const dateLabel = new Gtk.Label({ label: date.value })
    dateLabel.get_style_context().add_class("dash-date")

    time.connect("changed", () => timeLabel.set_label(time.value))
    date.connect("changed", () => dateLabel.set_label(date.value))

    const header = box(Gtk.Orientation.VERTICAL, 4, [timeLabel, dateLabel])
    header.get_style_context().add_class("dash-header")
    header.set_halign(Gtk.Align.CENTER)

    return header
}

// ─── Quick Actions ────────────────────────────────────────────────────────

function QuickActions() {
    const actions = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 8 })
    actions.get_style_context().add_class("quick-actions")
    actions.set_halign(Gtk.Align.CENTER)

    const buttons = [
        { label: "Term", cmd: "kitty" },
        { label: "Web", cmd: "brave-browser" },
        { label: "App", cmd: "rofi -show drun" },
        { label: "Lock", cmd: "hyprlock" },
        { label: "Exit", cmd: "hyprctl dispatch exit" },
    ]

    buttons.forEach(({ label: lbl, cmd }) => {
        const btn = new Gtk.Button({ label: lbl })
        btn.get_style_context().add_class("quick-btn")
        btn.connect("clicked", () => {
            execAsync(cmd).catch(console.error)
        })
        actions.pack_start(btn, true, true, 0)
    })

    return actions
}

// ─── Dashboard Window ─────────────────────────────────────────────────────────

const { TOP, RIGHT } = Astal.WindowAnchor

export default function Dashboard(gdkmonitor: Gdk.Monitor) {
    const cpuRing = StatRing({ poll: cpuUsage, title: "CPU", cssClass: "ring-cpu" })
    const memRing = StatRing({ poll: memUsage, title: "Memory", cssClass: "ring-mem" })
    const netCard = NetCard()

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
            class="Dashboard"
            gdkmonitor={gdkmonitor}
            anchor={TOP | RIGHT}
            exclusivity={Astal.Exclusivity.IGNORE}
            application={app}
        >
            {content}
        </window>
    )
}
