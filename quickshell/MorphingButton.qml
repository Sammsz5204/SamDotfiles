// ============================================================
// MorphingButton.qml — Atualizado com Morphing no Clique
//
// Radius on press/release migrado pros tokens do Motion.qml:
// descida rápida sem mola, subida com overshoot (M3 Expressive).
// ============================================================
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string icon: "󰎟"
    property string text: "Menu"
    signal clicked()

    property int pressToken: 0
    
    readonly property bool isExpanded: mouseArea.containsMouse
    readonly property bool isPressed: mouseArea.pressed

    implicitWidth: isExpanded ? (iconText.implicitWidth + labelText.implicitWidth + 30) : 26
    implicitHeight: 26

    Behavior on implicitWidth {
        NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent

        readonly property real restRadius: 19
        // restRadius (19) > height/2 (13) — ja' satura em pilula completa
        // no repouso. Usa o helper clamped pra calcular o press em cima
        // do raio VISUAL (13), senao a proporcao normal (19 * 0.67 ≈ 12.7)
        // fica acima do teto visual e a animacao nao aparece na tela.
        readonly property real pressedRadius: Motion.pressedRadiusClamped(restRadius, root.height)

        radius: restRadius
        color: isExpanded || isPressed ? Colors.surface : "transparent"

        Behavior on color {
            ColorAnimation { duration: Motion.hoverDuration; easing.type: Motion.hoverEasingType }
        }

        // radius e' "spatial" -> mola de verdade (ver Motion.qml).
        // Descida (press): mola mais rigida/rapida.
        SpringAnimation {
            id: pressAnim
            target: bgRect
            property: "radius"
            to: bgRect.pressedRadius
            spring: Motion.spatialFast.spring
            damping: Motion.spatialFast.damping
            mass: Motion.spatialFast.mass
        }

        // Subida (release): mola default — "assenta" com overshoot visivel.
        SpringAnimation {
            id: releaseAnim
            target: bgRect
            property: "radius"
            to: bgRect.restRadius
            spring: Motion.spatialDefault.spring
            damping: Motion.spatialDefault.damping
            mass: Motion.spatialDefault.mass
        }
    }

    Item {
        id: contentWrapper
        anchors.centerIn: parent
        height: 26
        width: iconText.implicitWidth + (isExpanded ? (labelText.implicitWidth + 6) : 0)
        clip: true 

        Behavior on width {
            NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }

        Text {
            id: iconText
            text: root.icon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
            color: isExpanded ? Colors.fg : Colors.muted

            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        Text {
            id: labelText
            text: root.text
            anchors.left: iconText.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: Colors.fg
            
            opacity: root.isExpanded ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
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

        onClicked: {
            root.pressToken++
            root.clicked()
        }
    }
}
