import QtQuick

// ============================================================
// FilledSlider.qml — inspirado no FilledSlider do Caelestia
// (caelestia-dots/shell, components/controls/FilledSlider.qml).
//
// So' DESENHA e emite sinais — nao sabe nada de volume/wpctl. Quem
// usa (VolumeOsd.qml) liga "value" num valor de fora e reage aos
// sinais. Por isso o slider nunca escreve em "value" (isso quebraria
// o binding de quem usa).
//
//   - trilha: pill totalmente arredondado
//   - preenchimento: da ponta ate' o handle (a ponta fica escondida
//     atras do handle redondo — nao precisa de clip nem raio por canto)
//   - handle: circulo do tamanho da espessura do slider, com icone;
//     enquanto mexe (ou o valor muda por fora) mostra a porcentagem
//
// vertical: false -> horizontal (0 na esquerda, 1 na direita)
// vertical: true  -> vertical   (0 embaixo, 1 em cima)
// ============================================================
Item {
    id: root

    // ---- API ----
    property real value: 0            // 0..1, vem de fora
    property string icon: ""
    property bool vertical: false

    property color trackColor: Colors.surface
    property color fillColor: Qt.lighter(Colors.accent, 1.9)
    property color handleColor: Colors.fg
    property color handleTextColor: Colors.bg

    readonly property alias dragging: dragArea.pressed

    signal moved(real newValue)        // clique na trilha / arrasto
    signal handleClicked()             // toque no handle sem arrastar
    signal wheelStep(int direction)    // +1 sobe, -1 desce

    implicitWidth: vertical ? 48 : 260
    implicitHeight: vertical ? 187 : 48

    // ---- geometria ----
    readonly property real thickness: vertical ? width : height
    readonly property real handleSize: thickness
    readonly property real span: Math.max(1, (vertical ? height : width) - handleSize)

    // Valor mostrado: segue "value" com animacao, exceto durante o
    // arrasto (ai o handle segue o mouse 1:1, sem atraso).
    property real displayValue: value
    Behavior on displayValue {
        enabled: !root.dragging
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // posicao do handle ao longo do eixo do slider (x se horizontal,
    // y se vertical — no vertical o 1 fica em cima, entao inverte)
    readonly property real handlePos: (vertical ? 1 - displayValue : displayValue) * span

    // "moving" = mostrar a porcentagem no lugar do icone
    property bool moving: false
    property real _lastValue: value

    onValueChanged: {
        if (Math.abs(value - _lastValue) < 0.01) return;
        _lastValue = value;
        moving = true;
        hideTimer.restart();
    }

    onMovingChanged: swapAnim.restart()

    Timer {
        id: hideTimer
        interval: 500
        onTriggered: if (!root.dragging) root.moving = false
    }

    // ---------------- trilha + preenchimento ----------------
    Rectangle {
        id: track
        anchors.fill: parent
        radius: root.thickness / 2
        color: root.trackColor

        Rectangle {
            x: 0
            y: root.vertical ? root.handlePos : 0
            width: root.vertical ? parent.width : root.handlePos + root.handleSize
            height: root.vertical ? parent.height - root.handlePos : parent.height
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
        x: root.vertical ? 0 : root.handlePos
        y: root.vertical ? root.handlePos : 0
        color: root.handleColor

        Text {
            id: label
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: root.moving ? Math.round(root.value * 100) : root.icon
            color: root.handleTextColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: root.moving ? 13 : 18
            font.bold: root.moving
        }
    }

    // "pulinho" ao trocar entre icone e numero (mesma ideia do
    // Behavior on moving do Caelestia)
    SequentialAnimation {
        id: swapAnim
        NumberAnimation { target: label; property: "scale"; to: 0.3; duration: 80; easing.type: Easing.InCubic }
        NumberAnimation { target: label; property: "scale"; to: 1; duration: 150; easing.type: Easing.OutCubic }
    }

    // ---------------- interacao ----------------
    MouseArea {
        id: dragArea
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        property bool didDrag: false
        property bool startedOnHandle: false
        property real grabOffset: 0
        property real pressCoord: 0

        function coord(mouse) { return root.vertical ? mouse.y : mouse.x; }

        function valueAt(mouse) {
            let v = (coord(mouse) - grabOffset - root.handleSize / 2) / root.span;
            v = Math.max(0, Math.min(1, v));
            return root.vertical ? 1 - v : v;
        }

        onPressed: mouse => {
            didDrag = false;
            pressCoord = coord(mouse);
            const handleCenter = root.handlePos + root.handleSize / 2;
            startedOnHandle = Math.abs(pressCoord - handleCenter) <= root.handleSize / 2;
            // pegou no handle: mantem a distancia entre o cursor e o
            // centro dele (sem "pulo"); pegou na trilha: pula pra la'
            grabOffset = startedOnHandle ? pressCoord - handleCenter : 0;
            root.moving = true;
            hideTimer.stop();
            if (!startedOnHandle) root.moved(valueAt(mouse));
        }

        onPositionChanged: mouse => {
            if (!pressed) return;
            if (!didDrag && Math.abs(coord(mouse) - pressCoord) > 3) didDrag = true;
            if (didDrag || !startedOnHandle) root.moved(valueAt(mouse));
        }

        onReleased: {
            // toque no handle sem arrastar = mute/unmute
            if (startedOnHandle && !didDrag) root.handleClicked();
            hideTimer.restart();
        }

        onCanceled: hideTimer.restart()

        onWheel: wheel => root.wheelStep(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
