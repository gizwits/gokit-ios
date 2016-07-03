//
//  GizPhoneCell.h
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GosPhoneCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextField *textInput;
@property (weak, nonatomic) IBOutlet UIButton *getVerifyCodeBtn;
@property (strong, nonatomic) id delegate;

@end

@protocol GizPhoneCellDelegate <NSObject>
@required

- (void)didSendCodeBtnPressed;

@end
