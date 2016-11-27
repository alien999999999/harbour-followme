import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: "mainPage"

	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	property var entryModel: []

	signal gotoEntry (var entry)

	SilicaListView {
		id: "entryList"

		property bool loading
		property bool firstTime

		anchors.fill: parent

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
					for (var i in entryList.children) {
						if (entryList.children[i].starred != undefined) {
							entryList.children[i].fetchChapters.activate();
						}
					}
				}
			}
		}

		model: entryModel

		delegate: FollowMeItem {
			property var entryItem: entryModel[index]
			property var ps: app.ps

			primaryText: entryItem.label
			secondaryText: entryItem.provider
			starred: ( entryItem.last < entryItem.total )
			last: entryItem.last
			total: entryItem.total
			locator: entryItem.locator
			entryItems: entryItem.items

			onClicked: {
				if (entryItem.items.length == 0) {
					// TODO: fetch online + retry only once
					fetchChapters.gotopage = true;
					fetchChapters.activate();
					return ;
				}
				gotoEntry(entryItem);
			}

			Fetch {
				id: "fetchChapters"
				locator: entryItem.locator
				fetchautostart: entryItem.items.length == 0

				property bool gotopage

				onDone: {
					if (success) {
						entryItem.items = entries;
						entryItem.items.sort(function (a,b) {
							return ( a.id < b.id ? -1 : (a.id > b.id ? 1 : 0));
						});
						entryItem.total = entryItem.items.length;
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
				locator: entryItem.locator
			}

			DownloadChapters {
				id: "downloadChapters"
				locator: entryItem.locator
				chapters: entryItem.items

				onDone: console.log("chapters are downloaded: " + (success ? "ok" : "nok"));
			}

			menu: ContextMenu {
				MenuItem {
					visible: (entryItem.provider in app.plugins)
					text: qsTr("Check updates")
					onClicked: {
						fetchChapters.activate();
					}
				}
				MenuItem {
					visible: (entryItem.provider in app.plugins) && (last > 0) && (total > 0)
					text: qsTr("Download some chapters")
					onClicked: {
						var dialog = pageStack.push(Qt.resolvedUrl("SliderDialog.qml"), {
							title: qsTr("Download until chapter"),
							number: (last + 10 < total ? last + 10 : total),
							unit: qsTr("chapter"),
							minimum: last,
							maximum: total
						});
						dialog.accepted.connect(function (){
							console.log("download chapters from " + last + " until " + dialog.number);
							downloadChapters.from = last;
							downloadChapters.to = dialog.number;
							downloadChapters.activate();
						});
					}
				}
				MenuItem {
					text: qsTr("Stop following")
					onClicked: {
						//remorseTimer
					}
				}
			}
		}

	        VerticalScrollDecorator {}

		PyListEntries {
			id: "listEntries"
			base: app.dataPath
			locator: []
			autostart: true
			depth: 2
			event: "entryReceived"
			eventHandler: entryReceived

			signal entryReceived (var entry)

			onStarted: entryList.loading = true;
				
			onEntryReceived: {
				console.log("receiving: " + entry.filename);
				// TODO: inserted Sorting using the insert!
				if (entry.label == undefined) {
					entry.label = item.filename;
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
				entry.provider = entry.locator[0];
				entryModel.push(entry);

				// TODO: find something to display updated entryModel
			}

			onFinished: {
				entryList.loading = false;
				entryList.firstTime = (entries.length == 0);
				// show update entries
				entryList.model = entryModel;
			}
		}
	}

	onGotoEntry: {
		if (entry.last < 1) {
			// select the first one if not read before (or unsaved)
			entry.last = 1;
		}
		console.log('last entry was: ' + entry.last);
		console.log('go to entry with id: ' + entry.items[entry.last - 1].id);
		// TODO: save the last entry in EntryPage
		ps.push(Qt.resolvedUrl("EntryPage.qml"), {
			locator: entry.locator.concat([entry.items[entry.last - 1].id]),
			current: entry.last,
			prev: entry.last > 1 ? entry.last - 1 : -1,
			next: entry.last < entry.total ? entry.last + 1 : -1,
			name: entry.label,
			siblings: entry.items,
			parentEntry: entry
		});
	}

	onStatusChanged: {
		if (status == 2) {
			if (app.dirtyList) {
				entryList.loading = true;
				entryList.model = [];
				entryModel = [];
				entryList.model = entryModel;
				console.log("reloading list");
				listEntries.activate();
				app.dirtyList = false;
			}
		}
	}
}
