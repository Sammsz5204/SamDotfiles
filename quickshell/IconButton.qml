// ============================================================
// IconButton.qml — icone clicavel simples, com hover.
//
// Convertido do scale-bounce antigo (squishAnimation no item
// inteiro, disparado so' no onClicked) pro mesmo padrao de radius
// on press/release dos outros botoes, via Motion.qml — so' o raio
// muda, sem escalar o item (M3 real e' mais sutil que isso).
// ============================================================
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string icon: ""
    signal clicked()

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 26

    readonly property real restRadius: 13
    readonly property real pressedRadius: Motion.pressedRadius(restRadius)

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.restRadius // valor inicial; a partir daqui quem escreve sao as SpringAnimation abaixo
        color: mouseArea.containsMouse ? Colors.surface : "transparent"

        Behavior on color {
            ColorAnimation { duration: Motion.hoverDuration; easing.type: Motion.hoverEasingType }
        }

        // radius e' "spatial" -> mola de verdade (ver Motion.qml).
        SpringAnimation {
            id: pressAnim
            target: bgRect; property: "radius"; to: root.pressedRadius
            spring: Motion.spatialFast.spring
            damping: Motion.spatialFast.damping
            mass: Motion.spatialFast.mass
        }

        SpringAnimation {
            id: releaseAnim
            target: bgRect; property: "radius"; to: root.restRadius
            spring: Motion.spatialDefault.spring
            damping: Motion.spatialDefault.damping
            mass: Motion.spatialDefault.mass
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
            ColorAnimation { duration: Motion.hoverDuration; easing.type: Motion.hoverEasingType }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: { releaseAnim.stop(); pressAnim.restart() }
        onReleased: { pressAnim.stop(); releaseAnim.restart() }
        onCanceled: { pressAnim.stop(); releaseAnim.restart() }

        onClicked: root.clicked()
    }
}
