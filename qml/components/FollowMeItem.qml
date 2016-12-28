import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
	property string primaryText
	property string secondaryText
	property int last
	property int total
	property bool starred
	property bool detail: true

	width: parent.width

	Label {
		text: primaryText
		color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
		truncationMode: TruncationMode.Fade
		anchors {
			left: parent.left
			leftMargin: Theme.paddingMedium
			top: parent.top
			topMargin: Theme.paddingSmall
		}
	}

	Label {
		visible: detail
		text: secondaryText
		color: Theme.secondaryColor
		font.pixelSize: Theme.fontSizeSmall
		truncationMode: TruncationMode.Fade
		anchors {
			left: parent.left
			leftMargin: Theme.paddingMedium
			bottom: parent.bottom
			bottomMargin: Theme.paddingSmall
		}
	}

	Image {
		source: starred ? '../icons/starGold.svg' : '../icons/starGrey.svg'
		height: parent.height/2
		sourceSize.height: height
		fillMode: Image.PreserveAspectFit
		anchors {
			right: parent.right
			rightMargin: Theme.paddingMedium
			top: parent.top
			topMargin: Theme.paddingSmall
		}
	}

	Label {
		visible: detail
		text: ( last > 0 ? last : '??') + '/' + ( total >= 0 ? total : '??' )
		color: Theme.secondaryColor
		font.pixelSize: Theme.fontSizeSmall
		anchors {
			right: parent.right
			rightMargin: Theme.paddingMedium
			bottom: parent.bottom
			bottomMargin: Theme.paddingSmall
		}
	}
}
