import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
	property string name
	property var locator
	property int showItem
	property bool favView

	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	SilicaListView {
		anchors.fill: parent

		header: Column {
			width: parent.width
			height: header.height + Theme.paddingLarge
			PageHeader {
				id: "header"
				title: storage.getLabel(locator) + ": " + name
			}

			BusyIndicator {
				running: true
				size: BusyIndicatorSize.Large
				visible: listModel.count == 0
			}
		}

		model: ListModel {
			id: "listModel"
		}

		delegate: ListItem {
			id: "listItem"
			property bool want

			Label {
				text: model.label
				color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
				x: Theme.horizontalPageMargin
				anchors.verticalCenter: parent.verticalCenter
				truncationMode: TruncationMode.Fade
			}

			Image {
				source: want ? '../images/starGold.svg' : '../images/starGrey.svg'
				height: label.height*3/4
				sourceSize.height: height
				fillMode: Image.PreserveAspectFit
				anchors {
					right: parent.right
					rightMargin: Theme.paddingMedium
					verticalCenter: parent.verticalCenter
				}
			}

			onClicked: {
				console.log(want);
				var l = locator.concat([model.id]);
				if (favView) {
					console.log(locator);
					console.log(l);
					storage.setProperties(l, {'want': !want, name: model.label}, function (l, result){
						storage.getProperty(l, 'want', function (l, w){
							if (w != undefined) {
								want = w;
							}
						});
					});
				}
				else {
					pageStack.push(Qt.resolvedUrl(storage.getPage(l)), {name: storage.getData(locator, 'name'), locator: l, show: model.last});
				}
			}

			Component.onCompleted: {
				storage.getProperty(locator.concat([model.id]), 'want', function (l, r){
					if (r != undefined) {
						want = r;
					}
				});
			}
		}

	        VerticalScrollDecorator {}

		Component.onCompleted: storage.fillEntries(locator, listModel);
	}
}
