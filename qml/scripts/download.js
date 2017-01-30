.pragma library

/** ajax(url, callback)
 * do an asynchronous call for an url
 * when done, issue a callback with the status and the responseText
 */
function ajax(url, callback) {
	var xhr = new XMLHttpRequest;
	xhr.open("GET", url);
	xhr.onreadystatechange = function() {
		if (xhr.readyState == XMLHttpRequest.DONE) {
			if (callback != undefined) {
				callback(xhr.status, xhr.responseText);
			}
		}
	}
	return xhr.send();
}

/** getURL(plugin, locator)
 * compile an URL for a specific locator (and plugin)
 * if it fails, returns an empty string
 */
function getURL(plugin, locator) {
	var url = '';
	var i = locator.length - 1;
	while (i > 0) {
		// first start with the file if it's defined, or the id otherwise
		var u = (locator[i].file != undefined ? locator[i].file : locator[i].id);
		// we need to encode it, except for / 's
		u = encodeURIComponent(u).replace(/%2F/g, '/');
		i--;
		// for each level, check with prefix and/or suffix + add the previous url parts to it
		url = plugin.levels[i].filePrefix + u + plugin.levels[i].fileSuffix + url;
		// if this level is not cumulative, there's no reason to continue traversing
		if (!plugin.levels[i].fileCumulative) {
			break;
		}
	}
	// prefixBase is only for the base part of the url (ie: where the cumulativeness stops
	if (plugin.levels[i].filePrefixBase) {
		url = plugin.url + url;
	}
	// path suffix is specific for the current level
	if (locator.length <= plugin.levels.length && plugin.levels[locator.length - 1].pathSuffix != undefined) {
		url = url + plugin.levels[locator.length - 1].pathSuffix;
	}
	return url;
}

/** getSuffix(file)
 * gets the suffix from a file
 */
function getSuffix(file) {
	var l = file.split('/');
	var suffix = '';
	var r = l[l.length - 1].match(/\.[a-z0-9]{3,4}$/);
	if (r != null) {
		suffix = r[0];
	}
	return suffix;
}

/** getAbsoluteFile(remoteFile)
 * try to determine the absoluteFile 's name when downloaded
 */
function getAbsoluteFile(locator, remoteFile) {
	var l = locator.slice();
	var item = l.pop();
	var suffix = getSuffix(remoteFile);
	var file = item['id'].replace('/','-') + suffix;
	var folder = '';
	for (var i in l) {
		folder += '/' + l[i]['id'].replace('/','-');
	}
	return folder + '/' + file;
}

/** formatBytes(size)
 * show an integer (size) as a string with unit bytes
 */
function formatBytes(size) {
	size = parseInt(size);
	size = size >> 10;
	if (size < 2048) {
		return '';
	}
	size = size >> 10;
	if (size < 2048) {
		return size + ' MB';
	}
	size = size >> 10;
	return size + ' GB';
}
