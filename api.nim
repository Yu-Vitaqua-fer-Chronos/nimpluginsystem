#[
const plugin* {.exportc.} = Plugin(
  name: "1.19.3-networking",
  displayname: "Networking 1.19.3",
  semver: (0, 1, 0),
  # requires: @[],
  # optionalRequires: @[],
  description: "A plugin implementing the Minecraft 1.19.3 protocol",
  reloadable: false # Could probably be true
)

proc setup*() {.cdecl, exportc.}
proc teardown*() {.cdecl, exportc.}
proc enable*() {.cdecl, exportc.}
proc disable*() {.cdecl, exportc.}
]#
import std/[
  dynlib
]

type
  PluginProcedure = proc(plugin: Plugin)

  Server* {.exportc.} = ref object
    plugins*: seq[Plugin]

  Plugin* {.exportc.} = ref object
    name*, displayname*, description*: string
    semver*: (int, int, int)
    requires*, optionalRequires*: seq[string]
    reloadable*: bool

    server*: Server
    libhandle*: LibHandle
    isLoaded*: bool

proc registeredPluginNames(srv: Server): seq[string] =
  for plugin in srv.plugins:
    result.add plugin.name

proc registerPlugin(srv: Server, path: string) =
  var libhandle = loadLib(path)

  if libhandle == nil:
    echo path & " is not a valid path! Skipping..."
    return

  var plugin = cast[Plugin](libhandle.symAddr("plugin"))

  if plugin == nil:
    echo path & " is not a Nimberite plugin! Skipping..."
    return

  if plugin.name == "":
    echo path & " doesn't have a valid internal name!"
    return

  elif plugin.name in srv.registeredPluginNames():
    echo path & " shares the same internal name as another plugin!"
    return

  if plugin.displayname == "":
    plugin.displayname = plugin.name
    echo "[" & plugin.displayname & "] Doesn't have a displayname, " &
      "setting it to the plugin's internal name"

  plugin.server = srv
  plugin.libhandle = libhandle

  srv.plugins.add plugin
  return


proc requestSetup(p: Plugin): Plugin =
  if p.isLoaded:
    return p

  let nimMain = cast[proc()](p.libhandle.symAddr("NimMain"))

  if nimMain != nil:
    nimMain()

  let setup = cast[PluginProcedure](p.libhandle.symAddr("setup"))

  if setup == nil:
    return p

  setup(p)
