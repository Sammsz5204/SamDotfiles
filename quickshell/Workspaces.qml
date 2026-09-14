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

            // Morphing de Raio: Abaixa o rounding no comeco do press, e arredonda ao soltar
            radius: isPressed ? 3 : (isFocused || mouseArea.containsMouse ? 10 : 0)

            Behavior on radius {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            color: isFocused
                ? Colors.green
                : (mouseArea.containsMouse || isPressed ? Colors.surface : "transparent")


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
                    from: 0.75
                    to: 1
                    duration: 420
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
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
                font.pixelSize: 16

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
