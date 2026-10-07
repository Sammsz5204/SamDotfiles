// ============================================================
// ResourceItem.qml — versao compacta do StatRing.qml, pensada pra
// viver na Bar (nao no SystemPanelPopup): anel PEQUENO com icone
// dentro + porcentagem do lado, mesmo padrao do Resource.qml do
// illogical-impulse (end-4/dots-hyprland) e do equivalente no
// nandoroid-shell — nada de anel grande com label embaixo, so' o
// essencial, do tamanho de um modulo normal da barra (26px de altura,
// igual ClockWidget/Volume/etc).
// ============================================================
import QtQuick

Item {
    id: root

    property string icon: ""
    property real value: 0          // 0..1
    property color ringColor: Colors.fg
    property int warningThreshold: 101   // em % (0-100); >= isso vira ringColor = Colors.brightRed

    readonly property bool warning: value * 100 >= warningThreshold
    readonly property real displayColor: warning ? Colors.brightRed : ringColor

    implicitWidth: rowLayoutWidth
    implicitHeight: 26

    readonly property real ringSize: 18
    readonly property real spacing: 5
    readonly property real rowLayoutWidth: ringSize + spacing + label.implicitWidth

    property real animatedValue: 0
    Behavior on animatedValue {
        NumberAnimation { duration: Motion.effectsSlow; easing.type: Motion.effectsEasing }
    }
    onValueChanged: animatedValue = value

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: hoverArea.containsMouse ? Colors.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.effectsFast } }
    }

    Canvas {
        id: canvas
        width: root.ringSize
        height: root.ringSize
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            const gap = 0.45;
            const start = -0.5 * Math.PI;
            let progress = root.animatedValue;
            if (progress <= 0.01) progress = 0.01;
            if (progress >= 0.99) progress = 1.0;

            const end = start + progress * 2 * Math.PI;
            const r = width / 2 - 2;

            // trilha de fundo (com gap, igual o StatRing — so' nao
            // desenha se tiver quase cheio, pra nao sobrepor)
            if (progress < 0.92) {
                ctx.beginPath();
                const bgStart = end + gap;
                const bgEnd = start + 2 * Math.PI - gap;
                if (bgEnd > bgStart) {
                    ctx.arc(width / 2, height / 2, r, bgStart, bgEnd);
                    ctx.strokeStyle = Colors.bg;
                    ctx.lineWidth = 3;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
            }

            // arco de progresso
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r, start, end);
            ctx.strokeStyle = root.displayColor;
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.stroke();
        }

        Connections {
            target: root
            function onAnimatedValueChanged() { canvas.requestPaint(); }
            function onDisplayColorChanged() { canvas.requestPaint(); }
        }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            // Colors.fg (nao root.displayColor) de proposito — o anel
            // colorido (ringColor: blue/green/yellow) pode ficar perto
            // demais do fundo da barra dependendo do tema, mesmo
            // problema de contraste que ja resolvemos no slider. O
            // icone precisa de contraste garantido, igual todo resto
            // de texto/icone da barra (ClockWidget, Volume, etc. — todos
            // usam Colors.fg).
            color: Colors.fg
        }
    }

    Text {
        id: label
        anchors.left: canvas.right
        anchors.leftMargin: root.spacing
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.value * 100)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: hoverArea.containsMouse ? Colors.fg : Colors.muted
        Behavior on color { ColorAnimation { duration: Motion.effectsFast } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
