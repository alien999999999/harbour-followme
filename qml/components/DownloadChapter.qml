import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
	id: "downloadChapter"

	property var locator
	property var chapter

	property bool autostart

	property int todo: 0
	property bool success: true

	property var downloadPageComponent: Qt.createComponent(Qt.resolvedUrl("DownloadPage.qml"));
	property var downloadPageList: []

	property var presentPageList: []

	signal pageDone (bool success)
	signal done (bool success)

	PySaveEntry {
		id: "saveChapter"
		base: app.dataPath
		locator: downloadChapter.locator
	}

	onPageDone: {
		console.log('page todo: ' + todo);
		todo = todo - 1;
		if (!success) {
			downloadChapter.success = false;
		}
		if (todo == 0) {
			saveChapter.save(chapter);
			downloadChapter.done(downloadChapter.success);
		}
	}

	Fetch {
		id: "fetchChapter"
		locator: downloadChapter.locator

		onDone: {
			if (success && entries.length > 0) {
				chapter.items = entries;
				todo = entries.length;
				for (var i in entries) {
					var o = downloadPageComponent.createObject(null, {
						locator: downloadChapter.locator.concat([entries[i].id]),
						chapter: downloadChapter.chapter,
						pageIndex: i,
						pageList: presentPageList
					});
					downloadPageList.push(o);
					o.done.connect(pageDone);
					o.activate();
				}
				return ;
			}
			downloadChapter.done(false);
		}
	}

	PyListEntries {
		id: "chapterListPages"
		base: app.dataPath
		locator: downloadChapter.locator
		files: true

		onFinished: {
			presentPageList = entries;
			fetchChapter.activate();
		}
	}

	function activate() {
		chapterListPages.activate();
	}

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
