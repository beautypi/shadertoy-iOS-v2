#!/usr/bin/env python3 
# -*- coding: utf-8 -*-

## Usage sample:
## ./batchsed.py -d /Users/chenqiu1024/Projects/shadertoy-iOS-v2 -f "(.+/\w+_(ok|ng))\.log" -o "\1_replaced.log" -t es3gl_replacements.txt

from posixpath import expanduser
import re
import os
import argparse
import sys
from functools import reduce
import ast
def fileIterator(rootDir, filterExp=None):
    filterRegex = re.compile(filterExp)
    indent = []
    pathComponents = []
    dirs = [rootDir, "#POP#"]
    while len(dirs) > 0:
        currentDir = dirs.pop(0)
        if currentDir == "#POP#":
            if len(pathComponents) > 0:
                pathComponents.pop()
            if len(indent) > 0:
                indent.pop()
            continue

##        print("%s%s/" % ("".join(indent), currentDir))
        indent.append("    ")
        pathComponents.append(currentDir)
        pathComponents.append(" ")
        fullPath = os.path.abspath(reduce(lambda x,y : os.path.join(x,y), pathComponents))
        fullPath = fullPath[:-1]
        pathComponents.pop()
##        print("Full path of directory:%s" % fullPath)
        if filterExp is None:
            yield fullPath
        else:
            match = filterRegex.match(fullPath)
##            print("Match '%s' with '%s' is %s" % (fullPath, filterExp, match))
            if not match is None:
                yield fullPath 
        fullPath = fullPath[:-1]
        files = os.listdir(fullPath)
        index = 0
        for f in files:
            pathComponents.append(f)
            fullPath = os.path.abspath(reduce(lambda x,y : os.path.join(x,y), pathComponents))
##            print("Full path of file:%s" % fullPath)
            if os.path.isdir(fullPath):
##                print("+  %s" % f)
                dirs.insert(index, f)
                index = index + 1
##            elif os.path.isfile(f):
            else:
                if filterExp is None:
                    yield fullPath
                else:
                    match = filterRegex.match(fullPath)
##                    print("Match '%s' with '%s' is %s" % (fullPath, filterExp, match))
                    if not match is None:
                        yield fullPath 
##                print("%s%s" % ("".join(indent), f))
            pathComponents.pop()

        dirs.insert(index, "#POP#")

def ls(rootDir, filterExp=None):
    for f in fileIterator(rootDir, filterExp):
        print(f)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Do regex replacement in files that match certain filename pattern in specified directory")
    parser.add_argument("--dir", "-d", type=str, help="Specify the path for file searching directory")
    parser.add_argument("--filePattern", "-f", type=str, help="Specify the regex pattern of target files")
    parser.add_argument("--outFilePattern", "-o", type=str, help="Specify the regex pattern of pathes of output files")
    parser.add_argument("--textPattern", "-p", type=str, help="Specify the dictionary of regexes of search targets and replacements")
    parser.add_argument("--dictFile", "-t", type=str, help="Specify the dictionary file of regexes of search targets and replacements")
    args = parser.parse_args()
    rootDir = args.dir
    if not os.path.exists(rootDir):
        raise ValueError("Path " + rootDir + " does not exist.")

    filePattern = args.filePattern
    if filePattern is None:
        filePattern = ".*"
    fileRegex = re.compile(filePattern)

    outFilePattern = args.outFilePattern

    replaceDict = {}
    if not args.textPattern is None:
        replaceDict = ast.literal_eval(args.textPattern)
    if not args.dictFile is None:
        f = open(args.dictFile, 'r')
        dictText = f.read()
        f.close()
        dict = ast.literal_eval("{" + dictText + "}");
        replaceDict.update(dict)

    if replaceDict:
        for filepath in fileIterator(rootDir, filePattern):  
            f = open(filepath, 'r')
            txt = f.read()
            f.close()
            for textPattern in replaceDict:
                replacement = replaceDict[textPattern]
                textRegex = re.compile(textPattern, re.IGNORECASE)
                matches = textRegex.finditer(txt)
                if not matches is None:
                    newTxt = ""
                    end = 0
                    for match in matches:
                        start = match.start(0)
                        newTxt = newTxt + txt[end:start]
                        end = match.end(0)
                        ## TODO: Add replaced subtext
                        matched = txt[start:end]
                        if not replacement is None:
                            sub = textRegex.sub(replacement, matched)
                            newTxt = newTxt + sub
                        else:
                            newTxt = newTxt + matched
                        ##groups = match.groups()
                        ##for i in range(len(groups) + 1):
                        ##    start = match.start(i)
                        ##    end = match.end(i)
                        ##    print("From %d to %d" % (start, end))
                        ##    print(txt[start:end])
                    newTxt = newTxt + txt[end:len(txt)]
                    ##print(newTxt)
                    txt = newTxt
                else:
                    print("No matches")

            if not outFilePattern is None:
                newFilePath = fileRegex.sub(outFilePattern, filepath)
                f = open(newFilePath, 'w')
                f.write(txt)
                f.close()
                print(newFilePath)
    ##for f in fileIterator(rootDir, filterExp):
    ##    print(f)
    