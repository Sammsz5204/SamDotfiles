pragma Singleton
import QtQuick

// ============================================================
// Motion.qml — tokens de animacao M3 Expressive, reescrito pra seguir
// a separacao REAL que a spec usa (nao e' so' "duration + easing" pra
// tudo — foi uma simplificacao nossa ate' aqui):
//
//   SPATIAL  (posicao, tamanho, raio, escala — qualquer coisa "fisica")
//            -> MOLA DE VERDADE (spring physics), propositalmente
//               sub-amortecida — "passa do ponto" antes de assentar,
//               e' isso que da' a sensacao expressive.
//
//   EFFECTS  (cor, opacidade) -> duration+easing comum, SEM overshoot
//            nenhum — a propria doc do M3 diz que cor/opacidade com
//            overshoot parece "piscar", nao parece elegante.
//
// Fonte: M3EMotion (pacote material_3_expressive) + MaterialSpringMotion
// (pacote motor), os dois documentam o mesmo par de tabelas (stiffness/
// damping por velocidade x categoria):
//
//   expressive spatial:  fast(800, 0.6)  default(380, 0.8)  slow(200, 0.8)
//   expressive effects:  fast(3800, 1)   default(1600, 1)   slow(800, 1)
//
// Esses numeros sao do motor de fisica do Compose/Flutter (nao sao as
// mesmas unidades do SpringAnimation do QtQuick — nao da' pra copiar
// o valor cru). O que importa e' a RELACAO entre eles: effects sempre
// com damping=1 (critico, sem overshoot, nunca); spatial sempre com
// damping<1 (sub-amortecido, sempre overshoot); fast=mais rigido e mais
// amortecido que slow nas duas familias. Os valores de spring/damping
// do SpringAnimation abaixo foram ajustados pra reproduzir essa MESMA
// relacao dentro do que o QtQuick aceita, nao pra bater numero exato.
// ============================================================
QtObject {
    id: root

    // ---------------- SPATIAL (mola — posicao/tamanho/raio/escala) ----
    // Behavior on x/y/width/height/radius/scale {
    //     SpringAnimation { spring: Motion.spatialDefault.spring; damping: Motion.spatialDefault.damping }
    // }
    readonly property var spatialFast: QtObject {
        readonly property real spring: 6.5
        readonly property real damping: 0.42
        readonly property real mass: 1.0
    }
    readonly property var spatialDefault: QtObject {
        readonly property real spring: 3.2
        readonly property real damping: 0.45
        readonly property real mass: 1.0
    }
    readonly property var spatialSlow: QtObject {
        readonly property real spring: 1.6
        readonly property real damping: 0.5
        readonly property real mass: 1.0
    }

    // ---------------- EFFECTS (duration+easing — cor/opacidade) ------
    // Behavior on color/opacity { ColorAnimation/NumberAnimation {
    //     duration: Motion.effectsDefault; easing.type: Motion.effectsEasing
    // } }
    // damping=1 na tabela de referencia = critico = SEM overshoot, por
    // isso aqui e' so' easing comum (nunca Easing.OutBack/InBack).
    readonly property int effectsFast: 100
    readonly property int effectsDefault: 200
    readonly property int effectsSlow: 350
    readonly property int effectsEasing: Easing.OutCubic

    // ---------------- tokens de duracao (fallback) --------------------
    // Pra quando um Behavior simples (sem mola) e' suficiente — ex:
    // hover de cor, que ja' e' "effects" por definicao.
    readonly property int short1: 50
    readonly property int short2: 100
    readonly property int short3: 150
    readonly property int short4: 200
    readonly property int medium1: 250
    readonly property int medium2: 300
    readonly property int medium3: 350
    readonly property int medium4: 400
    readonly property int long1: 450
    readonly property int long2: 500

    // ---------------- compatibilidade com o codigo existente ----------
    // Mantidos pra nao quebrar os componentes que ja' usam esses nomes
    // (ActionBtn, MorphingButton, MediaButton, IconButton, popups) —
    // ver TODO de migracao no final do arquivo.
    readonly property int pressDuration: 100
    readonly property int pressEasingType: Easing.OutCubic
    readonly property int releaseDuration: 260
    readonly property int releaseEasingType: Easing.OutBack
    readonly property real releaseOvershoot: 1.4
    readonly property real pressRadiusRatio: 0.67
    readonly property real hoverRadiusRatio: 1.33
    readonly property int hoverDuration: 150
    readonly property int hoverEasingType: Easing.OutCubic

    readonly property int popupEnterDuration: 320
    readonly property int popupEnterEasingType: Easing.OutBack
    readonly property real popupEnterOvershoot: 1.4
    readonly property int popupEnterFadeDuration: 200
    readonly property int popupExitDuration: 200
    readonly property int popupExitEasingType: Easing.InCubic
    readonly property int popupExitFadeDuration: 160

    function pressedRadius(restRadius) { return restRadius * root.pressRadiusRatio; }
    function hoverRadius(restRadius) { return restRadius * root.hoverRadiusRatio; }
    function pressedRadiusClamped(restRadius, height) {
        const visualRest = Math.min(restRadius, height / 2);
        return visualRest * root.pressRadiusRatio;
    }

    // ============================================================
    // Migracao NumberAnimation+OutBack -> SpringAnimation (mola de
    // verdade), por componente:
    //   [x] ActionBtn.qml       (radius on press/release/hover)
    //   [x] MorphingButton.qml  (radius on press/release)
    //   [x] MediaButton.qml     (radius on press/release)
    //   [x] IconButton.qml      (radius on press/release)
    //   [x] SystemPanelPopup.qml (scale=mola, opacity=easing)
    //   [x] LauncherPopup.qml    (scale=mola, opacity=easing)
    //   [x] VolumeOsd.qml        (y=mola, opacity=easing)
    //
    // Ainda usando NumberAnimation+OutBack (nao e' obrigatorio trocar,
    // mas segue a mesma logica se algum dia quiser revisitar):
    //   - Workspaces.qml   (Layout.preferredWidth do item focado) —
    //     spatial, caso a parte (indicador de estado, nao gesto de
    //     toque — ver conversa anterior)
    //   - ActionBtn.qml    (x/y/width do drag-and-drop entre tiles,
    //     Behavior com OutBack) — spatial, candidato a SpringAnimation
    //     se quiser continuar a migracao
    //   - LauncherPopup.qml (scale dos cards da lista de apps, hover/
    //     press) — spatial, mesmo caso
    //   - Bar.qml (entrada da barra: opacity+y do background) — y e'
    //     spatial (mola), opacity fica effects (ja' esta certo, so' nao
    //     migrado)
    // ============================================================
}
