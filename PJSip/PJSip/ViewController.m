//
//  ViewController.m
//  PjSip
//
//  Created by sunluwei on 16/7/11.
//  Copyright © 2016年 hador. All rights reserved.
//

#import "ViewController.h"
#import <pjsua-lib/pjsua.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *hostLbl;
@property (weak, nonatomic) IBOutlet UITextField *usernameLbl;
@property (weak, nonatomic) IBOutlet UITextField *passwordLbl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(__handleRegisterStatus:)
                                                 name:@"SIPRegisterStatusNotification"
                                               object:nil];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)__handleRegisterStatus:(NSNotification *)notification {
    pjsua_acc_id acc_id = [notification.userInfo[@"acc_id"] intValue];
    pjsip_status_code status = [notification.userInfo[@"status"] intValue];
    NSString *statusText = notification.userInfo[@"status_text"];
    
    if (status != PJSIP_SC_OK) {
        NSLog(@"登录失败, 错误信息: %d(%@)", status, statusText);
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:acc_id forKey:@"login_account_id"];
    [[NSUserDefaults standardUserDefaults] setObject:self.hostLbl.text forKey:@"server_uri"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self __switchToDialViewController];
}

- (void)__switchToDialViewController {
    UIViewController *dialViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DialViewController"];
    
    CATransition *transition = [[CATransition alloc] init];
    
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionFade;
    transition.duration  = 0.5;
    transition.removedOnCompletion = YES;
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow.layer addAnimation:transition forKey:@"change_view_controller"];
    
    keyWindow.rootViewController = dialViewController;
}

- (IBAction)loginClike {
    NSString *server = self.hostLbl.text;
    NSString *username = self.usernameLbl.text;
    NSString *password = self.passwordLbl.text;
    
    pjsua_acc_id acc_id;
    pjsua_acc_config cfg;
    
    pjsua_acc_config_default(&cfg);
    cfg.id = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", username, server].UTF8String);
    cfg.reg_uri = pj_str((char *)[NSString stringWithFormat:@"sip:%@", server].UTF8String);
    cfg.reg_retry_interval = 0;
    cfg.cred_count = 1;
    cfg.cred_info[0].realm = pj_str("*");
    cfg.cred_info[0].username = pj_str((char *)username.UTF8String);
    cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    cfg.cred_info[0].data = pj_str((char *)password.UTF8String);
    
    pj_status_t status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
    
    if (status != PJ_SUCCESS) {
        NSString *errorMessage = [NSString stringWithFormat:@"登录失败, 返回错误号:%d!", status];
        NSLog(@"register error: %@", errorMessage);
    }
    
}

@end
