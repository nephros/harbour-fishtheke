import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils.js" as Datehelper
import Nemo.DBus 2.0
import Nemo.Notifications 1.0

Page {
    id: detailPage

    Notification {
         id: notification
         urgency: Notification.Critical
         isTransient: true
     }

    Item {
        id: browser
        property bool isActive: true
        function sendURL(name, url) {
           Qt.openUrlExternally(url)
        }
    }

    Item {
        id: clipboard
        property bool isActive: true
        function sendURL(name, url) {
           Clipboard.text = url
        }
    }

    Item {
        id: videoPlayer
        property bool isActive: false
        Component.onCompleted: {
            isActive = datafetcher.fileExists("/usr/bin/harbour-videoPlayer")
        }

        function sendURL(name, url) {
           datafetcher.runExternalCommand("/usr/bin/harbour-videoPlayer -p \"" + url + "\"")
        }
    }
    DBusInterface {
        id: gallery
        property bool isActive: false

        service: 'com.jolla.gallery'
        iface: 'com.jolla.gallery.ui'
        path: '/com/jolla/gallery/ui'
        Component.onCompleted: {
            isActive = datafetcher.fileExists("/usr/bin/jolla-gallery")
        }

        function sendURL(name, url) {
            typedCall('playVideoStream',
                          { 'type': 'as', 'value': [url] },
                          function(result) { console.log('Send ' + url + ' to gallery.') },
                          function(error, message) { notification.previewSummary = qsTr('Failed to send to %1', '%1 is application name').arg(qsTr('Jolla gallery', 'application name'));
                                                     notification.previewBody = message;
                                                     notification.publish()}
                      )
        }
    }

    DBusInterface {
        id: jupii
        property bool isActive: false
        service: 'org.jupii'
        iface: 'org.freedesktop.DBus.Peer'
        path: '/'
        Component.onCompleted: {
            typedCall('Ping',
                          [] ,
                          function(result) { isActive = true
                                             iface = 'org.jupii.Player'},
                          function(error, message) { isActive = false }
                      )
        }

        function sendURL(name, url) {
            typedCall('addUrl',
                          [{ 'type': 's', 'value': url },
                          { 'type': 's', 'value': name }] ,
                          function(result) { console.log('Send ' + url + ' to jupii.') },
                          function(error, message) { notification.previewSummary = qsTr('Failed to send to %1', '%1 is application name').arg(qsTr('Jupii', 'application name'));
                                                     notification.previewBody = message;
                                                     notification.publish()}
                      )
        }
    }

    DBusInterface {
        id:kodimote
        property bool isActive: false
        service: 'org.mpris.MediaPlayer2.kodimote'
        iface: 'org.freedesktop.DBus.Peer'
        path: '/org/mpris/MediaPlayer2'

        Component.onCompleted: {
            typedCall('Ping',
                      [] ,
                      function(result) { isActive = true
                                         iface = 'org.mpris.MediaPlayer2.Player'},
                      function(error, message) { isActive = false }
                      )
        }
        function sendURL(name, url) {
            typedCall('OpenUri',
                      { 'type': 's', 'value': url } ,
                      function(result) { console.log('Send ' + url + ' to Kodimote.') },
                      function(error, message) { notification.previewSummary = qsTr('Failed to send to %1', '%1 is application name').arg(qsTr('Kodimote', 'application name'));
                                                 notification.previewBody = message;
                                                 notification.publish()}
                      )
        }
    }


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

            DetailItem { id: title; label: qsTr("title"); value: item.title }
            DetailItem { label: qsTr("channel"); value: item.channel }
            DetailItem { label: qsTr("duration"); value: Datehelper.seconds_to_DHMS(item.duration) }
            DetailItem { label: qsTr("timestamp"); value: Datehelper.date_from_epoch(item.timestamp) }
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
                    menu: actionsMenu
                    onClicked: {
                        if (menuOpen) {
                            closeMenu()
                        } else {
                            openMenu()
                        }
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

                    Component {
                        id: actionsMenu
                        ContextMenu {
                            Repeater {
                                model: [[clipboard,   qsTr("Copy to clipboard")],
                                        [browser,     qsTr("Open in browser")],
                                        [gallery,     qsTr("Jolla gallery", "application name")],
                                        [jupii,       qsTr("Jupii", "application name")],
                                        [kodimote,    qsTr("Kodimote", "application name")],
                                        [videoPlayer, qsTr("LLs VideoPlayer", "application name")],
                                       ]
                                MenuItem {
                                    visible: modelData[0].isActive
                                    text: modelData[1]
                                    onClicked: { modelData[0].sendURL(detailPage.item.title, url) }
                                }
                            }
                        }
                    }
                }
            }

            VerticalScrollDecorator {}
        }
    }
}
