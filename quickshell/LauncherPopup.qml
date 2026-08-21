// ============================================================
// LauncherPopup.qml — Material 3 Expressive Animated
// ============================================================
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PopupWindow {
    id: root

    implicitWidth: 420
    implicitHeight: 520

    color: "transparent"
    visible: false

    property var allApps: []
    property var filteredApps: []

    function updateFilter() {
        if (!allApps) return;
        var q = searchInput.text.toLowerCase().trim();
        if (q === "") {
            filteredApps = allApps;
        } else {
            filteredApps = allApps.filter(app => 
                (app.name && app.name.toLowerCase().includes(q)) ||
                (app.comment && app.comment.toLowerCase().includes(q))
            );
        }
    }

    // Leitura silenciosa dos .desktop
    Process {
        id: appScanner
        command: [
            "python3", "-c",
            "import os, glob, configparser, json\n" +
            "apps = []\n" +
            "paths = ['/usr/share/applications/*.desktop', os.path.expanduser('~/.local/share/applications/*.desktop')]\n" +
            "seen = set()\n" +
            "for p in paths:\n" +
            "    for f in glob.glob(p):\n" +
            "        try:\n" +
            "            cfg = configparser.ConfigParser(interpolation=None)\n" +
            "            cfg.read(f, encoding='utf-8')\n" +
            "            if 'Desktop Entry' in cfg:\n" +
            "                e = cfg['Desktop Entry']\n" +
            "                if e.get('NoDisplay') == 'true' or e.get('Type') != 'Application': continue\n" +
            "                name = e.get('Name', '')\n" +
            "                if not name or name in seen: continue\n" +
            "                seen.add(name)\n" +
            "                exec_cmd = e.get('Exec', '').split('%')[0].strip()\n" +
            "                icon = e.get('Icon', '')\n" +
            "                comment = e.get('Comment', '')\n" +
            "                apps.append({'name': name, 'icon': icon, 'exec': exec_cmd, 'comment': comment})\n" +
            "        except Exception: pass\n" +
            "apps.sort(key=lambda x: x['name'].lower())\n" +
            "print(json.dumps(apps))"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allApps = JSON.parse(this.text);
                    root.updateFilter();
                } catch(e) {}
            }
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Colors.bg
        border.color: Colors.surface
        border.width: 2
        radius: 13

        // --- M3 EXPRESSIVE ENTRANCE ---
        // Faz o popup "nascer" do canto superior esquerdo (onde fica o botao)
        transformOrigin: Item.TopLeft
        
        scale: root.visible ? 1.0 : 0.85
        opacity: root.visible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        }
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 12

            // Barra de Busca
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                color: searchInput.activeFocus ? Colors.bg : Colors.surface
                border.color: searchInput.activeFocus ? Colors.accent : "transparent"
                border.width: 2
                radius: 13

                // Transição suave de cor na borda e fundo ao focar
                Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: searchInput.activeFocus ? Colors.accent : Colors.muted
                        
                        // O ícone pula levemente ao ganhar foco
                        scale: searchInput.activeFocus ? 1.15 : 1.0
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    TextField {
                        id: searchInput

                        Layout.fillWidth: true
                        placeholderText: "Pesquisar aplicativos..."
                        placeholderTextColor: Colors.muted
                        color: Colors.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        background: null

                        Keys.onEscapePressed: root.visible = false

                        onTextChanged: root.updateFilter()

                        onAccepted: {
                            if (root.filteredApps.length > 0) {
                                var firstApp = root.filteredApps[0];
                                Quickshell.execDetached(["bash", "-c", firstApp.exec + " &"]);
                                root.visible = false;
                            }
                        }
                    }

                    Text {
                        visible: searchInput.text.length > 0
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Colors.muted

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = ""
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // Lista de Apps
            ListView {
                id: appListView

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8 // Mais respiro entre os itens M3

                model: root.filteredApps

                delegate: Rectangle {
                    id: appCard

                    width: appListView.width
                    height: 56
                    radius: 16
                    property var appData: modelData

                    // Fundo tonal dinâmico
                    color: itemMouse.pressed 
                        ? Qt.darker(Colors.surface, 1.2)
                        : (itemMouse.containsMouse ? Qt.lighter(Colors.surface, 1.15) : "transparent")

                    // --- M3 EXPRESSIVE SQUISH/FLOAT ---
                    scale: itemMouse.pressed ? 0.94 : (itemMouse.containsMouse ? 1.02 : 1.0)

                    Behavior on scale { 
                        NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 2.5 } 
                    }
                    Behavior on color { 
                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic } 
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Ícone com leve elevação no hover
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 10
                            color: itemMouse.containsMouse ? Colors.bg : Colors.surface
                            
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰵆"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: Colors.accent
                                
                                scale: itemMouse.containsMouse ? 1.1 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: appCard.appData.name || ""
                                color: Colors.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: appCard.appData.comment || "Aplicativo do sistema"
                                color: Colors.muted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", appCard.appData.exec + " &"]);
                            root.visible = false;
                        }
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
        }
    }
}