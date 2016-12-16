import QtQuick 2.0
import Sailfish.Silica 1.0

// Item used to download a chapter:
//  - fetch the chapter to find all pages
//  - get a list of current page files
//  - use DownloadPages to download all pages and complete their images (absoluteFile)
//  - save the chapter
// Must be specified:
//  - locator
//  - chapter (items to be completed)

Item {
	id: "downloadChapter"

	property var locator
	property var chapter
	property bool nodownload
	property bool force

	property bool autostart

	property var downloadPagesComponent: Qt.createComponent(Qt.resolvedUrl("DownloadPages.qml"));
	property var downloadPages

	property var presentPageList: []

	signal donePages (bool success)
	signal done (bool success)

	PySaveEntry {
		id: "saveChapter"
		base: app.dataPath
		locator: downloadChapter.locator
	}

	onDonePages: {
		console.log('downloadChapter.donePages: saving chapter');
		saveChapter.save(chapter);
		downloadChapter.done(success);
	}

	function fetchPages(){
		downloadPages = downloadPagesComponent.createObject(downloadChapter, {
			locator: downloadChapter.locator,
			chapter: downloadChapter.chapter,
			pageList: downloadChapter.presentPageList,
			nodownload: downloadChapter.nodownload,
			force: downloadChapter.force,
			donePagesHandler: function () {
				console.log('downloadPages.donePages: finished');
				downloadChapter.donePages(true);
			}
		});
		downloadPages.activate();
	}

	Fetch {
		id: "fetchChapter"
		locator: downloadChapter.locator

		onStarted: chapter.items = [];

		onReceived: chapter.items.push({id: entry.id, file: entry.file, label: entry.label});

		onDone: {
			console.log('fetching chapter is done, with ' + entries.length + ' pages');
			if (success && entries.length > 0) {
				// save for now (maybe not even save later?), problem is that the items should not be expanded...
				saveChapter.save(chapter);
				//chapter.items = entries;
				fetchPages();
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
			console.log('current files in path: ' + entries.length);
			console.log('fetching Chapter...');
			fetchChapter.activate();
		}
	}

	function activate() {
		if (presentPageList.length == 0) {
			chapterListPages.activate();
			return ;
		}
		fetchChapter.activate();
	}

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
