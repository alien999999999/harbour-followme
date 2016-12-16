import pyotherside
import os

# helper function to find the resulting folder from the locator (and base)
def locateFolder(base, locator):
    folder = os.path.expanduser(base)
    return os.path.join(folder, '/'.join([x['id'].replace('/','-') for x in locator]))

# list files or directories from a certain locator (and in a certain depth)
# send event for each item
def listData(base, locator, files = False, excludes = [], event = "received", depth = 1):
    entries = []
    folder = locateFolder(base, locator)
    try:
        dirlist = os.listdir(folder)
    except:
        pass
        dirlist = []
    for name in dirlist:
        if name not in excludes:
            absoluteFile = os.path.join(folder, name)
            dir = os.path.isdir(absoluteFile)
            l = list(locator)
            l.append({'id': name})
            if depth == 1:
                # depth == 1, so we're at the end of the depth
                if dir and not files:
                    # we're looking for directories
                    entry = loadData(base, l);
                    if not entry:
                        entry = {}
                    entry['file'] = name;
                    if 'items' not in entry:
                        entry['items'] = [];
                    # send the data
                    pyotherside.send(event, entry)
                    entries.append(entry)
                elif not dir and files:
                    # we're looking for files
                    entry = {'locator': l, 'file': name, 'absoluteFile': absoluteFile}
                    pyotherside.send(event, entry)
                    entries.append(entry)
            else:
                if dir and depth > 1:
                    # call itself recursively with one less depth
                    entries += listData(base, l, files, excludes, event, depth - 1)
    return entries

def loadData(base, locator):
    folder = locateFolder(base, locator)
    filename = folder + '/.FollowMe'
    try:
        f = open(filename, 'r')
        entry = eval(f.read())
        f.close()
        if 'parent' in entry:
            entry['locator'] = entry['parent']
            del entry['parent']
            entry['locator'].append(locator[-1])
        if 'locator' not in entry:
            entry['locator'] = locator
        if 'file' in entry and 'file' not in entry['locator'][-1]:
            entry['locator'][-1]['file'] = entry['file']
        if 'label' in entry and 'label' not in entry['locator'][-1]:
            entry['locator'][-1]['label'] = entry['label']
    except:
        pass
        entry = False
    return entry

def saveData(base, locator, entry):
    folder = locateFolder(base, locator)
    os.makedirs(folder, exist_ok = True)
    filename = folder + '/.FollowMe'
    entry = dict(entry)
    entry['parent'] = locator[:-1]
    if 'locator' in entry:
        del entry['locator']
    r = True
    try:
        f = open(filename, 'w')
        f.write(str(entry))
        f.close()
    except:
        pass
        r = False
    return r

def downloadData(base, locator, suffix, remotefile):
    fileitem = locator.pop()
    folder = locateFolder(base, locator)
    try:
        os.makedirs(folder, exist_ok = True)
    except FileExistsError:
        pass
    filename = folder + '/' + fileitem['id'].replace('/','-') + suffix
    if os.path.isfile(filename):
        return filename
    try:
        import urllib.request
        img = urllib.request.urlopen(remotefile)
        f = open(filename, 'bw')
        f.write(img.read())
        f.close()
    except:
        raise
        filename = False
    return filename

