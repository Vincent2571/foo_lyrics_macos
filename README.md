# Mac Lyrics for foobar2000

Native Apple Silicon lyrics component for foobar2000 2.x on macOS.

## Install

1. Open foobar2000 → Preferences → Components.
2. Click `+` and select `foo_lyrics_macos.component`.
3. Restart foobar2000.
4. Play a local track. The lyrics window opens automatically; it can also be opened from View → Show Lyrics Window.

## Lyrics location

For `/Music/Artist/Song.flac`, use either:

- `/Music/Artist/Song.lrc`
- `/Music/Artist/lyrics/Song.lrc`

Timestamped LRC lines such as `[01:23.45]Text` are synchronized precisely. Plain-text LRC files use estimated per-line timing based on track duration and are labeled `估算同步`.

## Build

Run `./script/build_and_run.sh --verify`. The component is staged in `dist/`.

This MVP is local-only. Online lyric search and saving are planned for a later version.
