import QtQuick 2.15
import QtQuick.Window 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int sessionIndex: session.index
    property bool isMainScreen: Screen.width > Screen.height

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginFailed() {
            pw_entry.text = ""
        }
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background)
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        visible: isMainScreen
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(new Date(), "hh:mm")
                color: "white"
                font.pixelSize: 72
                font.bold: true
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm")
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(new Date(), "dddd, dd MMMM")
                color: Qt.rgba(255, 255, 255, 0.7)
                font.pixelSize: 18
            }

            Rectangle { width: 1; height: 20; color: "transparent" }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                PasswordBox {
                    id: pw_entry
                    width: 280
                    height: 42
                    font.pixelSize: 16
                    color: Qt.rgba(30, 30, 46, 0.8)
                    borderColor: "transparent"
                    focusColor: "transparent"
                    hoverColor: Qt.rgba(30, 30, 46, 1.0)
                    textColor: "white"
                    radius: 8
                    tooltipEnabled: false

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(userModel.lastUser, pw_entry.text, sessionIndex)
                            event.accepted = true
                        }
                    }
                }

                Button {
                    id: loginBtn
                    width: 42; height: 42
                    text: "\u2192"
                    font.pixelSize: 20
                    color: Qt.rgba(203, 166, 247, 0.8)
                    activeColor: Qt.rgba(203, 166, 247, 0.6)
                    pressedColor: Qt.rgba(203, 166, 247, 1.0)
                    borderColor: "transparent"
                    textColor: "white"

                    onClicked: sddm.login(userModel.lastUser, pw_entry.text, sessionIndex)
                }
            }

            Rectangle { width: 1; height: 30; color: "transparent" }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                ComboBox {
                    id: session
                    width: 160
                    height: 28
                    font.pixelSize: 12
                    model: sessionModel
                    index: sessionModel.lastIndex
                    color: "transparent"
                    borderColor: Qt.rgba(255, 255, 255, 0.15)
                    focusColor: Qt.rgba(255, 255, 255, 0.25)
                    hoverColor: Qt.rgba(255, 255, 255, 0.1)
                    textColor: Qt.rgba(255, 255, 255, 0.6)
                    menuColor: Qt.rgba(24, 24, 37, 0.95)
                }

                LayoutBox {
                    id: layoutBox
                    width: 90
                    height: 28
                    visible: keyboard.enabled && keyboard.layouts.length > 0
                    font.pixelSize: 12
                    color: "transparent"
                    borderColor: Qt.rgba(255, 255, 255, 0.15)
                    focusColor: Qt.rgba(255, 255, 255, 0.25)
                    hoverColor: Qt.rgba(255, 255, 255, 0.1)
                    textColor: Qt.rgba(255, 255, 255, 0.6)
                    menuColor: Qt.rgba(24, 24, 37, 0.95)
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 24
            spacing: 16

            Text {
                text: "\u23FB"
                font.pixelSize: 20
                color: Qt.rgba(255, 255, 255, 0.3)
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.powerOff()
                }
            }
            Text {
                text: "\u21BB"
                font.pixelSize: 20
                color: Qt.rgba(255, 255, 255, 0.3)
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.reboot()
                }
            }
        }
    }

    Component.onCompleted: {
        pw_entry.focus = true
    }
}
