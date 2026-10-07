import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// ============================================================
// EmojiPicker.qml — desliza da borda DIREITA da tela quando
// EmojiPickerState.requestedVisible vira true (chamado via IPC, ver
// shell.qml: "quickshell ipc call emoji toggle", pra ligar num atalho
// do hyprland.lua). Uma instancia por monitor, mesmo padrao da Bar.
//
// Dados: le ~/.config/quickshell/data/emoji_data.json (gerado a partir
// do pacote Python "emoji" — 1927 emojis, sem variantes de tom de
// pele, cada um com nome + apelidos pra busca). Se esse arquivo nao
// existir, o painel abre vazio com uma mensagem — nao quebra o resto
// da shell.
//
// Clique num emoji = copia pro clipboard (wl-copy) e fecha o painel.
// Cole com Ctrl+V onde quiser escrever.
// ============================================================
PanelWindow {
    id: root

    required property var screenTarget
    screen: screenTarget

    anchors {
        top: true
        bottom: true
        right: true
    }

    implicitWidth: 360
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.requestedVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ---------------- mostrar/esconder (mesmo padrao dos outros popups) --
    readonly property bool requestedVisible: EmojiPickerState.requestedVisible
    property bool closing: false
    visible: requestedVisible || closing

    onRequestedVisibleChanged: {
        if (requestedVisible) {
            closing = false;
            searchInput.text = "";
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else {
            closing = true;
        }
    }

    // ---------------- dados ----------------
    property var allEmoji: []
    property var filteredEmoji: []

    function updateFilter() {
        const q = searchInput.text.toLowerCase().trim();
        if (q === "") {
            filteredEmoji = allEmoji;
        } else {
            filteredEmoji = allEmoji.filter(it => it.k.toLowerCase().includes(q));
        }
    }

    Process {
        id: dataLoader
        command: ["bash", "-c", "cat ~/.config/quickshell/data/emoji_data.json 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text);
                    root.allEmoji = parsed;
                    root.updateFilter();
                } catch (e) {
                    root.allEmoji = [];
                }
            }
        }
    }

    function copyEmoji(ch) {
        Quickshell.execDetached(["bash", "-c", "printf '%s' '" + ch + "' | wl-copy"]);
        EmojiPickerState.close();
    }

    // ---------------- pill/painel ----------------
    Item {
        id: slideWrap
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 340

        property real hiddenOffset: width + 20
        x: root.requestedVisible ? 0 : hiddenOffset
        opacity: root.requestedVisible ? 1 : 0

        // x e' "spatial" (posicao) -> mola de verdade. opacity e'
        // "effects" -> duration+easing, sem mola (ver Motion.qml).
        Behavior on x {
            SpringAnimation {
                spring: Motion.spatialDefault.spring
                damping: Motion.spatialDefault.damping
                mass: Motion.spatialDefault.mass
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: Motion.effectsDefault; easing.type: Motion.effectsEasing }
        }

        onOpacityChanged: if (opacity === 0 && root.closing) root.closing = false

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            anchors.rightMargin: 10
            color: Colors.bg
            radius: 19
            border.width: 2
            border.color: Colors.surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // ---------------- busca (mesmo estilo do LauncherPopup) ----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: searchInput.activeFocus ? Colors.surface : Qt.lighter(Colors.bg, 1.15)
                    border.color: searchInput.activeFocus ? Colors.accent : "transparent"
                    border.width: 2
                    radius: 13

                    Behavior on color { ColorAnimation { duration: Motion.effectsDefault } }
                    Behavior on border.color { ColorAnimation { duration: Motion.effectsDefault } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 12

                        Text {
                            text: "󰞅"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: searchInput.activeFocus ? Colors.accent : Colors.muted
                            Behavior on color { ColorAnimation { duration: Motion.effectsDefault } }
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Pesquisar emoji..."
                            placeholderTextColor: Colors.muted
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            background: null

                            Keys.onEscapePressed: EmojiPickerState.close()
                            onTextChanged: root.updateFilter()
                            onAccepted: {
                                if (root.filteredEmoji.length > 0)
                                    root.copyEmoji(root.filteredEmoji[0].e);
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
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // ---------------- aviso se o dataset nao carregou ----------------
                Text {
                    visible: root.allEmoji.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Nao encontrei ~/.config/quickshell/data/emoji_data.json"
                    color: Colors.muted
                    font.pixelSize: 12
                }

                // ---------------- grid de emojis ----------------
                GridView {
                    id: grid
                    visible: root.allEmoji.length > 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    cellWidth: width / 6
                    cellHeight: cellWidth
                    model: root.filteredEmoji

                    delegate: Item {
                        required property var modelData
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            id: cell
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 14
                            color: cellArea.pressed
                                ? Colors.accent
                                : (cellArea.containsMouse ? Colors.surface : "transparent")

                            Behavior on color { ColorAnimation { duration: Motion.effectsFast } }

                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.modelData.e
                                font.pixelSize: 24
                                scale: cellArea.containsMouse ? 1.15 : 1.0
                                Behavior on scale {
                                    SpringAnimation {
                                        spring: Motion.spatialFast.spring
                                        damping: Motion.spatialFast.damping
                                        mass: Motion.spatialFast.mass
                                    }
                                }
                            }

                            MouseArea {
                                id: cellArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                ToolTip.visible: containsMouse
                                ToolTip.text: parent.parent.modelData.n
                                ToolTip.delay: 500
                                onClicked: root.copyEmoji(parent.parent.modelData.e)
                            }
                        }
                    }
                }
            }
        }
    }
}
