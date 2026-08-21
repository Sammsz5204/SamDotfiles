// ============================================================
// TrayModule.qml — equivalente ao "tray" do waybar.
// ============================================================
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    spacing: 6

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem
            required property var modelData

            Layout.preferredWidth: 18
            Layout.preferredHeight: 18

            Image {
                anchors.fill: parent
                source: trayItem.modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        trayItem.modelData.activate();
                    } else {
                        trayItem.modelData.display(root.Window.window, mouse.x, mouse.y);
                    }
                }
            }
        }
    }
}
