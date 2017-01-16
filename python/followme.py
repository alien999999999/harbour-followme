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
    # find the folder
    folder = locateFolder(base, locator)
    try:
        dirlist = os.listdir(folder)
    except:
        pass
        dirlist = []
    for name in dirlist:
        if name not in excludes:
            # determine the file absolute path
            absoluteFile = os.path.join(folder, name)
            # is it a directory?
            dir = os.path.isdir(absoluteFile)
            # clone the locator
            l = list(locator)
            # set the id as the relative file
            l.append({'id': name})
            if depth == 1:
                # depth == 1, so we're at the end of the depth
                if dir and not files:
                    # we're looking for directories
                    entry = loadData(base, l);
                    entry['file'] = name;
                    if 'items' not in entry:
                        entry['items'] = [];
                    # send the data
                    pyotherside.send(event, entry)
                    entries.append(entry)
                elif not dir and files:
                    # we're looking for files
                    entry = {'locator': l, 'file': name, 'absoluteFile': absoluteFile}
                    # send the data
                    pyotherside.send(event, entry)
                    entries.append(entry)
            else:
                if dir and depth > 1:
                    # call itself recursively with one less depth
                    entries += listData(base, l, files, excludes, event, depth - 1)
    return entries

def loadData(base, locator):
    # find the folder
    folder = locateFolder(base, locator)
    # determine the filename
    filename = folder + '/.FollowMe'
    # load the entry from the filename
    try:
        f = open(filename, 'r')
        # parse the entry
        entry = eval(f.read())
        f.close()
    except Exception as e:
        pass
        entry = {'error': e}
    # if a parent is inside the entry, create a locator from it
    if 'parent' in entry:
        entry['locator'] = list(entry['parent'])
        entry['locator'].append(locator[-1])
        del entry['parent']
    # if there is no locator in the entry set it.
    if 'locator' not in entry:
        entry['locator'] = locator
    # if there is a file in the entry and not in the locator, add it
    if 'file' in entry and 'file' not in entry['locator'][-1]:
        entry['locator'][-1]['file'] = entry['file']
    # if there is a label in the entry and not in the locator, add it
    if 'label' in entry and 'label' not in entry['locator'][-1]:
        entry['locator'][-1]['label'] = entry['label']
    # check if subitems don't have locators or subitems
    if 'items' in entry:
        for item in entry['items']:
            if 'items' in item:
                del item['items']
            if 'locator' in item:
                del item['locator']
    return entry

def saveData(base, entry):
    # clone the entry
    entry = dict(entry)
    # get the locator
    locator = entry['locator']
    # replace the locator with parent
    del entry['locator']
    entry['parent'] = locator[:-1]
    # check if subitems don't have locators or subitems
    if 'items' in entry:
        for item in entry['items']:
            if 'items' in item:
                del item['items']
            if 'locator' in item:
                del item['locator']
    # find the folder
    folder = locateFolder(base, locator)
    # make sure the folder exists
    os.makedirs(folder, exist_ok = True)
    # determine the filename
    filename = folder + '/.FollowMe'
    # save the entry to the filename
    r = True
    try:
        f = open(filename, 'w')
        f.write(str(entry))
        f.close()
    except:
        pass
        r = False
    return r

def downloadData(base, locator, suffix, remotefile, redownload):
    success = True
    # clone the locator
    l = list(locator)
    # extract the last part
    fileitem = l.pop()
    # determine the parent folder
    folder = locateFolder(base, l)
    # make sure the directory exists
    try:
        os.makedirs(folder, exist_ok = True)
    except FileExistsError:
        pass
    # get the filename
    name = fileitem['id'].replace('/','-') + suffix
    # get the absolute filename
    absoluteFile = os.path.join(folder, name)
    if os.path.isfile(absoluteFile) and not redownload:
        return (name, success)
    try:
        import urllib.request
        req = urllib.request.Request(remotefile)
        req.add_header('Accept', '*/*')
        req.add_header('User-Agent', 'FollowMe/1.0')
        img = urllib.request.urlopen(req)
        f = open(absoluteFile, 'bw')
        f.write(img.read())
        f.close()
    except Exception as e:
        pass
        success = str(e)
    return (name, success)

def getFolderSize(folder):
    total_size = 0
    try:
        dirlist = os.listdir(folder)
    except:
        dirlist = []
        pass
    try:
        total_size = os.path.getsize(folder)
    except:
        pass
    for item in dirlist:
        itempath = os.path.join(folder, item)
        if os.path.isfile(itempath):
            try:
                total_size += os.path.getsize(itempath)
            except:
                pass
        elif os.path.isdir(itempath):
            total_size += getFolderSize(itempath)
    return total_size

def dataSize(base, locator):
    # determine the parent folder
    folder = locateFolder(base, locator)
    # return the recursive folder size
    return getFolderSize(folder)
