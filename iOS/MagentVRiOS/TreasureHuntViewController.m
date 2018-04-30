/*
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "TreasureHuntViewController.h"

#import "TreasureHuntRenderer.h"

#import <GVRKit/GVRKit.h>

@interface TreasureHuntViewController ()<GVRRendererViewControllerDelegate> {
}
@end

@implementation TreasureHuntViewController
int agent_view_num;
- (void)viewDidLoad {
    
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Message" preferredStyle:UIAlertControllerStyleAlert];
//    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
//        textField.placeholder = @"Enter agent number(0~1249):";
//        textField.secureTextEntry = YES;
//    }];
//    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        NSArray * textfields = alert.textFields;
//        UITextField * namefield = textfields[0];
//        NSLog(@"%@",namefield.text);
//        agent_view_num = [namefield.text intValue];
//    }]];
//    [self presentViewController:alert animated:YES completion:nil];
    
  TreasureHuntRenderer *renderer = [[TreasureHuntRenderer alloc] init];

  // Embedded (widget) view with its own view controller.
  GVRRendererViewController *viewController =
      [[GVRRendererViewController alloc] initWithRenderer:renderer];
  viewController.delegate = self;
  viewController.view.frame = CGRectMake(20, 50, self.view.bounds.size.width - 40, 200);
  viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:viewController.view];
  [self addChildViewController:viewController];
}

#pragma mark - GVRRendererViewControllerDelegate

- (GVRRenderer *)rendererForDisplayMode:(GVRDisplayMode)displayMode {
  // Always present (not push) view controller for fullscreen landscape right VR mode.
  return [[TreasureHuntRenderer alloc] init];
}

@end
