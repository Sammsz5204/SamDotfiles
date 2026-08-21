// ============================================================
// ClockWidget.qml — equivalente ao "clock" do waybar.
// ============================================================
import QtQuick
import Quickshell

Item {
    id: root
    property string text: ""

    implicitWidth: label.implicitWidth + 12
    implicitHeight: 26

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "hh:mm AP")
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.bold: true
        color: Colors.fg
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
