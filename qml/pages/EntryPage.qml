import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: "entryPage"
	property var parentEntry
	property int current

	property var chapter

	property int prev: current < 0 ? -1 : current - 1
	property int next: (current + 1) < parentEntry.items.length ? current + 1 : -1
	property var partModel: chapter != undefined && chapter.items != undefined ? chapter.items : []

	signal gotoSibling (int number)
	signal showChapter (bool success, var item)
	signal chapterLoaded ()
	signal markRead (bool force)
	signal markLast ()

	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	// TODO: make sure to cache them ALL (and save afterwards (if any fetching was done))
	SilicaListView {
		id: "entryView"
		anchors.fill: parent

		header: Column {
			width: parent.width
			height: header.height + Theme.paddingLarge
			PageHeader {
				id: "header"
				title: parentEntry.label + ": " + "Chapter" + " " + (chapter != undefined && chapter.label != undefined ? chapter.label : ( parentEntry.items[current].label != undefined ? parentEntry.items[current].label : parentEntry.items[current].id ) )
			}

			BusyIndicator {
				anchors.horizontalCenter: parent.horizontalCenter
				running: true
				size: BusyIndicatorSize.Large
				visible: entryView.count == 0
			}
		}

		model: partModel

		delegate: FollowMeImage {
			id: "followMeImage"

			property var part: partModel[index]

			width: parent.width
			parentLocator: chapter.locator
			partIndex: index
			partId: part.id
			file: part.file
			absoluteFile: part.absoluteFile != undefined ? app.dataPath + part.absoluteFile : ''

			signal refreshImage()
			signal refreshImageFilename()
			signal imageSaved(bool success, var entry)

			onRefreshImageFilename: {
				console.log("refreshing image filename...");
				app.downloadQueue.immediate({
					locator: parentLocator.concat([{id: part.id, file: part.file, label: part.label}]),
					entry: entryPage.chapter,
					pageIndex: partIndex,
					saveHandler: imageSaved
				});
			}

			onRefreshImage: {
				console.log("refreshing image (ie: re-download " + entryPage.chapter.items[partIndex]['remoteFile'] + ")...");
				app.downloadQueue.immediate({
					locator: parentLocator.concat([{id: part.id, file: part.file, label: part.label},{}]),
					chapter: entryPage.chapter,
					remoteFile: entryPage.chapter.items[partIndex]['remoteFile'],
					pageIndex: partIndex,
					saveHandler: imageSaved
				}, function (){
					console.log('immediate download has been queued, clearing the imageSource');
					followMeImage.imageSource = '';
				});
			}

			onImageSaved: {
				if (success && entryPage.chapter.items[followMeImage.partIndex].absoluteFile != undefined && entryPage.chapter.items[followMeImage.partIndex].absoluteFile != '') {
					console.log("image was saved properly, now it's time to set the imageSource");
					followMeImage.imageSource = app.dataPath + entryPage.chapter.items[followMeImage.partIndex].absoluteFile;
				}
			}

			onImageError: {
				console.log("image has error, redownloading it...");
				if (entryPage.chapter.items[partIndex]['remoteFile'] != undefined) {
					refreshImage();
				}
				else {
					refreshImageFilename();
				}
			}

			menu: ContextMenu {
				MenuItem {
					text: "Refresh"
					onClicked: refreshImage();
				}
			}
		}

	        VerticalScrollDecorator {}

		PullDownMenu {
			visible: prev >= 0 || next > 0
			MenuItem {
				visible: parentEntry.items.length > 1
				text: qsTr("Jump To")
				onClicked: {
					var dialog = pageStack.push(Qt.resolvedUrl("SliderDialog.qml"), {
						title: qsTr("Jump to chapter"),
						number: entryPage.current + 1,
						unit: qsTr("chapter"),
						minimum: 1,
						maximum: entryPage.parentEntry.items.length
					});
					dialog.accepted.connect(function (){
						gotoSibling(dialog.number - 1);
					});
				}
			}
			MenuItem {
				visible: next > 0
				text: qsTr("Next")
				onClicked: gotoSibling(next);
			}
			MenuItem {
				visible: prev >= 0
				text: qsTr("Previous")
				onClicked: gotoSibling(prev);
			}
		}

		PushUpMenu {
			visible: next > 0
			MenuItem {
				text: qsTr("Next")
				onClicked: gotoSibling(next);
			}
		}
	}

	PySaveEntry {
		id: "saveChapter"
		base: app.dataPath
		entry: entryPage.chapter

		onFinished: {
			console.log('saving chapter: ' + (success ? "ok" : "nok"));
			app.dirtyList = true;
		}
	}

	PySaveEntry {
		id: "saveEntry"
		base: app.dataPath
		entry: entryPage.parentEntry

		onFinished: {
			console.log('saving entry: ' + (success ? "ok" : "nok"));
			app.dirtyList = true;
		}
	}

	PyLoadEntry {
		id: "loadChapter"
		base: app.dataPath
		locator: parentEntry.locator.concat([{id: parentEntry.items[current].id, file: parentEntry.items[current].file, label: parentEntry.items[current].label}])
		autostart: true

		onFinished: {
			if (success) {
				// fix label before saving parent
				if (entry.label != undefined) {
					parentEntry.items[current].label = entry.label;
				}
				chapter = entry;
				chapterLoaded();
				return ;
			}
			// fetch them online (not from dir)
			console.log('downloading chapter');
			// show busyIndicator by destroying the chapter items
			// make a chapter start (either it's gotten corrupted, or it's a new one)
			entryView.model = [];
			if (chapter == undefined) {
				chapter = ({id: parentEntry.items[current].id, file: parentEntry.items[current].file, label: parentEntry.items[current].label, items: [], last: -1, read: false});
			}
			else {
				chapter = ({id: parentEntry.items[current].id, file: parentEntry.items[current].file, label: parentEntry.items[current].label, items: [], last: -1, read: false});
			}
			partModel = chapter.items;
			entryView.model = partModel;
			// TODO: when it's done, i need to do the same stuff if it were successfull in loading...
			app.downloadQueue.immediate({
				locator: loadChapter.locator,
				depth: 1,
				sort: true,
				entry: chapter,
				signal: showChapter
			});
		}
	}

	onShowChapter: {
		console.log('chapter now has ' + chapter.items.length + ' parts, setting model (maybe reset is required first?)');
		partModel = chapter.items;
		entryView.model = partModel;
	}

	onChapterLoaded: {
		markLast();
		entryView.model = partModel;

		// mark it as read
		console.log("saving to chapter: " + entryPage.current);
		markRead(false);

		// fix the cover
		app.coverPage.primaryText = parentEntry.label;
		app.coverPage.secondaryText = parentEntry.locator[0].label;
		app.coverPage.chapterText = 'Chapter: ' + (parentEntry.items[current].label != undefined ? parentEntry.items[current].label : parentEntry.items[current].id);
	}

	onMarkRead: {
		// no need to save if already read
		if (chapter.read != undefined && chapter.read && !force) {
			return ;
		}
		// mark chapter read
		chapter.read = true;
		saveChapter.activate();
	}

	onMarkLast: {
		// no need to save parentEntry if this was the last one
		if (parentEntry.last != undefined && parentEntry.last == parentEntry.items[current].id) {
			return ;
		}
		// save last entry
		parentEntry.last = parentEntry.items[current].id;
		saveEntry.activate();
	}

	onGotoSibling: {
		console.log('gotoSibling(' + number + '): ' + entryPage.parentEntry.items[number].id);
		entryView.model = [];
		entryPage.current = number;
		entryView.model = partModel;
		loadChapter.activate();
	}
}
