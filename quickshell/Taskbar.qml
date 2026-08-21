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

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            SequentialAnimation {
                id: squishAnimation

                NumberAnimation {
                    target: taskBtn
                    property: "scale"
                    to: 0.95
                    duration: 100
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: taskBtn
                    property: "scale"
                    to: 1.03
                    duration: 160
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.5
                }

                NumberAnimation {
                    target: taskBtn
                    property: "scale"
                    to: 1
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            onPressTokenChanged: squishAnimation.restart()

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
