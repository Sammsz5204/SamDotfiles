// ============================================================
// MorphingButton.qml — Atualizado com Morphing no Clique
// ============================================================
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string icon: "󰎟"
    property string text: "Menu"
    signal clicked()

    property int pressToken: 0
    
    readonly property bool isExpanded: mouseArea.containsMouse
    readonly property bool isPressed: mouseArea.pressed

    implicitWidth: isExpanded ? (iconText.implicitWidth + labelText.implicitWidth + 30) : 26
    implicitHeight: 26

    Behavior on implicitWidth {
        NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
    }

    Rectangle {
        anchors.fill: parent
        
        radius: isPressed ? 8 : (isExpanded ? 19 : 19)
        color: isExpanded || isPressed ? Colors.surface : "transparent"

        Behavior on radius {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    Item {
        id: contentWrapper
        anchors.centerIn: parent
        height: 26
        width: iconText.implicitWidth + (isExpanded ? (labelText.implicitWidth + 6) : 0)
        clip: true 

        Behavior on width {
            NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }

        Text {
            id: iconText
            text: root.icon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
            color: isExpanded ? Colors.fg : Colors.muted

            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        Text {
            id: labelText
            text: root.text
            anchors.left: iconText.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: Colors.fg
            
            opacity: root.isExpanded ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        }
    }


    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            root.pressToken++
            root.clicked()
        }
    }
}
