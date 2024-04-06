# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from std/parseopt import OptParser, next, cmdEnd
from std/strformat import fmt

const Prefix: string = "[DEBUG:] "

proc print*(line: string) =
  echo(fmt"{Prefix}{line}")

proc output_options*(p_debug: var OptParser) =
  while true:
    p_debug.next()
    stdout.write(fmt"{Prefix}Option: ({p_debug.kind})")
    if p_debug.kind != cmdEnd:
      stdout.write(fmt" '{p_debug.key}' = '{p_debug.val}'")
    echo()
    if p_debug.kind == cmdEnd:
      break
