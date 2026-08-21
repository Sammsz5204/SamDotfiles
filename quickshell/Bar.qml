import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38

    color: "transparent"

    margins {
        top: 8
        left: 10
        right: 10
    }

    exclusionMode: ExclusionMode.Auto
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        id: background

        anchors.fill: parent
        color: Colors.bg
        radius: 13

        RowLayout {
            id: leftLayout

            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            spacing: 6

        MorphingButton {
    		Layout.alignment: Qt.AlignVCenter
    		icon: ""
    		text: "Apps"
    
    		onClicked: Quickshell.execDetached([
        	"rofi",
        	"-show",
        	"drun"
    	   ])
	}

            IdleInhibitor {
            }

            Volume {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout {
            id: centerLayout

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            spacing: 10

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }

            ClockWidget {
                Layout.alignment: Qt.AlignVCenter
            }

            Taskbar {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout {
            id: rightLayout

            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }

            spacing: 6

            StatText {
                Layout.alignment: Qt.AlignVCenter
                iconText: "󰂯"

                command: [
                    "bash",
                    "-c",
                    "~/.config/scripts/bluetooth-display.sh"
                ]

                intervalMs: 10000

                onClicked: Quickshell.execDetached([
                    "blueman-manager"
                ])
            }

            MorphingStat {
                Layout.alignment: Qt.AlignVCenter
                icon: "" // Ícone pro processador
                hoverName: "CPU"
                command: [
                    "bash",
                    "-c",
                    "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1"
                ] //[cite: 5]
                suffix: "%" //[cite: 5]
                intervalMs: 2000 //[cite: 5]

                onClicked: Quickshell.execDetached([
                    "kitty",
                    "-e",
                    "btop --force-utf"
                ]) //[cite: 5]
            }

            MorphingStat {
                Layout.alignment: Qt.AlignVCenter
                icon: "󰘚" // Ícone pra memória
                hoverName: "RAM"
                command: [
                    "bash",
                    "-c",
                    "free -b | awk '/Mem:/ {printf \"%.1fG/%.1fG\", $3/1073741824, $2/1073741824}'"
                ] //[cite: 5]
                intervalMs: 30000 //[cite: 5]
            }

            TrayModule {
                Layout.alignment: Qt.AlignVCenter
            }

            MorphingButton {
                Layout.alignment: Qt.AlignVCenter
                icon: "󰎟" //[cite: 5]
                text: "System"
                
                onClicked: {
                    systemPanel.visible = !systemPanel.visible //[cite: 5]
                }
            }
        }
    }

    // Popup associado diretamente a esta barra.
    // Assim não é necessário passar uma referência pelo shell.qml.
    SystemPanelPopup {
        id: systemPanel

        anchor.window: bar
        anchor.rect.x: bar.width - width - 10
        anchor.rect.y: bar.height + 5
    }
}
