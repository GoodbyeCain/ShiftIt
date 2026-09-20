#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

typedef struct _KeyCombo {
    NSUInteger flags;
    NSInteger code;
} KeyCombo;

FOUNDATION_STATIC_INLINE KeyCombo SRMakeKeyCombo(NSInteger code, NSUInteger flags) {
    KeyCombo keyCombo;
    keyCombo.code = code;
    keyCombo.flags = flags;
    return keyCombo;
}

NSString *SRStringForKeyCode(NSInteger keyCode);
NSUInteger SRCocoaToCarbonFlags(NSUInteger cocoaFlags);

@class SRRecorderControl;

@interface NSObject (SRRecorderDelegate)

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo;

@end

@interface SRRecorderControl : NSControl {
@private
    id delegate_;
    KeyCombo keyCombo_;
    BOOL recording_;
}

@property(assign) id delegate;

- (KeyCombo)keyCombo;
- (void)setKeyCombo:(KeyCombo)keyCombo;
- (NSString *)keyComboString;

@end
