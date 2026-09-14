// ============================================================
// Taskbar.qml — equivalente ao "wlr/taskbar" do waybar. Usa o
// protocolo foreign-toplevel (mesma fonte que o waybar usava).
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Wayland

RowLayout {
    id: root
    spacing: 4

    Repeater {
        model: ToplevelManager.toplevels

        Rectangle {
            id: taskBtn
            required property var modelData

            Layout.preferredWidth: 24
            Layout.preferredHeight: 22
            radius: 6
            color: modelData.activated ? Colors.surface : "transparent"

            property int pressToken: 0

            Text {
                anchors.centerIn: parent
                text: "●"
                font.pixelSize: 8
                color: taskBtn.modelData.activated ? Colors.green : Colors.muted
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    taskBtn.pressToken++
                    taskBtn.modelData.activate()
                }
            }
        }
    }
}
