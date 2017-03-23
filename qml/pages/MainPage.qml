import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/download.js" as Utils

Page {
	id: "mainPage"

	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	property var entryItems: ({})

	signal gotoEntry (var entry)
	signal refreshList ()
	// update the model depending on sorting from entryItems
	signal refreshedList ()
	// signal to signify start of refreshing
	signal startRefreshing ()
	// signal for item update
	signal entryUpdate (string entryIndex)
	// signal triggered by downloadqueue
	signal downloadedEntry (bool success, var item)
	// signal to insert an item (sortedly)
	signal insertSort (var entry)
	// signal to move to fix sorting
	signal moveSort (var entry, int i)
	// signal to remove an item
	signal removedEntry (var entry)

	SilicaListView {
		id: "entryList"

		property bool loading

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
				anchors.horizontalCenter: parent.horizontalCenter
				running: true
				size: BusyIndicatorSize.Large
				visible: entryList.loading
			}
		}

		TouchInteractionHint {
			running: true
			interactionMode: TouchInteraction.Pull
			direction: TouchInteraction.Down
			visible: entryList.count == 0 && !entryList.loading
		}

		InteractionHintLabel {
			text: "Pull to find something to follow"
			visible: entryList.count == 0 && !entryList.loading
		}

		PullDownMenu {
			MenuItem {
				text: qsTr("Settings");
				onClicked: {
					var dialog = pageStack.push(Qt.resolvedUrl("SettingsDialog.qml"), {
						dataPath: app.dataPath
					});
					dialog.accepted.connect(function (){
						console.log("dataPath needs to be saved");
						app.dataPath = dialog.dataPath;
						app.saveDataPath();
						refreshList();
					});
				}
			}
			MenuItem {
				visible: app.downloadQueue.running
				text: qsTr("Stop downloading");
				onClicked: app.downloadQueue.stop(function (){});
			}
			MenuItem {
				text: qsTr("Browse");
				onClicked: pageStack.push(Qt.resolvedUrl("AddEntryPage.qml"))
			}
			MenuItem {
				text: qsTr("Search");
				onClicked: {
					pageStack.push(Qt.resolvedUrl("SearchDialog.qml"), {
						title: qsTr("Search"),
						searchLabel: qsTr("Name"),
						searchString: ""
					});
				}
			}
			MenuItem {
				text: qsTr("Check updates")
				onClicked: {
					for (var i in entryItems) {
						app.downloadQueue.append({
							locator: entryItems[i].locator,
							entry: entryItems[i],
							depth: 1,
							sort: true,
							signal: downloadedEntry
						});
					}
				}
			}
		}

		model: ListModel {
			id: 'entryModel'
		}

		delegate: FollowMeItem {
			id: 'followMeItem'

			property var entryItem: entryItems[model.entryIndex]

			signal markUnWanted (bool force)

			signal entryUpdate ()

			primaryText: model.label
			secondaryText: model.provider
			last: model.last
			total: model.total
			starred: ( model.total == '??' || model.last != model.total || entryItem.currentCompletion < 1)

			/*onModelChanged: {
				console.log("model changed... maybe we can trigger the size check");
			}*/

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

			PyCleanEntry {
				id: "cleanEntry"
				base: app.dataPath

				onFinished: {
					sizeEntry.activate();
				}
			}

			PySizeEntry {
				id: "sizeEntry"
				base: app.dataPath
				locator: entryItem.locator

				autostart: entryItem.items.length > 0 && entryItem.last != undefined && entryItem.last != -1

				onFinished: {
					if (success) {
						followMeItem.sizeText = Utils.formatBytes(size);
					}
				}
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

			onEntryUpdate: {
				console.log("entry update for " + entryItem.label);
				console.log("entry update: entry has parts: " + entryItem.items.length);
			}

			menu: ContextMenu {
				MenuItem {
					visible: (entryItem.locator[0].id in app.plugins)
					text: qsTr("Check updates")
					onClicked: {
						app.downloadQueue.append({
							locator: entryItem.locator,
							entry: entryItem,
							depth: 1,
							sort: true,
							signal: downloadedEntry
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
								l = parseInt(i);
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
					visible: entryItem.items.length > 0 && entryItem.last != undefined && entryItem.last != -1 && entryItem.last != entryItem.items[0].id && entryItem.last != entryItem.items[0].label
					text: qsTr("Cleanup read chapters")
					onClicked: {
						//remorseTimer
						// if all is read, just clean the whole item
						if (entryItem.last == entryItem.items[entryItem.items.length - 1].label) {
							console.log('cleaning up all of ' + entryItem.locator[entryItem.locator.length - 1].label);
							cleanEntry.locators = [entryItem.locator]
							cleanEntry.activate();
						}
						else {
							// add until last is found
							cleanEntry.locators = []
							for (var i in entryItem.items) {
								// if last is found, start from here and break off the loop
								if (entryItem.items[i].label == entryItem.last || entryItem.items[i].id == entryItem.last) {
									console.log('found last item at index: ' + i);
									console.log('cleaning up until ' + i + ' of ' + entryItem.locator[entryItem.locator.length - 1].label);
									cleanEntry.activate();
									break;
								}
								// add the next one too
								cleanEntry.locators.push(entryItem.locator.concat([{id: entryItem.items[i].id, file: entryItem.items[i].file, label: entryItem.items[i].label}]));
							}
						}
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
			depth: 2
			event: "entryReceived"
			eventHandler: entryReceived

			signal entryReceived (var entry)

			onStarted: startRefreshing();
				
			onEntryReceived: {
				// Fix old entries without label
				if (entry.label == undefined) {
					entry.label = item.id;
				}

				// Add empty list of items if not defined yet
				if (entry.items == undefined) {
					entry.items = [];
				}

				// currentIndex will not be saved, so it needs to be recalculated.
				// however, if this has never been looked at, we can't have 0 as currentIndex, we need to keep it undefined
				// we can only find currentIndex if last is set

				// set the last if not defined yet
				if (entry.last == undefined) {
					entry.last = -1;
				}
				else {
					// track down the currentIndex comparing with last
					for (var i in entry.items) {
						if (entry.items[i].id == entry.last) {
							entry.currentIndex = parseInt(i);
						}
					}
				}

				// set a currentCompletion if not defined yet
				if (entry.currentCompletion == undefined) {
					entry.currentCompletion = 0;
					if (entry.items.length > 0 && entry.last == entry.items[entry.items.length - 1].label) {
						entry.currentCompletion = 1;
					}
				}

				// Fix setting label a (bad) label for provider (TODO: check if this is still needed)
				if (entry.locator[0].label == undefined) {
					entry.locator[0].label = entry.locator[0].id;
				}

				// set want if not defined yet
				if (entry.want == undefined) {
					entry.want = true;
				}

				// assign the item to a hash with the only unique identifier we know of... the relative path location
				entryItems[entry.locator[0].id + '/' + entry.locator[1].id] = entry;
			}

			onFinished: refreshedList();
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
		console.log('last entry was: ' + entry.last);
		if (entry.currentIndex == undefined) {
			entry.currentIndex = 0;
		}
		if (entry.items.length > 0) {
			console.log('go to entry with id: ' + entry.items[entry.currentIndex].id);
		}
		pageStack.push(Qt.resolvedUrl("EntryPage.qml"), {parentEntry: entry});
	}

	onRefreshList: {
		console.log("reloading list");
		listEntries.activate();
	}

	// signal to start before refreshing
	onStartRefreshing: {
		entryList.loading = true;
		entryList.model.clear();
	}

	function compareEntry(a, b) {
		var ascore = (entryItems[a].items.length == 0 ? -0.4 : (entryItems[a].currentIndex == undefined ? -0.5 : 
			((entryItems[a].currentIndex + (entryItems[a].currentCompletion == undefined ? 0 : entryItems[a].currentCompletion)) / entryItems[a].items.length)
		));
		var bscore = (entryItems[b].items.length == 0 ? -0.4 : (entryItems[b].currentIndex == undefined ? -0.5 : 
			((entryItems[b].currentIndex + (entryItems[b].currentCompletion == undefined ? 0 : entryItems[b].currentCompletion)) / entryItems[b].items.length)
		));
		var score = (bscore >= 1 ? -1 : bscore) - (ascore >= 1 ? -1 : ascore);
		if (score == 0) {
			var alabel = (entryItems[a].label != undefined ? entryItems[a].label : (entryItems[a].id != undefined ? entryItems[a].id : ''));
			var blabel = (entryItems[b].label != undefined ? entryItems[b].label : (entryItems[b].id != undefined ? entryItems[b].id : ''));
			score = (alabel.toLowerCase() < blabel.toLowerCase() ? -1 : (alabel.toLowerCase() > blabel.toLowerCase() ? 1 : 0));
		}
		return score;
	}

	/** binarySearch(entry, strict, i)
	 * entry: the entry to check the position for
	 * strict: bool
	 *   true: just find the index in the list (default)
	 *   false: find the place where the entry should be
	 * i: startindex place to start searching (default is the middle)
	 */
	function binarySearch(entryIndex, strict, i) {
		// starting index is halfway by default
		if (i == undefined) {
			i = entryList.model.count >> 1;
		}

		// strict mode is true by default
		if (strict == undefined) {
			strict == true;
		}

		// set the starting boundaries
		var min = 0;
		var max = entryList.model.count;

		// loop until we're inside the boundaries
		while (i >= min && i < max) {

			// initialize variables
			var skip = 0;

			// find the current entry (on the index)
			var e = entryList.model.get(i).entryIndex;

			if (e == entryIndex) {
				if (strict) {
					// found the entry, so return it
					return i;
				}

				// if not strict, this one is not correct, so we need to skip it
				if (i > min) {
					i = i - 1;
					e = entryList.model.get(i).entryIndex;
				}
				else {
					i = i + 1;
					if (i == max) {
						// if we're at max already, we can just return the actual entry (ie: unchanged)
						return min;
					}
					e = entryList.model.get(i).entryIndex;
				}
			}

			// compare the entry
			var r = compareEntry(entryIndex, e);
			if (!strict && r == 0) {
				return i;
			}
			if (r < 0) {
				max = i;
				i = min + ((max - min) >> 1);
			}
			else {
				min = i + 1;
				i = max - ((max - min) >> 1);
			}
		}
		return ( strict ? -1 : i );
	}

	onInsertSort: {
		// get entryIndex
		var entryIndex = entry.locator[0].id + '/' + entry.locator[1].id;

		// make sure it exists before converting to a model Item
		if (entryItems[entryIndex] == undefined) {
			entryItems[entryIndex] = entry;
		}

		// convert to a modelItem
		var modelItem = convertEntryToModel(entryItems, entryIndex);

		// find the position and insert or append
		var i = binarySearch(entryIndex, false);
		if (i == entryList.model.count) {
			entryList.model.append(modelItem);
		}
		else {
			entryList.model.insert(i, modelItem);
		}
	}

	onMoveSort: {
		// get entryIndex
		var entryIndex = entry.locator[0].id + '/' + entry.locator[1].id;

		if (i == -1) {
			i = binarySearch(entryIndex);
		}
		else {
			var j = binarySearch(entryIndex, false, i);
			if (i != j) {
				entryList.model.move(i, j, 1);
				// try to keep the moved item in view
				entryList.positionViewAtIndex(j, ListView.Visible);
			}
		}
	}

	onRemovedEntry: {
		// get entryIndex
		var entryIndex = entry.locator[0].id + '/' + entry.locator[1].id;

		var i = binarySearch(entryIndex);
		if (i >= 0) {
			entryList.model.remove(i);
		}
	}

	function convertEntryToModel(entryItems, entryIndex, detail) {
		var entryItem = entryItems[entryIndex];
		var modelItem = ({
			entryIndex: entryIndex,
			detail: detail,
			label: entryItem.label,
			provider: entryItem.locator[0].label,
			last: (entryItem.last != undefined && entryItem.last != -1 ? entryItem.last : '??'),
			total: (entryItem.items.length > 0 ? (entryItem.items[entryItem.items.length - 1].label != undefined ? entryItem.items[entryItem.items.length - 1].label : entryItem.items[entryItem.items.length - 1].id) : '??')
		});
		if (modelItem.last.toString != undefined) {
			modelItem.last = modelItem.last.toString();
		}
		return modelItem;
	}

	// loading must be true
	// model must be empty
	// entryItems must be filled in
	onRefreshedList: {
		var model = [];
		// fill the list with all wanted ones
		for (var i in entryItems) {
			if (entryItems[i].want) {
				model.push(i);
			}
		}

		// sort alphabetically on Label first
		// group on status (busy(completion (0-1))/new(0)/completed+read(-1))
		model.sort(compareEntry);

		// update the listview
		for (var i in model) {
			entryList.model.append(convertEntryToModel(entryItems, model[i]));
		}
		entryList.loading = false;

		// update cover page
		app.coverPage.primaryText = entryList.model.count + ' followed';
		app.coverPage.secondaryText = '';
		app.coverPage.chapterText = '';

		// list has refreshed: it's not dirty anymore
		app.dirtyList = false;
	}

	onEntryUpdate: {
		console.log('signal entryUpdate had been triggered with ' + entryIndex);
		var entryItem = entryItems[entryIndex];
		var lastIndex = -1;
		for (var i = 0; i < entryList.model.count; i++) {
			if (entryList.model.get(i).entryIndex == entryIndex) {
				// update the fields that can change in the model (last, total)
				var l = (entryItem.last != undefined && entryItem.last != -1 ? entryItem.last : '??');
				if (l.toString != undefined) {
					l = l.toString();
				}
				var maxchapter = (entryItem.items.length > 0 ? (entryItem.items[entryItem.items.length - 1].label != undefined ? entryItem.items[entryItem.items.length - 1].label : entryItem.items[entryItem.items.length - 1].id) : '??');
				console.log('updating last to ' + l);
				console.log('updating total to ' + maxchapter);
				entryList.model.get(i).last = l;
				entryList.model.get(i).total = maxchapter;

				// remember the index
				lastIndex = i;
			}
		}

		// it might be necessary to move this item to a better sorted position
		moveSort(entryItem, lastIndex);
	}

	onDownloadedEntry: {
		if (success) {
			// update the model item
			entryUpdate(item['entry'].locator[0].id + '/' + item['entry'].locator[1].id);
		}
	}

	onStatusChanged: {
		if (entryList.model != undefined && entryList.model.count > 0) {
			app.coverPage.primaryText = entryList.model.count + ' followed';
		}
		else {
			app.coverPage.primaryText = 'Loading...';
		}
		app.coverPage.secondaryText = '';
		app.coverPage.chapterText = '';
		if (status == 1 && app.dirtyList && app.pluginsReady) {
			console.log("status changed and main list is dirty and plugins were ready");
			refreshList();
		}
	}

	Component.onCompleted: {
		app.mainList = entryList;
		app.entryUpdate.connect(entryUpdate);
		app.insertSort.connect(insertSort);
		app.moveSort.connect(moveSort);
		app.removedEntry.connect(removedEntry);
		app.pluginsCompleted.connect(refreshList);
	}
}
