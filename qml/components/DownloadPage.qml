import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
	id: "downloadPage"

	property var locator
	property var chapter
	property int pageIndex
	property var pageList
	property bool force

	property bool autostart

	property bool success: true

	signal done (bool success)

	function pageExists() {
		for (var i in pageList) {
			if (pageList[i].absoluteFile == chapter.items[pageIndex].absoluteFile) {
				return true;
			}
		}
		return false;
	}

	Fetch {
		id: "fetchPage"
		locator: downloadPage.locator

		onDone: {
			if (success && entries.length > 0 && entries[0] != undefined && entries[0].remoteFile != undefined) {
				chapter.items[pageIndex].remoteFile = entries[0].remoteFile;
				if (!pageExists()) {
					downloadFile.url = chapter.items[pageIndex].remoteFile;
					downloadFile.activate();
					return ;
				}
			}
			downloadPage.done(false);
		}
	}

	PyDownloadFile {
		id: "downloadFile"
		base: app.dataPath
		locator: downloadPage.locator

		onError: downloadPage.done(false);

		onFinished: {
			if (success) {
				chapter.items[pageIndex].absoluteFile = filename;
				var f = filename.split('/');
				chapter.items[pageIndex].file = f[f.length - 1];
			}
			downloadPage.done(success);
		}
	}

	function activate() {
		if (force || chapter.items[pageIndex].remoteFile == undefined || chapter.items[pageIndex].remoteFile == '') {
			fetchPage.activate();
			return ;
		}
		if (!pageExists()) {
			console.log('chapter: page with index ' + pageIndex + ': ' + chapter.items[pageIndex]);
			console.log('chapter: page with index ' + pageIndex + ' has url: ' + chapter.items[pageIndex].remoteFile);
			downloadFile.url = chapter.items[pageIndex].remoteFile;
			downloadFile.activate();
			return ;
		}
		downloadPage.done(true);
	}

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
