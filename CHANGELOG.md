# Changelog

All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

## [v0.3.0](https://github.com/loichyan/tmux-toggle-popup/compare/v0.2.0..v0.3.0) - 2024-10-21

### ⚠️ Breaking Changes

- Use xargs(1) and printf(1) to parse tmux commands ([#8](https://github.com/loichyan/tmux-toggle-popup/pull/8)). This allows users to input `;` directly as the command delimiter without worrying about Bash's interpretation. The new parser may yield results that differ from the previous version, although this is usually not the case.

### ✨ Highlights

- We've implemented several improvements to make it easier for other programs to integrate with this plugin ([#5](https://github.com/loichyan/tmux-toggle-popup/pull/5), [#9](https://github.com/loichyan/tmux-toggle-popup/pull/9)). You can now override popup global options on the fly using the newly added arguments for `@popup-toggle`.
- This release also includes some fixes to address the changes in `display-popup` introduced in tmux versions 3.5 and 3.5a ([#14](https://github.com/loichyan/tmux-toggle-popup/pull/14)).

### ⛰️ Features

- [**breaking**] Support bind additional toggle keys in popups - @loichyan - [#9](https://github.com/loichyan/tmux-toggle-popup/pull/9)
- [**breaking**] Improve hooks parsing and escaping - @loichyan - [#8](https://github.com/loichyan/tmux-toggle-popup/pull/8)
- Support override global options through the toggle script - @cenk1cenk2 - [#5](https://github.com/loichyan/tmux-toggle-popup/pull/5)
- Set a env variable to identify popup servers - @loichyan - [d95d654](https://github.com/loichyan/tmux-toggle-popup/commit/d95d654f3eee8f1b9e86ebc000a9718305a442ce)
- Support autostart popup server - @loichyan - [13bb98a](https://github.com/loichyan/tmux-toggle-popup/commit/13bb98a31debe4d7ca62b2f05e1401d93af53e23)

### 🐛 Bug Fixes

- Improve workarounds for default shell of popups - @loichyan - [#17](https://github.com/loichyan/tmux-toggle-popup/pull/17)
- Do not clear the popup opened flag before detaching - @loichyan - [#16](https://github.com/loichyan/tmux-toggle-popup/pull/16)
- Revert to `default-shell` promptly - @loichyan - [#15](https://github.com/loichyan/tmux-toggle-popup/pull/15)
- Propagate user's default shell to popup servers - @loichyan - [c662850](https://github.com/loichyan/tmux-toggle-popup/commit/c6628500e001997bbd8c45442cea5ed3d1d9b204)
- Ensure popup commands are interpreted by sh - @loichyan - [9d4dc82](https://github.com/loichyan/tmux-toggle-popup/commit/9d4dc82bf8b682e139cd0a2b3e91abf75ef28b4e)
- The first argument is eaten in `xargs bash -c` - @loichyan - [d50e9d5](https://github.com/loichyan/tmux-toggle-popup/commit/d50e9d58a5431e9bff787463edb8aaec4a5caae2)
- Try to fix Bash errors on macOS - @loichyan - [9148507](https://github.com/loichyan/tmux-toggle-popup/commit/9148507d16e20768d3211555d1592ac9d88d110d)
- Respect the user's `@popup-autostart` setting - @loichyan - [#11](https://github.com/loichyan/tmux-toggle-popup/pull/11)
- Escape `$session_args` before passing to tmux - @cenk1cenk2 - [#7](https://github.com/loichyan/tmux-toggle-popup/pull/7)
- Forward environment overrides to popup sessions - @loichyan - [#6](https://github.com/loichyan/tmux-toggle-popup/pull/6)
- Always retrieve option values from global - @loichyan - [61789c7](https://github.com/loichyan/tmux-toggle-popup/commit/61789c7b22fc6428a3248575503d65d88841de73)

### 📚 Documentation

- Use git-cliff to generate changelogs - @loichyan - [#18](https://github.com/loichyan/tmux-toggle-popup/pull/18)
- Fix wrong default value of `@popup-on-init` - @loichyan - [4190348](https://github.com/loichyan/tmux-toggle-popup/commit/4190348f56bafbfb74d0e4ef779bce22f94c44a6)
- Move examples after descriptions - @loichyan - [f262873](https://github.com/loichyan/tmux-toggle-popup/commit/f26287301f3e1a6a9c747e4170102114b3d44265)
- Display shorter links - @loichyan - [631d208](https://github.com/loichyan/tmux-toggle-popup/commit/631d20835269e1bf15abfdccde6477e19dcfb6cd)
- Update README - @loichyan - [95db7e1](https://github.com/loichyan/tmux-toggle-popup/commit/95db7e1108336576b82a90e57346eec25e1b7c43)
- Fix wrong issue ID - @loichyan - [6b45025](https://github.com/loichyan/tmux-toggle-popup/commit/6b45025101aa047ad470f28ac3bb33f6fc7c2932)

### 🚜 Refactor

- Use `==` in bash conditions - @loichyan - [4ab9467](https://github.com/loichyan/tmux-toggle-popup/commit/4ab946735ca4c67869825cadc7b70673d4500167)
- Always use Bash's condition syntax - @loichyan - [397038e](https://github.com/loichyan/tmux-toggle-popup/commit/397038e5cbbca5d5d1d3ca246ccd0c2e33554df2)

### ⚙️ Miscellaneous Tasks

- Auto release with GitHub Actions - @loichyan - [#19](https://github.com/loichyan/tmux-toggle-popup/pull/19)
- Set up GitHub Actions to run tests - @loichyan - [cb93148](https://github.com/loichyan/tmux-toggle-popup/commit/cb93148f70764842c30926c665849bd5ede507ba)

### ❤️ New Contributors

- @cenk1cenk2 made their first contribution in [#7](https://github.com/loichyan/tmux-toggle-popup/pull/7)

## [v0.2.0](https://github.com/loichyan/tmux-toggle-popup/compare/v0.1.0..v0.2.0) - 2024-06-05

### ⚠️ Breaking Changes

- Tmux commands are parsed by Bash(1), thus semicolons in hooks (`@popup-on-open` and `@popup-on-close`) must now be explicitly escaped or quoted ([#1](https://github.com/loichyan/tmux-toggle-popup/pull/1)).
- `@popup-on-open` is renamed to `@popup-on-init` ([#2](https://github.com/loichyan/tmux-toggle-popup/pull/2)).
- `@popup-on-close` is removed, as it cannot handle popup exits. Instead, consider setting the `client-detached` and `pane-exited` hooks in `@popup-on-init` ([#2](https://github.com/loichyan/tmux-toggle-popup/pull/2)).

### ✨ Highlights

- Add two new hooks: `@popup-before-open` and `@popup-after-close` ([#2](https://github.com/loichyan/tmux-toggle-popup/pull/2)).
- Add `@popup-focus`, primarily used as a workaround of [tmux/tmux#3991](https://github.com/tmux/tmux/issues/3991) ([#3](https://github.com/loichyan/tmux-toggle-popup/pull/3)).

### ⛰️ Features

- (**keybinding**) Add `@popup-focus` to manually fire focus events by @loichyan in [7002950](https://github.com/loichyan/tmux-toggle-popup/commit/700295042f452354a262ebd8941d7a3948229102)
- (**hook**) Add `@popup-before-open` and `@popup-after-close` by @loichyan in [f091b1b](https://github.com/loichyan/tmux-toggle-popup/commit/f091b1b02a5fb2a99a1c85c0c77afe242ecd1991)
- (**toggle**) Close popup if no arguments given by @loichyan in [5ef9ea4](https://github.com/loichyan/tmux-toggle-popup/commit/5ef9ea4d5c103ff8786722221eca939ef3dc1ea5)

### 🐛 Bug Fixes

- (**toggle**) Remove output of tmux in popup by @loichyan in [5eb66cd](https://github.com/loichyan/tmux-toggle-popup/commit/5eb66cd17ddaa030d4ea675513322aa1702d92c8)
- (**toggle**) Print help to stdout by @loichyan in [57dafb3](https://github.com/loichyan/tmux-toggle-popup/commit/57dafb3891bae7eb9bddf57d46c43636bddfa745)
- (**options**) Show inherited options by @loichyan in [2d1ce82](https://github.com/loichyan/tmux-toggle-popup/commit/2d1ce823e984111dff7ed880606140baa14f347f)

### 📚 Documentation

- Minor tweaks by @loichyan in [1bf5b26](https://github.com/loichyan/tmux-toggle-popup/commit/1bf5b263c33e35a46732705fbb609aa9f49e363c)
- Explain the positional parameters of `@popup-focus` by @loichyan in [07d60e7](https://github.com/loichyan/tmux-toggle-popup/commit/07d60e79c2905f6c682d24a25ed5cb3ac875c580)
- New section for "hooks" by @loichyan in [00a3f04](https://github.com/loichyan/tmux-toggle-popup/commit/00a3f047da4e64ba5e95bc1edb5d87224ffc17d5)
- Add descriptions to helper functions by @loichyan in [f3256bc](https://github.com/loichyan/tmux-toggle-popup/commit/f3256bc5cfe603b7bebd10bda6f76e1f137c46ef)

### 🚜 Refactor

- (**helpers**) Long options parsing by @loichyan in [08ce21f](https://github.com/loichyan/tmux-toggle-popup/commit/08ce21f89eb08847a2e7bd2a372de2e274f59623)
- (**hook**) [**breaking**] Rename `@popup-on-open` to `@popup-on-init` by @loichyan in [d37f1fd](https://github.com/loichyan/tmux-toggle-popup/commit/d37f1fd2a3982f4907a95baaa4d1e69e77a469b3)
- (**hook**) [**breaking**] Remove `@popup-on-close` by @loichyan in [5932e3b](https://github.com/loichyan/tmux-toggle-popup/commit/5932e3bf1113f2f47bb409ccfafc815957a40922)
- (**helpers**) [**breaking**] Improve command parsing by @loichyan in [86e49dd](https://github.com/loichyan/tmux-toggle-popup/commit/86e49dd9ea66a61845afc29a76ef78d6d4a41a0d)
- (**helpers**) Support additional variable definitions in `format` by @loichyan in [3090e11](https://github.com/loichyan/tmux-toggle-popup/commit/3090e115ea4e761bafa65046e47c93a1f7ce1d2e)
- (**toggle**) Use `getopts` to parse parameters by @loichyan in [b0adc2e](https://github.com/loichyan/tmux-toggle-popup/commit/b0adc2ebf7092915a8403ba1d3d0db45f753a1de)

### ⚙️ Miscellaneous Tasks

- (**shellcheck**) Annotate source path by @loichyan in [0adbb84](https://github.com/loichyan/tmux-toggle-popup/commit/0adbb843bfc44c9497212315ec52ab2e78a08003)
- Remove obsolete assets by @loichyan in [caf96dc](https://github.com/loichyan/tmux-toggle-popup/commit/caf96dc2ca9ad6509cc5620d6d2663d3c14b4863)

## [v0.1.0] - 2024-05-28

### ⛰️ Features

- Open all popups in a dedicated server by @loichyan in [10dd213](https://github.com/loichyan/tmux-toggle-popup/commit/10dd213b2e16e2fe3549c16d4a08f8d72802bec1)
- Copy from loichyan/dotfiles by @loichyan in [706a401](https://github.com/loichyan/tmux-toggle-popup/commit/706a401ea67a4b68d329c0a3655b6a25243e5883)

### 📚 Documentation

- Add a demo video by @loichyan in [658abaf](https://github.com/loichyan/tmux-toggle-popup/commit/658abaf17dc957e62f749457e8277bcfdf48fc8b)
- Add manual by @loichyan in [8c50b5b](https://github.com/loichyan/tmux-toggle-popup/commit/8c50b5b180e55717a624a3eb3ad6ffc40ffcd173)

### 🚜 Refactor

- [**breaking**] Rename `@popup-{name}-opened` to `@__popup_opened` by @loichyan in [0a126f9](https://github.com/loichyan/tmux-toggle-popup/commit/0a126f99772415f8bfc6f2031d557abb260bd71e)
- (**options**) Support multiple commands in hooks by @loichyan in [09d7d9f](https://github.com/loichyan/tmux-toggle-popup/commit/09d7d9f7798f17403dc61640b82f8254af9d7510)
- (**options**) Rename `@popup-format` to `@popup-id-format` by @loichyan in [8fff1f7](https://github.com/loichyan/tmux-toggle-popup/commit/8fff1f790e49a8308a57a8a32d217f74726d7f5a)
- (**keybindings**) Bind `@popup-toggle` to toggle popups by @loichyan in [803a751](https://github.com/loichyan/tmux-toggle-popup/commit/803a7515df97e931830d90a0d25ec27812368711)

### ⚙️ Miscellaneous Tasks

- Initial commit by @loichyan in [a65dc33](https://github.com/loichyan/tmux-toggle-popup/commit/a65dc33b84a0953a3dee4580ebb2729e460f2163)

<!-- generated by git-cliff -->
