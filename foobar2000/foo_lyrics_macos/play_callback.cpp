#include "stdafx.h"
#include "Mac/fooLastfmMacPreferences.h"
#include <SDK/play_callback.h>

namespace {
static const char *meta_first(const file_info &info, const char *name) {
    const char *value = info.meta_get(name, 0);
    return value ? value : "";
}

class lyrics_playback_callback : public play_callback_static {
public:
    unsigned get_flags() override {
        return flag_on_playback_new_track | flag_on_playback_time |
               flag_on_playback_seek | flag_on_playback_stop;
    }
    void on_playback_new_track(metadb_handle_ptr track) override {
        file_info_impl info;
        if (!track->get_info(info)) return;
        lyrics_window_set_track(meta_first(info, "TITLE"), meta_first(info, "ARTIST"),
                                track->get_path(), info.get_length());
    }
    void on_playback_time(double time) override { lyrics_window_set_time(time); }
    void on_playback_seek(double time) override { lyrics_window_set_time(time); }
    void on_playback_stop(play_control::t_stop_reason) override { lyrics_window_set_stopped(); }
    void on_playback_starting(play_control::t_track_command, bool) override {}
    void on_playback_pause(bool) override {}
    void on_playback_edited(metadb_handle_ptr) override {}
    void on_playback_dynamic_info(const file_info &) override {}
    void on_playback_dynamic_info_track(const file_info &) override {}
    void on_volume_change(float) override {}
};
static service_factory_t<lyrics_playback_callback> factory;
}
