# PinterestSDK for iOS

The PinterestSDK for iOS will allow you to authenticate an account with Pinterest and make requests on behalf of the authenticated user. For details on the supported endpoint, visit [the Pinterest API](https://api.pinterest.com/developers/signup/).

## Installation

The PinterestSDK is a cocoapod. In order to use it you will need to create a `Podfile` if you do not already have one. Information on installing cocoapods and creating a Podfile can be found at [Cocoapods.org](http://cocoapods.org/). (Hint — to install cocoapods, run `sudo gem install cocoapods` from the command line; to create a Podfile, run `pod init`).

Open up the Podfile and add the following dependency:

```bash
pod "PinterestSDK", :path => '~/path/to/iOS-PDK'
```

Save your Podfile and run 'pod install' from the command line.

You can also just give the example app a try:

```bash
pod try https://github.com/pinterest/ios-pdk.git
```

## Setting up your App 

### Registering Your App
Visit the [Pinterest Developer Site](https://dev.pinterest.com/apps/) and register your application. This will generate an appId for you which you will need in the next steps. Make sure to add your redirect URIs. For iOS your redirect URI will be `pdk[your-appId]`. For example, if you appId is 1234 your redirect URI will be `pdk1234`.

### Configuring Xcode
The PinterestSDK will authenticate using OAuth either via the Pinterest app or, if the Pinterest app isn't installed, Safari. In order to redirect back to your app after authentication you will need set up a custom URL scheme. To do this, go to your app's plist and add a URL scheme named `pdk[your-appId]`. 

![Xcode Screenshot](https://raw.githubusercontent.com/pinterest/ios-pdk/master/Example/PinterestSDK/Images.xcassets/XcodeScreenshot.png)

### Configuring PDKClient
Before you make any calls using the PDKClient in your app, you will need to configure it with your appId: 

```objective-c
[PDKClient configureSharedInstanceWithAppId:@"12345"];
```

The end of `application:didFinishLaunchingWithOptions:` seems like a reasonable place.

## Example App

A good place to start exploring the PDK is with the example app. To run it browse to the Example directory and run `pod install`.  Next open `PinterestSDK.xcworkspace` in XCode and run it.

## Getting Started 

### Authenticating

To authenticate a user, call `authenticateWithPermissions:withSuccess:andFailure:` on PDKClient. If the current auth token isn't valid or this is the first time you've requested a token, this call will cause an app switch to either the Pinterest app or Safari. To handle the switch back to your app, implement your app's `application:handleOpenURL:` as follows:

```objective-c
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [[PDKClient sharedInstance] handleCallbackURL:url];
}
```

PDKClient is now fully configured and ready to be used to make requests.

### Making Requests
PDKClient has methods to make direct GET, POST, PUT and DELETE requests. The supported endpoints can be found on the [the Pinterest API](https://dev.pinterest.com/docs/api/) webpage. The methods signatures are:

```objective-c
/**
 *  Makes a GET API request
 *
 *  @param path         The path to endpoint
 *  @param parameters   Any parameters that need to be sent to the endpoint
 *  @param successBlock Called when the API call succeeds
 *  @param failureBlock Called when the API call fails
 */
- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
    withSuccess:(PDKClientSuccess)successBlock
     andFailure:(PDKClientFailure)failureBlock;

/**
 *  Makes a DELETE API request
 *
 *  @param path         The path to the endpoint
 *  @param parameters   Any parameters that need to be sent to the endpoint
 *  @param successBlock Called when the API call succeeds
 *  @param failureBlock Called when the API call fails
 */
- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
       withSuccess:(PDKClientSuccess)successBlock
        andFailure:(PDKClientFailure)failureBlock;

/**
 *  Makes a PUT API request
 *
 *  @param path         The path to the endpoint
 *  @param parameters   Any parameters that need to be sent to the endpoint
 *  @param successBlock Called when the API call succeeds
 *  @param failureBlock Called when the API call fails
 */
- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
    withSuccess:(PDKClientSuccess)successBlock
     andFailure:(PDKClientFailure)failureBlock;

/**
 *  Makes a POST API request
 *
 *  @param path         The path to the endpoint
 *  @param parameters   Any parameters that need to be sent to the endpoint
 *  @param successBlock Called when the API call succeeds
 *  @param failureBlock Called when the API call fails
 */
- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
     withSuccess:(PDKClientSuccess)successBlock
      andFailure:(PDKClientFailure)failureBlock;
```

Using one of these methods is straightforward:

```objective-c
[[PDKClient sharedInstance] getPath:@"me/"
                        parameters:nil
                       withSuccess:^(PDKResponseObject *responseObject) {
                       	   // success actions
                       } andFailure:^(NSError *error) {
                           // failure actions
                       }];
```

### PDKResponseObject and Pagination

You probably noticed that each endpoint method has a block of type PDKClientSuccess. The block's signature is:
```
typedef void (^PDKClientSuccess)(PDKResponseObject *responseObject);
```

On success, you are given a `PDKResponseObject`. This object encapsulates any type of object that you could get back from a request. If the request is to get a user's boards, then you can call `[responseObject boards]` to get an array with objects of type `PDKBoard`. If the request returns a list of pins, call `[responseObject pins]`.

If the response is paginated, you can use the response object to see if there is more data `[responseObject hasNext]`. And request the data if it exists `[responseObject loadNextWithSuccess:success andFailure:failure]`.

Here is an example of how that would work:
```objective-c
if ([self.currentResponseObject hasNext]) {
    __weak PDKViewController *weakSelf = self;
    [self.currentResponseObject loadNextWithSuccess:^(PDKResponseObject *responseObject) {
        weakSelf.currentResponseObject = responseObject;
        weakSelf.pins = [weakSelf.pins arrayByAddingObjectsFromArray:[responseObject pins]];
        [weakSelf.collectionView reloadData];
    } andFailure:nil];
}
```
The only tricky part here is that you need to replace your most recent responseObject with the new one returned by the `loadNextWithSuccess:andFailure:` call. Otherwise calling load next on the old responseObject will load the same data again.

### Fields

The SDK has three basic resource types: [Users](https://dev.pinterest.com/docs/api/users/), [Pins](https://dev.pinterest.com/docs/api/pins/) and [Boards](https://dev.pinterest.com/docs/api/boards/). By default a request returns a select few of the fields available in each object. To request more fields you must specify the fields you want as a comma separated list in the request URL. For example, by default a pin request will return the fields url, note, link and id. Let's say that you only need id and note, but also want the pin's image. Your request would look something like:

```
https://api.pinterest.com/v1/me/pins/?access_token=<your-access-token>&fields=id,image,note
```

For a list of available fields on each object, refer to the bottom of the [Getting Started documentation](https://dev.pinterest.com/docs/getting-started/). 

## PDK Convenience API methods

PDKClient also comes with convenience methods for almost all of the PDK endpoints. In each of these calls you must provide a list of fields that you wish the endpoint to return. 
#### Authenticated  User (me) methods

```objective-c
- (void)getAuthenticatedUserPinsWithFields:(NSSet *)fields
                                   success:(PDKClientSuccess)successBlock
                                andFailure:(PDKClientFailure)failureBlock;

- (void)getAuthenticatedUserLikesWithFields:(NSSet *)fields
                                    success:(PDKClientSuccess)successBlock
                                 andFailure:(PDKClientFailure)failureBlock;

- (void)getAuthenticatedUserBoardsWithFields:(NSSet *)fields
                                     success:(PDKClientSuccess)successBlock
                                  andFailure:(PDKClientFailure)failureBlock;
- (void)getAuthorizedUserFollowersWithFields:(NSSet *)fields
                                     success:(PDKClientSuccess)successBlock
                                  andFailure:(PDKClientFailure)failureBlock;

- (void)getAuthorizedUserFollowedUsersWithFields:(NSSet *)fields
                                         success:(PDKClientSuccess)successBlock
                                      andFailure:(PDKClientFailure)failureBlock;

- (void)getAuthorizedUserFollowedBoardsWithFields:(NSSet *)fields
                                          success:(PDKClientSuccess)successBlock
                                       andFailure:(PDKClientFailure)failureBlock;
- (void)getAuthorizedUserFollowedInterestsWithSuccess:(PDKClientSuccess)successBlock
                                           andFailure:(PDKClientFailure)failureBlock;
```

#### Board endpoints
```objective-c
- (void)getBoardWithIdentifier:(NSString *)boardId
                        fields:(NSSet *)fields
                   withSuccess:(PDKClientSuccess)successBlock
                    andFailure:(PDKClientFailure)failureBlock;

- (void)getBoardPins:(NSString *)boardId
              fields:(NSSet *)fields
         withSuccess:(PDKClientSuccess)successBlock
          andFailure:(PDKClientFailure)failureBlock;

- (void)deleteBoard:(NSString *)boardId
        withSuccess:(PDKClientSuccess)successBlock
         andFailure:(PDKClientFailure)failureBlock;

- (void)createBoard:(NSString *)boardName
   boardDescription:(NSString *)description
        withSuccess:(PDKClientSuccess)successBlock
         andFailure:(PDKClientFailure)failureBlock;
```

#### Pin endpoints
```objective-c

- (void)getPinWithIdentifier:(NSString *)pinId
                      fields:(NSSet *)fields
                 withSuccess:(PDKClientSuccess)successBlock
                  andFailure:(PDKClientFailure)failureBlock;

- (void)createPinWithImageURL:(NSURL *)imageURL
                         link:(NSURL *)link
                      onBoard:(NSString *)boardId
                  description:(NSString *)pinDescription
                  withSuccess:(PDKClientSuccess)successBlock
                   andFailure:(PDKClientFailure)failureBlock;

- (void)createPinWithImage:(UIImage *)image
                      link:(NSURL *)link
                   onBoard:(NSString *)boardId
               description:(NSString *)pinDescription
                  progress:(PDKPinUploadProgress)progressBlock
               withSuccess:(PDKClientSuccess)successBlock
                andFailure:(PDKClientFailure)failureBlock;
```

## Related Articles
[Pinterest API Docs](https://dev.pinterest.com/docs/getting-started/)

[Pinterest API signup](https://api.pinterest.com/developers/signup/)

