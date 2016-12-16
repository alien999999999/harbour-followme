import QtQuick 2.0
import Sailfish.Silica 1.0

// Item used to download all pages:
//  - repeater for each page
//  - use DownloadPage to download the page and complete the chapter item with absoluteFile (image)
// Must be specified:
//  - locator
//  - chapter (items to be completed)
//  - pageList (a local list of files already present)
//  - donePagesHandler (to proceed when done)

Item {
	id: "downloadPages"

	property var locator
	property var chapter
	property var pageList: []
	property bool nodownload
	property bool force

	property var donePagesHandler

	property bool autostart

	property int todo: chapter != undefined && chapter.items != undefined ? chapter.items.length : 0

	property var downloadPageRepeaterComponent: Qt.createComponent(Qt.resolvedUrl("DownloadPageRepeater.qml"));
	property var downloadPageRepeater

	signal finishedPage (int index, bool success, string filename)
	signal donePages ()

	function activate() {
		// initiate the Repeater... dynamically
		downloadPageRepeater = downloadPageRepeaterComponent.createObject(downloadPages, {
			locator: downloadChapter.locator,
			chapter: downloadChapter.chapter,
			pageList: downloadChapter.presentPageList,
			nodownload: downloadChapter.nodownload,
			force: downloadChapter.force,
			finishedPageHandler: downloadPages.finishedPage,
			donePagesHandler: downloadPages.donePages
		});
	}

	Component.onCompleted: {
		if (donePagesHandler != undefined) {
			console.log("downloadPages: hooking the donePagesHandler");
			donePages.connect(donePagesHandler);
		}
		console.log("downloadPages: " + chapter.items.length + " pages");
		if (autostart) {
			activate();
		}
	}
}
