//
//  IncomingCallViewController.h
//  PjSip
//
//  Created by sunluwei on 16/7/11.
//  Copyright © 2016年 hador. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IncomingCallViewController : UIViewController

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, assign) NSInteger callId;

@end
