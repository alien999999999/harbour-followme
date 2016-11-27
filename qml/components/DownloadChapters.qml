import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
	id: "downloadChapters"

	property var locator
	property var chapters

	property bool autostart

	property int from
	property int to
	property int todo
	property bool success: true

	property var downloadChapterComponent: Qt.createComponent(Qt.resolvedUrl("DownloadChapter.qml"));
	property var downloadChapterList: []

	signal chapterDone (bool success)
	signal done (bool success)

	onChapterDone: {
		if (!success) {
			downloadChapters.success = false;
		}
		todo = todo - 1;
		if (todo == 0) {
			done(downloadChapters.success);
		}
	}

	function activate() {
		todo = to - from;
		success = true;
		console.log('chapters: ' + chapters.join(','));
		for (var i = from; i <= to; i++) {
			console.log('chapter: ' + chapters[i - 1].id);
			var o = downloadChapterComponent.createObject(null, {
				locator: locator.concat([chapters[i - 1].id]),
				chapter: {
					id: chapters[i - 1].id, 
					label: chapters[i - 1].label,
					items: []
				}
			});
			downloadChapterList.push(o);
			o.done.connect(chapterDone);
			o.activate();
		}
	}

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
