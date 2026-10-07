import QtQuick
import QtQuick.Layouts
import Quickshell

// ============================================================
// ActionBtn.qml — reescrito depois de aprender com o nandoroid-shell
// (github.com/na-ive/nandoroid-shell) que o jeito robusto de fazer
// isso e' NAO usar GridLayout/RowLayout pra posicionar os tiles.
//
// Posicionamento manual: a Popup calcula targetX/targetY/targetWidth
// pra cada tile (via SystemPanelState.visibleLayout, empacotamento
// greedy pre-calculado em JS — testado em Python antes de virar
// codigo) e passa como propriedade normal. Como NENHUM Layout do Qt
// esta escrevendo x/y/width aqui, Behavior neles funciona sem
// restricao nenhuma — a doc so' desaconselha isso quando e' o proprio
// Layout quem escreve a propriedade (foi exatamente o que causava o
// "teleporta e so' depois estica" nas duas tentativas anteriores).
//
// So' 1x1/2x1 agora (largura, nunca altura) — igual o Quick Settings
// do Android de verdade, e o que permite esse posicionamento simples
// (altura sempre igual pra todo mundo).
//
// Radius (M3 Expressive, via Motion.qml): migrado de uma Behavior
// simetrica unica pra curva assimetrica — descida (press) rapida sem
// mola, subida (release) com overshoot. A transicao de HOVER (nao e'
// gesto de toque) continua suave e simetrica, so' que agora tambem
// via token (Motion.hoverDuration). Como radius passou a ser
// controlado por NumberAnimation imperativa, nao pode mais ter um
// binding declarativo (`radius: cond ? a : b`) — os dois brigariam
// pela mesma propriedade. Por isso os handlers de hover/press/release
// abaixo escrevem o "to" e disparam a animacao certa na mao, em vez
// de deixar um binding decidir sozinho.
// ============================================================
Rectangle {
    id: root

    property string moduleId: ""
    property string icon: ""
    property string label: ""
    property color iconColor: Colors.fg
    property string cmd: ""

    // Calculados e passados pela Popup (a partir de SystemPanelState.visibleLayout)
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 65
    readonly property real tileHeight: 65

    // Quando o proprio drag deste tile esta em andamento, a Popup pede
    // pra esconder o tile "de verdade" (o "fantasma" que segue o mouse
    // e' quem fica visivel nesse momento) — ver SystemPanelPopup.qml.
    property bool ghosted: false

    signal closeRequested()
    signal dragStarted(string moduleId, real globalX, real globalY)
    signal dragMoved(real globalX, real globalY)
    signal dragEnded()

    // So' comeca a animar DEPOIS que o layout inicial ja' assentou uma
    // vez — sem isso a primeira abertura do painel tambem "anima" (nao
    // e' o que a gente quer, so' mudanca de verdade deve).
    property bool animReady: false
    Component.onCompleted: Qt.callLater(() => root.animReady = true)

    x: targetX
    y: targetY
    width: targetWidth
    height: tileHeight

    Behavior on x {
        enabled: root.animReady
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }
    Behavior on y {
        enabled: root.animReady
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }
    Behavior on width {
        enabled: root.animReady
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }

    opacity: ghosted ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 100 } }

    // Fundo tonal liso, sem borda. Clareia no hover e escurece no press.
    color: mArea.pressed
        ? Colors.surface
        : (mArea.containsMouse ? Qt.lighter(Colors.surface, 1.9) : Colors.surface)

    border.width: SystemPanelState.editMode ? 2 : 0
    border.color: Colors.brightBlue
    Behavior on border.width { NumberAnimation { duration: 150 } }

    // ---------------- radius (M3 Expressive via Motion.qml) ----------------
    readonly property real restRadius: 15
    readonly property real hoverRadius: Motion.hoverRadius(restRadius)     // ~20
    readonly property real pressedRadius: Motion.pressedRadius(restRadius) // ~10

    radius: restRadius // valor inicial; a partir daqui quem escreve sao as SpringAnimation abaixo

    // radius e' "spatial" (M3 Expressive) -> mola de verdade, nao
    // duration+easing fingindo overshoot. Press mais rigido/rapido
    // (spatialFast); release e hover com a mola default (mais visivel,
    // "assenta" devagar) — ver Motion.qml pra tabela completa.
    SpringAnimation {
        id: pressAnim
        target: root; property: "radius"; to: root.pressedRadius
        spring: Motion.spatialFast.spring
        damping: Motion.spatialFast.damping
        mass: Motion.spatialFast.mass
    }
    SpringAnimation {
        id: releaseAnim
        target: root; property: "radius"
        spring: Motion.spatialDefault.spring
        damping: Motion.spatialDefault.damping
        mass: Motion.spatialDefault.mass
    }
    SpringAnimation {
        id: hoverAnim
        target: root; property: "radius"
        spring: Motion.spatialDefault.spring
        damping: Motion.spatialDefault.damping
        mass: Motion.spatialDefault.mass
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    // ---------------- ripple (M3 Expressive) ----------------
    // Inspirado no RippleButton do nandoroid-shell, mas via Canvas em
    // vez de Qt5Compat.GraphicalEffects (OpacityMask+RadialGradient) —
    // assim nao precisa instalar um modulo novo. O recorte de cantos
    // arredondados e' feito na mao (ctx.clip() num path arredondado
    // desenhado com arcTo, a mesma tecnica ja usada na alca de resize),
    // nao com uma mascara separada.
    Canvas {
        id: rippleCanvas
        anchors.fill: parent
        z: 1

        property real rippleX: 0
        property real rippleY: 0
        property real rippleRadius: 0
        property real rippleAlpha: 0

        onRippleRadiusChanged: requestPaint()
        onRippleAlphaChanged: requestPaint()

        function roundedRectPath(ctx, w, h, r) {
            ctx.beginPath();
            ctx.moveTo(r, 0);
            ctx.arcTo(w, 0, w, h, r);
            ctx.arcTo(w, h, 0, h, r);
            ctx.arcTo(0, h, 0, 0, r);
            ctx.arcTo(0, 0, w, 0, r);
            ctx.closePath();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (rippleAlpha <= 0 || rippleRadius <= 0) return;

            ctx.save();
            // Raio fixo aproximado (nao acompanha o Behavior do radius
            // do tile em tempo real) — simplificacao deliberada, o
            // ripple e' rapido demais pra essa diferenca ser perceptivel.
            roundedRectPath(ctx, width, height, 15);
            ctx.clip();

            const grad = ctx.createRadialGradient(
                rippleX, rippleY, 0,
                rippleX, rippleY, rippleRadius
            );
            grad.addColorStop(0, Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, rippleAlpha * 0.30));
            grad.addColorStop(1, Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0));
            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, width, height);
            ctx.restore();
        }

        NumberAnimation {
            id: rippleExpand
            target: rippleCanvas
            property: "rippleRadius"
            from: 0
            duration: 450
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: rippleFade
            target: rippleCanvas
            property: "rippleAlpha"
            from: 1
            to: 0
            duration: 550
            easing.type: Easing.InCubic
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.icon
            color: root.iconColor
            font.pixelSize: 20
            Layout.alignment: Qt.AlignHCenter

            // O icone da um pulinho extra descolado do botao
            scale: mArea.containsMouse ? 1.15 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 3.0 }
            }
        }

        Text {
            text: root.label
            color: Colors.fg
            font.pixelSize: 10
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignHCenter
        }
    }

    MouseArea {
        id: mArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // No modo de edicao o clique principal nao executa nada — so'
        // os controles de edicao (✕ / setas / arrastar) respondem.
        enabled: !SystemPanelState.editMode

        onPressed: mouse => {
            const maxDist = Math.max(
                Math.hypot(mouse.x, mouse.y),
                Math.hypot(width - mouse.x, mouse.y),
                Math.hypot(mouse.x, height - mouse.y),
                Math.hypot(width - mouse.x, height - mouse.y)
            );
            rippleCanvas.rippleX = mouse.x;
            rippleCanvas.rippleY = mouse.y;
            rippleExpand.to = maxDist;
            rippleExpand.restart();
            rippleFade.restart();

            hoverAnim.stop();
            releaseAnim.stop();
            pressAnim.restart();
        }

        onReleased: {
            pressAnim.stop();
            releaseAnim.to = mArea.containsMouse ? root.hoverRadius : root.restRadius;
            releaseAnim.restart();
        }

        onCanceled: {
            pressAnim.stop();
            releaseAnim.to = mArea.containsMouse ? root.hoverRadius : root.restRadius;
            releaseAnim.restart();
        }

        onEntered: {
            if (mArea.pressed) return;
            releaseAnim.stop();
            hoverAnim.to = root.hoverRadius;
            hoverAnim.restart();
        }

        onExited: {
            if (mArea.pressed) return;
            releaseAnim.stop();
            hoverAnim.to = root.restRadius;
            hoverAnim.restart();
        }

        onClicked: {
            if (root.cmd === "__CLOSE__") {
                root.closeRequested();
                return;
            }

            if (root.cmd !== "") {
                Quickshell.execDetached(["bash", "-c", root.cmd]);
                root.closeRequested();
            }
        }
    }

    // ---------------- arrastar pra reordenar (so' no modo de edicao) --
    // Fica ATRAS dos controles de canto (z menor), entao ✕/setas/resize
    // continuam recebendo o clique deles normalmente — essa area so'
    // pega o resto do tile. Emite sinais com coordenada GLOBAL pra quem
    // ta escutando (a Popup) poder comparar posicao entre tiles
    // diferentes sem precisar saber a hierarquia de quem emitiu.
    MouseArea {
        id: dragArea
        anchors.fill: parent
        visible: SystemPanelState.editMode
        enabled: SystemPanelState.editMode
        cursorShape: Qt.SizeAllCursor
        preventStealing: true

        onPressed: mouse => {
            const g = mapToGlobal(mouse.x, mouse.y);
            root.dragStarted(root.moduleId, g.x, g.y);
        }
        onPositionChanged: mouse => {
            const g = mapToGlobal(mouse.x, mouse.y);
            root.dragMoved(g.x, g.y);
        }
        onReleased: root.dragEnded()
        onCanceled: root.dragEnded()
    }

    // ---------------- controles do modo de edicao ----------------
    Rectangle {
        visible: SystemPanelState.editMode
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -6
        width: 20
        height: 20
        radius: 10
        color: Colors.brightRed
        z: 10

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: Colors.bg
            font.pixelSize: 10
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: SystemPanelState.hide(root.moduleId)
        }
    }

    // Redimensionar: alca no canto inferior-direito (igual o Android),
    // desenhada como uma quina grossa. Arrastar acumula distancia e
    // "engata" um degrau de tamanho a cada ~40px — cresce/encolhe SEM
    // voltar pro inicio ao passar do limite (testado em Python). So'
    // largura agora (1x1 <-> 2x1) — sem "altura" nesse sistema.
    Item {
        id: resizeHandle
        visible: SystemPanelState.editMode
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: -4
        width: 22
        height: 22
        z: 10

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = Colors.brightGreen;
                ctx.lineWidth = 3;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(width * 0.4, height * 0.9);
                ctx.lineTo(width * 0.9, height * 0.9);
                ctx.lineTo(width * 0.9, height * 0.4);
                ctx.stroke();
            }
        }

        MouseArea {
            id: resizeArea
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.SizeHorCursor
            preventStealing: true

            property real accumDx: 0
            // Coordenada GLOBAL (tela), nao local — a local se move junto
            // com a propria alca quando o tile cresce/encolhe no meio do
            // gesto, o que corrompia a distancia acumulada (o cursor
            // "descolava" do painel). Global e' um referencial fixo,
            // imune a isso.
            property real lastGlobalX: 0
            readonly property real stepPx: 40

            onPressed: mouse => {
                accumDx = 0;
                const g = mapToGlobal(mouse.x, mouse.y);
                lastGlobalX = g.x;
            }

            onPositionChanged: mouse => {
                const g = mapToGlobal(mouse.x, mouse.y);
                accumDx += (g.x - lastGlobalX);
                lastGlobalX = g.x;

                if (accumDx > stepPx) {
                    SystemPanelState.growSize(root.moduleId);
                    accumDx = 0;
                } else if (accumDx < -stepPx) {
                    SystemPanelState.shrinkSize(root.moduleId);
                    accumDx = 0;
                }
            }
        }
    }

    RowLayout {
        visible: SystemPanelState.editMode
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: -8
        spacing: 4
        z: 10

        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: Colors.surface
            border.color: Colors.muted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "‹"
                color: Colors.fg
                font.pixelSize: 12
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: SystemPanelState.moveLeft(root.moduleId)
            }
        }

        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: Colors.surface
            border.color: Colors.muted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "›"
                color: Colors.fg
                font.pixelSize: 12
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: SystemPanelState.moveRight(root.moduleId)
            }
        }
    }
}
