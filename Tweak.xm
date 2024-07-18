#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
//#import <Foundation/Foundation.h>
//#import <SpringBoard/SpringBoard.h>
//#import <substrate.h>
//#import <logos/logos.h>
//#import <QuartzCore/QuartzCore.h>
//#import <IOSurface/IOSurface.h>
//#import <QuartzCore/QuartzCore2.h>
#import <QuartzCore/CAAnimation.h>
#import <UIKit/UIGraphics.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <objc/runtime.h>
#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import <notify.h>
#import "UIImage+LiveBlur.h"
//#import <Foundation/NSTask.h>


static BOOL isMoving = FALSE;

static BOOL isShowing = FALSE;

static UIWindow *window;

static UIWindow *tmpWindow;

//Some useful class :)
@interface UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor;

@end

@implementation UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor {
  UIGraphicsBeginImageContext(self.size);
  CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
  [self drawInRect:drawRect];
  [tintColor set];
  UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return tintedImage;
}

@end


@interface SwipeRecognizer : UIImageView
CGPoint startLocation;
NSString *swipeDirection;
CGPoint pt;
BOOL canMove;
-(void)setRepositionEnabled;
@property(nonatomic, assign) NSString *swipeDirection;
@property (nonatomic, assign) id  delegate; //So it can call stuff off in the original tweak stuff 
@end

@interface TouchAssistant : UIImageView
UIButton *unloadButton;
UIButton *homeButton;
UIButton *deviceButton;
UIButton *volumeUp;
UIButton *volumeDown;
UIView *mainView;
UILabel *volumeLabel;
-(void)homeButton;
-(void)goHome;
-(void)launch;
-(void)unload;
-(void)lockButton;
-(void)setVolumeUp;
-(void)setVolumeDown;
-(void)setVolumeLabel;
- (void)updateWindowLevel:(NSNotification *)notification;
@end

@interface SBMediaController
-(float)volume;
-(void)setVolume:(float)volume;
-(void)_changeVolumeBy:(float)by;
-(void)increaseVolume;
-(void)decreaseVolume;
@end

static TouchAssistant *assistantLauncher;

static SwipeRecognizer *swipeIt;


%ctor {

if(!assistantLauncher){
  assistantLauncher = [[TouchAssistant alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
}

//Register it for application launcher (springboard counts as one I think...)
[[NSNotificationCenter defaultCenter] addObserver:assistantLauncher  selector:@selector(updateWindowLevel:)  name:UIApplicationDidFinishLaunchingNotification  object:nil];


}

@implementation SwipeRecognizer
@synthesize swipeDirection, delegate;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

[NSObject cancelPreviousPerformRequestsWithTarget:assistantLauncher]; //So it doesn't run multiple times.
[UIView beginAnimations:@"dim" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.3];
swipeIt.alpha = 1.0;
[UIView commitAnimations];
    // test wether the thing is touched
    UITouch *touch = [touches anyObject];
    CGPoint touchBegan = [touch locationInView:window];
    startLocation = touchBegan; //Need this....
    [self performSelector:@selector(setRepositionEnabled) withObject:nil afterDelay:0.5]; //Allow it to be moved after 2 seconds. (1 or 1.5 now)



}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
        CGPoint pt = [[touches anyObject] locationInView:window];
        float dx = pt.x - startLocation.x + (60 /2 ); //Calculating the offset from where it was. 
        float dy = pt.y - startLocation.y + (60 /2); //Seeing otherwise it offsets slightly. Don't ask me why, I'm super tired right now. :p

        //Little bit of code below to stop it going off screen.  Maybe use something like this to determine where it should reset the view to?
        if(dy >= 480 - (60 / 2)){
        	dy = 480 - (60 / 2); 
        }
        if(dy <= 60 / 2 ){
        	dy = 60 / 2;
        }
        if(dx >= 320 - (60 / 2)){
        	dx = 320 - (60 / 2);
        }
        if(dx <= 60 / 2 ){
        	dx = 60 / 2;
        }

        CGPoint newCenter = CGPointMake(dx, dy); //Oh... Right. The code I copied this from used the variables :P I didn't set them. Just use dx and dy.
  if(canMove){
   //Cheat cheat cheat :P
  self.center = newCenter; //Now we just change the view.... Not the window.
}
   // }
}

