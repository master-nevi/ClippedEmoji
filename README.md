# ClippedEmoji

## Update from Apple
**Apple has acknowledged the bug, however could not recommend a workaround at this time. 😞**

## iOS 10.0
<img width="374" alt="clip-10 0" src="https://cloud.githubusercontent.com/assets/987706/18972179/fe36056a-864c-11e6-9dd0-d5da39c60b47.png">

## iOS 9.3
<img width="375" alt="clip-9 3" src="https://cloud.githubusercontent.com/assets/987706/18972178/fe32c6e8-864c-11e6-8197-9c4bd025b697.png">

**We've already opened a bug with Apple. See the following for more info on the bug:**
* https://openradar.appspot.com/radar?id=4998540401049600
* https://github.com/facebook/AsyncDisplayKit/issues/2304

## Current Workaround
```objective-c
    BOOL isIOS10OrGreater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10}];
    if (isIOS10OrGreater) {
      [_textStorage enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, _textStorage.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = (UIFont *)value;
        if ([font.fontName isEqualToString:@".AppleColorEmojiUI"]) {
          [_textStorage addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AppleColorEmoji" size:font.pointSize] range:range];
        }
      }];
    }
    
```
