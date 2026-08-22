// ============================================================
// LockContext.qml — estado de autenticacao, compartilhado entre
// todas as telas (se voce tem 2 monitores, os dois usam o MESMO
// contexto, senao digitar em um e ver no outro ficaria dessincronizado).
//
// A logica de PAM aqui e' quase 1:1 com o exemplo OFICIAL da
// documentacao do quickshell (nao a variante do Caelestia, que
// depende de modulos internos dele — Caelestia.Config, SessionManager,
// etc — que voce nao tem). Isso e' de proposito: e' a peca mais
// sensivel do projeto inteiro, entao segui o que esta documentado
// como referencia, sem inventar por cima.
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    signal unlocked
    signal failed

    // Compartilhado entre todas as WlSessionLockSurface (uma por monitor)
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property int failCount: 0

    // Limpa o erro assim que a pessoa comeca a digitar de novo
    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "" || unlockInProgress)
            return;

        root.unlockInProgress = true;
        pam.start();
    }

    PamContext {
        id: pam

        // Config PROPRIA do quickshell, nao a do sistema (login/sudo) —
        // assim um comportamento inesperado do PAM do sistema nunca
        // consegue quebrar o lockscreen. Ver pam/password.conf.
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.currentText);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.failCount = 0;
                root.unlocked();
            } else {
                root.currentText = "";
                root.showFailure = true;
                root.failCount += 1;
                root.failed();
            }
            root.unlockInProgress = false;
        }
    }
}
