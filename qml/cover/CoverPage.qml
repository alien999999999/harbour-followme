import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

CoverBackground {
	property string primaryText
	property string secondaryText
	property string chapterText

	CoverPlaceholder {
		text: "FollowMe"
		icon.source: "icon.png"
	}

	Column {
		width: parent.width

		Label {
			text: primaryText
			color: Theme.primaryColor
			truncationMode: TruncationMode.Fade
			width: parent.width
			anchors {
				leftMargin: Theme.paddingMedium
				topMargin: Theme.paddingSmall
			}
		}

		Label {
			text: secondaryText
			color: Theme.secondaryColor
			font.pixelSize: Theme.fontSizeSmall
			truncationMode: TruncationMode.Fade
			width: parent.width
			anchors {
				leftMargin: Theme.paddingMedium
				topMargin: Theme.paddingSmall
			}
		}

		Label {
			text: chapterText
			color: Theme.primaryColor
			truncationMode: TruncationMode.Fade
			width: parent.width
			anchors {
				leftMargin: Theme.paddingMedium
				topMargin: Theme.paddingSmall
			}
		}

	}

	QueueProgress {
		id: "queueProgress"

		downloadQueue: app.downloadQueue

		anchors {
			bottom: parent.bottom
			bottomMargin: Theme.paddingSmall
			topMargin: Theme.paddingSmall
		}
		width: parent.width
	}

}

