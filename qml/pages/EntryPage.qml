import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: "entryPage"
	property string name
	property var locator
	property string label: locator[locator.length - 1].label
	property int prev
	property int current
	property int next
	property var siblings
	property var parentEntry
	property var chapter: ({id: siblings[current - 1].id, label: siblings[current - 1].label, items: []})
	property var partItems: chapter.items

	signal gotoSibling (int number)
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
				title: name + ": " + "Chapter" + " " + label
			}

			BusyIndicator {
				running: true
				size: BusyIndicatorSize.Large
				visible: entryView.count == 0
			}
		}

		model: partItems

		delegate: FollowMeImage {
			id: "followMeImage"

			property var part: partItems[index]

			width: parent.width
			parentLocator: entryPage.locator
			partIndex: index
			partId: part.id
			file: part.file
			absoluteFile: part.absoluteFile != undefined ? part.absoluteFile : ''

			DownloadPage {
				id: "reDownloadPage"
				locator: parentLocator.concat([{id: part.id, file: part.file, label: part.label}])
				chapter: entryPage.chapter
				pageIndex: partIndex
				pageList: [] //TODO: need to get the page list from disk!

				onDone: {
					if (part.absoluteFile != undefined) {
						absoluteFile = part.absoluteFile;
						// TODO: avoid this, by prechecking the absoluteFile and saving the chapter with it.
						saveChapter.activate();
					}
					console.log('re-fetched file complete');
					console.log('remoteFile = ' + chapter.items[pageIndex]['remoteFile']);
					console.log('absoluteFile = ' + chapter.items[pageIndex]['absoluteFile']);
					console.log('part.absoluteFile = ' + part['absoluteFile']);
					console.log('reDownloadPage might need some reinitialize to redraw image');
					followMeImage.imageSource = part['absoluteFile'];
				}
			}

			onImageError: {
				console.log("image has error, redownloading it...");
				reDownloadPage.activate();
			}

			menu: ContextMenu {
				MenuItem {
					text: "Refresh"
					onClicked: {
						reDownloadPage.force = true;
						reDownloadPage.activate();
					}
				}
			}
		}

	        VerticalScrollDecorator {}

		PullDownMenu {
			visible: prev > 0 || next > 0
			MenuItem {
				visible: siblings.length > 1
				text: qsTr("Jump To")
				onClicked: {
					var dialog = pageStack.push(Qt.resolvedUrl("SliderDialog.qml"), {
						title: qsTr("Jump to chapter"),
						number: entryPage.current,
						unit: qsTr("chapter"),
						minimum: 1,
						maximum: entryPage.siblings.length
					});
					dialog.accepted.connect(function (){
						gotoSibling(dialog.number);
					});
				}
			}
			MenuItem {
				visible: next > 0
				text: qsTr("Next")
				onClicked: gotoSibling(next);
			}
			MenuItem {
				visible: prev > 0
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
		locator: entryPage.locator
		entry: entryPage.chapter

		onFinished: {
			console.log('saving chapter [' + locator.length + ']: ' + (success ? "ok" : "nok"));
			app.dirtyList = true;
		}
	}

	PySaveEntry {
		id: "saveEntry"
		base: app.dataPath
		locator: entryPage.parentEntry.locator
		entry: entryPage.parentEntry

		onFinished: {
			console.log('saving entry [' + locator.length + ']: ' + (success ? "ok" : "nok"));
			app.dirtyList = true;
		}
	}

	DownloadChapter {
		id: "downloadChapter"
		locator: entryPage.locator
		chapter: entryPage.chapter
		nodownload: true

		onDone: {
			// force saving while marking as read
			markRead(true);
			console.log("chapter items: " + chapter.items.length);
			console.log("saving to chapter: " + entryPage.current);
			markLast();
			partItems = chapter.items;
			entryView.model = partItems;
		}
	}

	PyLoadEntry {
		id: "loadChapter"
		base: app.dataPath
		locator: entryPage.locator
		autostart: true

		onFinished: {
			if (success) {
				markLast();
				chapter = entry;
				label = entry.label;
				partItems = entry.items;
				entryView.model = partItems;
				console.log("saving to chapter: " + entryPage.current);
				// mark it as read
				markRead(false);
				return ;
			}
			// fetch them online (not from dir)
			console.log('downloading chapter');
			downloadChapter.activate();
		}
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
		if (parentEntry.last != undefined && parentEntry.last == current) {
			return ;
		}
		// save last entry
		parentEntry.last = current;
		saveEntry.activate();
	}

	onGotoSibling: {
		console.log('gotoSibling(' + number + '): ' + entryPage.siblings[number - 1].id);
		entryView.model = [];
		entryPage.locator.splice(entryPage.locator.length - 1, 1, {id: entryPage.siblings[number - 1].id, label: entryPage.siblings[number - 1].label, file: entryPage.siblings[number - 1].file});
		entryPage.current = number;
		entryPage.prev = number - 1 > 0 ? number - 1 : -1;
		entryPage.next = number + 1 < entryPage.siblings.length ? number + 1 : -1;
		entryView.model = partItems;
		loadChapter.activate();
		// i wonder if some kind of refresh is needed...
	}
}
