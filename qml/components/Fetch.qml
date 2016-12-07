import QtQuick 2.0
import Sailfish.Silica 1.0

Ajax {
	property var locator
	property var plugin: plugins[locator[0]]
	property var level: plugin != undefined ? plugin.levels[locator.length - 1] : undefined
	property bool fetchautostart
	autostart: false

	signal received (var entry)
	signal started ()
	signal done (bool success, var entries)

	onFinished: {
		console.log('fetching "' + locator.join('/') + '" got me something...');
		console.log('url: ' + url);
		// TODO: preFilter + filter + call received
		if (level.filter == '') {
			console.log('only data: ' + data.length);
			received(data);
			return ;
		}
		console.log('data length: ' + data.length);
		started();
		var re;
		var lastIndex = 0;
		console.log('checking preFilter: ');
		if (level.preFilter != undefined && level.preFilter.length > 0) {
			re = RegExp(level.preFilter, 'gm');
			re.test(data);
			lastIndex = re.lastIndex;
			if (lastIndex == 0) {
				console.error('preFilter not found in data');
				done(false, []);
				return ;
			}
		}
		re = RegExp(level.filter, 'gm');
		re.lastIndex = lastIndex;
		var results;
		var res = [];
		while (results = re.exec(data)) {
			if (lastIndex != 0 && results.index != lastIndex) {
				console.log('start does not match: ' + lastIndex + ' != ' + results.index);
				break;
			}
			console.log('checking filter starting from ' + lastIndex);
			var label = results[level.filterName];
			var id = encodeURIComponent(results[level.filterFile]).replace(/%2F/g, '/');
			var file = level.filePrefix + id + level.fileSuffix;
			var absoluteFile = file;
			if (level.filePrefixBase) {
				absoluteFile = plugin.url + absoluteFile;
			}
			var entry = {id: id, label: label, file: file}
			if (absoluteFile != file) {
				entry['remoteFile'] = absoluteFile;
			}
			received(entry);
			res.push(entry);
			lastIndex = re.lastIndex;
		}
		console.log('fetching "' + locator.join('/') + '" got me some results: ' + res.length);
		done(res.length > 0, res);
	}

	Component.onCompleted: {
		if (plugin != undefined) {
			url = '';
			var i = locator.length - 1;
			while (i > 0) {
				var u = locator[i];
				i--;
				url = plugin.levels[i].filePrefix + u + plugin.levels[i].fileSuffix + url;
				if (!plugin.levels[i].fileCumulative) {
					break;
				}
			}
			url = plugin.url + url;
			if (locator.length > 0 && locator.length <= plugin.levels.length && plugin.levels[locator.length - 1].pathSuffix != undefined) {
				url = url + plugin.levels[locator.length - 1].pathSuffix;
			}
			if (fetchautostart) {
				console.log('fetching "' + url + '"');
				activate();
			}
		}
	}
}
