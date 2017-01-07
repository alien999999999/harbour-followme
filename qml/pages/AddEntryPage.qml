import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
	id: searchPage

	property var pluginModel: []

	allowedOrientations: Orientation.Portrait | Orientation.Landscape

	SilicaListView {
		id: "searchView"

		anchors.fill: parent

		header: Column {
			width: parent.width
			height: header.height + Theme.paddingLarge
			PageHeader {
				id: "header"
				title: "Content providers"
			}
		}

		model: pluginModel

		delegate: ListItem {
			property var provider: pluginModel[index]

			width: parent.width

			Label {
				text: app.plugins[provider].label
				color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
				x: Theme.horizontalPageMargin
				anchors.verticalCenter: parent.verticalCenter
			}

			onClicked: pageStack.push(Qt.resolvedUrl("ProviderPage.qml"), {'provider': provider})
		}

	        VerticalScrollDecorator {}

		Component.onCompleted: {
			for (var i in app.plugins) {
				pluginModel.push(i);
			}
			searchView.model = pluginModel;
		}
	}
}
