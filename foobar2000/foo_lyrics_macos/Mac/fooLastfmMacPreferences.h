#pragma once

#ifdef __cplusplus
extern "C" {
#endif
void lyrics_window_initialize(void);
void lyrics_window_shutdown(void);
void lyrics_window_show(void);
void lyrics_window_set_track(const char *title, const char *artist, const char *path, double duration);
void lyrics_window_set_time(double seconds);
void lyrics_window_set_stopped(void);
#ifdef __cplusplus
}
#endif
