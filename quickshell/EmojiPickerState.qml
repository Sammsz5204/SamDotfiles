pragma Singleton
import QtQuick

// ============================================================
// EmojiPickerState.qml — estado compartilhado minusculo. Existe so'
// porque o EmojiPicker.qml roda uma instancia POR MONITOR (mesmo
// padrao da Bar/VolumeOsd), mas o atalho de teclado chama o IPC uma
// vez so' — precisa de um lugar comum pra "abrir/fechar" que todas as
// instancias escutem ao mesmo tempo.
// ============================================================
QtObject {
    id: root

    property bool requestedVisible: false

    function toggle() { requestedVisible = !requestedVisible; }
    function open() { requestedVisible = true; }
    function close() { requestedVisible = false; }
}
