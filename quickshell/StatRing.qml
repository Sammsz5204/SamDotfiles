// ============================================================
// StatRing.qml — Material 3 Expressive (Com Gap/Duas Partes)
// ============================================================
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string icon: ""
    property string label: ""
    property real value: 0
    property color ringColor: "white"

    width: 100
    height: 95

    property real animatedValue: 0

    Behavior on animatedValue {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutCubic
        }
    }

    onValueChanged: {
        animatedValue = value
    }

    // Efeito Breathing no hover
    scale: mArea.containsMouse ? 1 : 0.95
    Behavior on scale {
        NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // Ajuste o tamanho do buraco/gap entre as barras (em radianos)
            var gap = 0.35 
            
            var start = -0.5 * Math.PI
            var progress = root.animatedValue

            // Trava os extremos pra animação não bugar a renderização
            if (progress <= 0.01) progress = 0.01
            if (progress >= 0.99) progress = 1.0

            var progressAngle = progress * 2 * Math.PI
            var end = start + progressAngle

            // 1. Desenha a Trilha de Progresso (Barra colorida)
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, width / 2 - 6, start, end)
            ctx.strokeStyle = root.ringColor
            ctx.lineWidth = 10
            ctx.lineCap = "round"
            ctx.stroke()

            // 2. Desenha a Trilha de Fundo (com os gaps)
            // Se tiver quase 100%, a gente nem desenha o fundo pra não sobrepor
            if (progress < 0.92) { 
                ctx.beginPath()
                var bgStart = end + gap
                var bgEnd = start + 2 * Math.PI - gap

                // Garante que o fundo só vai ser desenhado se sobrar espaço físico pra ele
                if (bgEnd > bgStart) {
                    ctx.arc(width / 2, height / 2, width / 2 - 6, bgStart, bgEnd)
                    ctx.strokeStyle = Colors.bg 
                    ctx.lineWidth = 10
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }
        }

        Connections {
            target: root
            function onAnimatedValueChanged() {
                canvas.requestPaint()
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        
        // Texto faz escala inversa pra não crescer junto com o anel no hover
        scale: 1 / root.scale

        Text {
            text: root.icon
            color: root.ringColor
            font.pixelSize: 18
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: Math.round(root.value * 100) + "%"
            color: Colors.fg
            font.pixelSize: 13
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.label
            color: Colors.fg
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignHCenter
        }
    }

    MouseArea {
        id: mArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}