import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string icon: ""
    property string label: ""
    property real value: 0
    property color ringColor: "white"

    width: 100
    height: 100

    Canvas {
        id: canvas

        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")

            ctx.clearRect(0, 0, width, height)

            ctx.beginPath()
            ctx.arc(
                width / 2,
                height / 2,
                width / 2 - 4,
                0,
                2 * Math.PI
            )
            ctx.strokeStyle = Colors.bg
            ctx.lineWidth = 8
            ctx.stroke()

            ctx.beginPath()

            var start = -0.5 * Math.PI
            var end = start + (root.value * 2 * Math.PI)

            ctx.arc(
                width / 2,
                height / 2,
                width / 2 - 4,
                start,
                end
            )

            ctx.strokeStyle = root.ringColor
            ctx.lineWidth = 8
            ctx.lineCap = "round"
            ctx.stroke()
        }

        Connections {
            target: root

            function onValueChanged() {
                canvas.requestPaint()
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: root.icon
            color: root.ringColor
            font.pixelSize: 18
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: Math.round(root.value * 100) + "%"
            color: Colors.fg
            font.pixelSize: 13
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.label
            color: Colors.fg
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
