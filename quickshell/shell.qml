// ============================================================
// shell.qml — ponto de entrada. So instancia a Bar em cada monitor
// conectado (equivalente ao "output": ["HDMI-A-3","VGA-1"] do waybar,
// so que reativo — nao precisa listar nome de monitor na mao).
// Padrao confirmado na doc oficial: Scope + Variants + PanelWindow.
// ============================================================
import Quickshell
import QtQuick

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        Bar {
    	   modelData: screen
	}
    }
}
