// ============================================================
// IconButton.qml — icone clicavel simples, com hover (equivalente ao
// #custom-launcher / #custom-system-panel do style.css: cinza parado,
// vira @fg + fundo @surface no hover).
// ============================================================
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string icon: ""
    signal clicked()

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 26

    property int pressToken: 0

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: mouseArea.containsMouse ? Colors.surface : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
        color: mouseArea.containsMouse ? Colors.fg : Colors.muted

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    SequentialAnimation {
        id: squishAnimation

        NumberAnimation {
            target: root
            property: "scale"
            to: 0.95
            duration: 100
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "scale"
            to: 1.03
            duration: 160
            easing.type: Easing.OutBack
            easing.overshoot: 0.5
        }

        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    onPressTokenChanged: squishAnimation.restart()

    MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
        root.pressToken++
        root.clicked()
    }
}
}
