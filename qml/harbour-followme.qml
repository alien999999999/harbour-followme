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
	property var mainList

	signal pluginsCompleted ()
	signal entryUpdate (string entryIndex)
	signal insertSort (var entry)
	signal moveSort (var entry, int i)
	signal removedEntry (var entry)

	function getPlugin(locator) {
		// empty locators will never have a plugin
		if (locator == undefined || locator.length == 0) {
			return undefined;
		}
		// check the plugin with the first locator's id
		return plugins[locator[0].id];
	}

	function getLevel(locator) {
		// get the plugin first
		var plugin = getPlugin(locator);
		// if no plugin, then no level
		// if locator is bigger than the maximum level, we'll return undefined
		if (plugin == undefined || locator.length > plugin.levels.length) {
			return undefined;
		}
		return plugin.levels[locator.length - 1];
	}

	function isLevelType(locator, type) {
		var level = getLevel(locator);
		// check if this level's type is what we expect
		// if it's undefined, it's definately not what we expected :-)
		return (level != undefined && level.type == type);
	}

	function isDownload(locator) {
		return isLevelType(locator, "image");
	}

	function saveDataPath() {
		dataPathConfig.value = app.dataPath;
		dataPathConfig.sync();
		createDataPath.activate();
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

	PyCreateDataPath {
		id: "createDataPath"

		onFinished: {
			pluginEntries.activate();
		}
	}

	PyDataPath {
		id: "pyDataPath"
		path: "Downloads/FollowMe"

		onFinished: {
			if (dataPath != '') {
				app.dataPath = dataPath;
				createDataPath.activate();
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
				createDataPath.activate();
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

