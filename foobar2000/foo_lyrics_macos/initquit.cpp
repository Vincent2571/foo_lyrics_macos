#include "stdafx.h"
#include "Mac/fooLastfmMacPreferences.h"
#include <SDK/initquit.h>

namespace {
class lyrics_lifecycle : public initquit {
public:
    void on_init() override { lyrics_window_initialize(); }
    void on_quit() override { lyrics_window_shutdown(); }
};
static service_factory_single_t<lyrics_lifecycle> factory;
}
