# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import std/parseopt as po
from std/strformat import fmt

# dependencies
import webui as webui

# project imports
import version as version
import exit as exit
when defined(DEBUG):
  import debug as debug

proc show_help =
  echo(version.long())
  echo(version.compiled())
  echo(version.copyright())
  echo()
  echo(fmt"    {version.ProgramName} [options]")
  echo()
  echo("Options for direct output:")
  echo("  --help         WARNING! Show this help and exit")
  echo("  --version      WARNING! Show version information and exit")
  exit.success()

proc main =

  const options_long_no_val = @[
    "help",
    "version"
  ]

  var p = po.initOptParser(shortNoVal = {}, longNoVal = options_long_no_val)

  when defined(DEBUG):
    var p_debug = p
    debug.output_options(p_debug)

  while true:
    p.next()
    case p.kind
      of po.cmdEnd:
        break
      of po.cmdShortOption, po.cmdLongOption:
        if p.key in options_long_no_val and p.val != "":
          exit.failure_msg(fmt"Command line option '{p.key}' doesn't take a value")
        case p.key:
        # Options for direct output:
          of "help":
            show_help()
          of "version":
            success_msg(version.long())
          else:
            exit.failure_msg(fmt"Unrecognized command line option '{p.key}'")
      of po.cmdArgument:
        exit.failure_msg(fmt"This program doesn't take any non-option arguments: '{p.key}'")

  const window_template = staticRead("../templates/index.html")
  let window = webui.newWindow()
  window.show(window_template)
  webui.wait()

when isMainModule:
  main()
