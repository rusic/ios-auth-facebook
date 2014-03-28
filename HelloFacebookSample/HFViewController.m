/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "HFViewController.h"

#import <CoreLocation/CoreLocation.h>

#import "HFAppDelegate.h"

#import <UNIRest.h>

#import "ASIHTTPRequestConfig.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIProgressDelegate.h"
#import "ASICacheDelegate.h"
#import "ASIHTTPRequest.h"
//#import "ASIHTTPRequest.m"
#import "ASIDataCompressor.h"
//#import "ASIDataCompressor.m"
#import "ASIDataDecompressor.h"
//#import "ASIDataDecompressor.m"
#import "ASIFormDataRequest.h"
#import "ASIInputStream.h"
//#import "ASIInputStream.m"
//#import "ASIFormDataRequest.m"
#import "ASINetworkQueue.h"
//#import "ASINetworkQueue.m"
#import "ASIDownloadCache.h"
//#import "ASIDownloadCache.m"
#import "ASIAuthenticationDialog.h"
//#import "ASIAuthenticationDialog.m"
#import "Reachability.h"
//#import "Reachability.m"


@interface HFViewController () <FBLoginViewDelegate>

@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostStatus;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostPhoto;
@property (strong, nonatomic) IBOutlet UIButton *buttonPickFriends;
@property (strong, nonatomic) IBOutlet UIButton *buttonPickPlace;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;

@property (strong, nonatomic) NSString *rusic_participant_token;
@property (strong, nonatomic) NSString *image_id;

- (IBAction)postStatusUpdateClick:(UIButton *)sender;
- (IBAction)postPhotoClick:(UIButton *)sender;
- (IBAction)pickFriendsClick:(UIButton *)sender;
- (IBAction)pickPlaceClick:(UIButton *)sender;

- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error;


@end

@implementation HFViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create Login View so that the app will be granted "status_update" permission.
    FBLoginView *loginview = [[FBLoginView alloc] init];

    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
#ifdef __IPHONE_7_0
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        loginview.frame = CGRectOffset(loginview.frame, 5, 25);
    }
#endif
#endif
#endif
    loginview.delegate = self;

    [self.view addSubview:loginview];

    [loginview sizeToFit];
}

- (void)viewDidUnload {
    self.buttonPickFriends = nil;
    self.buttonPickPlace = nil;
    self.buttonPostPhoto = nil;
    self.buttonPostStatus = nil;
    self.labelFirstName = nil;
    self.loggedInUser = nil;
    self.profilePic = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - FBLoginViewDelegate

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // first get the buttons set for login mode
    self.buttonPostPhoto.enabled = YES;
    self.buttonPostStatus.enabled = YES;
    self.buttonPickFriends.enabled = YES;
    self.buttonPickPlace.enabled = YES;

    // "Post Status" available when logged on and potentially when logged off.  Differentiate in the label.
    [self.buttonPostStatus setTitle:@"Post Status Update (Logged On)" forState:self.buttonPostStatus.state];
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    // here we use helper properties of FBGraphUser to dot-through to first_name and
    // id properties of the json response from the server; alternatively we could use
    // NSDictionary methods such as objectForKey to get values from the my json object
    self.labelFirstName.text = [NSString stringWithFormat:@"Hello %@!", user.first_name];
    // setting the profileID property of the FBProfilePictureView instance
    // causes the control to fetch and display the profile picture for the user
    self.profilePic.profileID = user.id;
    self.loggedInUser = user;

    // Set up the headers including the X-API-Key provided by Rusic admin system
    NSDictionary* headers = @{
        @"accept": @"application/vnd.rusic.v1+json",
        @"X-API-Key": @"2a5e3e02c586ee2c21b4fb8346aece7d"
    };
    
    // Setup parameters for creating a new participant
    NSDictionary* parameters = @{
        @"participant[provider]": @"facebook",
        @"participant[uid]": user.id,
        @"participant[oauth_token]": [[[FBSession activeSession] accessTokenData] accessToken],
        @"participant[nickname]": user.username
    };
    
    // Post to the participant endpoint with the headers and parametes defined aboce
    [[UNIRest post:^(UNISimpleRequest* request) {
        [request setUrl:@"http://api.rusic.com/participants"];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        // Get the response body
        UNIJsonNode* body = [response body];
        
        // Create a dictionary of the response body
        NSDictionary* dic = [body JSONObject];
        
        // Set the participant token to the rusic_participant_token key
        self.rusic_participant_token = [dic objectForKey:@"rusic_participant_token"];
        
        // Log the token out
        NSLog(@"rusic_participant_token: %@", self.rusic_participant_token);
    }];
    
    
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // test to see if we can use the share dialog built into the Facebook application
    FBShareDialogParams *p = [[FBShareDialogParams alloc] init];
    p.link = [NSURL URLWithString:@"http://developers.facebook.com/ios"];
#ifdef DEBUG
    [FBSettings enableBetaFeatures:FBBetaFeaturesShareDialog];
#endif
    BOOL canShareFB = [FBDialogs canPresentShareDialogWithParams:p];
    BOOL canShareiOS6 = [FBDialogs canPresentOSIntegratedShareDialogWithSession:nil];

    self.buttonPostStatus.enabled = canShareFB || canShareiOS6;
    self.buttonPostPhoto.enabled = NO;
    self.buttonPickFriends.enabled = NO;
    self.buttonPickPlace.enabled = NO;

    // "Post Status" available when logged on and potentially when logged off.  Differentiate in the label.
    [self.buttonPostStatus setTitle:@"Post Status Update (Logged Off)" forState:self.buttonPostStatus.state];

    self.profilePic.profileID = nil;
    self.labelFirstName.text = nil;
    self.loggedInUser = nil;
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // see https://developers.facebook.com/docs/reference/api/errors/ for general guidance on error handling for Facebook API
    // our policy here is to let the login view handle errors, but to log the results
    NSLog(@"FBLoginView encountered an error=%@", error);
}

#pragma mark -

// Convenience method to perform some action that requires the "publish_actions" permissions.
- (void)performPublishAction:(void(^)(void))action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    action();
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled) {
                                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied"
                                                                                                        message:@"Unable to get permission to post"
                                                                                                       delegate:nil
                                                                                              cancelButtonTitle:@"OK"
                                                                                              otherButtonTitles:nil];
                                                    [alertView show];
                                                }
                                            }];
    } else {
        action();
    }

}

