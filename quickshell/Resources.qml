// ============================================================
// Resources.qml — CPU/RAM/Disk compactos pra Bar. Mesmos comandos de
// leitura que ja' estavam no SystemPanelPopup.qml (top/free/df), so'
// que agora alimentando ResourceItem (anel pequeno) em vez de StatRing
// (anel grande) — o card grande saiu do painel, mudou de lugar.
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
    id: root
    spacing: 10

    property real cpuPct: 0
    property real ramPct: 0
    property real diskPct: 0

    ResourceItem {
        icon: "󰻠"
        value: root.cpuPct
        ringColor: Colors.blue
        warningThreshold: 90
    }

    ResourceItem {
        icon: "󰍛"
        value: root.ramPct
        ringColor: Colors.green
        warningThreshold: 90
    }

    ResourceItem {
        icon: "󰋊"
        value: root.diskPct
        ringColor: Colors.yellow
        warningThreshold: 90
    }

    Process {
        id: cpuProc
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text.trim());
                if (!isNaN(n)) root.cpuPct = n / 100;
            }
        }
    }

    Process {
        id: ramProc
        command: ["bash", "-c", "free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text.trim());
                if (!isNaN(n)) root.ramPct = n / 100;
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -h / | awk 'NR==2 {print $5}' | sed 's/%//'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text.trim());
                if (!isNaN(n)) root.diskPct = n / 100;
            }
        }
    }

    // cpu sobe rapido, disco quase nao muda — mesmos intervalos que o
    // SystemPanelPopup ja usava
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { cpuProc.running = true; ramProc.running = true; }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }
}
