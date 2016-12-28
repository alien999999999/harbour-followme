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
