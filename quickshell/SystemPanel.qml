import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: root
    width: 380
    height: 650
    visible: false
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // Mock values - hook these up to Quickshell's Process/Command API later
    property real cpuPct: 0.23
    property real ramPct: 0.18
    property real diskPct: 0.75
    property string songTitle: "Nenhuma música"
    property string songArtist: "Desconhecido"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        color: Colors.bg
        border.color: Colors.surface
        border.width: 2
        radius: 14

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // --- STATS (3 RINGS) ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: Colors.surface
                radius: 14

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    StatRing { icon: "󰻠"; value: root.cpuPct; label: "CPU"; ringColor: Colors.blue; Layout.fillWidth: true }
                    StatRing { icon: "󰍛"; value: root.ramPct; label: "RAM"; ringColor: Colors.green; Layout.fillWidth: true }
                    StatRing { icon: "󰋊"; value: root.diskPct; label: "DISK"; ringColor: Colors.yellow; Layout.fillWidth: true }
                }
            }


            // --- MEDIA WIDGET ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                color: Colors.surface
                radius: 14

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 38; height: 38
                        radius: 10
                        color: Colors.bg
                        Text { anchors.centerIn: parent; text: "󰝚"; color: Colors.blue; font.pixelSize: 18 }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: root.songTitle; color: Colors.fg; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight }
                        Text { text: root.songArtist; color: Colors.muted; font.pixelSize: 10; font.weight: Font.Medium; elide: Text.ElideRight }
                    }

                    RowLayout {
                        spacing: 8
                        Text { text: "󰒮"; color: Colors.fg; font.pixelSize: 14; MouseArea { anchors.fill: parent } }
                        Text { text: "󰐊"; color: Colors.fg; font.pixelSize: 14; MouseArea { anchors.fill: parent } }
                        Text { text: "󰒭"; color: Colors.fg; font.pixelSize: 14; MouseArea { anchors.fill: parent } }
                    }
                }
            }

            // --- QUICK ACTIONS ---
            Text {
                text: "AÇÕES RÁPIDAS"
                color: Colors.muted
                font.pixelSize: 11
                font.bold: true
                Layout.leftMargin: 4
            }

            GridLayout {
                columns: 4
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                ActionBtn { icon: "󰐥"; label: "Desligar"; iconColor: Colors.brightRed }
                ActionBtn { icon: "󰜉"; label: "Reiniciar"; iconColor: Colors.yellow }
                ActionBtn { icon: "󰍃"; label: "Sair"; iconColor: Colors.yellow }
                ActionBtn { icon: "󰌾"; label: "Bloquear"; iconColor: Colors.yellow }

                ActionBtn { icon: "󰒲"; label: "Suspender"; iconColor: Colors.blue }
                ActionBtn { icon: "󰆍"; label: "Terminal"; iconColor: Colors.green }
                ActionBtn { icon: "󰉋"; label: "Arquivos"; iconColor: Colors.green }
                ActionBtn { icon: "󰒓"; label: "Configs"; iconColor: Colors.brightBlue }

                ActionBtn { icon: "󰖩"; label: "Rede"; iconColor: Colors.blue }
                ActionBtn { icon: "󰍛"; label: "Monitor"; iconColor: Colors.brightBlue }
                ActionBtn { icon: "󰂚"; label: "Notificações"; iconColor: Colors.yellow }
                ActionBtn { icon: "󰅖"; label: "Fechar"; iconColor: Colors.brightRed }
            }

            Item { Layout.fillHeight: true } // Spacer

