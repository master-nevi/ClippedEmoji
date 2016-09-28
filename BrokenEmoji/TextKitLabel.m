//
//  TextKitView.m
//  BrokenEmoji
//
//  Created by David Robles on 9/27/16.
//  Copyright © 2016 David Robles. All rights reserved.
//

#import "TextKitLabel.h"

@interface NSAttributedString (IntrinsicSize)

- (CGSize)intrinsicSize;

@end

@implementation NSAttributedString (IntrinsicSize)

- (CGSize)intrinsicSize {
    /* Documentation notes on [NSAttributedString size]:
     "In iOS 7 and later, this method returns fractional sizes; to use a returned size to size views, you must use raise its value to the nearest higher integer using the ceil function."
     */
    CGSize size = [self boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesFontLeading context:nil].size;
    size.width = ceil(size.width);
    size.height = ceil(size.height);
    return size;
}

@end

#define DEBUG_RENDERER 1
#define GNLog(fmt, ...) NSLog((@"%s [Line %d] \n\n" fmt @"\n\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

@interface TextKitViewRenderer : NSObject

@property(nonatomic) NSAttributedString *contents;

@end

@implementation TextKitViewRenderer {
    NSTextStorage *_textStorage;
    NSLayoutManager *_layoutManager;
    NSTextContainer *_textContainer;
    BOOL _needsUpdateSize;
}

- (CGSize)intrinsicContentSize {
    return [_contents intrinsicSize];
}

- (CGSize)renderedSize {
    return _textContainer.size;
}

- (void)drawInRect:(CGRect)frame {
    CGRect bounds = (CGRect){.size = frame.size};
    [self updateContainerSizeIfNeeded:bounds.size];
    [self updateTextStorage:_contents]; // reset text storage to the original contents
    
#if DEBUG_RENDERER
    NSMutableString *stringContentsDebug = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < _contents.length; i++) {
        [stringContentsDebug appendFormat:@"contents[%ld] = %c\n", (long)i, [_contents.string characterAtIndex:i]];
    }
    GNLog(@"processing chars:\n%@", stringContentsDebug);
#endif
    
    [_layoutManager ensureLayoutForBoundingRect:bounds inTextContainer:_textContainer];
    
    NSRange glyphRange = [_layoutManager glyphRangeForBoundingRect:bounds inTextContainer:_textContainer];
    if (glyphRange.length == 0) {
        return;
    }
    
    [_layoutManager invalidateGlyphsForCharacterRange:NSMakeRange(0, _textStorage.length) changeInLength:0 actualCharacterRange:NULL];
    [_layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, _textStorage.length)];
    
    glyphRange = [_layoutManager glyphRangeForBoundingRect:bounds inTextContainer:_textContainer];
    CGSize intrinsicSize = [_textStorage intrinsicSize];
    CGFloat centeredLineFragmentOriginY = CGRectGetMidY(bounds) - intrinsicSize.height/2.0;
    
#if DEBUG_RENDERER
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendString:[NSString stringWithFormat:@"\n textStorageIntrinsicSize: %@", NSStringFromCGSize(intrinsicSize)]];
    [description appendString:[NSString stringWithFormat:@"\n frame: %@", NSStringFromCGRect(frame)]];
    [description appendString:[NSString stringWithFormat:@"\n glyphRange: %@", NSStringFromRange(glyphRange)]];
    [description appendString:[NSString stringWithFormat:@"\n intrinsicSize: %@", NSStringFromCGSize([self intrinsicContentSize])]];
    [description appendString:[NSString stringWithFormat:@"\n textStorage.description: %@", _textStorage.description]];
    GNLog(@"%@", description);
#endif
    [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:frame.origin];
    [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:CGPointMake(frame.origin.x, centeredLineFragmentOriginY)];
}

#pragma mark - Private lib

- (void)setContents:(NSTextStorage *)contents {
    if (!_textStorage) {
        NSLayoutManager *manager = [[NSLayoutManager alloc] init];
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeZero]; // No limitation
        _textStorage = [[NSTextStorage alloc] init];
        [_textStorage addLayoutManager:manager];
        [manager addTextContainer:container];
        _layoutManager = manager;
        _textContainer = container;
        _textContainer.lineFragmentPadding = 0;
        _textContainer.maximumNumberOfLines = 1;
        _textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    _contents = contents;
    _needsUpdateSize = YES;
}

- (void)updateTextStorage:(NSAttributedString *)contents {
    [_textStorage replaceCharactersInRange:NSMakeRange(0, [_textStorage length]) withAttributedString:contents];
}

- (void)updateContainerSizeIfNeeded:(CGSize)size {
    if (!CGSizeEqualToSize(size, _textContainer.size)) {
        _needsUpdateSize = YES;
    }
    
    if (!_needsUpdateSize) {
        return;
    }
    
    _textContainer.size = size;
    _needsUpdateSize = NO;
}

@end

@implementation TextKitLabel {
    TextKitViewRenderer *_renderer;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _renderer = [[TextKitViewRenderer alloc] init];
}

#pragma mark - Properties

- (void)setAttributedText:(NSAttributedString *)attributedText {
    _renderer.contents = attributedText;
    
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
}

- (NSAttributedString *)attributedText {
    return _renderer.contents;
}

#pragma mark - UIView overrides

- (void)drawRect:(CGRect)rect {
    [_renderer drawInRect:(CGRect){.size = rect.size}];
}

- (CGSize)intrinsicContentSize {
    return [_renderer intrinsicContentSize];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.bounds.size, [_renderer renderedSize])) {
        [self setNeedsDisplay];
    }
}

@end
