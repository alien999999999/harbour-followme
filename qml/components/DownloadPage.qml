import QtQuick 2.0
import Sailfish.Silica 1.0

// Item used to download the page:
//  - fetch the page and check for the image filename (remoteFile)
//  - download the image filename into a local file (absoluteFile)
// Must be specified:
//  - locator
//  - chapter (object to be completed)
//  - pageIndex (specific page that needs to be downloaded)
//  - pageList (a local list of files already present)
// Will trigger a done signal with success, actual filenames will be in the chapter

Item {
	id: "downloadPage"

	property var locator
	property var chapter
	property int pageIndex
	property var pageList
	property bool nodownload
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

	// This Fetch will get the actual image filename
	Fetch {
		id: "fetchPage"
		locator: downloadPage.locator

		onDone: {
			console.log('fetchPage: success = ' + (success ? 'ok' : 'nok'));
			console.log('fetchPage: should be the actual part (level 4?): ' + locator.length);
			console.log('fetchPage: entries: ' + entries.length);
			if (success && entries.length > 0 && entries[0] != undefined && entries[0].remoteFile != undefined) {
				// only the first entry is the actual image file
				console.log('fetchPage: remoteFile is: ' + entries[0].remoteFile);
				chapter.items[pageIndex].remoteFile = entries[0].remoteFile;
				chapter.items[pageIndex].absoluteFile = downloadFile.getAbsoluteFile(chapter.items[pageIndex].remoteFile);
				if (!nodownload && !pageExists()) {
					// if the page does not exist, download it and exit
					downloadFile.url = chapter.items[pageIndex].remoteFile;
					downloadFile.activate();
					return ;
				}
				downloadPage.done(success);
				return ;
			}
			downloadPage.done(false);
		}
	}

	// This will download the file and set the absoluteFile into the chapter item
	PyDownloadFile {
		id: "downloadFile"
		base: app.dataPath
		locator: downloadPage.locator

		onError: downloadPage.done(false);

		onFinished: {
			console.log('downloadFile finished: ' + success);
			if (success) {
				console.log('downloaded into: ' + filename);
				// when successfully downloaded, set the absoluteFile and file to the new local file
				chapter.items[pageIndex].absoluteFile = filename;
				var f = filename.split('/');
				chapter.items[pageIndex].file = f[f.length - 1];
			}
			downloadPage.done(success);
		}
	}

	function activate() {
		console.log('downloadPage: activated');
		console.log('chapter items: ' + chapter.items.length);
		console.log('chapter page: ' + pageIndex);
		if (force || chapter.items[pageIndex].remoteFile == undefined || chapter.items[pageIndex].remoteFile == '') {
			console.log('page ' + pageIndex + ' has no remoteFile yet, fetching it...');
			// if forced or remoteFile does not exist, fetch it and exit
			fetchPage.activate();
			return ;
		}
		console.log('page ' + pageIndex + ' already has remoteFile "' + chapter.items[pageIndex].remoteFile + '"');
		if (!nodownload && !pageExists()) {
			// if the page does not exist, download it and exit
			console.log('chapter: page with index ' + pageIndex + ': ' + chapter.items[pageIndex]);
			console.log('chapter: page with index ' + pageIndex + ' has url: ' + chapter.items[pageIndex].remoteFile);
			downloadFile.url = chapter.items[pageIndex].remoteFile;
			downloadFile.activate();
			return ;
		}
		console.log('page ' + pageIndex + ' seems to be already there (or were not downloading): "' + chapter.items[pageIndex].absoluteFile + '"');
		// the file page already exists or no download is wanted
		downloadPage.done(true);
	}

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
