// ============================================================
// LockSurface.qml — o visual. Inspirado no layout do Caelestia
// (relogio grande de 2 tons, data, avatar circular, campo de senha
// em pilula, mensagem de estado) mas desenhado do zero com os
// componentes que voce ja tem — nao copiei codigo do Caelestia aqui,
// so a ideia de layout, porque o dele depende de modulos (M3Shapes,
// MaterialIcon, etc) que nao existem fora do shell dele.
// ============================================================
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    required property LockContext context

    color: Colors.bg

    // Foco garantido mesmo se o mouse nao passar por cima primeiro
    focus: true
    Component.onCompleted: forceActiveFocus()

    // Recaptura o foco caso alguma outra janela roube (bug comum
    // de foco em compositores wlroots com telas de lock)
    HoverHandler {
        onHoveredChanged: if (hovered) root.forceActiveFocus()
    }

    Keys.onPressed: event => {
        if (context.unlockInProgress)
            return;

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            context.tryUnlock();
        } else if (event.key === Qt.Key_Backspace) {
            context.currentText = event.modifiers & Qt.ControlModifier
                ? ""
                : context.currentText.slice(0, -1);
        } else if (event.text && /^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            context.currentText += event.text;
        }
    }

    // Leve "shake" quando a senha erra — feedback sem precisar de texto
    SequentialAnimation {
        id: shake
        loops: 1
        NumberAnimation { target: centerColumn; property: "x"; to: centerColumn.baseX - 10; duration: 60 }
        NumberAnimation { target: centerColumn; property: "x"; to: centerColumn.baseX + 10; duration: 60 }
        NumberAnimation { target: centerColumn; property: "x"; to: centerColumn.baseX - 6; duration: 60 }
        NumberAnimation { target: centerColumn; property: "x"; to: centerColumn.baseX; duration: 60 }
    }
    Connections {
        target: root.context
        function onFailed() { shake.start() }
    }

    ColumnLayout {
        id: centerColumn
        property real baseX: (root.width - width) / 2

        x: baseX
        y: (root.height - height) / 2
        width: 360
        spacing: 28

        // ---------------- relogio ----------------
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Text {
                    text: Qt.formatDateTime(clock.date, "hh")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 96
                    font.weight: Font.DemiBold
                    color: Colors.accent
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "mm")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 96
                    font.weight: Font.Light
                    color: Colors.fg
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toUpperCase()
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.letterSpacing: 1.5
                color: Colors.muted
            }
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        // ---------------- avatar (placeholder circular) ----------------
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 72
            height: 72
            radius: 36
            color: Colors.surface
            border.color: Colors.accent
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "󰀄"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 32
                color: Colors.accent
            }
        }

        // ---------------- campo de senha (pilula, mesma linguagem do MorphingButton) ----------------
        Rectangle {
            id: inputPill
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            implicitHeight: 52
            radius: height / 2
            color: Colors.surface
            border.width: 2
            border.color: root.context.showFailure ? Colors.red : (root.activeFocus ? Colors.accent : "transparent")

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 8
                spacing: 10

                Text {
                    text: root.context.unlockInProgress ? "󰔟" : "󰌾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: Colors.muted
                }

                // Mascara a senha com bolinhas em vez de mostrar o TextInput cru
                Text {
                    Layout.fillWidth: true
                    text: "●".repeat(root.context.currentText.length)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.letterSpacing: 3
                    color: Colors.fg
                    elide: Text.ElideLeft

                    Text {
                        visible: root.context.currentText.length === 0
                        text: "Digite sua senha"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: Colors.muted
                    }
                }

                // Botao de enviar — mesmo "morph" de largura que o resto do rice usa
                Rectangle {
                    id: sendBtn
                    implicitHeight: 36
                    implicitWidth: root.context.currentText.length > 0 ? 36 : 0
                    radius: 18
                    color: sendMouse.pressed ? Colors.accent : Colors.bg
                    opacity: root.context.currentText.length > 0 ? 1 : 0
                    clip: true

                    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: Colors.fg
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.context.tryUnlock()
                    }
                }
            }
        }

        // ---------------- mensagem de estado ----------------
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.context.showFailure ? "Senha incorreta" : " "
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Colors.red
            opacity: root.context.showFailure ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
