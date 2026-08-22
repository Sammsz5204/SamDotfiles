// ============================================================
// shell.qml — ponto de entrada. So instancia a Bar em cada monitor
// conectado (equivalente ao "output": ["HDMI-A-3","VGA-1"] do waybar,
// so que reativo — nao precisa listar nome de monitor na mao).
// Padrao confirmado na doc oficial: Scope + Variants + PanelWindow.
// ============================================================
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        Bar {
            modelData: modelData
        }
    }

    // ============================================================
    // Lockscreen — comeca DESTRAVADO (locked: false). So trava quando
    // chamado via IPC (bind do hyprland.lua) ou "qs -c quickshell ipc
    // call lock lock" na mao. Nao troca a hyprlock ainda — os dois
    // ficam disponiveis em paralelo ate isso rodar estavel por um tempo.
    // ============================================================
    LockContext {
        id: lockContext
        onUnlocked: lock.locked = false
    }

    WlSessionLock {
        id: lock
        locked: false

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    IpcHandler {
        target: "lock"

        function engage(): void {
            lockContext.currentText = "";
            lockContext.showFailure = false;
            lock.locked = true;
        }

        function disengage(): void {
            lock.locked = false;
        }

        function isLocked(): bool {
            return lock.locked;
        }
    }
}
