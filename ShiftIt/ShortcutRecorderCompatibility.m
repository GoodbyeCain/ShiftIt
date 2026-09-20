#import <ApplicationServices/ApplicationServices.h>

#import "ShortcutRecorderCompatibility.h"

static NSString *SRStringForSpecialKeyCode(NSInteger keyCode) {
    switch (keyCode) {
        case kVK_LeftArrow:
            return [NSString stringWithFormat:@"%C", (unichar)0x2190];
        case kVK_RightArrow:
            return [NSString stringWithFormat:@"%C", (unichar)0x2192];
        case kVK_UpArrow:
            return [NSString stringWithFormat:@"%C", (unichar)0x2191];
        case kVK_DownArrow:
            return [NSString stringWithFormat:@"%C", (unichar)0x2193];
        case kVK_Space:
            return @" ";
        case kVK_Return:
        case kVK_ANSI_KeypadEnter:
            return [NSString stringWithFormat:@"%C", (unichar)0x21A9];
        case kVK_Tab:
            return [NSString stringWithFormat:@"%C", (unichar)0x21E5];
        case kVK_Delete:
            return [NSString stringWithFormat:@"%C", (unichar)0x232B];
        case kVK_ForwardDelete:
            return [NSString stringWithFormat:@"%C", (unichar)0x2326];
        case kVK_Escape:
            return [NSString stringWithFormat:@"%C", (unichar)0x238B];
        case kVK_PageUp:
            return [NSString stringWithFormat:@"%C", (unichar)0x21DE];
        case kVK_PageDown:
            return [NSString stringWithFormat:@"%C", (unichar)0x21DF];
        case kVK_Home:
            return [NSString stringWithFormat:@"%C", (unichar)0x2196];
        case kVK_End:
            return [NSString stringWithFormat:@"%C", (unichar)0x2198];
        case kVK_F1:
            return @"F1";
        case kVK_F2:
            return @"F2";
        case kVK_F3:
            return @"F3";
        case kVK_F4:
            return @"F4";
        case kVK_F5:
            return @"F5";
        case kVK_F6:
            return @"F6";
        case kVK_F7:
            return @"F7";
        case kVK_F8:
            return @"F8";
        case kVK_F9:
            return @"F9";
        case kVK_F10:
            return @"F10";
        case kVK_F11:
            return @"F11";
        case kVK_F12:
            return @"F12";
        case kVK_F13:
            return @"F13";
        case kVK_F14:
            return @"F14";
        case kVK_F15:
            return @"F15";
        case kVK_F16:
            return @"F16";
        case kVK_F17:
            return @"F17";
        case kVK_F18:
            return @"F18";
        case kVK_F19:
            return @"F19";
        case kVK_F20:
            return @"F20";
        default:
            return nil;
    }
}

NSString *SRStringForKeyCode(NSInteger keyCode) {
    NSString *specialKey = SRStringForSpecialKeyCode(keyCode);
    if (specialKey) {
        return specialKey;
    }

    CGEventRef event = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keyCode, true);
    if (!event) {
        return nil;
    }

    UniChar characters[4] = {0};
    UniCharCount characterCount = 0;
    CGEventKeyboardGetUnicodeString(event, 4, &characterCount, characters);
    CFRelease(event);

    if (characterCount == 0) {
        return nil;
    }

    return [NSString stringWithCharacters:characters length:characterCount];
}

NSUInteger SRCocoaToCarbonFlags(NSUInteger cocoaFlags) {
    NSUInteger carbonFlags = 0;
    if (cocoaFlags & NSEventModifierFlagCommand) {
        carbonFlags |= cmdKey;
    }
    if (cocoaFlags & NSEventModifierFlagOption) {
        carbonFlags |= optionKey;
    }
    if (cocoaFlags & NSEventModifierFlagControl) {
        carbonFlags |= controlKey;
    }
    if (cocoaFlags & NSEventModifierFlagShift) {
        carbonFlags |= shiftKey;
    }
    return carbonFlags;
}

