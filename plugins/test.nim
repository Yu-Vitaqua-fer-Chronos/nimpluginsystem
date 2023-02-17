import ../api

proc plugin*(): Plugin {.dynlib, exportc.} = Plugin(
  name: "test-plugin",
  displayname: "Test Plugin",
  semver: (0, 1, 0),
  # requires: @[],
  # optionalRequires: @[],
  description: "A plugin implementing the Minecraft 1.19.3 protocol",
  reloadable: false # Could probably be true
)

proc setup*(plugin: Plugin) {.dynlib, exportc.} =
  var test = plugin.server.requestPlugin("test-plugin")
  echo "Hello from " & test.displayname & "!"

proc teardown*(plugin: Plugin) {.dynlib, exportc.} =
  echo "Bye from " & plugin.displayname & "!"

proc enable*(plugin: Plugin) {.dynlib, exportc.} = discard

proc disable*(plugin: Plugin) {.dynlib, exportc.} = discard