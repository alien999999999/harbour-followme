import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.3
import org.nemomobile.configuration 1.0
import "pages"
import "cover"
import "components"

ApplicationWindow
{
	id: "app"

	property string dataPath: "~/sdcard/FollowMe"
	property string pluginPath: "/usr/share/harbour-followme/qml/plugins"
	property bool dirtyList
	property var ps: pageStack
	property var plugins: ({})
	property bool pluginsReady

	property alias downloadQueue: dQueue
	property alias coverPage: cp

	signal pluginsCompleted ()

	function getPlugin(locator) {
		if (locator == undefined || locator.length == 0) {
			return undefined;
		}
		console.log('there are ' + plugins.length + ' plugins: ');
		console.log('looking for plugin ' + locator[0].id);
		return plugins[locator[0].id];
	}

	function getLevel(locator) {
		var plugin = getPlugin(locator);
		console.log('plugin ' + plugin.label + ' levels ' + plugin.levels.length);
		if (plugin == undefined || locator.length > plugin.levels.length) {
			return undefined;
		}
		return plugin.levels[locator.length - 1];
	}

	function isLevelType(locator, type) {
		var level = getLevel(locator);
		console.log('locator with length ' + locator.length + '; has level type: ' + level.type);
		return (level != undefined && level.type == type);
	}

	function isDownload(locator) {
		return isLevelType(locator, "image");
	}

	function saveDataPath() {
		dataPathConfig.value = app.dataPath;
		dataPathConfig.sync();
	}

	PyListEntries {
		id: "pluginEntries"
		base: pluginPath
		locator: []
		event: "pluginFound"
		eventHandler: pluginFound

		signal pluginFound (var entry)

		onPluginFound: plugins[entry.locator[0].id] = entry;

		onFinished: {
			pluginsReady = true;
			pluginsCompleted();
		}
	}

	PyDataPath {
		id: "pyDataPath"
		path: "Downloads/FollowMe"

		onFinished: {
			if (dataPath != '') {
				app.dataPath = dataPath;
				pluginEntries.activate();
			}
		}
	}

	ConfigurationValue {
		id: "dataPathConfig"
		key: "/harbour-followme/dataPath"
		Component.onCompleted: {
			if (value == undefined) {
				pyDataPath.activate();
			}
			else {
				app.dataPath = value;
				pluginEntries.activate();
			}
		}
	}

	DownloadQueue {
		id: "dQueue"
	}

	initialPage: Component {
		MainPage {}
	}

	cover: CoverPage {
		id: "cp"
	}
}

