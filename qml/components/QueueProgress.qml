import QtQuick 2.0
import Sailfish.Silica 1.0

// Item used to show the queue download progress
// Must be specified:
//  - downloadQueue

Item {
	property var downloadQueue

	signal qChanged ()

	width: parent.width
	visible: downloadQueue.running
	height: downloadQueue.running ? 128 : 0

	ProgressBar {
		id: "progressBar"

		anchors.fill: parent

		label: downloadQueue.currentLabel()
		value: downloadQueue.currentValue()
	}

	onQChanged: {
		// TODO: make some better approximation of progress
		//progressBar.value = downloadQueue.position / downloadQueue.queueLength;
		console.log('Queue was changed(' + downloadQueue.queue.length + '), running: ' + downloadQueue.running);
	}

	Component.onCompleted: {
		downloadQueue.qChanged.connect(qChanged);
	}
}
