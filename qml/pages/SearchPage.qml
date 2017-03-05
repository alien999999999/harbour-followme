import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: "searchPage"
	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	property string searchName
	property var searchModel: []
	property int todo: 0

	signal activate()
	signal done(bool success, var entries)

	SilicaListView {
		id: "searchList"
		property bool loading: true

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
				title: qsTr("Search for ") + searchName
			}

			BusyIndicator {
				anchors.horizontalCenter: parent.horizontalCenter
				running: true
				size: BusyIndicatorSize.Large
				visible: searchList.loading
			}
		}

		model: searchModel

		delegate: FollowMeItem {
			id: "followMeItem"
			property var entryItem: searchModel[index]
			primaryText: entryItem.label != undefined ? entryItem.label : entryItem.id
			secondaryText: entryItem.provider
			starred: (entryItem.want != undefined && entryItem.want)
			detail: false

			PyLoadEntry {
				base: app.dataPath
				locator: [{id: entryItem.provider}, {id:entryItem.id, label: entryItem.label}];
				autostart: true

				onFinished: {
					if (success && entry != undefined) {
						console.log('success in loading the item: ' + entry.id + ' from (old-id): ' + entryItem.id);
						if (entry.provider == undefined) {
							entry.provider = entryItem.provider;
						}
						entryItem = entry;
					}
				}
			}

			PySaveEntry {
				id: "saveEntry"
				base: app.dataPath
			}

			onClicked: {
				starred = !starred;
				entryItem.want = starred;
				console.log('toggle (+save) entryItem: ');
				console.log(entryItem);
				entryItem.locator = [{id: entryItem.provider, label: entryItem.providerLabel}, {id:entryItem.id, label: entryItem.label}];
				saveEntry.save(entryItem);
				if (entryItem.want) {
					app.insertSort(entryItem);
				}
				else {
					app.removedEntry(entryItem);
				}
			}
		}

	        VerticalScrollDecorator {}
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

	onActivate: {
		// for each plugin issue an immediate search
		for (var i in app.plugins) {
			app.downloadQueue.immediate({
				locator: [{id: i, label: app.plugins[i].label}],
				depth: 1,
				searchName: searchPage.searchName,
				needProvider: true,
				done: searchPage.done,
				doneHandler: function (success, item, entries, saveEntry){
					item.done(success, entries);
					return [];
				}
			}, function (){
				console.log('immediate request was filed; position: ' + app.downloadQueue.position);
				searchModel = [];
				searchList.model = searchModel;
				todo = todo + 1;
			});
		}
	}

	onDone: {
		if (success) {
			console.log('found ' + entries.length + ' entries');
			searchModel = searchModel.concat(entries);
		}
		todo = todo - 1;
		if (todo <= 0) {
			searchList.loading = false;
			searchList.model = searchModel.sort(function (a,b) {
				if (a == undefined || b == undefined) {
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
			todo = 0;
		}
	}

	onStatusChanged: {
		if (status == PageStatus.Active) {
			activate();
		}
	}
}

