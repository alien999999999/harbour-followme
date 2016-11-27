import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: "providerPage"
	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	property var provider
	property var locator: [provider]
	property int level: locator.length
	property var entryModel: []

	SilicaListView {
		id: "favList"
		property bool loading: true

		anchors.fill: parent

		header: Column {
			width: parent.width
			height: pageHeader.height + Theme.paddingLarge
			PageHeader {
				id: 'pageHeader'
				title: app.plugins[provider].label + ' ' + app.plugins[provider].levels[level - 1].label
			}

			BusyIndicator {
				running: true
				size: BusyIndicatorSize.Large
				visible: favList.loading
			}
		}

		PullDownMenu {
			MenuItem {
				visible: app.plugins[provider].search != undefined
				text: qsTr("Search");
				onClicked: pageStack.push(Qt.resolvedUrl("SearchProviderPage.qml"), { 'provider': provider });
			}
			MenuItem {
				text: qsTr("Refresh");
				onClicked: {
					favList.loading = true;
					favList.model = [];
					entryModel = [];
					favList.model = entryModel;
					fetchEntries.activate();
				}
			}
		}

		model: entryModel

		delegate: FollowMeItem {
			// TODO: no loading, no last, no total, contextmenu
			property var entryItem: entryModel[index]
			primaryText: entryItem.label != undefined ? entryItem.label : entryItem.id
			starred: (entryItem.want != undefined && entryItem.want)
			locator: [provider, entryItem.id]
			detail: false

			PyLoadEntry {
				base: app.dataPath
				locator: [provider, entryItem.id]
				autostart: true

				onFinished: {
					if (success && entry != undefined) {
						entryItem = entry;
					}
				}
			}

			PySaveEntry {
				id: "saveEntry"
				base: app.dataPath
				locator: [provider, entryItem.id]
			}

			onClicked: {
				starred = !starred;
				entryItem.want = starred;
				entryItem.label = primaryText;
				saveEntry.save(entryItem);
				app.dirtyList = true;
			}
		}

	        VerticalScrollDecorator {}

		Fetch {
			id: "fetchEntries"
			locator: providerPage.locator
			fetchautostart: true

			onStarted: entryModel = [];
			
			onReceived: {
				entryModel.push(entry);
				favList.model = entryModel;
			}

			onDone: favList.loading = false;
		}
	}
}


