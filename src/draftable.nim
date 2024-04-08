# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import std/os as os
import std/parseopt as po
from std/paths import Path, `/`
from std/strformat import fmt
from std/times import Time, format, initDuration, `-`, `<`

# dependencies
import webui as webui

# project imports
import version as version
import exit as exit
import config as config
import table as table
when defined(DEBUG):
  import debug as debug

const
  options_long_no_val = @[
    "help",
    "version",
  ]

  ProjectCofigFilename = "project.draftable"
  UpdateSleepMs = 1000

  IconData = staticRead("../icons/favicon.svg")
  IconType = "image/svg+xml"

  HeadJs = staticRead("../templates/resources/script.js")
  HeadCssReadableCss = staticRead("../templates/resources/readable.css")
  HeadCss = staticRead("../templates/resources/style.css")
  BaseTemplateStartStub = staticRead("../templates/resources/base-start.html")
  BaseTemplateStart = fmt(BaseTemplateStartStub)
  BaseTemplateEnd = staticRead("../templates/resources/base-end.html")

  PageIndex = "index"
  PageIndexTemplate = staticRead(fmt"../templates/{PageIndex}.html")
  PageLicenses = "licenses"
  PageLicensesTemplate = staticRead(fmt"../templates/{PageLicenses}.html")

when defined(DEBUG):
  const
    TimeFormat = "HH:mm:ss"

type
  Status = object
    current_page: string
    is_outdated: bool = true

var status: ref Status
new(status)


proc show_help =
  echo(version.long())
  echo(version.compiled())
  echo(version.copyright())
  echo()
  echo(fmt"    {version.ProgramName} [options] PROJECT_DIR")
  echo()
  echo("Options for direct output:")
  echo("  --help         WARNING! Show this help and exit")
  echo("  --version      WARNING! Show version information and exit")
  exit.success()


proc eh_click_hello(e: webui.Event): string =
  let js_fn_name: string = e.element
  echo("JS function call to '", js_fn_name, "', event: '", e.eventType, "'")
  return "Message from Nim"


proc closure_navigate_to_page(status: ref Status, page: string): proc =

  proc navigate_to_page(e: webui.Event): string =
    when defined(DEBUG):
        debug.print(fmt"Navigating to '{page}' ...")
    status.current_page = page
    status.is_outdated = true
    return fmt"Navigated to '{page}'"

  result = navigate_to_page


proc main =

  var p = po.initOptParser(shortNoVal = {}, longNoVal = options_long_no_val)

  when defined(DEBUG):
    var p_debug = p
    debug.output_options(p_debug)

  var project_dir: string = ""

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
        if project_dir != "":
          exit.failure_msg(fmt"This program only takes one non-option argument - new: '{p.key}'")
        else:
          project_dir = p.key

  if project_dir == "":
    exit.failure_msg("No project dir provided")

  if not os.dirExists(project_dir):
    if os.fileExists(project_dir):
      exit.failure_msg("Provided project dir is actually a file")
    else:
      exit.failure_msg("Provided project dir does not exist")

  let project_config_path: Path = project_dir.Path / ProjectCofigFilename.Path
  if not os.fileExists(project_config_path.string):
    exit.failure_msg(fmt"Project config file does not exist: '{ProjectCofigFilename}'")

  let config: config.Config = config.parse_config(project_config_path)

  let main_file_path: Path = project_dir.Path / config.main_file.Path
  if not os.fileExists(main_file_path.string):
    exit.failure_msg(fmt"Main file does not exist: '{config.main_file}'")

  var template_table_inner = ""

  status.current_page = PageIndex

  var is_status_modified = false
  var template_filled = ""

  let window = webui.newWindow()
  window.setIcon(IconData, IconType)
  window.bind("eh_click_hello", eh_click_hello)
  window.bind("navigate_index", closure_navigate_to_page(status, PageIndex))
  window.bind("navigate_licenses", closure_navigate_to_page(status, PageLicenses))

  var main_file_modified_old: Time = os.getLastModificationTime(main_file_path.string)
  var main_file_modified_new: Time = main_file_modified_old - initDuration(minutes=1)
  when defined(DEBUG):
    var main_file_modified_old_s, main_file_modified_new_s: string

  while true:
    if status.is_outdated:
      when defined(DEBUG):
        main_file_modified_old_s = main_file_modified_old.format(TimeFormat)
        main_file_modified_new_s = main_file_modified_new.format(TimeFormat)
        debug.print(fmt"main modified: '{main_file_modified_old_s}' -> '{main_file_modified_new_s}'")
      case status.current_page
        of PageLicenses:
          template_filled = fmt(PageLicensesTemplate)
        else:
          template_table_inner = table.build(main_file_path)
          template_filled = fmt(PageIndexTemplate)
      window.show(template_filled)
      status.is_outdated = false
    if not window.shown():
      when defined(DEBUG):
        debug.print("Window not shown anymore, exiting...")
      break
    os.sleep(UpdateSleepMs)
    main_file_modified_old = main_file_modified_new
    main_file_modified_new = os.getLastModificationTime(main_file_path.string)
    is_status_modified = main_file_modified_old < main_file_modified_new
    status.is_outdated = status.is_outdated or is_status_modified


when isMainModule:
  main()
