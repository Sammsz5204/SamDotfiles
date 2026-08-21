// ============================================================
// Workspaces.qml — workspace switcher com animações
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root
    spacing: 4

    Repeater {
        model: Hyprland.workspaces.values

        Rectangle {
            id: wsBtn

            required property var modelData

            readonly property bool isFocused:
                Hyprland.focusedWorkspace?.id === modelData.id

            readonly property bool isPressed: mouseArea.pressed

            property int pressToken: 0
            property bool entered: false

            Layout.preferredWidth: isFocused ? 24 : 22
            Layout.preferredHeight: 24

            // Morphing de Raio: 12 (Circulo) -> 8 (Focado/Hover) -> 12 (Pressionado)
            radius: isPressed ? 12 : (isFocused || mouseArea.containsMouse ? 8 : 12)

            color: isFocused
                ? Colors.green
                : (mouseArea.containsMouse || isPressed ? Colors.surface : "transparent")

            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.65

            Behavior on radius {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutBack
                }
            }

            ParallelAnimation {
                id: enterAnimation

                NumberAnimation {
                    target: wsBtn
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: wsBtn
                    property: "scale"
                    from: 0.65
                    to: 1
                    duration: 420
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.6
                }
            }

            SequentialAnimation {
                id: squishAnimation

                NumberAnimation {
                    target: wsBtn
                    property: "scale"
                    to: 0.86
                    duration: 70
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: wsBtn
                    property: "scale"
                    to: 1.08
                    duration: 100
                    easing.type: Easing.OutBack
                    easing.overshoot: 2.0
                }

                NumberAnimation {
                    target: wsBtn
                    property: "scale"
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            onPressTokenChanged: {
                squishAnimation.restart()
            }

            Component.onCompleted: {
                enterAnimation.start()
            }

            Text {
                anchors.centerIn: parent

                text: wsBtn.modelData.name.startsWith("special:")
                ? "★"
                : wsBtn.modelData.name

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14

                color: wsBtn.isFocused
                    ? Colors.bg
                    : Colors.muted

                scale: wsBtn.scale
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                hoverEnabled: true

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    wsBtn.pressToken++
                    wsBtn.modelData.activate();
                }
            }
        }
    }
}
