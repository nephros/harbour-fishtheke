import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils.js" as Datehelper

Page {
    id: detailPage
    allowedOrientations: Orientation.All

    property var item
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            spacing: Theme.paddingMedium

            anchors {
                topMargin: Theme.paddingLarge

                left: parent.left
                leftMargin: Theme.horizontalPageMargin

                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }

            PageHeader { title: item.title; wrapMode: Text.WordWrap }
            DetailItem { label: qsTr("channel"); value: item.channel }
            DetailItem { label: qsTr("duration"); value: Datehelper.seconds_to_DHMS(item.duration) }
            DetailItem { label: qsTr("timestamp"); value: Format.formatDate(new Date(item.timestamp*1000), Formatter.DateMedium) + " " + Format.formatDate(new Date(item.timestamp*1000), Formatter.TimeValue) }
            Text {
                color: Theme.primaryColor
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                text: item.description
            }

            SilicaListView {
                id: urlView
                // Warning! height: parent.height leads to a weird hanging of the UI for a couple of seconds.
                height: 8 * (Theme.fontSizeLarge + Theme.paddingMedium)
                width: parent.width
                anchors.left: parent.left
                property string type
                property string url
                model: ListModel {
                    Component.onCompleted: {
                        if (detailPage.item.url_video_hd) {
                            append({"type": "Stream-URL HD", "url": detailPage.item.url_video_hd});
                        }
                        if (detailPage.item.url_video_sd) {
                            append({"type": "Stream-URL SD", "url": detailPage.item.url_video_sd});
                        }
                        if (detailPage.item.url_video) {
                            append({"type": "Stream-URL", "url": detailPage.item.url_video});
                        }
                        if (detailPage.item.url_website) {
                            append({"type": "Website", "url": detailPage.item.url_website});
                        }
                    }
                }

                delegate: ListItem {
                    id: streamButtonItem
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("SendingPage.qml"), {"type": type, "url": url, "item": item})
                    }
                    contentWidth: parent.width
                    width: parent.width;
                    contentHeight: Theme.itemSizeSmall // one line delegate

                    Label {
                        id: streamButtonLabel
                        padding: Theme.paddingMedium
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: type
                        color: streamButtonItem.highlighted ? Theme.highlightColor : Theme.highlightBackgroundColor
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }
            }

            VerticalScrollDecorator {}
        }
    }
}