// Post Status Update button handler; will attempt different approaches depending upon configuration.
- (IBAction)postStatusUpdateClick:(UIButton *)sender {
    // Post a status update to the user's feed via the Graph API, and display an alert view
    // with the results or an error.

    NSURL *urlToShare = [NSURL URLWithString:@"http://developers.facebook.com/ios"];

    // This code demonstrates 3 different ways of sharing using the Facebook SDK.
    // The first method tries to share via the Facebook app. This allows sharing without
    // the user having to authorize your app, and is available as long as the user has the
    // correct Facebook app installed. This publish will result in a fast-app-switch to the
    // Facebook app.
    // The second method tries to share via Facebook's iOS6 integration, which also
    // allows sharing without the user having to authorize your app, and is available as
    // long as the user has linked their Facebook account with iOS6. This publish will
    // result in a popup iOS6 dialog.
    // The third method tries to share via a Graph API request. This does require the user
    // to authorize your app. They must also grant your app publish permissions. This
    // allows the app to publish without any user interaction.

    // If it is available, we will first try to post using the share dialog in the Facebook app
    FBAppCall *appCall = [FBDialogs presentShareDialogWithLink:urlToShare
                                                          name:@"Hello Facebook"
                                                       caption:nil
                                                   description:@"The 'Hello Facebook' sample application showcases simple Facebook integration."
                                                       picture:nil
                                                   clientState:nil
                                                       handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                           if (error) {
                                                               NSLog(@"Error: %@", error.description);
                                                           } else {
                                                               NSLog(@"Success!");
                                                           }
                                                       }];

    if (!appCall) {
        // Next try to post using Facebook's iOS6 integration
        BOOL displayedNativeDialog = [FBDialogs presentOSIntegratedShareDialogModallyFrom:self
                                                                              initialText:nil
                                                                                    image:nil
                                                                                      url:urlToShare
                                                                                  handler:nil];

        if (!displayedNativeDialog) {
            // Lastly, fall back on a request for permissions and a direct post using the Graph API
            [self performPublishAction:^{
                NSString *message = [NSString stringWithFormat:@"Updating status for %@ at %@", self.loggedInUser.first_name, [NSDate date]];

                FBRequestConnection *connection = [[FBRequestConnection alloc] init];

                connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession
                | FBRequestConnectionErrorBehaviorAlertUser
                | FBRequestConnectionErrorBehaviorRetry;

                [connection addRequest:[FBRequest requestForPostStatusUpdate:message]
                     completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
                         [self showAlert:message result:result error:error];
                         self.buttonPostStatus.enabled = YES;
                     }];
                [connection start];

                self.buttonPostStatus.enabled = NO;
            }];
        }
    }
}

