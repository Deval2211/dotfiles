import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"

export default function SimpleDashboard(gdkmonitor: Gdk.Monitor) {
    const label = new Gtk.Label({ label: "AGS Dashboard Working!" })
    label.get_style_context().add_class("test-label")

    return (
        <window
            name="dashboard"
            class="Dashboard"
            gdkmonitor={gdkmonitor}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
            margin_top={10}
            margin_right={10}
            layer={Astal.Layer.OVERLAY}
            visible={true}
            application={app}
        >
            {label}
        </window>
    ) as Gtk.Widget
}
