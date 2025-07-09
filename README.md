# 🌀 tmux-toggle-popup

A handy plugin to create toggleable popups.

[toggle-popup-demo.webm](https://github.com/user-attachments/assets/faf45582-50c5-4efb-86cb-1f1d0e4d95a9)

<details>
<summary>Information</summary>

- font: [0xProto](https://github.com/0xType/0xProto)
- tmux: [tmux-base16](https://github.com/loichyan/tmux-base16)
- Neovim: [Meowim](https://github.com/loichyan/Meowim)

</details>

## 📦 Installation

### Requirements

- tmux >= **3.4** (not tested on earlier versions)

### With [tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

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

Reload tmux environment with: `tmux source-file ~/.tmux.conf`. You should now be able to use the
plugin.

## 🚗 Quick start

Create keybindings to toggle your preferred shell and
[lazygit](https://github.com/jesseduffield/lazygit):

```tmux
bind -n M-t run "#{@popup-toggle} -Ed'#{pane_current_path}' -w75% -h75%"
bind -n M-g run "#{@popup-toggle} -Ed'#{pane_current_path}' -w90% -h90% --name=lazygit lazygit"
```

## ⌨️ Commands

Commands are shell scripts exported by this plugin, which you can bind keys to. The basic usage is
`tmux bind-key <key> run-shell '#{@command_name} ...<args>'`.

### `@popup-toggle`

**Description**: A shell script to toggle popups. When invoked in your working session, it opens a
reusable popup window identified by `--name`. It supports three modes to handle nested toggle calls,
namely when invoked in an opened popup with a different name specified:

1. `switch`: The default mode. Keep the popup window open and switch to the new popup.
2. `force-close`: Close the opened popup window. This is the expected behavior when the name matches
   or no arguments are provided.
3. `force-open`: Open a new popup window within the current one, i.e., popup-in-popup.

If you have set popup keybindings in your `.tmux.conf`, which should be loaded in both your default
server and the popup server, there's no need to worry about the toggle keys. For instance, if `M-t`
is bound to open a shell, you can press it to open a popup in your working session and then press it
again to close the popup.

However, if you wish to set a keybinding outside of `.tmux.conf`, it can get a bit tricky. You may
refer to [#5](https://github.com/loichyan/tmux-toggle-popup/pull/5) for more details. TL;DR, you can
pass your desired key(s) to `@popup-toggle` using `--toggle-key M-t`, and the script will handle the
necessary adjustments. You can also specify a different key table using `--toggle '-n M-t'` or
`--toggle '-Troot M-t'`.

```text
Usage:

  toggle.sh [OPTIONS] [POPUP_OPTIONS] [SHELL_COMMAND]...

Options:

  --name <name>               Popup name [Default: "default"]
  --id <id>                   Popup ID, default to the expanded ID format
  --toggle-mode <mode>        Action to handle nested calls [Default: "switch"]
  --toggle-key <key>          Bind additional keys to close the opened popup
  -[BCE]                      Flags passed to display-popup
  -[bcdehsStTwxy] <value>     Options passed to display-popup

Popup Options:

  Override global popup options on the fly.

  --socket-name <value>       Socket name
  --id-format <value>         Popup ID format
  --on-init <hook>            Command to run on popup initialization
  --before-open <hook>        Hook to run before opening the popup
  --after-close <hook>        Hook to run after closing the popup

Examples:

  toggle.sh -Ed'#{pane_current_path}' --name=bash bash
```

**Example**:

```tmux
bind -n M-t run "#{@popup-toggle} -Ed'#{pane_current_path}' -w75% -h75%"
```

### `@popup-focus`

**Description**: Manually send focus enter or leave events. The name of the program that accepts
focus events can be specified and events are sent only if the current program matches any of the
names; if no name is provided, focus events are always sent.

```text
Usage:

  focus.sh [OPTION]... [PROGRAM]...

Options:

  --enter      Send focus enter event [Default mode]
  --leave      Send focus leave event

Examples:

  focus.sh --enter nvim emacs
```

**Example**:

A workaround for [tmux/tmux#3991](https://github.com/tmux/tmux/issues/3991), which has been fixed in
[tmux/tmux@a869693405f9](https://github.com/tmux/tmux/commit/a869693405f99c8ca8e2da32a08534489ce165f2).

```tmux
set -g @popup-before-open 'run "#{@popup-focus} --leave nvim"'
set -g @popup-after-close 'run "#{@popup-focus} --enter nvim"'
```

## ⚙️ Options

### `@popup-socket-name`

**Default**: `popup`

**Description**: The socket name (`tmux -L {@popup-socket-name} ...`) of the server in which all
popup sessions are opened. Typically, it’s recommended to open popups in a standalone server, as it
may start many sessions for popups, which can be quite annoying when you open the session selector.

A special environment variable, `$TMUX_POPUP_SERVER`, is set to its value before the server starts,
which is used to identify popup servers. You can check this variable and load different
configurations in your `.tmux.conf`.

**Example**:

```tmux
# Configurations specified for popup servers
if '[ -n "$TMUX_POPUP_SERVER" ]' {
    set -g exit-empty off
    set -g status off
}
```

### `@popup-id-format`

**Default**: `#{b:socket_path}/#{session_name}/#{b:pane_current_path}/{popup_name}`

**Description**: A format string used to generate IDs for each popup, allowing you to customize how
popups are shared across sessions, windows, and panes. By default, popups are independent across
sessions, and in each session, popups are shared among the same project (identified by the directory
name). A placeholder named `{popup_name}` is substituted with the popup name during the expansion.

### `@popup-autostart`

**Default**: `off`

**Description**: If enabled, the designated tmux server for popups will start automatically.

### `@popup-toggle-mode`

**Default**: `switch`

**Description**: The default toggle mode of `@popup-toggle`.

## 🪝 Hooks

A hook consists of tmux commands. To write hooks, we support a limited version of `.tmux.conf`.

To elaborate further, each tmux command must be delimited by semicolons (`;`). You can use escaped
spaces (`\`) or quotes (either `'` or `"`) to prevent an individual argument from being split.
Additionally, you can nest different types of quotes within one another. Any character preceded by a
backslash (`\`) is treated as a literal escape, meaning that `\;` is interpreted as `;`. To input
`\;`, you need to escape the backslash, using `\\;`.

A hook will be executed either in the caller session (i.e., the session that calls `@popup-toggle`)
or in the popup session (i.e., the session where a popup resides).

**Example**:

```tmux
# Keep the server running and hide status bar.
set -g @popup-on-init '
  set exit-empty off ; set status off
'
# Bind to multiple commands should be escaped,
set -g @popup-on-init '
  bind -n M-1 display random\ text \\; display and\ more
'
# or quoted.
set -g @popup-on-init "
  bind -n M-2 \"display 'random text' ; display 'and more'\"
"
```

### `@popup-on-init`

**Default**: `set exit-empty off ; set status off`

**Description**: tmux commands executed in the popup each time after it is opened.

### `@popup-before-open`

**Default**: empty

**Description**: tmux commands executed in the caller each time before a popup is opened.

### `@popup-after-close`

**Default**: empty

**Description**: tmux commands executed in the caller each time after a popup is closed.

## ⚖️ License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.
