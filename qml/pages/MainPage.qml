import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: "mainPage"

	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	property var entryModel: []

	signal gotoEntry (var entry)
	signal refreshList ()

	SilicaListView {
		id: "entryList"

		property bool loading
		property bool firstTime

		anchors {
			top: parent.top
			bottom: queueProgress.top
		}
		width: parent.width

		header: Column {
			width: parent.width
			height: pageHeader.height + Theme.paddingLarge
			PageHeader {
				id: 'pageHeader'
				title: qsTr("FollowMe")
			}

			BusyIndicator {
				running: true
				size: BusyIndicatorSize.Large
				visible: entryList.loading
			}
		}

		TouchInteractionHint {
			running: true
			interactionMode: TouchInteraction.Pull
			direction: TouchInteraction.Down
			visible: entryList.firstTime
		}

		InteractionHintLabel {
			text: "Pull to find something to follow"
			visible: entryList.firstTime
		}

		PullDownMenu {
			MenuItem {
				text: qsTr("Search");
				onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"))
			}
			MenuItem {
				text: qsTr("Browse");
				onClicked: pageStack.push(Qt.resolvedUrl("AddEntryPage.qml"))
			}
			MenuItem {
				text: qsTr("Check updates")
				onClicked: {
					for (var i in entryModel) {
						app.downloadQueue.append({
							locator: entryModel[i].locator,
							entry: entryModel[i],
							depth: 1,
							sort: true
						});
					}
				}
			}
		}

		model: entryModel

		delegate: FollowMeItem {
			id: 'followMeItem'

			property var entryItem: entryModel[index]

			signal markUnWanted (bool force)

			primaryText: entryItem.label
			secondaryText: entryItem.locator[0].label
			last: entryItem.last
			total: entryItem.items == undefined ? -1 : entryItem.items.length
			starred: ( entryItem.last < total )

			onClicked: {
				if (entryItem.items.length == 0) {
					console.log("clicked on item " + entryItem.label + ", but first we need to find the number of chapters");
					// TODO: fetch online + retry only once
					fetchChapters.gotopage = true;
					fetchChapters.activate();
					return ;
				}
				console.log("clicked on item " + entryItem.label + ", going to EntryPage");
				gotoEntry(entryItem);
			}

			Fetch {
				id: "fetchChapters"
				locator: entryItem.locator

				property bool gotopage

				onStarted: entryItem.items = [];

				onReceived: entryItem.items.push({id: entry.id, file: entry.file, label: entry.label});

				onDone: {
					if (success) {
						entryItem.items.sort(function (a,b) {
							if (a == undefined | b == undefined) {
								return 0;
							}
							var sa = parseInt(a.id);
							var sb = parseInt(b.id);
							if (sa == NaN || sb == NaN || ('' + sa) != a.id || ('' + sb) != b.id) {
								sa = a.id;
								sb = b.id;
							}
							return ( sa < sb ? -1 : (sa > sb ? 1 : 0));
						});
						entryItem.total = entryItem.items.length;
						followMeItem.total = entryItem.total;
						console.log('chapters: ' + entryItem.total);
						saveEntry.save(entryItem);
						if (gotopage) {
							gotoEntry(entryItem);
						}
					}
				}
			}

			PySaveEntry {
				id: "saveEntry"
				base: app.dataPath
			}

			DownloadChapters {
				id: "downloadChapters"
				locator: entryItem.locator
				chapters: entryItem.items

				onDone: console.log("chapters are downloaded: " + (success ? "ok" : "nok"));
			}

			onMarkUnWanted: {
				if (!entryItem.want) {
					entryItem.want = false;
					saveEntry.activate();
					followMeItem.height = 0;
				}
			}

			menu: ContextMenu {
				MenuItem {
					visible: (entryItem.locator[0].id in app.plugins)
					text: qsTr("Check updates (old)")
					onClicked: {
						fetchChapters.activate();
					}
				}
				MenuItem {
					visible: (entryItem.locator[0].id in app.plugins) && (total > 0)
					text: qsTr("Download some chapters (new)")
					onClicked: {
						if (last == undefined || last < 1) {
							last = 1
						}
						var dialog = pageStack.push(Qt.resolvedUrl("SliderDialog.qml"), {
							title: qsTr("Download until chapter"),
							number: (last + 10 < total ? last + 10 : total),
							unit: qsTr("chapter"),
							minimum: last,
							maximum: total
						});
						dialog.accepted.connect(function (){
							console.log("download chapters from " + last + " until " + dialog.number);
							for (var i = last - 1; i < dialog.number; i++) {
								console.log("downloading #" + (i + 1));
								for (var j in entryItem.items[i]) { console.log(" - " + j + ": " + entryItem.items[i][j]); }
								app.downloadQueue.append({
									locator: entryItem.locator.concat([{id: entryItem.items[i].id, file: entryItem.items[i].file, label: entryItem.items[i].label}]),
									entry: entryItem.items[i],
									sort: true
								});
							}
						});
					}
				}
				MenuItem {
					text: qsTr("Stop following")
					onClicked: {
						//remorseTimer
						markUnWanted(false);
					}
				}
			}
		}

	        VerticalScrollDecorator {}

		PyListEntries {
			id: "listEntries"
			base: app.dataPath
			locator: []
			//autostart: true
			depth: 2
			event: "entryReceived"
			eventHandler: entryReceived

			signal entryReceived (var entry)

			onStarted: entryList.loading = true;
				
			onEntryReceived: {
				// TODO: inserted Sorting using the insert!
				if (entry.label == undefined) {
					entry.label = item.id;
				}
				if (entry.last == undefined) {
					entry.last = -1;
				}
				if (entry.total == undefined) {
					entry.total = -1;
				}
				if (entry.items == undefined) {
					entry.items = [];
				}
				if (entry.locator[0].label == undefined) {
					entry.locator[0].label = entry.locator[0].id;
				}
				if (entry.want == undefined || entry.want) {
					entryModel.push(entry);
				}

				// TODO: find something to display updated entryModel
			}

			onFinished: {
				entryList.loading = false;
				entryList.firstTime = (entries.length == 0);
				// show update entries
				entryModel.sort(function (a,b) {
					return (a.last != undefined && a.last > 0 ? (a.last == a.items.length ? 1 : -1) : 0) - (b.last != undefined && b.last > 0 ? (b.last == b.items.length ? 1 : -1) : 0);
				});
				entryList.model = entryModel;
			}
		}
	}

	QueueProgress {
		id: "queueProgress"

		downloadQueue: app.downloadQueue

		anchors {
			bottom: parent.bottom
			bottomMargin: Theme.paddingSmall
			topMargin: Theme.paddingSmall
		}
		width: parent.width
	}

	onGotoEntry: {
		if (entry.last < 1) {
			// select the first one if not read before (or unsaved)
			entry.last = 1;
		}
		console.log('last entry was: ' + entry.last);
		console.log('go to entry with id: ' + entry.items[entry.last - 1].id);
		// TODO: save the last entry in EntryPage
		pageStack.push(Qt.resolvedUrl("EntryPage.qml"), {
			locator: entry.locator.concat([{id: entry.items[entry.last - 1].id, label: entry.items[entry.last - 1].label, file: entry.items[entry.last - 1].file}]),
			current: entry.last,
			prev: entry.last > 1 ? entry.last - 1 : -1,
			next: entry.last < entry.total ? entry.last + 1 : -1,
			name: entry.label,
			siblings: entry.items,
			parentEntry: entry
		});
	}

	onRefreshList: {
		entryList.loading = true;
		entryList.model = [];
		entryModel = [];
		entryList.model = entryModel;
		console.log("reloading list");
		listEntries.activate();
		app.dirtyList = false;
	}

	onStatusChanged: {
		if (status == 1 && app.dirtyList && app.pluginsReady) {
			console.log("status changed and main list is dirty and plugins were ready");
			refreshList();
		}
	}

	Component.onCompleted: {
		app.pluginsCompleted.connect(refreshList);
	}
}
