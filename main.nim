import std/[
  os,
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
    s.registerPlugin(pluginFile)

  for plugin in s.plugins:
    requestSetup(plugin)
    echo fmt"[{plugin.displayname}] Loaded plugin!"

  for plugin in s.plugins:
    requestTeardown(plugin)
    echo fmt"[{plugin.displayname}] Unloaded plugin!"

var server = Server()
server.start()