// Post Photo button handler
- (IBAction)postPhotoClick:(UIButton *)sender {
  // Just use the icon image from the application itself.  A real app would have a more
  // useful way to get an image.
  UIImage *img = [UIImage imageNamed:@"Icon-72@2x.png"];


    BOOL canPresent = [FBDialogs canPresentShareDialogWithPhotos];
    NSLog(@"canPresent: %d", canPresent);
    
  FBShareDialogPhotoParams *params = [[FBShareDialogPhotoParams alloc] init];
  params.photos = @[img];

  FBAppCall *appCall = [FBDialogs presentShareDialogWithPhotoParams:params
                                                        clientState:nil
                                                            handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                                if (error) {
                                                                    NSLog(@"Error: %@", error.description);
                                                                } else {
                                                                    NSLog(@"Success!");
                                                                }
                                                            }];
  if (!appCall) {
    [self performPublishAction:^{
      FBRequestConnection *connection = [[FBRequestConnection alloc] init];
      connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession
      | FBRequestConnectionErrorBehaviorAlertUser
      | FBRequestConnectionErrorBehaviorRetry;

      [connection addRequest:[FBRequest requestForUploadPhoto:img]
           completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
             [self showAlert:@"Photo Post" result:result error:error];
             if (FBSession.activeSession.isOpen) {
               self.buttonPostPhoto.enabled = YES;
             }
           }];
      [connection start];

      self.buttonPostPhoto.enabled = NO;
    }];
  }
}

// Pick Friends button handler
- (IBAction)pickFriendsClick:(UIButton *)sender {

    NSLog(@"About to post to rusic rusic_participant_token: %@", self.rusic_participant_token);
    
    // Setup Header providing the X-Rusic-Participant-Token
    NSDictionary* headers = @{
      @"accept": @"application/vnd.rusic.v1+json",
      @"X-API-Key": @"2a5e3e02c586ee2c21b4fb8346aece7d",
      @"X-Rusic-Participant-Token": self.rusic_participant_token
    };
    
    NSString *image = [NSString stringWithFormat:@"%@", self.image_id];
    
    NSLog(@"%@", image);
    
    // Setup Parameters with some static (fake) data
    NSDictionary* parameters = @{
      @"idea[title]": @"Bang",
      @"idea[content]": @"Bar",
      @"idea[image_ids][]": image
    };
    
    // Make a post request to the Rusic `space` with the headers and parameter
    [[UNIRest post:^(UNISimpleRequest* request) {
        [request setUrl:@"http://api.rusic.com/buckets/416/ideas"];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        NSLog(@"Idea created!");
    }];

}

// Pick Place button handler
- (IBAction)pickPlaceClick:(UIButton *)sender {
    
    NSLog(@"POST IMAGE");
    
    NSString *apiurl = @"http://api.rusic.com/images";
    //NSString *contenttype = @"image/png";
    //NSString *apikey = @"2a5e3e02c586ee2c21b4fb8346aece7d";
    NSString *imagename = @"Test.jpg";
    UIImage *image = [UIImage imageNamed: imagename];
    
    NSLog(@"Image width is %f", image.size.width);
    NSLog(@"Image height is %f", image.size.height);
    
	NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
	//NSURL *url = [NSURL URLWithString: apiurl];
    
    NSURL *url = [NSURL URLWithString: apiurl];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setDelegate:self];
    [request setData:imageData withFileName:@"Default.png" andContentType:@"image/jpeg" forKey:@"image[file]"];
    [request addRequestHeader:@"accept" value:@"application/vnd.rusic.v1+json"];
    [request addRequestHeader:@"X-API-Key" value:@"2a5e3e02c586ee2c21b4fb8346aece7d"];
    [request addRequestHeader:@"X-Rusic-Participant-Token" value: self.rusic_participant_token];
    
    [request startAsynchronous];
    
}

- (void)requestFinished:(ASIFormDataRequest *)request
{
    
    NSLog(@"requestFinished");
    
    // Use when fetching text data
    NSString *responseString = [request responseString];
    NSLog(@"%@", responseString);
    

    //parse out the json data
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:jsonData //1
                          
                          options:kNilOptions
                          error:&error];
    
    self.image_id = [json objectForKey:@"id"]; //2

}

- (void)requestFailed:(ASIFormDataRequest *)request
{
    NSLog(@"ERROR");
    NSError *error = [request error];
    NSLog(@"%@", error);
}

// UIAlertView helper for post buttons
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error {

    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertTitle = @"Error";
        // Since we use FBRequestConnectionErrorBehaviorAlertUser,
        // we do not need to surface our own alert view if there is an
        // an fberrorUserMessage unless the session is closed.
        if (error.fberrorUserMessage && FBSession.activeSession.isOpen) {
            alertTitle = nil;

        } else {
            // Otherwise, use a general "connection problem" message.
            alertMsg = @"Operation failed due to a connection problem, retry later.";
        }
    } else {
        NSDictionary *resultDict = (NSDictionary *)result;
        alertMsg = [NSString stringWithFormat:@"Successfully posted '%@'.", message];
        NSString *postId = [resultDict valueForKey:@"id"];
        if (!postId) {
            postId = [resultDict valueForKey:@"postId"];
        }
        if (postId) {
            alertMsg = [NSString stringWithFormat:@"%@\nPost ID: %@", alertMsg, postId];
        }
        alertTitle = @"Success";
    }

    if (alertTitle) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                            message:alertMsg
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}



@end
