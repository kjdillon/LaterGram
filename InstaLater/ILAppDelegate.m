//
//  ILAppDelegate.m
//  InstaLater
//
//  Created by Kyle Dillon on 7/16/14.
//  Copyright (c) 2014 KJDev. All rights reserved.
//

#import "ILAppDelegate.h"
#import "ILViewController.h"
#import "ILPostViewController.h"

@implementation ILAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    application.applicationIconBadgeNumber = 0;
    
    /*
    // Handle launching from a notification
    UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotif) {
        NSLog(@"Recieved Notification %@",localNotif);
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ILPostViewController *postVC = [storyboard instantiateViewControllerWithIdentifier:@"postVC"];
        postVC.urlString = [[localNotif userInfo] objectForKey:@"postURLString"];
        postVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.window.rootViewController presentModalViewController:postVC animated:YES];
    }
     */
    
    return YES;
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    // Handle the notificaton when the app is running
    /*
    NSLog(@"Recieved Notification %@",notif);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ILPostViewController *postVC = [storyboard instantiateViewControllerWithIdentifier:@"postVC"];
    postVC.urlString = [[notif userInfo] objectForKey:@"postURLString"];
    postVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentModalViewController:postVC animated:YES];
     */
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    NSLog(@"app will enter foreground");
    NSLog(@"app did become active");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
