# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from system import string, quit, QuitSuccess, QuitFailure

proc success* =
  quit(QuitSuccess)

proc success_msg*(output: string) =
  quit(output, QuitSuccess)

proc failure* =
  quit(QuitFailure)

proc failure_msg*(output: string) =
  quit(output, QuitFailure)
