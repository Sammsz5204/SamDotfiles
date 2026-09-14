pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// ============================================================
// SystemPanelState.qml — camada de ESTADO (item 12/15): quais modulos
// estao ativos, em que ordem, quantas colunas. Persiste em
// Quickshell.stateDir (diretorio oficial pra esse tipo de dado —
// documentado, nao e' um caminho inventado na mao).
//
// Raiz e' "Scope" (nao QtObject) porque precisamos aninhar um FileView
// como filho — QtObject puro nao tem propriedade padrao pra receber
// elemento filho declarado (so' segura property/function soltos).
// Mesmo tipo que o LockContext.qml ja usa hoje pra aninhar o
// PamContext, e aquele ja roda sem erro.
//
// A logica de hide/show/move foi simulada e testada em Python antes
// de virar QML (inclusive os casos de borda: mover o primeiro item
// pra esquerda, o ultimo pra direita, esconder/mostrar tudo).
// ============================================================
Scope {
    id: root

    // Edicao e' estado de SESSAO, nao precisa persistir — sempre
    // comeca em modo normal quando o painel abre.
    property bool editMode: false
    function toggleEditMode() { editMode = !editMode }

    property alias order: adapter.order
    property alias hidden: adapter.hidden
    property alias gridColumns: adapter.gridColumns

    function isHidden(id) {
        return root.hidden.indexOf(id) !== -1;
    }

    function hide(id) {
        if (!root.isHidden(id)) {
            const h = root.hidden.slice();
            h.push(id);
            root.hidden = h;
        }
        const o = root.order.slice();
        const i = o.indexOf(id);
        if (i !== -1) {
            o.splice(i, 1);
            root.order = o;
        }
    }

    function show(id) {
        const h = root.hidden.slice();
        const i = h.indexOf(id);
        if (i !== -1) {
            h.splice(i, 1);
            root.hidden = h;
        }
        if (root.order.indexOf(id) === -1) {
            const o = root.order.slice();
            o.push(id);
            root.order = o;
        }
    }

    function moveLeft(id) { root._move(id, -1) }
    function moveRight(id) { root._move(id, 1) }

    function _move(id, delta) {
        const o = root.order.slice();
        const i = o.indexOf(id);
        const j = i + delta;
        if (i === -1 || j < 0 || j >= o.length) return;
        const tmp = o[i];
        o[i] = o[j];
        o[j] = tmp;
        root.order = o;
    }

    // Reordena pra um indice arbitrario (usado pelo drag-and-drop —
    // moveLeft/moveRight continuam existindo pros botoes de seta).
    // Testado em Python antes disso, inclusive indice fora do range
    // (gruda na borda em vez de quebrar) e mover pra mesma posicao
    // (vira no-op).
    function reorderTo(id, targetIndex) {
        const o = root.order.slice();
        const i = o.indexOf(id);
        if (i === -1) return;
        o.splice(i, 1);
        const clamped = Math.max(0, Math.min(targetIndex, o.length));
        o.splice(clamped, 0, id);
        root.order = o;
    }

    // ---------------- tamanho dos modulos (item novo: "resizeable") ---
    // Guardado por id, paralelo e DESACOPLADO da ordem de proposito —
    // reordenar nao pode bagunçar tamanho nenhum. Testado em Python:
    // sobrescrever nao duplica, tamanho sobrevive a reorder.
    //
    // So' 1x1/2x1 (largura, nunca altura) — igual o Quick Settings do
    // Android de verdade. O "2x2" foi invencao nossa; tirei porque um
    // tile mais "alto" so' funciona direito com um motor de grid 2D
    // (GridLayout), que foi exatamente o que causou o bug de teleporte
    // que nunca fechamos de vez. Sem essa dimensao extra, a gente troca
    // pra Column-de-RowLayout (linhas independentes, pre-calculadas em
    // JS) — arquitetura que resolve o problema na raiz, nao so' remenda.
    property alias sizedIds: adapter.sizedIds
    property alias sizeValues: adapter.sizeValues

    readonly property var sizeOptions: ["1x1", "2x1"]

    function sizeFor(id) {
        const i = root.sizedIds.indexOf(id);
        return i !== -1 ? root.sizeValues[i] : "1x1";
    }

    function setSize(id, size) {
        const ids = root.sizedIds.slice();
        const vals = root.sizeValues.slice();
        const i = ids.indexOf(id);
        if (i !== -1) {
            vals[i] = size;
        } else {
            ids.push(id);
            vals.push(size);
        }
        root.sizedIds = ids;
        root.sizeValues = vals;
    }

    // Cicla pro proximo tamanho da lista (mantido como utilitario)
    function cycleSize(id) {
        const cur = root.sizeFor(id);
        const idx = root.sizeOptions.indexOf(cur);
        const next = root.sizeOptions[(idx + 1) % root.sizeOptions.length];
        root.setSize(id, next);
    }

    // Usado pela alca de resize arrastavel: cresce/encolhe UM passo,
    // travando nas pontas (nao volta pro inicio ao passar do maximo,
    // nem fica negativo ao passar do minimo). Testado em Python.
    function growSize(id) {
        const idx = root.sizeOptions.indexOf(root.sizeFor(id));
        root.setSize(id, root.sizeOptions[Math.min(idx + 1, root.sizeOptions.length - 1)]);
    }

    function shrinkSize(id) {
        const idx = root.sizeOptions.indexOf(root.sizeFor(id));
        root.setSize(id, root.sizeOptions[Math.max(idx - 1, 0)]);
    }

    // "1x1" -> 1, "2x1" -> 2 (quantas colunas de largura). Fallback
    // seguro (1) pra qualquer valor invalido/corrompido.
    function widthUnitsFor(id) {
        return root.sizeFor(id) === "2x1" ? 2 : 1;
    }

    function resetToDefaults() {
        root.order = SystemPanelModules.defaultOrder.slice();
        root.hidden = [];
        root.gridColumns = 4;
        root.sizedIds = [];
        root.sizeValues = [];
    }

    // Listas ja resolvidas contra o registro — e' isso que a UI consome,
    // nunca ids crus.
    readonly property var visibleModules: root.order
        .filter(id => !root.isHidden(id))
        .map(id => SystemPanelModules.byId(id))
        .filter(m => m !== null)

    readonly property var availableToAdd: root.hidden
        .map(id => SystemPanelModules.byId(id))
        .filter(m => m !== null)

    // ---------------- layout achatado (pre-calculado) ----------------
    // Em vez de deixar um GridLayout 2D decidir sozinho onde cada tile
    // vai (auto-placement que pode reposicionar ATE o proprio tile
    // redimensionado — foi exatamente isso que causou o bug de
    // teleporte que nunca fechamos), a gente decide aqui, em JS, a
    // linha/coluna de cada modulo — greedy, na ordem: acumula largura
    // ate estourar "gridColumns", ai comeca linha nova.
    //
    // Formato ACHATADO (um item por entrada, com row/col/w), nao
    // agrupado em arrays-de-arrays — assim a UI pode desenhar tudo com
    // posicionamento manual (x/y calculados, nao Layout.columnSpan),
    // o que deixa x/y/width livres pra ter Behavior sem restricao
    // nenhuma (a regra "nao anime x/y/width/height de item em Layout"
    // so' vale quando e' o PROPRIO Layout que escreve — se somos nos
    // que calculamos e atribuimos, nao ha conflito algum).
    //
    // Testado em Python (incluindo item 2x1 empurrando o resto pra
    // proxima linha) antes de virar QML: nunca perde nem reordena
    // nenhum modulo.
    readonly property var visibleLayout: {
        const cols = root.gridColumns;
        const result = [];
        let rowIndex = 0;
        let colUnits = 0;
        for (const m of root.visibleModules) {
            const w = root.widthUnitsFor(m.id);
            if (colUnits + w > cols && colUnits > 0) {
                rowIndex += 1;
                colUnits = 0;
            }
            result.push({ module: m, row: rowIndex, col: colUnits, widthUnits: w });
            colUnits += w;
        }
        return result;
    }

    readonly property int totalRows: root.visibleLayout.length > 0
        ? root.visibleLayout[root.visibleLayout.length - 1].row + 1
        : 0

    FileView {
        id: fileView
        path: Quickshell.stateDir + "/system-panel.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            // Arquivo novo/vazio: popula com a ordem padrao na primeira
            // vez, senao o painel abriria sem nenhum modulo.
            if (adapter.order.length === 0 && adapter.hidden.length === 0) {
                adapter.order = SystemPanelModules.defaultOrder.slice();
            }
        }
        onLoadFailed: error => {
            adapter.order = SystemPanelModules.defaultOrder.slice();
        }

        JsonAdapter {
            id: adapter
            property list<string> order: []
            property list<string> hidden: []
            property int gridColumns: 4
            property list<string> sizedIds: []
            property list<string> sizeValues: []
        }
    }
}
