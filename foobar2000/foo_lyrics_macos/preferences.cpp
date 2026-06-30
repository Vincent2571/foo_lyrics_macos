#include "stdafx.h"
#include "Mac/fooLastfmMacPreferences.h"
#include <SDK/menu.h>

namespace {
static const GUID command_guid = {0x7d6a1632, 0x192c, 0x4ad9, {0xa9,0x21,0x6c,0xf5,0x10,0x9b,0x36,0x22}};
class lyrics_menu : public mainmenu_commands {
public:
    t_uint32 get_command_count() override { return 1; }
    GUID get_command(t_uint32) override { return command_guid; }
    void get_name(t_uint32, pfc::string_base &out) override { out = "Show Lyrics Window"; }
    bool get_description(t_uint32, pfc::string_base &out) override { out = "Show the macOS lyrics window"; return true; }
    GUID get_parent() override { return mainmenu_groups::view; }
    void execute(t_uint32, service_ptr_t<service_base>) override { lyrics_window_show(); }
};
static mainmenu_commands_factory_t<lyrics_menu> factory;
}
