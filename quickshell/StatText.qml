// ============================================================
// StatText.qml — roda um comando de tempos em tempos e mostra o
// resultado com um icone na frente. E' o equivalente do "custom/*"
// do waybar (exec + interval) ou do defpoll do eww.
// ============================================================
import QtQuick
import Quickshell.Io

Item {
    id: root

    property string iconText: ""
    property var command: []
    property string suffix: ""
    property int intervalMs: 5000
    signal clicked()

    property string value: "…"

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
        text: root.iconText + " " + root.value + root.suffix
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: mouseArea.containsMouse ? Colors.fg : Colors.muted
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.command.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Process {
        id: proc
        command: root.command
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.value = this.text.trim()
        }
    }

    Timer {
        interval: root.intervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
