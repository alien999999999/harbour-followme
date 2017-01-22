import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
	property string primaryText
	property string secondaryText
	property string sizeText
	property string last
	property string total
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
		source: starred ? '../images/starGold.svg' : '../images/starGrey.svg'
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

	Row {
		spacing: Theme.paddingLarge
		anchors {
			right: parent.right
			bottom: parent.bottom
		}

		Label {
			text: sizeText
			color: Theme.secondaryColor
			font.pixelSize: Theme.fontSizeSmall
			anchors {
				leftMargin: Theme.paddingMedium
				rightMargin: Theme.paddingMedium
				bottom: parent.bottom
				bottomMargin: Theme.paddingSmall
			}
		}

		Label {
			visible: detail
			text: last + '/' + total
			color: Theme.secondaryColor
			font.pixelSize: Theme.fontSizeSmall
			anchors {
				leftMargin: Theme.paddingMedium
				rightMargin: Theme.paddingMedium
				bottom: parent.bottom
				bottomMargin: Theme.paddingSmall
			}
		}
	}
}
