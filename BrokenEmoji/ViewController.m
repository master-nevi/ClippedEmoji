//
//  ViewController.m
//  BrokenEmoji
//
//  Created by David Robles on 9/27/16.
//  Copyright © 2016 David Robles. All rights reserved.
//

#import "ViewController.h"
#import "TextKitLabel.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *myLabel;
@property (weak, nonatomic) IBOutlet UITextField *myTextField;
@property (weak, nonatomic) IBOutlet TextKitLabel *myTextKitLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *mainInputField;
@property (weak, nonatomic) IBOutlet UIButton *workaroundButton;
@property (weak, nonatomic) IBOutlet UIButton *breakButton;

@end

@implementation ViewController {
    CGFloat _keyboardEncroachmentInView;
    NSDictionary *_textAttributes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIFont *font = [UIFont systemFontOfSize:30 weight:UIFontWeightRegular];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    _textAttributes = @{
                                 NSParagraphStyleAttributeName : paragraphStyle,
                                 NSForegroundColorAttributeName : [UIColor blueColor],
                                 NSFontAttributeName : font};
    
    [self.mainInputField addTarget:self action:@selector(listTextFieldHasChanged) forControlEvents:UIControlEventEditingChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    NSString *startText = @"😊😔☺️😏";
    [self applyStringToViews:startText applyWorkaround:NO];
    self.mainInputField.text = startText;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)listTextFieldHasChanged {
    [self applyStringToViews:self.mainInputField.text applyWorkaround:NO];
}

- (void)applyStringToViews:(NSString *)string applyWorkaround:(BOOL)applyWorkaround {
    NSAttributedString *attributedString = ({
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:_textAttributes];
        [attributedString fixAttributesInRange:NSMakeRange(0, [attributedString length])];
        if (applyWorkaround) {
            [attributedString enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, [attributedString length]) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if ([font.fontName isEqualToString:@".AppleColorEmojiUI"]) {
                    [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AppleColorEmoji" size:font.pointSize] range:range];
                }
            }];
        }
        
        attributedString;
    });
    
    self.breakButton.enabled = applyWorkaround;
    self.workaroundButton.enabled = !applyWorkaround;
    
    [self applyAttributedStringToViews:attributedString];
}

- (void)applyAttributedStringToViews:(NSAttributedString *)attributedString {
    self.myLabel.attributedText = attributedString;
    self.myTextField.attributedText = attributedString;
    self.myTextKitLabel.attributedText = attributedString;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    CGRect frameEnd = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationOptions animationOptions = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
    CGFloat animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect viewFrameInWindowCoordinates = [self.view convertRect:self.view.bounds toView:self.view.window];
    CGFloat keyboardEncroachmentInView = CGRectGetMaxY(viewFrameInWindowCoordinates) - CGRectGetMinY(frameEnd);
    CGFloat delta = keyboardEncroachmentInView - _keyboardEncroachmentInView;
    _keyboardEncroachmentInView = keyboardEncroachmentInView;
    
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:animationOptions
                     animations:^{
                         CGFloat insetBottom = self.scrollView.contentInset.bottom;
                         insetBottom += delta;
                         self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, insetBottom, 0);
                         [self.view layoutIfNeeded];
                     } completion:nil];
}

- (IBAction)workaroundButtonTapped:(id)sender {
    [self applyStringToViews:self.mainInputField.text applyWorkaround:YES];
}

- (IBAction)breakTextFieldTapped:(id)sender {
    [self applyStringToViews:self.mainInputField.text applyWorkaround:NO];
}

- (IBAction)backgroundTapped:(UITapGestureRecognizer *)gestureRecognizer {
    [self.view endEditing:YES];
}

@end
