import std/[
  os,
  dynlib,
  strutils,
  strformat
]

import ./api

when defined(windows):
  const SHARED_LIB_EXT = ".dll"
else:
  const SHARED_LIB_EXT = ".so"

var pluginFiles: seq[string]

proc start(s: Server) =
  for file in walkDirRec("plugins"):
    if file.endswith(SHARED_LIB_EXT):
      pluginFiles.add file

  for pluginFile in pluginFiles:
    discard s.registerPlugin(pluginFile)

  for plugin in s.plugins:
    requestSetup(plugin)

  #echo fmt"[{plugin.displayname}] Loaded plugin!"
