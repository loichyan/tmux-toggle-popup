# 🌀 tmux-toggle-popup

A handy plugin that helps create toggleable popups.

[demo.webm](https://github.com/loichyan/tmux-toggle-popup/assets/73006950/99a94285-3839-4fe0-949f-5649ad34d5a5)

<details>
<summary>Environment</summary>
<br>

- DE: [Gnome 46](https://release.gnome.org/46) & [PaperWM](https://github.com/paperwm/PaperWM)
- Tmux: [Catppuccin theme](https://github.com/catppuccin/tmux)
- Font: [Rec Mono Duotone](https://www.recursive.design)
- Keystrokes: [Show Me the Key](https://showmethekey.alynx.one)
- Rickroll: [rickrollrc](https://github.com/keroserene/rickrollrc)

_Check
[the dotfiles](https://github.com/loichyan/dotfiles/tree/5899f0e7572de4102261051277b22990e53f8bed)
for more details_

</details>

## 📦 Installation

### Requirements

- Tmux >= **3.4** (not tested on earlier versions)

### With [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add this plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin "loichyan/tmux-toggle-popup"
```

### Manual installation

Clone the repo:

```sh
git clone https://github.com/loichyan/tmux-toggle-popup ~/clone/path
```

Add this line to the bottom of `.tmux.conf`:

```tmux
run ~/clone/path/toggle-popup.tmux
```

Reload Tmux environment with: `tmux source-file ~/.tmux.conf`. You should now be able to use the
plugin.

## ✍️ Usage

Create keybindings to toggle your preferred shell and
[lazygit](https://github.com/jesseduffield/lazygit):

```tmux
bind -n M-t run "#{@popup-toggle} -Ed'#{pane_current_path}' -w75% -h75%"
bind -n M-g run "#{@popup-toggle} -Ed'#{pane_current_path}' -w90% -h90% --name=lazygit lazygit"
```

## ⚙️ Options

### `@popup-socket-name`

**Default**: `popup`

**Description**: The socket name (`tmux -L {@popup-socket-name} ...`) of the server in which all
popup sessions are opened. A special environment variable, `$TMUX_POPUP_SERVER`, is set to its value
before the server starts, which is used to identify popup servers. You can check this variable and
load different configurations in your `.tmux.conf`.

**Example**:

```tmux
# configurations for popup servers
if '[ -n "$TMUX_POPUP_SERVER" ]' {
    set -g exit-empty off
    set -g status off
}
# ...other configurations
```

### `@popup-id-format`

**Default**: `#{b:socket_path}/#{session_name}/#{b:pane_current_path}/#{@popup_name}`

**Description**: A format string used to generate IDs for each popup, allowing you to customize how
popups are shared across sessions, windows, and panes. By default, popups are independent across
sessions, and in each session, popups are shared among the same project (identified by the directory
name). A variable named `@popup_name` is assigned the name of the popup during the expansion of the
format string.

### `@popup-autostart`

**Default**: `off`

**Description**: If enabled, the designated tmux server for popups will start automatically.

## 🪝 Hooks

A hook consists of Tmux commands delimited by semicolons (`;`). Each hook is interpreted by bash(1)
as a sequence of shell arguments, which are then passed to tmux(1). Hence, semicolons should be
escaped (`\;`) or quoted (`";"`) to prevent them from being recognized as bash command delimiters.
Each command can alternatively be delimited by a line break, which is substituted with `\;` before
interpretation.

A hook will be executed either in the caller (i.e., the session that calls `@popup-toggle`) or in
the popup (i.e., the session that opens as a popup).

**Example**:

```tmux
set -g @popup-on-init '
  set exit-empty off
  set status off
'
# Escaping "\;" is required when binding key to multiple commands
set -g @popup-on-init '
  bind M-r display "some text" \\\; display "another text"
'
```

### `@popup-on-init`

**Default**: `set exit-empty off \; set status off`

**Description**: Tmux commands executed in the popup each time after it is opened.

### `@popup-before-open`

**Default**: empty

**Description**: Tmux commands executed in the caller each time before a popup is opened.

### `@popup-after-close`

**Default**: empty

**Description**: Tmux commands executed in the caller each time after a popup is closed.

## ⌨️ Keybindings

### `@popup-toggle`

**Example**:

```tmux
bind -n M-t run "#{@popup-toggle} -Ed'#{pane_current_path}' -w75% -h75%"
```

**Description**: A shell script to toggle a popup: when invoked in a popup of the same name, it
closes the popup; otherwise, it opens a popup of the specified name. If no argument is passed or
`--toggle` is specified and called in a popup, it will close the popup.

By default, if you call it with the name _A_ specified within another opened popup _B_, it will open
a new popup _A_ inside _B_ instead of closing _B_ (i.e. popup-in-popup). You may find this behavior
surprising, but tmux simply allows us to do so. You can bind `run "#{@popup-toggle}"` to a primary
toggle key, which will close the opened popup anyway.

```text
USAGE:

  toggle.sh [OPTION]... [SHELL_COMMAND]...

OPTION:

  --name <name>               Popup name.
  --socket-name <value>       Socket name.
  --id-format <value>         Popup ID format.
  --on-init <hook>            Command to run on popup initialization.
  --before-open <hook>        Hook to run before opening the popup.
  --after-close <hook>        Hook to run after closing the popup.
  --toggle                    Always close the current popup instead of opening a new one.
  -[BCE]                      Flags passed to display-popup.
  -[bcdehsStTwxy] <value>     Options passed to display-popup.

EXAMPLES:

  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
```

### `@popup-focus`

**Example**:

A workaround for <https://github.com/tmux/tmux/issues/3991>.

```tmux
set -g @popup-before-open 'run "#{@popup-focus} --leave nvim"'
set -g @popup-after-close 'run "#{@popup-focus} --enter nvim"'
```

**Description**: Manually send focus enter or leave events. The name of the program that accepts
focus events can be specified and events are sent only if the current program matches any of the
names; if no name is provided, focus events are always sent.

```text
USAGE:

  focus.sh [OPTION]... [PROGRAM]...

OPTION:

  --enter           Send focus enter event. [Default mode]
  --leave           Send focus leave event.

EXAMPLES:

  focus.sh --enter nvim emacs
```

## ⚖️ License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.
