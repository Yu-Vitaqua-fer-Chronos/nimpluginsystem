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

proc setup*(plugin: Plugin) {.cdecl, exportc.}
proc teardown*(plugin: Plugin) {.cdecl, exportc.}
proc enable*(plugin: Plugin) {.cdecl, exportc.}
proc disable*(plugin: Plugin) {.cdecl, exportc.}
]#
import std/[
  dynlib
]

type
  NimMain = proc() {.gcsafe, stdcall.}

  Getter[T] = proc(): T {.gcsafe, stdcall.}
  Setter[T] = proc(t: T) {.gcsafe, stdcall.}

  PluginProcedure = proc(plugin: Plugin) {.gcsafe, stdcall.}

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

proc registerPlugin*(srv: Server, path: string) =
  var libhandle = loadLib(path)

  if libhandle == nil:
    echo path & " is not a valid path! Skipping..."
    return

  let nimMain = cast[NimMain](libhandle.symAddr("NimMain"))

  if nimMain != nil:
    nimMain()

  var plugin = cast[Getter[Plugin]](libhandle.symAddr("plugin"))()

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

proc requestPlugin*(srv: Server, pluginName: string): Plugin =
  for plugin in srv.plugins:
    if plugin.name == pluginName:
      return plugin

  return nil

proc requestSetup*(p: Plugin) =
  if p.isLoaded:
    return

  p.isLoaded = true

  let setup = cast[PluginProcedure](p.libhandle.symAddr("setup"))

  if setup == nil:
    return

  setup(p)

proc requestTeardown*(p: Plugin) =
  let teardown = cast[PluginProcedure](p.libhandle.symAddr("teardown"))

  if teardown == nil:
    return

  teardown(p)