// when the event ends, put the BOOL back to NO
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setRepositionEnabled) object:nil]; //Stopping the timer type thing from the touches began. This stops it ever setting it to enabled, so we know it's just a tap.
    isMoving = FALSE;
    //Don't want to reset the frame if it was just a tap...
    if(canMove){

    float currentX = self.center.x;
    float currentY = self.center.y;

    if(currentY >= 80 && currentY <= 400){ //Only reset the x (side to side) if it's more towards the middle of the screen. 
    if(currentX >= 160){
    	currentX = 320 - (60 / 2); //Right at the edge of the right side of the screen.
    }
    if(currentX <= 160){
    	currentX = 60 / 2; //Better because it is supposed to animate back down :P
    }
	}
  else{
    if(currentY <= 79){
      currentY = 30;
    }
    if(currentY >= 401){
      currentY = 450;
    }
  }


   
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(moveSwipeDone:finished:context:)];
	self.center = CGPointMake(currentX, currentY); //Change the center of this view to the new numbers, to make it go to the right place on release.
	//self.transform = CGAffineTransformScale(self.transform, 1.0, 1.0); //Setting the scale back to normal :) Too tired to figure out why it doesn't animate down.
	[UIView commitAnimations];
	
}
else{
[assistantLauncher launch];
}
canMove = FALSE; //Yayyyy
}

- (void)moveSwipeDone:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
	   window.frame = self.frame; //More hacks! Reset the window to the current frame of the swipeIt, so it doesn't cover the whole screen anymore :3
    self.frame = CGRectMake(0,0, 60, 60);	//Otherwise it is still off by a long shot of where the window actually is. Even though visible, it's not able to be touched because it's not in the parent view's frame.
/*	assistantLauncher.frame = self.frame;
	assistantLauncher.center = self.center;
	assistantLauncher.frame = CGRectMake(0,0, 60, 60);*/
}

-(void)setRepositionEnabled{

self.center = window.center; //So it doesn't default to the top left :p
window.frame = CGRectMake(0,0,320,480); //Make the window full screen while dragging... That way you have the full canvas to track touches.
canMove = TRUE; //Now we know it's a drag.

//Little animation up
[UIView beginAnimations:nil context:nil];
[UIView setAnimationDuration:0.2];
//self.transform = CGAffineTransformScale(self.transform, 1.3, 1.3); //Setting the view to be 1.3 times as big as it is right now.
[UIView commitAnimations];

}
@end

@implementation TouchAssistant
-(id)initWithFrame:(CGRect)frame{
 self = [super initWithFrame:frame];

if(self){
[self performSelector:@selector(dimOpenButton) withObject:nil afterDelay:10]; //Run it after a delay
}
return self;
}

-(void)launch{
  NSAutoreleasePool *buttonPool = [[NSAutoreleasePool alloc] init];
swipeIt.hidden = TRUE;
swipeIt.frame = window.frame; //Magic. Look at that. 4 lines total (two more in the unload) to negate the need for a whole UIWindow again
window.frame = CGRectMake(0,0,320,480);
if(!mainView){ 
//Moved in the buttons and other things into this checking code, because you were adding them again and again. Major leak in memory and resources.
mainView = [[UIView alloc] init];


mainView.frame = CGRectMake(0, 0, 320, 480);

//Making another view to draw attention away from the blur. This is basically just an empty UIView, put behind everything but over the view that uses the blur (mainView), so it dims it.
UIView *dimView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,480)];
dimView.backgroundColor = [UIColor darkGrayColor];
dimView.alpha = 0.4; //Making it semi-transparent so you can still see the blur.
[mainView addSubview:dimView];
[dimView release];
//


unloadButton = [UIButton buttonWithType: UIButtonTypeCustom];
unloadButton.frame = CGRectMake(115, 163, 90, 90);
[unloadButton setImage:[UIImage imageWithContentsOfFile:@"/Library/TouchAssistant/unloadButton.png"] forState:UIControlStateNormal]; //This is how to set a button image properly ;)
[unloadButton addTarget:self action:@selector(unload) forControlEvents:UIControlEventTouchUpInside];
[mainView addSubview:unloadButton];

