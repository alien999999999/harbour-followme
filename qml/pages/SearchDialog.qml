import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	property alias title: pageHeader.title
	property alias searchLabel: searchField.label
	property alias searchString: searchField.text

	canAccept: searchString != ''
	acceptDestination: Qt.resolvedUrl("SearchPage.qml")

	Column {
		width: parent.width

		PageHeader {
			id: 'pageHeader'
			title: qsTr("Search")
		}

		TextField {
			id: "searchField"
			width: parent.width
			label: qsTr("Search")
			text: ''
			placeholderText: label
			focus: true
			anchors.leftMargin: Theme.horizontalPageMargin
			anchors.rightMargin: Theme.horizontalPageMargin
		}

	}

	onAcceptPendingChanged: {
		if (acceptPending) {
			acceptDestinationInstance.searchName = searchField.text;
		}
	}
}
