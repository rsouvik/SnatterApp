//
//  QAAppDelegate.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/20/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIBaseViewController;

@interface QAAppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIBaseViewController* baseViewController;
@property (strong, nonatomic) UINavigationController *navigationController;

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
