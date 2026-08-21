// ============================================================
// IdleInhibitor.qml — equivalente ao "idle_inhibitor" do waybar.
// Enquanto ativo, segura um "systemd-inhibit" rodando (mata ele =
// solta o lock = SIGTERM quando running vira false).
// ============================================================
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Item {
    id: root
    property bool active: false

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: mouseArea.containsMouse ? Colors.surface : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.active ? "󰒳" : "󰒲"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
        color: root.active ? Colors.accent : (mouseArea.containsMouse ? Colors.fg : Colors.muted)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.active = !root.active
        
    }

    Process {
        id: inhibitProc
        command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch",
                  "--who=quickshell", "--why=manual", "sleep", "infinity"]
        running: root.active
    }
}
