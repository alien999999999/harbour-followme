import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
	id: "listItem"

	property int partIndex
	property string partId
	property string file
	property string absoluteFile
	property var parentLocator

	signal imageError (var parentLocator, int partIndex, string partId)

	property bool ready: imageFile.status === Image.Ready
	width: parent.width
	height: ready ? imageFile.sourceSize.height * width / imageFile.sourceSize.width : busyFile.height + Theme.paddingLarge * 2

	Image {
		id: "imageFile"
		source: absoluteFile
		fillMode: Image.PreserveAspectFit
		width: parent.width
		height: ready ? imageFile.sourceSize.height * width / imageFile.sourceSize.width : 0
		Component.onCompleted: {
			if (imageFile.status === Image.Error) {
				// fetch online
				console.log("error in image " + absoluteFile);
				imageError(listItem.parentLocator, listItem.partIndex, listItem.partId);
			}
		}
	}

	BusyIndicator {
		width: parent.width
		id: "busyFile"
		running: true
		size: BusyIndicatorSize.Small
		visible: !ready
		anchors.verticalCenter: parent.verticalCenter
	}
}
