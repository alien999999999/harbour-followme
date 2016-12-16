import QtQuick 2.0
import Sailfish.Silica 1.0

Repeater {
	id: "pageRepeater"

	property var chapter
	property var locator
	property var pageList: []

	property bool nodownload
	property bool force

	property var finishedPageHandler
	property var donePagesHandler

	property int todo: chapter != undefined && chapter.items != undefined ? chapter.items.length : 0
	property var downloadPages: []

	signal finishedPage (int index, bool success, string filename)
	signal donePages ()

	model: chapter.items
	delegate: DownloadPage {
		id: "downloadPage"
		locator: pageRepeater.locator.concat([{id: chapter.items[pageIndex].id, file: chapter.items[pageIndex].file, label: chapter.items[pageIndex].label}])
		chapter: pageRepeater.chapter
		pageIndex: index
		pageList: pageRepeater.pageList
		nodownload: pageRepeater.nodownload
		force: pageRepeater.force

		onDone: {
			todo = todo - 1
			console.log("pages left: " + todo);
			finishedPage(pageIndex, success, nodownload ? chapter.items[pageIndex].remoteFile : chapter.items[pageIndex].absoluteFile);
			if (todo == 0) {
				console.log("triggering signal donePages");
				donePages();
			}
		}

		Component.onCompleted: {
			console.log("downloadPages, page: " + pageIndex);
			downloadPages.push(downloadPage);
		}
	}

	Component.onCompleted: {
		console.log("pageRepeater: hook signals");
		if (finishedPageHandler != undefined) {
			finishedPage.connect(finishedPageHandler);
		}
		if (donePagesHandler != undefined) {
			donePages.connect(donePagesHandler);
		}
		console.log("maybe we should activate all pages here");
		for (var i in downloadPages) {
			console.log("activate Page " + i);
			downloadPages[i].activate();
		}
	}
}
