# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from std/paths import Path
import std/streams as streams
from std/strformat import fmt
from std/strutils import split

# project imports
when defined(DEBUG):
  import debug as debug


type Config* = object
  main_file*: string = ""


proc parse_config*(project_config_path: Path): Config =
  result = Config()

  var strm = streams.newFileStream(project_config_path.string, fmRead)
  defer: strm.close()

  if isNil(strm):
    return

  var line = ""
  var key, val = ""
  while strm.readLine(line):
    if line == "":
      continue

    let split_iter: seq[string] = line.split('=')

    if split_iter.len != 2:
      echo(fmt"Less/more than one '=' in config line: '{line}'")
      continue

    key = split_iter[0]
    val = split_iter[1]  # length verified above
    case key
      of "main_file":
        result.main_file = val
      else:
        echo(fmt"Unrecognized key '{key}' in project config, ignoring")
        continue

    when defined(DEBUG):
      debug.print(fmt"Config option: '{key}' = '{val}'")
