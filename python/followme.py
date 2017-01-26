import pyotherside
import os

def dataPath(path):
    # expand homedir
    homePath = os.path.expanduser("~")
    # if sdcard exists, we'll take this as base
    dataPath = os.path.join(homePath, "sdcard")
    if os.path.exists(dataPath):
        dataPath = os.path.join(dataPath, path)
        # make sure the folder exists
        os.makedirs(dataPath, exist_ok = True)
        return dataPath
    # if not, we'll use the homePath as base
    dataPath = homePath
    if os.path.exists(dataPath):
        dataPath = os.path.join(dataPath, path)
        # make sure the folder exists
        os.makedirs(dataPath, exist_ok = True)
        return dataPath
    # weird, not having a homePath
    return ''

# helper function to find the resulting folder from the locator (and base)
def locateFolder(base, locator):
    folder = os.path.expanduser(base)
    # if base does not exist, return None
    if not os.path.exists(folder):
        return None
    return os.path.join(folder, '/'.join([x['id'].replace('/','-') for x in locator]))

# list files or directories from a certain locator (and in a certain depth)
# send event for each item
def listData(base, locator, files = False, excludes = [], event = "received", depth = 1):
    entries = []
    # find the folder
    folder = locateFolder(base, locator)
    # return empty list if base does not exist
    if folder is None:
        return []
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
    # return error if base does not exist
    if folder is None:
        return {'error': 'base folder does not exist'}
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
            if 'absoluteFile' in item and item['absoluteFile'].startswith('/home/'):
                i = item['absoluteFile'].find('/FollowMe/')
                if i >= 0:
                    item['absoluteFile'] = item['absoluteFile'][i+9:]
                else:
                    i = item['absoluteFile'].find('/.FollowMe/')
                    if i >= 0:
                        item['absoluteFile'] = item['absoluteFile'][i+10:]
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
    # return False if base does not exist
    if folder is None:
        return False
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
    # return False if base does not exist
    if folder is None:
        return ('', '', False)
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
        return (name, absoluteFile[len(base):], success)
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
    return (name, absoluteFile[len(base):], success)

def cleanDirectory(folder, excludes):
    nr = 0
    try:
        dirlist = os.listdir(folder)
    except:
        dirlist = []
        raise
    for name in dirlist:
        if name not in excludes:
            # determine the file absolute path
            absoluteFile = os.path.join(folder, name)
            # is it a directory?
            if os.path.isdir(absoluteFile):
                nr += cleanDirectory(absoluteFile, excludes)
            else:
                try:
                    # remove the file
                    os.unlink(absoluteFile)
                    nr += 1
                except:
                    raise
    return nr


def cleanData(base, locators, excludes):
    nr = 0
    for locator in locators:
        # determine the parent folder
        folder = locateFolder(base, locator)
        # skip cleaning if base does not exist
        if folder is not None:
            # clean the directory and return removed files
            nr += cleanDirectory(folder, excludes)
    return nr

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
    # return 0 if base does not exist
    if folder is None:
        return 0
    # return the recursive folder size
    return getFolderSize(folder)
