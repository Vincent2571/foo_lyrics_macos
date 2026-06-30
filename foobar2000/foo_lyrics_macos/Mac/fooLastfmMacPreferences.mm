#import "fooLastfmMacPreferences.h"
#import <Cocoa/Cocoa.h>

@interface FB2KLyricsLine : NSObject
@property double time;
@property(copy) NSString *text;
@end
@implementation FB2KLyricsLine
@end

@interface FB2KLyricsController : NSWindowController
@property(strong) NSTextField *heading;
@property(strong) NSTextView *textView;
@property(strong) NSArray<FB2KLyricsLine *> *lines;
@property NSInteger activeLine;
@property BOOL estimatedTiming;
@end

@implementation FB2KLyricsController
- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 560, 520)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable |
                  NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO];
    if ((self = [super initWithWindow:window])) {
        window.title = @"Lyrics";
        window.minSize = NSMakeSize(360, 260);
        [window center];
        NSView *root = window.contentView;

        _heading = [NSTextField labelWithString:@"等待播放…"];
        _heading.font = [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];
        _heading.alignment = NSTextAlignmentCenter;
        _heading.translatesAutoresizingMaskIntoConstraints = NO;

        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
        scroll.hasVerticalScroller = YES;
        scroll.drawsBackground = NO;
        scroll.translatesAutoresizingMaskIntoConstraints = NO;
        _textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
        _textView.editable = NO;
        _textView.selectable = YES;
        _textView.drawsBackground = NO;
        _textView.textContainerInset = NSMakeSize(24, 28);
        _textView.textContainer.widthTracksTextView = YES;
        _textView.autoresizingMask = NSViewWidthSizable;
        scroll.documentView = _textView;
        [root addSubview:_heading];
        [root addSubview:scroll];
        [NSLayoutConstraint activateConstraints:@[
            [_heading.topAnchor constraintEqualToAnchor:root.topAnchor constant:15],
            [_heading.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:16],
            [_heading.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-16],
            [scroll.topAnchor constraintEqualToAnchor:_heading.bottomAnchor constant:10],
            [scroll.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
            [scroll.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
            [scroll.bottomAnchor constraintEqualToAnchor:root.bottomAnchor]
        ]];
        _lines = @[];
        _activeLine = -1;
    }
    return self;
}

- (NSString *)localPathFromFoobarPath:(NSString *)path {
    if ([path hasPrefix:@"file://"]) return [NSURL URLWithString:path].path;
    return path;
}

- (NSArray<FB2KLyricsLine *> *)parseLRC:(NSString *)content {
    NSMutableArray *result = [NSMutableArray array];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d{1,3}):(\\d{2})(?:[\\.:](\\d{1,3}))?\\]" options:0 error:nil];
    for (NSString *raw in [content componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:raw options:0 range:NSMakeRange(0, raw.length)];
        if (matches.count == 0) continue;
        NSUInteger end = matches.lastObject.range.location + matches.lastObject.range.length;
        NSString *text = [[raw substringFromIndex:end] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        for (NSTextCheckingResult *match in matches) {
            double minute = [[raw substringWithRange:[match rangeAtIndex:1]] doubleValue];
            double second = [[raw substringWithRange:[match rangeAtIndex:2]] doubleValue];
            double fraction = 0;
            NSRange fr = [match rangeAtIndex:3];
            if (fr.location != NSNotFound) {
                NSString *digits = [raw substringWithRange:fr];
                fraction = digits.doubleValue / pow(10.0, digits.length);
            }
            FB2KLyricsLine *line = [FB2KLyricsLine new];
            line.time = minute * 60 + second + fraction;
            line.text = text.length ? text : @" ";
            [result addObject:line];
        }
    }
    [result sortUsingComparator:^NSComparisonResult(FB2KLyricsLine *a, FB2KLyricsLine *b) {
        return a.time < b.time ? NSOrderedAscending : (a.time > b.time ? NSOrderedDescending : NSOrderedSame);
    }];
    return result;
}

