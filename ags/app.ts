import app from "ags/gtk3/app"
import style from "./style.css"
import Dashboard from "./widget/Dashboard"

app.start({
    instanceName: "dashboard",
    css: style,
    main() {
        app.get_monitors().forEach(Dashboard)
    },
})