@implementation SRRecorderControl

@synthesize delegate = delegate_;

- (id)initWithFrame:(NSRect)frame {
    if (![super initWithFrame:frame]) {
        return nil;
    }

    keyCombo_ = SRMakeKeyCombo(-1, 0);
    recording_ = NO;
    [self setFocusRingType:NSFocusRingTypeExterior];
    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(130, 22);
}

- (KeyCombo)keyCombo {
    return keyCombo_;
}

- (void)setKeyCombo:(KeyCombo)keyCombo {
    keyCombo_ = keyCombo;
    [self setNeedsDisplay:YES];
}

- (NSString *)keyComboString {
    if (keyCombo_.code < 0) {
        return @"Record Shortcut";
    }

    NSMutableString *shortcut = [NSMutableString string];
    if (keyCombo_.flags & NSEventModifierFlagControl) {
        [shortcut appendFormat:@"%C", (unichar)kControlUnicode];
    }
    if (keyCombo_.flags & NSEventModifierFlagOption) {
        [shortcut appendFormat:@"%C", (unichar)kOptionUnicode];
    }
    if (keyCombo_.flags & NSEventModifierFlagShift) {
        [shortcut appendFormat:@"%C", (unichar)kShiftUnicode];
    }
    if (keyCombo_.flags & NSEventModifierFlagCommand) {
        [shortcut appendFormat:@"%C", (unichar)kCommandUnicode];
    }

    NSString *key = SRStringForKeyCode(keyCombo_.code);
    if (key) {
        [shortcut appendString:[key uppercaseString]];
    }
    return shortcut;
}

- (void)mouseDown:(NSEvent *)event {
    recording_ = YES;
    [[self window] makeFirstResponder:self];
    [self setNeedsDisplay:YES];
}

- (BOOL)resignFirstResponder {
    recording_ = NO;
    [self setNeedsDisplay:YES];
    return [super resignFirstResponder];
}

- (void)keyDown:(NSEvent *)event {
    NSUInteger modifiers = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
    NSInteger keyCode = [event keyCode];

    if (keyCode == kVK_Escape && modifiers == 0) {
        recording_ = NO;
        [self setNeedsDisplay:YES];
        return;
    }

    if ((keyCode == kVK_Delete || keyCode == kVK_ForwardDelete) && modifiers == 0) {
        keyCombo_ = SRMakeKeyCombo(-1, 0);
    } else {
        keyCombo_ = SRMakeKeyCombo(keyCode, modifiers);
    }

    recording_ = NO;
    [self setNeedsDisplay:YES];

    if ([delegate_ respondsToSelector:@selector(shortcutRecorder:keyComboDidChange:)]) {
        [delegate_ shortcutRecorder:self keyComboDidChange:keyCombo_];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = NSInsetRect([self bounds], 1, 1);
    NSBezierPath *background = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4 yRadius:4];
    [(recording_ ? [NSColor selectedControlColor] : [NSColor controlBackgroundColor]) setFill];
    [background fill];
    [[NSColor separatorColor] setStroke];
    [background stroke];

    NSString *title = recording_ ? @"Type Shortcut" : [self keyComboString];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]], NSFontAttributeName,
        (recording_ ? [NSColor alternateSelectedControlTextColor] : [NSColor controlTextColor]), NSForegroundColorAttributeName,
        nil];
    NSSize titleSize = [title sizeWithAttributes:attributes];
    NSPoint titleOrigin = NSMakePoint(NSMidX(bounds) - titleSize.width / 2,
                                     NSMidY(bounds) - titleSize.height / 2);
    [title drawAtPoint:titleOrigin withAttributes:attributes];

    if ([[self window] firstResponder] == self) {
        NSSetFocusRingStyle(NSFocusRingOnly);
        [background fill];
    }
}

@end
