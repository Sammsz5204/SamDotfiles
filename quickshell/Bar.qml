import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
    
PanelWindow {
    id: bar

    required property var modelData

    
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38

    color: "transparent"

    margins {
        top: 8
        left: 10
        right: 10
    }

    exclusionMode: ExclusionMode.Auto
    WlrLayershell.layer: WlrLayer.Top

    // Nota: "requestedVisible" (nao "visible") — o popup so' desmonta a
    // superficie de verdade depois que a animacao de saida termina
    // (ver LauncherPopup.qml/SystemPanelPopup.qml). Usar "visible" aqui
    // voltaria a cortar a animacao de saida pela metade.
    WlrLayershell.keyboardFocus: launcherPanel.requestedVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Startup animation handler
    StartupSplash {
        screenTarget: bar.modelData
        onFinished: barEnterAnim.start()
    }


    // Ele fica escutando o arquivo sem gastar  tanto processamento. 

    Process {
        id: shortcutListener
        command: ["bash", "-c", "if [ ! -p /tmp/qs_toggle ]; then mkfifo /tmp/qs_toggle; fi; cat /tmp/qs_toggle"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                launcherPanel.requestedVisible = !launcherPanel.requestedVisible
                restartTimer.start()
            }
        }
    }

    // Um timer rápido só pro QML reiniciar o listener com segurança
    Timer {
        id: restartTimer
        interval: 20
        onTriggered: shortcutListener.running = true
    }
    // -------------------------------------

    Rectangle {
        id: background

        anchors.fill: parent
        color: Colors.bg
        radius: 19

        // Hidden initially until splash finishes
        opacity: 0
        transform: Translate { id: barTrans; y: -30 }

        ParallelAnimation {
            id: barEnterAnim
            NumberAnimation { target: background; property: "opacity"; to: 1; duration: 320; easing.type: Easing.OutCubic }
            NumberAnimation { target: barTrans; property: "y"; to: 0; duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        RowLayout {
            id: leftLayout

            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            spacing: 6

            MorphingButton {
                  Layout.alignment: Qt.AlignVCenter
                  icon: ""
                  text: "Apps"
    
                  onClicked: launcherPanel.requestedVisible = !launcherPanel.requestedVisible
              }

            IdleInhibitor {
            }

            Resources {
                Layout.alignment: Qt.AlignVCenter
            }

            Volume {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout {
            id: centerLayout

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            spacing: 10

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }

            ClockWidget {
                Layout.alignment: Qt.AlignVCenter
            }

            Taskbar {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout {
            id: rightLayout

            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }

            spacing: 6


            TrayModule {
                Layout.alignment: Qt.AlignVCenter
            }

            MorphingButton {
                Layout.alignment: Qt.AlignVCenter
                icon: "󰎟" 
                text: "System"
                
                onClicked: {
                    systemPanel.requestedVisible = !systemPanel.requestedVisible
                }
            }
        }
    }


    LauncherPopup {
        id: launcherPanel

        anchor.window: bar
        anchor.rect.x: 10
        anchor.rect.y: bar.height + 5
    }

    SystemPanelPopup {
        id: systemPanel

        anchor.window: bar
        anchor.rect.x: bar.width - width - 10
        anchor.rect.y: bar.height + 5
    }
}
