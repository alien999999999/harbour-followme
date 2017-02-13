import QtQuick 2.0
import Sailfish.Silica 1.0

import "../scripts/download.js" as Utils

Ajax {
	property var locator: []
	property var plugin: locator != undefined && locator.length > 0 && locator[0].id != undefined ? plugins[locator[0].id] : undefined
	property var level: locator != undefined && plugin != undefined && plugin.levels != undefined ? ( searchName != '' && plugin.search != undefined && plugin.search != false ? plugin.search : plugin.levels[locator.length - 1] ) : undefined
	property bool needProvider: false
	property string searchName: ''

	property bool fetchautostart
	autostart: false

	signal received (var entry)
	signal done (bool success, var entries)

	onStarted: {
		if (searchName != '' && plugin.search != undefined && plugin.search != false) {
			url = Utils.searchURL(plugin, searchName);
		}
		else {
			url = Utils.getURL(plugin, locator);
		}
	}

	onFinished: {
		if (status != 200) {
			console.log('xhr status: ' + status);
			done(false,[]);
			return ;
		}
		console.log('fetching "' + url + '" got me something...');
		// TODO: preFilter + filter + call received
		if (level.filter == '') {
			console.log('only data: ' + data.length);
			received(data);
			return ;
		}
		console.log('data length: ' + data.length);

		// initialize variables
		var re;
		var searchRegExp = searchName;
		var lastIndex = 0;

		// check preFilter
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

		// prepare filter RegExp
		re = RegExp(level.filter, 'gm');

		// also create search RegExp if needed
		if (searchName != '') {
			searchRegExp = RegExp(searchName, 'i');
		}

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
			var entry = {id: id, label: label, file: file};
			var l = locator.concat([entry]);
			var remoteFile = Utils.getURL(plugin, l);
			console.log('url of found entry is: ' + remoteFile);
			//entry['locator'] = l;
			console.log('it has level type: ' + app.getLevel(l).type);

			// download request need to have remoteFile set
			if (app.isDownload(l)) {
				// if remoteFile is full URL, it suffices
				if (remoteFile.match(/^[a-z0-9]+:\/\/./)) {
					entry['remoteFile'] = remoteFile;
				}
				else {
					// check if file is a full URL, than it would suffice too
					if (file.match(/^[a-z0-9]+:\/\/./)) {
						entry['remoteFile'] = file;
					}
				}
			}

			// if provider is needed in the entry, add it
			if (needProvider) {
				entry['provider'] = locator[0].id;
			}

			// set lastIndex correctly for next loop
			lastIndex = re.lastIndex;

			// only filter searchName is there is no native search
			if (searchName != '' && plugin.search == false) {
				// if the search String is not found, just continue the loop
				if (label.search(searchRegExp) < 0) {
					continue;
				}
			}

			// trigger the received signal and push it to the results
			console.log('found id "' + id + '", file:"' + file + '", remoteFile: "' + remoteFile + '"');
			received(entry);
			res.push(entry);
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
