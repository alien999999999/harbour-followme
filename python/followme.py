import pyotherside
import os

def locateFolder(base, locator):
    folder = os.path.expanduser(base)
    return os.path.join(folder, '/'.join(locator))

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
            l.append(name)
            if depth == 1:
                if dir and not files:
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
                    entry = {'locator': l, 'file': name, 'absoluteFile': absoluteFile}
                    pyotherside.send(event, entry)
                    entries.append(entry)
            else:
                if dir and depth > 1:
                    entries += listData(base, l, files, excludes, event, depth - 1)
    return entries

def loadData(base, locator):
    folder = locateFolder(base, locator)
    filename = folder + '/.FollowMe'
    try:
        f = open(filename, 'r')
        settings = eval(f.read())
        f.close()
        settings['locator'] = locator
    except:
        pass
        settings = False
    return settings

def saveData(base, locator, settings):
    folder = locateFolder(base, locator)
    os.makedirs(folder, exist_ok = True)
    filename = folder + '/.FollowMe'
    entries = dict(settings)
    if 'locator' in entries:
        del entries['locator']
    r = True
    try:
        f = open(filename, 'w')
        f.write(str(entries))
        f.close()
    except:
        pass
        r = False
    return r

def downloadData(base, locator, suffix, remotefile):
    filename = locator.pop()
    folder = locateFolder(base, locator)
    try:
        os.makedirs(folder, exist_ok = True)
    except FileExistsError:
        pass
    filename = folder + '/' + filename + suffix
    if os.path.isfile(filename):
        return filename
    try:
        import urllib.request
        img = urllib.request.urlopen(remotefile)
        f = open(filename, 'bw')
        f.write(img.read())
        f.close()
    except:
        pass
        filename = False
    return filename

