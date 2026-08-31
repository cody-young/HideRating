# HideRating

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

A World of Warcraft (retail) addon that keeps PvP ratings out of sight, with
two optional extras for cutting noise mid-session.

## Options

* **Hide PvP ratings** — masks ratings in the PvP window (all five rated
  brackets, plus the tier icons and bracket tooltips), on inspected players,
  in the battleground/arena scoreboard columns, the "average rating" footer,
  and the post-match rating-change summary. Rating column headers also stop
  accepting clicks, since sorting by a hidden column still leaks the order.
* **Only show whispers from friends** — whispers from anyone who is not a
  character friend or Battle.net friend are dropped. A sub-option keeps
  guildmates and current party/raid members audible.
* **Hide chat windows** — hides the chat frames, tabs and chat buttons. The
  edit box is reparented to UIParent while hidden, so typing and slash
  commands still work normally. A sub-option limits this to arenas and
  battlegrounds.

A **Show Ratings / Hide Ratings** button sits in the bottom-left of the PvP
window for when you do want a look, and it drives the same setting as the
options panel and slash command.

Nothing is masked destructively: turning a setting back off restores the
values the game had already put on screen, no reload needed.

## Commands

```
/hiderating            show the current state of every option
/hiderating rating     toggle rating hiding
/hiderating whispers   toggle friends-only whispers
/hiderating known      toggle guild/group members counting as friends
/hiderating chat       toggle chat hiding
/hiderating pvponly    toggle "chat hidden only in instanced PvP"
/hiderating config     open the options panel
```

`/hr` is a shorthand for `/hiderating`.

## License

GPLv3 or later. See [LICENSE](LICENSE).

Packaging and release setup: see [PUBLISHING.md](PUBLISHING.md).
