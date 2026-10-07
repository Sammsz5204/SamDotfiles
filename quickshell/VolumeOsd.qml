import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

// ============================================================
// VolumeOsd.qml — desliza da borda INFERIOR da tela quando o volume
// muda (scroll no Volume.qml da Bar, wpctl externo, etc), some sozinho
// depois de um tempo sem mudanca. Inspirado no OSD do Caelestia
// (caelestia-dots/shell, modules/osd/Wrapper.qml) — la' o deles desliza
// pela DIREITA; este desliza por BAIXO, a pedido.
//
// Uma instancia por monitor (ver shell.qml, mesmo padrao da Bar).
// ============================================================
PanelWindow {
    id: osd

    required property var screenTarget
    screen: screenTarget

    anchors {
        bottom: true
        left: true
        right: true
    }

    // Altura reservada pra pill deslizar sem cortar a sombra/gap —
    // so' o "pill" central e' clicavel/visivel de verdade, o resto
    // desta janela e' transparente e ignora clique.
    implicitHeight: 140
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ---------------- mostrar/esconder ----------------
    property bool requestedVisible: false
    property bool closing: false
    visible: requestedVisible || closing

    onRequestedVisibleChanged: {
        if (requestedVisible) {
            closing = false;
            hideTimer.stop();
        } else {
            closing = true;
        }
    }

    function show() {
        requestedVisible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: if (!pillArea.containsMouse && !slider.dragging) osd.requestedVisible = false
    }

    // ---------------- volume (wpctl) ----------------
    property real value: 0
    property bool muted: false

    function iconFor(v, isMuted) {
        if (isMuted) return "󰖁";
        if (v < 0.01) return "󰕿";
        if (v < 0.5) return "󰖀";
        return "󰕾";
    }

    property bool _initialized: false

    Process {
        id: pollProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim();
                const wasMuted = osd.muted;
                const oldValue = osd.value;
                osd.muted = text.includes("[MUTED]");
                const match = text.match(/[\d.]+/);
                if (match) osd.value = Math.min(1, parseFloat(match[0]));

                // Primeira leitura (ao iniciar a shell) so' registra o
                // valor atual do sistema, sem mostrar o OSD — sem isso,
                // o valor real (ex: 40%) comparado contra o 0 padrao
                // sempre parecia "mudou", e o OSD aparecia sozinho no
                // startup sem ninguem ter mexido em nada.
                if (!osd._initialized) {
                    osd._initialized = true;
                    return;
                }

                // So' mostra o OSD se algo REALMENTE mudou desde a
                // ultima leitura — sem isso, o poll periodico (so' pra
                // manter o valor certo se o painel principal tambem
                // mexer no volume) faria o OSD aparecer sozinho toda
                // hora.
                if (Math.abs(osd.value - oldValue) > 0.005 || osd.muted !== wasMuted) {
                    osd.show();
                }
            }
        }
    }

    Process { id: volumeSetProc; running: false }

    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onExited: pollProc.running = true
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!slider.dragging) pollProc.running = true
    }

    // ---------------- pill ----------------
    Item {
        id: pillWrap
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        width: 260
        height: 48

        // Desliza: comeca deslocado pra baixo do proprio tamanho (fora
        // da tela) e anima ate' 0 quando visible fica true — igual o
        // "offsetScale" do Wrapper.qml do Caelestia, so' que no eixo Y
        // em vez do X.
        property real hiddenOffset: height + 24
        y: osd.requestedVisible ? 0 : hiddenOffset
        opacity: osd.requestedVisible ? 1 : 0

        // y e' "spatial" (posicao) -> mola de verdade. opacity e'
        // "effects" -> duration+easing comum, sem mola (ver Motion.qml).
        Behavior on y {
            SpringAnimation {
                spring: Motion.spatialDefault.spring
                damping: Motion.spatialDefault.damping
                mass: Motion.spatialDefault.mass
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: Motion.effectsDefault; easing.type: Motion.effectsEasing }
        }

        // So' desmonta a janela de verdade DEPOIS que a saida terminou
        // (mesmo motivo do requestedVisible/closing: PopupWindow some
        // na hora se so' mexermos em "visible" direto).
        onOpacityChanged: if (opacity === 0 && osd.closing) osd.closing = false

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            // so' pra "containsMouse" segurar o hideTimer — o slider
            // por baixo continua recebendo os cliques normalmente.
        }

        FilledSlider {
            id: slider
            anchors.fill: parent
            vertical: false
            value: osd.value
            icon: osd.iconFor(osd.value, osd.muted)

            onMoved: v => {
                osd.value = v;
                osd.show();
                volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)];
                volumeSetProc.running = true;
            }
            onHandleClicked: {
                muteProc.running = true;
                osd.show();
            }
            onWheelStep: dir => {
                volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@",
                    (dir > 0 ? "2%+" : "2%-")];
                volumeSetProc.running = true;
                osd.show();
            }
        }
    }
}
