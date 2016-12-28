import QtQuick 2.0
import Sailfish.Silica 1.0

Ajax {
	property var locator: []
	property var plugin: locator != undefined && locator.length > 0 ? plugins[locator[0].id] : undefined
	property var level: locator != undefined && plugin != undefined ? plugin.levels[locator.length - 1] : undefined
	property bool fetchautostart
	autostart: false

	signal received (var entry)
	signal done (bool success, var entries)

	function getURL(plugin, locator) {
		console.log('Fetch: getURL(): locator length ' + locator.length);
		var url = '';
		var i = locator.length - 1;
		while (i > 0) {
			var u = (locator[i].file != undefined ? locator[i].file : locator[i].id);
			console.log('Fetch: basic url: "' + u + '"');
			u = encodeURIComponent(u).replace(/%2F/g, '/');
			console.log('Fetch: encoded url: "' + u + '"');
			i--;
			url = plugin.levels[i].filePrefix + u + plugin.levels[i].fileSuffix + url;
			console.log('Fetch: url: "' + url + '" (' + i + ')');
			console.log('Fetch: cumulative = ' + plugin.levels[i].fileCumulative);
			if (!plugin.levels[i].fileCumulative) {
				break;
			}
		}
		console.log('Fetch: prefixBase = ' + plugin.levels[i].filePrefixBase);
		// prefixBase is only for the base part of the url (ie: where the cumulativeness stops
		if (plugin.levels[i].filePrefixBase) {
			url = plugin.url + url;
		}
		// path suffix is specific for the current level
		if (locator.length <= plugin.levels.length && plugin.levels[locator.length - 1].pathSuffix != undefined) {
			console.log('Fetch: pathSuffix = ' + plugin.levels[locator.length - 1].pathSuffix);
			url = url + plugin.levels[locator.length - 1].pathSuffix;
		}
		return url;
	}

	onStarted: url = getURL(plugin, locator);

	onFinished: {
		console.log('fetching "' + url + '" got me something...');
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
			if (level.filterId == undefined) {
				level.filterId = level.filterFile;
			}
			var label = results[level.filterName];
			var id = results[level.filterId];
			var file = results[level.filterFile];
			var entry = {id: id, label: label, file: file}
			var l = locator.concat([entry]);
			var remoteFile = getURL(plugin, l);
			entry['locator'] = l;
			if (remoteFile.match(/^[a-z0-9]+:\/\/./)) {
				entry['remoteFile'] = remoteFile;
			}
			else {
				if (file.match(/^[a-z0-9]+:\/\/./)) {
					entry['remoteFile'] = file;
				}
			}
			console.log('found id "' + id + '", file:"' + file + '", remoteFile: "' + entry['remoteFile'] + '"');
			received(entry);
			res.push(entry);
			lastIndex = re.lastIndex;
		}
		console.log('fetching "' + url + '" got me some results: ' + res.length);
		done(res.length > 0, res);
	}

	Component.onCompleted: {
		if (fetchautostart) {
			console.log('Fetch: autofetch activating...');
			activate();
		}
	}
}
