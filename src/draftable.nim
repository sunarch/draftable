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
  OptionsLongNoVal = @[
    "help",
    "version",
  ]

  ProjectConfigFilename = "project.draftable"
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
    modified_old: Time
    modified_new: Time
    is_outdated: bool = true


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


proc live_view(config: config.Config, main_file_path: Path): string =

  var
    status: ref Status
    template_table_inner: string
    template_filled: string
  when defined(DEBUG):
    var
      modified_old_s: string
      modified_new_s: string

  new(status)
  status.current_page = PageIndex
  status.modified_old = os.getLastModificationTime(main_file_path.string)
  status.modified_new = status.modified_old - initDuration(minutes=1)

  let window: webui.Window = webui.newWindow()
  window.setIcon(IconData, IconType)
  window.bind("eh_click_hello", eh_click_hello)
  window.bind("navigate_index", closure_navigate_to_page(status, PageIndex))
  window.bind("navigate_licenses", closure_navigate_to_page(status, PageLicenses))

  while true:
    if status.is_outdated:
      when defined(DEBUG):
        modified_old_s = status.modified_old.format(TimeFormat)
        modified_new_s = status.modified_new.format(TimeFormat)
        debug.print(fmt"main modified: '{modified_old_s}' -> '{modified_new_s}'")
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

    status.modified_old = status.modified_new
    status.modified_new = os.getLastModificationTime(main_file_path.string)
    status.is_outdated = status.is_outdated or status.modified_old < status.modified_new

  result = fmt(PageIndexTemplate)


proc verify_project_dir(project_dir: string) =
  if project_dir == "":
    exit.failure_msg("No project dir provided")
  elif os.dirExists(project_dir):
    return
  elif os.fileExists(project_dir):
    exit.failure_msg("Provided project dir is actually a file")
  else:
    exit.failure_msg("Provided project dir does not exist")


proc create_file_path(dir: string, filename: string): Path =
  result = dir.Path / filename.Path


proc create_and_verify_file_path(dir: string, filename: string, desciption: string): Path =
  result = create_file_path(dir, filename)
  if not os.fileExists(result.string):
    exit.failure_msg(fmt"{desciption} file does not exist: '{filename}'")


proc main =

  var p = po.initOptParser(shortNoVal = {}, longNoVal = OptionsLongNoVal)

  when defined(DEBUG):
    var p_debug = p
    debug.output_options(p_debug)

  var project_dir: string = ""

  while true:
    p.next()
    case p.kind
      of po.cmdEnd:
        break
      of po.cmdShortOption:
        exit.failure_msg(fmt"This program does not take short arguments: '{p.key}'")
      of po.cmdLongOption:
        if p.key in OptionsLongNoVal and p.val != "":
          exit.failure_msg(fmt"Command line option '{p.key}' doesn't take a value")
        case p.key:
        # Options for direct output:
          of "help":
            show_help()
          of "version":
            exit.success_msg(version.long())
          else:
            exit.failure_msg(fmt"Unrecognized command line option '{p.key}'")
      of po.cmdArgument:
        if project_dir != "":
          exit.failure_msg(fmt"This program only takes one non-option argument - new: '{p.key}'")
        else:
          project_dir = p.key

  verify_project_dir(project_dir)

  let
    project_config_path: Path = create_and_verify_file_path(
      project_dir, ProjectConfigFilename, "Project config")

    config: config.Config = config.parse_config(project_config_path)

    main_file_path: Path = create_and_verify_file_path(
      project_dir, config.main_file, "Project main")

    save_file_path: Path = create_file_path(project_dir, "index.html")

  let last_rendered = live_view(config, main_file_path)
  writeFile(save_file_path.string, last_rendered)


when isMainModule:
  main()
