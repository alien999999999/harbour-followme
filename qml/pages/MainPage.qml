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
			last: entryItem.last == undefined || entryItem.last == -1 ? '??' : entryItem.last
			total: entryItem.items == undefined || entryItem.items.length == 0 ? '??' : ( entryItem.items[entryItem.items.length - 1].label != undefined ? entryItem.items[entryItem.items.length - 1].label : entryItem.items[entryItem.items.length - 1].id)
			starred: ( entryItem.last != total )

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
						//followMeItem.total = entryItem.items.length;
						console.log('chapters: ' + followMeItem.total);
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

			onMarkUnWanted: {
				console.log("wanted: " + entryItem.want);
				if (entryItem.want) {
					followMeItem.primaryText = '';
					followMeItem.secondaryText = '';
					followMeItem.detail = false;
					followMeItem.height = 0;
					entryItem.want = false;
					saveEntry.save(entryItem);
				}
			}

			menu: ContextMenu {
				MenuItem {
					visible: (entryItem.locator[0].id in app.plugins)
					text: qsTr("Check updates")
					onClicked: {
						app.downloadQueue.append({
							locator: entryModel[index].locator,
							entry: entryModel[index],
							depth: 1,
							sort: true
						});
					}
				}
				MenuItem {
					visible: (entryItem.locator[0].id in app.plugins) && (entryItem.items.length > 0)
					text: qsTr("Download some chapters")
					onClicked: {
						var t = entryItem.items.length;
						var l = 0;
						for (var i in entryItem.items) {
							if (last == entryItem.items[i].id) {
								l = i;
							}
						}
						// start 1-based (because it's visible)
						l++;
						var dialog = pageStack.push(Qt.resolvedUrl("SliderDialog.qml"), {
							title: qsTr("Download until chapter"),
							number: (l + 10 < t ? l + 10 : t),
							unit: qsTr("chapter"),
							minimum: l,
							maximum: t
						});
						dialog.accepted.connect(function (){
							console.log("download chapters from " + l + " until " + dialog.number);
							for (var i = l - 1; i < dialog.number; i++) {
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
					return (a.last != undefined && a.last > 0 ? (a.last == a.items[a.items.length - 1].id ? 1 : -1) : 0) - (b.last != undefined && b.last > 0 ? (b.last == b.items[b.items.length - 1].id ? 1 : -1) : 0);
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

	// MUST: entry.items.length > 0
	onGotoEntry: {
		var entryIndex = 0;
		if (entry.last != undefined) {
			for (var i in entry.items) {
				if (entry.items[i].id == entry.last) {
					entryIndex = i;
				}
			}
		}
		console.log('last entry was: ' + entry.last);
		console.log('go to entry with id: ' + entry.items[entryIndex].id);
		pageStack.push(Qt.resolvedUrl("EntryPage.qml"), {
			parentEntry: entry,
			current: entryIndex
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
