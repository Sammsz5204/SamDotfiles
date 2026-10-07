import QtQuick
import Quickshell.Io

// ============================================================
// VolumeFilledSlider.qml — inspirado no FilledSlider do Caelestia
// (caelestia-dots/shell, components/controls/FilledSlider.qml, o slider
// vertical do OSD de volume/brilho/mic).
//
// Estrutura (igual a deles):
//   - trilha: pill totalmente arredondado (radius = width/2)
//   - preenchimento: do topo do handle ate' o fundo, mesmo radius —
//     a ponta de cima fica escondida atras do handle redondo, entao
//     NAO precisa de clip nem de raio por canto (os bugs de canto
//     quadrado das versoes anteriores vinham exatamente disso)
//   - handle: circulo do tamanho da largura do slider, com o icone
//     dentro; enquanto voce mexe (ou o valor muda por fora) o icone
//     da' lugar a porcentagem, com um "pulinho" de escala na troca
//
// Logica de volume = a mesma do Volume.qml original (wpctl). Roda do
// mouse: +-2% por passo. Clique no handle sem arrastar: mute/unmute.
// ============================================================
Item {
    id: root

    // ---- valor (0..1) ----
    property real value: 0
    property bool muted: false

    // ---- aparencia (sobrescreva se o tema pedir) ----
    property color trackColor: Colors.surface
    property color fillColor: Qt.lighter(Colors.accent, 1.9)
    property color handleColor: Colors.fg
    property color handleTextColor: Colors.bg

    implicitWidth: 48
    implicitHeight: 187

    readonly property real handleSize: width
    readonly property alias dragging: dragArea.pressed

    // Valor mostrado: acompanha "value", animado, exceto durante o
    // arrasto (ai o handle segue o mouse 1:1, sem atraso).
    property real displayValue: value
    Behavior on displayValue {
        enabled: !root.dragging
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    readonly property real handleY: (1 - root.displayValue) * (root.height - root.handleSize)

    // "moving" = mostrar a porcentagem no lugar do icone
    property bool moving: false

    function iconFor(v, isMuted) {
        if (isMuted) return "󰖁";
        if (v < 0.01) return "󰕿";
        if (v < 0.5) return "󰖀";
        return "󰕾";
    }

    function setFromY(y) {
        const usable = root.height - root.handleSize;
        if (usable <= 0) return;
        const v = Math.max(0, Math.min(1, 1 - (y - root.handleSize / 2) / usable));
        root.value = v;
        volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)];
        volumeSetProc.running = true;
    }

    // Quando o valor muda por fora (scroll, outro app), mostra a
    // porcentagem por um instante, igual o Caelestia.
    property real _lastShown: value
    onValueChanged: {
        if (Math.abs(value - _lastShown) < 0.01) return;
        _lastShown = value;
        moving = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 500
        onTriggered: if (!root.dragging) root.moving = false
    }

    // ---------------- trilha ----------------
    Rectangle {
        id: track
        anchors.fill: parent
        radius: width / 2
        color: root.trackColor

        // preenchimento: do topo do handle ate' o fundo
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.handleY
            height: parent.height - y
            radius: parent.radius
            color: root.fillColor
        }
    }

    // ---------------- handle ----------------
    Rectangle {
        id: handle
        width: root.handleSize
        height: root.handleSize
        radius: width / 2
        y: root.handleY
        color: root.handleColor

        Text {
            id: label
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: root.moving ? Math.round(root.value * 100) : root.iconFor(root.value, root.muted)
            color: root.handleTextColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: root.moving ? 13 : 18
            font.bold: root.moving
        }

        // "pulinho" ao trocar entre icone e numero (mesma ideia do
        // Behavior on moving do Caelestia)
        SequentialAnimation {
            id: swapAnim
            NumberAnimation { target: label; property: "scale"; to: 0.3; duration: 80; easing.type: Easing.InCubic }
            NumberAnimation { target: label; property: "scale"; to: 1; duration: 150; easing.type: Easing.OutCubic }
        }
    }

    onMovingChanged: swapAnim.restart()

    // ---------------- interacao ----------------
    MouseArea {
        id: dragArea
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        property bool didDrag: false
        property bool startedOnHandle: false

        onPressed: mouse => {
            didDrag = false;
            startedOnHandle = mouse.y >= root.handleY && mouse.y <= root.handleY + root.handleSize;
            root.moving = true;
            hideTimer.stop();
            root.setFromY(mouse.y);
        }
        onPositionChanged: mouse => {
            if (!pressed) return;
            didDrag = true;
            root.setFromY(mouse.y);
        }
        onReleased: {
            // toque no handle sem arrastar = mute/unmute
            if (startedOnHandle && !didDrag)
                muteProc.running = true;
            hideTimer.restart();
        }
        onCanceled: hideTimer.restart()

        onWheel: wheel => {
            volumeStepProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@",
                (wheel.angleDelta.y > 0 ? "2%+" : "2%-")];
            volumeStepProc.running = true;
        }
    }

    // ---------------- wpctl ----------------
    Process {
        id: pollProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                // saida tipica: "Volume: 0.45" ou "Volume: 0.45 [MUTED]"
                const text = this.text.trim();
                root.muted = text.includes("[MUTED]");
                const match = text.match(/[\d.]+/);
                if (match) root.value = Math.min(1, parseFloat(match[0]));
            }
        }
    }

    Process { id: volumeSetProc; running: false }

    Process {
        id: volumeStepProc
        running: false
        onExited: pollProc.running = true
    }

    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onExited: pollProc.running = true
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        // nao briga com o dedo durante o arrasto
        onTriggered: if (!root.dragging) pollProc.running = true
    }
}