- (NSArray<FB2KLyricsLine *> *)estimatedLinesForText:(NSString *)content duration:(double)duration {
    NSMutableArray<NSString *> *texts = [NSMutableArray array];
    for (NSString *raw in [content componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *line = [raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (line.length) [texts addObject:line];
    }
    NSMutableArray<FB2KLyricsLine *> *result = [NSMutableArray array];
    if (texts.count == 0) return result;
    // Reserve a short intro/outro. This is deliberately an approximation for plain-text lyrics.
    double start = MIN(8.0, duration * 0.04);
    double usable = MAX(1.0, duration - start - MIN(8.0, duration * 0.03));
    double step = usable / texts.count;
    for (NSUInteger i = 0; i < texts.count; i++) {
        FB2KLyricsLine *line = [FB2KLyricsLine new];
        line.time = start + i * step;
        line.text = texts[i];
        [result addObject:line];
    }
    return result;
}

- (void)setTrackTitle:(NSString *)title artist:(NSString *)artist path:(NSString *)path duration:(double)duration {
    self.heading.stringValue = artist.length ? [NSString stringWithFormat:@"%@ — %@", title, artist] : title;
    NSString *audio = [self localPathFromFoobarPath:path];
    NSString *base = [audio stringByDeletingPathExtension];
    NSString *name = base.lastPathComponent;
    NSString *folder = base.stringByDeletingLastPathComponent;
    NSArray *candidates = @[[base stringByAppendingPathExtension:@"lrc"],
                            [[folder stringByAppendingPathComponent:@"lyrics"] stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"lrc"]]];
    NSString *content = nil;
    NSString *found = nil;
    for (NSString *candidate in candidates) {
        content = [NSString stringWithContentsOfFile:candidate encoding:NSUTF8StringEncoding error:nil];
        if (!content) content = [NSString stringWithContentsOfFile:candidate usedEncoding:nil error:nil];
        if (content) { found = candidate; break; }
    }
    self.activeLine = -1;
    if (!content) {
        self.lines = @[];
        self.textView.string = [NSString stringWithFormat:@"未找到本地歌词\n\n请将歌词保存为：\n%@", candidates.firstObject];
    } else {
        self.lines = [self parseLRC:content];
        self.estimatedTiming = self.lines.count == 0;
        if (self.estimatedTiming) {
            self.lines = [self estimatedLinesForText:content duration:duration];
            self.heading.stringValue = [self.heading.stringValue stringByAppendingString:@"  ·  估算同步"];
        }
        NSMutableArray *texts = [NSMutableArray array];
        for (FB2KLyricsLine *line in self.lines) [texts addObject:line.text];
        self.textView.string = [texts componentsJoinedByString:@"\n\n"];
        self.window.representedFilename = found;
    }
    [self applyHighlight:-1];
    [self showWindow:nil];
}

- (void)applyHighlight:(NSInteger)index {
    NSMutableAttributedString *value = [[NSMutableAttributedString alloc] initWithString:self.textView.string];
    NSRange all = NSMakeRange(0, value.length);
    [value addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:19 weight:NSFontWeightRegular],
                           NSForegroundColorAttributeName:NSColor.secondaryLabelColor,
                           NSParagraphStyleAttributeName:[self paragraphStyle]} range:all];
    if (index >= 0 && index < (NSInteger)self.lines.count) {
        NSArray *parts = [self.textView.string componentsSeparatedByString:@"\n\n"];
        NSUInteger location = 0;
        for (NSInteger i = 0; i < index; i++) location += [parts[i] length] + 2;
        NSRange range = NSMakeRange(location, [parts[index] length]);
        [value addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:22 weight:NSFontWeightSemibold],
                               NSForegroundColorAttributeName:NSColor.controlAccentColor} range:range];
        [self.textView.textStorage setAttributedString:value];
        [self.textView.layoutManager ensureLayoutForTextContainer:self.textView.textContainer];
        NSRange glyphRange = [self.textView.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
        NSRect lineRect = [self.textView.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textView.textContainer];
        NSClipView *clip = self.textView.enclosingScrollView.contentView;
        CGFloat targetY = MAX(0, NSMidY(lineRect) + self.textView.textContainerInset.height - NSHeight(clip.bounds) / 2.0);
        [clip scrollToPoint:NSMakePoint(0, targetY)];
        [self.textView.enclosingScrollView reflectScrolledClipView:clip];
    } else [self.textView.textStorage setAttributedString:value];
}

- (NSParagraphStyle *)paragraphStyle {
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    style.lineSpacing = 4;
    return style;
}

- (void)setPlaybackTime:(double)time {
    if (self.lines.count == 0) return;
    NSInteger next = -1;
    for (NSInteger i = 0; i < (NSInteger)self.lines.count; i++) {
        if (self.lines[i].time <= time + 0.05) next = i; else break;
    }
    if (next != self.activeLine) { self.activeLine = next; [self applyHighlight:next]; }
}
@end

static FB2KLyricsController *gLyrics;
static void onMain(dispatch_block_t block) { dispatch_async(dispatch_get_main_queue(), block); }

void lyrics_window_initialize(void) { onMain(^{ if (!gLyrics) gLyrics = [FB2KLyricsController new]; }); }
void lyrics_window_shutdown(void) { onMain(^{ [gLyrics close]; gLyrics = nil; }); }
void lyrics_window_show(void) { onMain(^{ if (!gLyrics) gLyrics = [FB2KLyricsController new]; [gLyrics showWindow:nil]; [gLyrics.window makeKeyAndOrderFront:nil]; }); }
void lyrics_window_set_track(const char *title, const char *artist, const char *path, double duration) {
    NSString *t = title ? [NSString stringWithUTF8String:title] : @"";
    NSString *a = artist ? [NSString stringWithUTF8String:artist] : @"";
    NSString *p = path ? [NSString stringWithUTF8String:path] : @"";
    onMain(^{ if (!gLyrics) gLyrics = [FB2KLyricsController new]; [gLyrics setTrackTitle:t artist:a path:p duration:duration]; });
}
void lyrics_window_set_time(double seconds) { onMain(^{ [gLyrics setPlaybackTime:seconds]; }); }
void lyrics_window_set_stopped(void) { onMain(^{ gLyrics.heading.stringValue = @"播放已停止"; }); }
