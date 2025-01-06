# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Here's a template for each release section. This file should only include changes that
are noticeable to end-users since the last release. For developers, this project follows
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) to track changes.

## [1.0.0] - YYYY-MM-DD

### Added

- (**breaking**) Always place breaking changes at the top.
- Append other changes in chronological order under the relevant subsections.

### Changed

### Deprecated

### Removed

### Fixed

### Security

[1.0.0]: https://github.com/user/repo/compare/v0.0.0..v1.0.0
-->

## [Unreleased]

### Added

- Add a new argument, `@popup-toggle --id <id>`, to set the ID of a popup directly ([#XX]).

## [0.4.0] - 2024-11-23

### Added

- Add a new toggle mode, `switch`, which always reuses the currently opened
  window when switching to another popup ([#21]).

### Changed

- (**breaking**) Replace `@popup-toggle --force` with `--toggle-mode=force-close` ([#21]).
- (**breaking**) Replace tmux variable `#{@popup_name}` in `@popup-id-format`
  with the `{popup_name}` placeholder ([#21]).

### Fixed

- Disable potential tmux messages from popups ([#23]).

[#21]: https://github.com/loichyan/tmux-toggle-popup/pull/21
[#23]: https://github.com/loichyan/tmux-toggle-popup/pull/23
[#XX]: https://github.com/loichyan/tmux-toggle-popup/pull/XX

## [0.3.0] - 2024-10-21

We've implemented several improvements to make it easier for other programs to
integrate with this plugin ([#5], [#9], thanks [@cenk1cenk2]). You can now
override popup global options on the fly using the newly added arguments of `@popup-toggle`.

### Added

- Support autostart popup server ([13bb98a]).
- Set an env variable to identify popup servers ([d95d654]).
- Support bind additional toggle keys in popups ([#9]).
- Support override global options through `@popup-toggle` ([#5]).

### Changed

- (**breaking**) Use xargs(1) and printf(1) to parse tmux commands ([#8]). This
  allows you to input `;` directly as the command delimiter without worrying
  about Bash's interpretation. The new parser may yield results that differ from
  the previous version, although this is usually not the case.

### Fixed

- Always retrieve option values from global ([61789c7]).
- Address the breaking changes in `display-popup` introduced in tmux versions
  3.5 and 3.5a ([#14]).

[#5]: https://github.com/loichyan/tmux-toggle-popup/pull/8
[#8]: https://github.com/loichyan/tmux-toggle-popup/pull/8
[#9]: https://github.com/loichyan/tmux-toggle-popup/pull/9
[#14]: https://github.com/loichyan/tmux-toggle-popup/pull/14
[13bb98a]: https://github.com/loichyan/tmux-toggle-popup/commit/13bb98a31debe4d7ca62b2f05e1401d93af53e23
[d95d654]: https://github.com/loichyan/tmux-toggle-popup/commit/d95d654f3eee8f1b9e86ebc000a9718305a442ce
[61789c7]: https://github.com/loichyan/tmux-toggle-popup/commit/61789c7b22fc6428a3248575503d65d88841de73
[@cenk1cenk2]: https://github.com/cenk1cenk2

## [0.2.0] - 2024-06-05

### Added

- Add two new hooks: `@popup-before-open` and `@popup-after-close` ([#2]).
- Add `@popup-focus`, primarily used as a workaround of [tmux/tmux#3991] ([#3]).
- Support close a popup if no argument passed to `@popup-toggle` ([5ef9ea4]).

### Changed

- (**breaking**) Use bash(1) to parse tmux commands, thus semicolons in hooks
  (`@popup-on-open` and `@popup-on-close`) must now be explicitly escaped or
  quoted ([#1]).
- (**breaking**) Rename `@popup-on-open` to `@popup-on-init` ([#2]).

### Removed

- (**breaking**) Remove `@popup-on-close`, as it cannot handle popup exits.
  Instead, consider setting the `client-detached` and `pane-exited` tmux hooks
  in `@popup-on-init` ([#2]).

### Fixed

- Hide messages of tmux commands in popups ([5eb66cd]).

[#1]: https://github.com/loichyan/tmux-toggle-popup/pull/1
[#2]: https://github.com/loichyan/tmux-toggle-popup/pull/2
[#3]: https://github.com/loichyan/tmux-toggle-popup/pull/3
[5ef9ea4]: https://github.com/loichyan/tmux-toggle-popup/commit/5ef9ea4d5c103ff8786722221eca939ef3dc1ea5
[5eb66cd]: https://github.com/loichyan/tmux-toggle-popup/commit/5eb66cd17ddaa030d4ea675513322aa1702d92c8
[tmux/tmux#3991]: https://github.com/tmux/tmux/issues/3991

## [0.1.0] - 2024-05-28

🎉 Initial release. See [README](https://github.com/loichyan/tmux-toggle-popup/blob/v0.1.0/README.md)
for more details.

[Unreleased]: https://github.com/loichyan/tmux-toggle-popup/compare/v0.4.0..HEAD
[0.4.0]: https://github.com/loichyan/tmux-toggle-popup/compare/v0.3.0..v0.4.0
[0.3.0]: https://github.com/loichyan/tmux-toggle-popup/compare/v0.2.0..v0.3.0
[0.2.0]: https://github.com/loichyan/tmux-toggle-popup/compare/v0.1.0..v0.2.0
[0.1.0]: https://github.com/loichyan/tmux-toggle-popup/releases/tag/v0.1.0
