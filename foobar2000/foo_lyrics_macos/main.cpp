#include "stdafx.h"

DECLARE_COMPONENT_VERSION("Mac Lyrics", "0.1.1",
    "Native LRC lyrics window for foobar2000 on macOS.\n"
    "Loads timestamped or plain .lrc files next to the playing audio file.");

VALIDATE_COMPONENT_FILENAME("foo_lyrics_macos.component");
FOOBAR2000_IMPLEMENT_CFG_VAR_DOWNGRADE;