homeButton = [UIButton buttonWithType: UIButtonTypeCustom];
homeButton.frame = CGRectMake(135, 290, 54, 54);
[homeButton setImage:[UIImage imageWithContentsOfFile:@"/Library/TouchAssistant/homeButton.png"] forState:UIControlStateNormal];
[homeButton addTarget:self action:@selector(homeButton) forControlEvents:UIControlEventTouchUpInside];
[mainView addSubview:homeButton];

deviceButton = [UIButton buttonWithType: UIButtonTypeCustom];
deviceButton.center = mainView.center;
deviceButton.frame = CGRectMake(135, 70, 54, 54);
[deviceButton setImage:[UIImage imageWithContentsOfFile:@"/Library/TouchAssistant/lockButton.png"] forState:UIControlStateNormal];
[deviceButton addTarget:self action:@selector(lockButton) forControlEvents:UIControlEventTouchUpInside];
[mainView addSubview:deviceButton];

volumeDown = [UIButton buttonWithType: UIButtonTypeCustom];
volumeDown.frame = CGRectMake(30, 183, 54, 54);
[volumeDown setImage:[UIImage imageWithContentsOfFile:@"/Library/TouchAssistant/volumeDown.png"] forState:UIControlStateNormal];
[volumeDown addTarget:self action:@selector(setVolumeDown) forControlEvents:UIControlEventTouchUpInside];
[mainView addSubview:volumeDown];

volumeUp = [UIButton buttonWithType: UIButtonTypeCustom];
volumeUp.frame = CGRectMake(245, 183, 54, 54);
[volumeUp setImage:[UIImage imageWithContentsOfFile:@"/Library/TouchAssistant/volumeUp.png"] forState:UIControlStateNormal];
[volumeUp addTarget:self action:@selector(setVolumeUp) forControlEvents:UIControlEventTouchUpInside];
[mainView addSubview:volumeUp];



[window addSubview:mainView];
}
[self setVolumeLabel];
//
mainView.alpha = 0.0;
//My magic code that combines various other things to make a quick blur of the whole screen. No code to crop it up/down as in control center though.
//It's not so good for the quality bit as if you use a number that doesn't evenly divide it it kinda freaks out :P
//Interpolation is how well it retains the quality of the blur I guess (used in part for the quick blurring).
//0 is none, and it goes up to 5 or 6 quality wise (1 is low, 5 or 6 is high)
if([[%c(SBUIController) sharedInstance] isWhited00r]){
mainView.backgroundColor = [UIColor colorWithPatternImage:[UIImage liveBlurForScreenWithQuality:4 interpolation:4 blurRadius:15]];
}
else{
  mainView.backgroundColor = [UIColor redColor];
}
[UIView beginAnimations:@"show" context:nil];
[UIView setAnimationDuration:0.3];
mainView.alpha = 1.0;
[UIView commitAnimations];
isShowing = TRUE;
[buttonPool drain];
}

-(void)unload{
[UIView beginAnimations:@"hide" context:nil];
[UIView setAnimationDidStopSelector:@selector(unloadAnimationDone:finished:context:)];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.3];
mainView.alpha = 0.0;
[UIView commitAnimations];
swipeIt.hidden = FALSE;


//

}

- (void)unloadAnimationDone:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
window.frame = swipeIt.frame; //Because swipeIt was reset to the original position of the window before it was opened. This is a reference to it on the large screen ;)
swipeIt.frame = CGRectMake(0,0,60,60); //And then resetting swipe it to once again be inside the window frame :P
isShowing = FALSE;

[self performSelector:@selector(dimOpenButton) withObject:nil afterDelay:10]; //Run it after a delay
}

-(void)dimOpenButton{
//To fade swipeIt :)
if(swipeIt){
[NSObject cancelPreviousPerformRequestsWithTarget:self]; //So it doesn't run multiple times.
[UIView beginAnimations:@"dim" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.3];
swipeIt.alpha = 0.5;
[UIView commitAnimations];
}
}

-(void)homeButton{
[self unload];
[self performSelector:@selector(goHome) withObject:nil afterDelay:0.5];
}


-(void)goHome{
[[%c(SBUIController) sharedInstance] clickedMenuButton];
}

