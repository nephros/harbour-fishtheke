import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils.js" as Datehelper
Page {
    property var currentAPI: datafetcher.getCurrentAPIObject();

    Connections {
        target: currentAPI
        onSearchStatusChanged: {
            loadingIndicator.running = currentAPI.isSearchInProgress();
            loadingIndicator.visible = currentAPI.isSearchInProgress();
            if (!currentAPI.isSearchInProgress() && currentAPI.moreToLoad) {
                console.warn('currentAPI.moreToLoad: ' + currentAPI.moreToLoad)
                loadMoreMenu.enabled = true
            } else {
                loadMoreMenu.enabled = false
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating && pageStack.depth === 2) {
            // When deactivating because of DetailedView coming into view, we have pageStack.depth = 3
            currentAPI.reset()
        }

        // There are 2 possibilities to get to "activating".
        // Either open it for the first time. Then there are no rows in currentAPI
        // or when returning from viewing an item. But then there have to be
        // rows in currentAPI. Thus if rows is 0, we are accessing this page
        // for the first time and start a search.
        if (status == PageStatus.Activating && currentAPI.rowCount() === 0) {
            currentAPI.search()
        }
    }

    id: resultsPage
    SilicaFlickable {
        id: resFlick
        anchors.fill: parent
        // Tell SilicaFlickable the height of its content.
        contentHeight: resultsPage.height
        contentWidth: resultsPage.width
        PushUpMenu {
            id: loadMoreMenu
            quickSelect: true
            MenuItem {
                text: qsTr("Load more")
                onClicked: {
                    currentAPI.loadMore();
                }
            }
        }
      SilicaListView {
        id: listView
        height: parent.height
        width: parent.width
        anchors.left: parent.left
        anchors.right: parent.right

        model: currentAPI

        delegate: ListItem {
            contentHeight: Theme.itemSizeLarge
            contentWidth: parent.width
            onClicked: {pageStack.push(Qt.resolvedUrl("DetailedView.qml"), {"item": display})}
            Column {
                width: parent.width
                Row {
                    width: parent.width
                    height: Theme.fontSizeExtraSmall
                    Label {
                        width: parent.width / 4
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: Theme.paddingMedium
                        text: display.channel
                    }

                    Label {
                        width: 3 * (parent.width / 4)
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignRight
                        rightPadding: Theme.paddingMedium
                        text: Datehelper.date_from_epoch(display.timestamp)
                    }
                }

                Label {
                    color: Theme.primaryColor
                    width: parent.width - Theme.horizontalPageMargin
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: Theme.paddingMedium
                    text: display.title
                }

                Label {
                    color: Theme.secondaryColor
                    width: parent.width - Theme.horizontalPageMargin
                    font.pixelSize: Theme.fontSizeExtraSmall
                    wrapMode: Text.Wrap
                    leftPadding: Theme.paddingMedium
                    text: Datehelper.seconds_to_DHMS(display.duration)
                }
            }
        }

        ViewPlaceholder {
            id: emptyText
            text: qsTr("No results found")
            enabled: listView.count == 0 && !currentAPI.isSearchInProgress() && status == PageStatus.Active
        }

        BusyIndicator {
            id: loadingIndicator
            visible: currentAPI.isSearchInProgress()
            running: visible
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }

        VerticalScrollDecorator {}
    }
  }
}
