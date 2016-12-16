import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.3
import "pages"
import "cover"
import "components"

ApplicationWindow
{
	id: "app"

	property string dataPath: "~/sdcard/.FollowMe"
	property string pluginPath: "/usr/share/harbour-followme/qml/plugins"
	property bool dirtyList
	property var ps: pageStack
	property var plugins: ({})
	property bool pluginsReady

	signal pluginsCompleted ()

	PyListEntries {
		base: pluginPath
		locator: []
		autostart: true
		event: "pluginFound"
		eventHandler: pluginFound

		signal pluginFound (var entry)

		onPluginFound: plugins[entry.locator[0].id] = entry;

		onFinished: {
			pluginsReady = true;
			pluginsCompleted();
		}
	}

	initialPage: Component {
		MainPage {}
	}

	cover: Component {
		CoverPage {}
	}
}