-(void)lockButton{
[[%c(SBUIController) sharedInstance] lock];
}

-(void)setVolumeUp{
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
float currentVolume = [[%c(SBMediaController) sharedInstance] volume];
float finalVolume = currentVolume + 0.05;
  [[%c(SBMediaController) sharedInstance] setVolume:finalVolume];
  [self performSelector:@selector(setVolumeLabel) withObject:nil afterDelay:0.5];
  [pool drain];
}

-(void)setVolumeDown{
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
float currentVolume = [[%c(SBMediaController) sharedInstance] volume];
float finalVolume = currentVolume - 0.05;
  [[%c(SBMediaController) sharedInstance] setVolume:finalVolume];
  [self performSelector:@selector(setVolumeLabel) withObject:nil afterDelay:0.5];
  [pool drain];
}

-(void)setVolumeLabel{
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
if(!volumeLabel){
//allocate it only once, so if the method is called more than one time, do not re-allocate it :p
volumeLabel = [[UILabel alloc] init];
volumeLabel.textAlignment = UITextAlignmentCenter;
volumeLabel.font = [UIFont boldSystemFontOfSize:15];
volumeLabel.frame = CGRectMake(0, 380, 320, 60);
[volumeLabel setBackgroundColor:[UIColor clearColor]];
volumeLabel.textColor = [UIColor whiteColor];
[mainView addSubview:volumeLabel];
}
float currentVolume = [[%c(SBMediaController) sharedInstance] volume];

NSNumber *percent;

percent = [NSNumber numberWithFloat:currentVolume * 100]; //What is this for? O.o

currentVolume = currentVolume * 100;
int currentVolumeInt = lroundf(currentVolume); //Rounding the float :) Much nicer looking visually for a user and should avoid the longer text bug.

if([[%c(SBUIController) sharedInstance] isWhited00r]){
volumeLabel.text = [NSString stringWithFormat:@"Volume level: %d", currentVolumeInt]; 
}
else{
  volumeLabel.text = @"Try whited00r ye bastard";
}

[pool drain];
}


//New method to handle window changes and whatnot
- (void)updateWindowLevel:(NSNotification *)notification{
if(!window){
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
swipeIt = [[SwipeRecognizer alloc] initWithFrame:CGRectMake(0,0,60,60)];
swipeIt.image = [UIImage imageWithContentsOfFile:@"/Library/TouchAssistant/main.png"]; //Set the image as the image not the background color...
swipeIt.delegate = assistantLauncher; //So now the subclass has a reference to the main code
swipeIt.userInteractionEnabled = TRUE;
swipeIt.hidden = FALSE;

window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 180, 60, 60)];
window.windowLevel = 9000;
window.userInteractionEnabled = TRUE;
window.hidden = FALSE;
window.backgroundColor = [UIColor clearColor];

[window addSubview:swipeIt];

[swipeIt addSubview:assistantLauncher];

[window makeKeyAndVisible];

[assistantLauncher release];
[pool drain];
}
else{
 //otherwise, if the window and assistant launcher exist, make it do this
window.hidden = FALSE;
[window makeKeyAndVisible];
window.windowLevel = 9000;
}
}
@end



%hook SBAwayController
-(void)lock{ //Hooking this to handle when the screen locks.
  %orig;
 if(isShowing && assistantLauncher){
  [assistantLauncher unload];
 }

}

-(void)_undimScreen{ //Hooked this to handle when the screen is locked and the tweak is open.
  %orig;
 if(isShowing && assistantLauncher){
  [assistantLauncher unload];
 }
}

-(BOOL)handleMenuButtonTap{ //Lockscreen handles home button presses itself.
 if(isShowing && assistantLauncher){
  [assistantLauncher unload];
 }

 return %orig;

}

-(BOOL)handleMenuButtonDoubleTap{ //Double press it. Oh yes.
 if(isShowing && assistantLauncher){
  [assistantLauncher unload];
 }

 return %orig;
}

%end

%hook SBUIController
-(void)lock{
  %orig;
 if(isShowing && assistantLauncher){
  [assistantLauncher unload];
 }
}

-(BOOL)clickedMenuButton{
 if(isShowing && assistantLauncher){
  [assistantLauncher unload];
 }

 return %orig;
}

%end