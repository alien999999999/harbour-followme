import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: "entryPage"
	property string name
	property var locator
	property string label: locator[locator.length - 1]
	property int prev
	property int current
	property int next
	property var siblings
	property var parentEntry
	property var chapter: ({id: siblings[current - 1].id, label: siblings[current - 1].label, items: []})
	property var partItems: chapter.items

	property var downloadPagesComponent: Qt.createComponent("../components/DownloadPages.qml");
	property var downloadPages

	signal gotoSibling (int number)
	signal markRead ()
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
			property var part: partItems[index]
			width: parent.width
			parentLocator: locator
			partIndex: index
			partId: part.id
			file: part.file
			absoluteFile: part.absoluteFile != undefined ? part.absoluteFile : ''

			DownloadPage {
				id: "reDownloadPage"
				locator: parentLocator.concat([part.id])
				chapter: siblings[current - 1]
				pageIndex: part.id
				pageList: partItems
				force: true;

				onDone: {
					console.log('re-fetched file');
					//part.absoluteFile = ;
				}
			}

			onImageError: {
				reDownloadPage.activate();
			}

			menu: ContextMenu {
				MenuItem {
					text: "Refresh"
					onClicked: reDownloadPage.activate();
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
			console.log('saving chapter [' + locator.join(',') + ']: ' + (success ? "ok" : "nok"));
			app.dirtyList = true;
		}
	}

	PySaveEntry {
		id: "saveEntry"
		base: app.dataPath
		locator: entryPage.parentEntry.locator
		entry: entryPage.parentEntry

		onFinished: {
			console.log('saving entry [' + locator.join(',') + ']: ' + (success ? "ok" : "nok"));
			app.dirtyList = true;
		}
	}

	Fetch {
		id: "fetchPages"
		locator: entryPage.locator

		onDone: {
			console.log("done fetching pages: create a downloadPages component, to get the actual pages...");
			downloadPages = downloadPagesComponent.createObject(entryPage, {
				base: app.dataPath,
				locator: entryPage.locator,
				outModel: partItems,
				inModel: entries,
				donePagesHandler: function () {
					console.log("done: " + partItems.length);
					markRead();
					console.log("saving to chapter: " + entryPage.current);
					markLast();
					entryView.model = partItems;
				}
			});
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
				markRead();
				return ;
			}
			// fetch them online (not from dir)
			console.log('fetching pages');
			fetchPages.activate();
		}
	}

	onMarkRead: {
		// mark chapter read
		chapter.read = true;
		saveChapter.activate();
	}

	onMarkLast: {
		// save last entry
		parentEntry.last = current;
		saveEntry.activate();
	}

	onGotoSibling: {
		console.log('gotoSibling(' + number + '): ' + entryPage.siblings[number - 1].id);
		var l = entryPage.locator;
		l.splice(entryPage.locator.length - 1, 1, entryPage.siblings[number - 1].id);
		for (var i in l) { console.log(' - ' + i + ': ' + l[i]); }
		pageStack.replace(Qt.resolvedUrl("EntryPage.qml"), {
			locator: l,
			current: number,
			prev: number - 1 > 0 ? number - 1 : -1,
			next: number + 1 < entryPage.siblings.length ? number + 1 : -1,
			name: entryPage.name,
			siblings: entryPage.siblings,
			parentEntry: entryPage.parentEntry
		});
	}
}
