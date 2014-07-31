//
//  ViewController.m
//  Breakout
//
//  Created by Christopher Gu on 3/20/14.
//  Copyright (c) 2014 Christopher Gu. All rights reserved.
//

#import "ViewController.h"
#import "PaddleView.h"
#import "BlockView.h"
#import "BallView.h"

@interface ViewController () <UICollisionBehaviorDelegate>
{
    UIDynamicAnimator *dynamicAnimator;
    UIPushBehavior *pushBehavior;
    UICollisionBehavior *collisionBehavior;
    UIDynamicItemBehavior *paddleDynamicBehavior;
    UIDynamicItemBehavior *ballDynamicBehavior;
    UIDynamicItemBehavior *bottomSideDynamicBehavior;
    UIDynamicItemBehavior *blockDynamicBehavior;
}

@property (weak, nonatomic) IBOutlet UIView *paddleView;
@property (weak, nonatomic) IBOutlet UIView *ballView;
@property (weak, nonatomic) IBOutlet UIView *bottomSideView;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *livesLabel;
@property (weak, nonatomic) IBOutlet UIButton *ballShootButton;
@property int livesCounter;
@property BOOL loaded;
@property (nonatomic) NSMutableArray *blocks;
@property (nonatomic) UIAlertView *gameOverAlert;
@property (nonatomic) UIAlertView *winnerAlert;



@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self gameStart];
}

//An example of how to add an image to a blockView
//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    
//    self.view.layer.contents = (__bridge id)[UIImage imageNamed:@"WonderWoman"].CGImage;
//}

#pragma mark - initialization methods

- (void)gameStart
{
    self.scoreLabel.text = @"0";
    self.livesCounter = 5;
    self.livesLabel.text = [NSString stringWithFormat:@"%i",self.livesCounter];
    
    self.ballShootButton.alpha = 0.0;
    self.ballView.alpha = 0.0;
    
    [self behaviorStart];
    [self blockCreator];
    
    self.loaded = YES;
}

- (void)behaviorStart
{
    dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView, self.bottomSideView]];
    ballDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    paddleDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    bottomSideDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.bottomSideView]];

    paddleDynamicBehavior.allowsRotation = NO;
    paddleDynamicBehavior.density = 10000;
    [dynamicAnimator addBehavior:paddleDynamicBehavior];
    
    bottomSideDynamicBehavior.allowsRotation = NO;
    bottomSideDynamicBehavior.density = 10000;
    [dynamicAnimator addBehavior:bottomSideDynamicBehavior];
    
    bottomSideDynamicBehavior.allowsRotation = YES;
    bottomSideDynamicBehavior.density = 0;
    [dynamicAnimator addBehavior:bottomSideDynamicBehavior];
    
    ballDynamicBehavior.allowsRotation = NO;
    ballDynamicBehavior.elasticity = 1.0;
    ballDynamicBehavior.friction = 0.0;
    ballDynamicBehavior.resistance = 0.0;
    ballDynamicBehavior.angularResistance = 0.0;
    [dynamicAnimator addBehavior:ballDynamicBehavior];
    
    collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    collisionBehavior.collisionDelegate = self;
    [dynamicAnimator addBehavior:collisionBehavior];
}

- (void)blockCreator
{
    for (BlockView *leftoverBlock in self.view.subviews) {
        if ([leftoverBlock isKindOfClass:[BlockView class]]) {
            [leftoverBlock removeFromSuperview];
        }
    }
    
    self.blocks = [NSMutableArray new];
    
    //    UIImage *blockRed = [[UIImage alloc] init];
    //    UIImage *blockYellow = [[UIImage alloc] init];
    //    UIImage *blockGreen = [[UIImage alloc] init];
    //
    //    blockRed = [UIImage imageNamed:@"breakout_block_red"];
    //    blockYellow = [UIImage imageNamed:@"breakout_block_yellow"];
    //    blockGreen = [UIImage imageNamed:@"breakout_block_green"];
    //
    //    NSArray *colors = @[blockRed,
    //                        blockYellow,
    //                        blockGreen];
    //
    //    for (int i = 0; i < 5; i++) {
    //        int row = i;
    //        for (int i = 0; i < 6; i++) {
    //            BlockView *blockView = [[BlockView alloc]initWithFrame:CGRectMake((25+(i*45)), (150+(row*15)), 45, 15)];
    //            blockView.blockImage.image = colors[arc4random()%3];
    //            [self.view addSubview:blockView];
    //            [self.blocks addObject:blockView];
    //            [collisionBehavior addItem:blockView];
    //        }
    //    }
    
    NSArray *colors = @[[UIColor redColor],
                        [UIColor yellowColor],
                        [UIColor greenColor]];
    
    for (int i = 0; i < 5; i++) {
        int row = i;
        for (int i = 0; i < 6; i++) {
            BlockView *blockView = [[BlockView alloc]initWithFrame:CGRectMake((25+(i*45)), (150+(row*15)), 45, 15)];
            [blockView setBackgroundColor:colors[arc4random()%3]];
            [self.view addSubview:blockView];
            [self.blocks addObject:blockView];
            [collisionBehavior addItem:blockView];
        }
    }
    
    blockDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:self.blocks];
    blockDynamicBehavior.allowsRotation = NO;
    blockDynamicBehavior.density = 999999;
    [dynamicAnimator addBehavior:blockDynamicBehavior];
}

- (void)ballStop
{
    self.ballView.center = self.view.center;
    self.ballView.alpha = 0.0;
    
    CGPoint cancelVelocity = CGPointMake([ballDynamicBehavior linearVelocityForItem:self.ballView].x * -1.0,
                                         [ballDynamicBehavior linearVelocityForItem:self.ballView].y * -1.0);
    [ballDynamicBehavior addLinearVelocity:cancelVelocity forItem:self.ballView];
    [dynamicAnimator updateItemUsingCurrentState:self.ballView];
}

- (void)ballPrepareToShoot
{
    CGPoint cancelVelocity = CGPointMake([ballDynamicBehavior linearVelocityForItem:self.ballView].x * -1.0,
                                         [ballDynamicBehavior linearVelocityForItem:self.ballView].y * -1.0);
    [ballDynamicBehavior addLinearVelocity:cancelVelocity forItem:self.ballView];
    [dynamicAnimator updateItemUsingCurrentState:self.ballView];
    
    [UIView animateWithDuration:1.0 animations:^{
        self.ballView.alpha = 1.0;
        self.ballShootButton.alpha = 1.0;
    }];
}

- (void)ballOriginalVelocitySetter
{
    CGPoint originalVelocity = CGPointMake(300.0, 500.0);
    [ballDynamicBehavior addLinearVelocity:originalVelocity forItem:self.ballView];
    [dynamicAnimator updateItemUsingCurrentState:self.ballView];
}

- (BOOL)shouldStartAgain
{
    BOOL startOrNo;
    if ([self.blocks  isEqual: @[]]) {
        startOrNo = YES;
    }
    else{
        startOrNo = NO;
    }
    return startOrNo;
}

#pragma mark - pan gesture recognizer delegate methods

- (IBAction)dragPaddle:(UIPanGestureRecognizer *)panGestureRecognizer
{
    self.paddleView.center = CGPointMake([panGestureRecognizer locationInView:self.view].x, self.paddleView.center.y);
    [dynamicAnimator updateItemUsingCurrentState:self.paddleView];
    
    if (self.loaded) {
        self.ballView.center = CGPointMake([panGestureRecognizer locationInView:self.view].x, self.paddleView.center.y - 45);
        [dynamicAnimator updateItemUsingCurrentState:self.ballView];
        [self ballPrepareToShoot];
    }
    
    
}

- (IBAction)ballShoot:(id)sender {
    CGFloat shootAngle;
    shootAngle = (self.paddleView.center.x - 160.0)*3;
    
    CGPoint originalVelocity = CGPointMake(shootAngle, -500.0);
    [ballDynamicBehavior addLinearVelocity:originalVelocity forItem:self.ballView];
    [dynamicAnimator updateItemUsingCurrentState:self.ballView];
    [UIView animateWithDuration:1.0 animations:^{
        self.ballShootButton.alpha = 0.0;
    }];
    self.loaded = NO;
}

#pragma mark - collision delegate methods

-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2 atPoint:(CGPoint)p
{
    // Checks if the ball collides with the bottoms of the screen
    if ([item1 isEqual:self.bottomSideView] && [item2 isEqual:self.ballView])
    {
        self.livesCounter--;
        
        if (self.livesCounter >= 0) {
            self.livesLabel.text = [NSString stringWithFormat:@"%i",self.livesCounter];
            [self ballStop];
            self.loaded = YES;
        }
        else
        {
            UIAlertView *gameOverAlert = [[UIAlertView alloc] initWithTitle:@"Game Over!"
                                                                  message:[NSString stringWithFormat:@"You got %@ points!", self.scoreLabel.text]
                                                                 delegate:self
                                                        cancelButtonTitle:@"Play again!"
                                                        otherButtonTitles:nil];
            [gameOverAlert show];
            [self ballStop];
        }
    }
    
    // Determines the behavior of the ball after it collides with the paddle
    if ([item1 isEqual:self.paddleView] && [item2 isEqual:self.ballView])
    {        
        CGFloat correctionDifference = ([ballDynamicBehavior linearVelocityForItem:self.ballView].x) * -0.25;
        CGPoint correctionVelocity = CGPointMake(correctionDifference, 0);
        [ballDynamicBehavior addLinearVelocity:correctionVelocity forItem:self.ballView];
        [dynamicAnimator updateItemUsingCurrentState:self.ballView];
        
        CGPoint antiVelocity = CGPointMake((p.x - self.paddleView.center.x) * 2.5, 0);
        [ballDynamicBehavior addLinearVelocity:antiVelocity forItem:self.ballView];
        [dynamicAnimator updateItemUsingCurrentState:self.ballView];
    }
    
    // Calculated the score added from colliding with blocks
    if ([item1 isKindOfClass:[BallView class]] && [item2 isKindOfClass:[BlockView class]]) {
        
        int addToScore = 0;
        
        NSMutableArray *markedForDeletion = [NSMutableArray new];
        
//        for (BlockView *block in self.blocks) {
//            if ([item2 isEqual:block]) {
//                if (block.blockImage.image == self.blockRed)
//                {
//                    block.blockImage.image = self.blockYellow;
//                    addToScore += 25;
//                }
//                else if (block.blockImage.image == self.blockYellow)
//                {
//                    block.blockImage.image = self.blockGreen;
//                    addToScore += 50;
//                }
//                else if (block.blockImage.image == self.blockGreen)
//                {
//                    [collisionBehavior removeItem:block];
//                    [UIView animateWithDuration:0.5 animations:^{block.alpha = 0.0;}];
//                    [markedForDeletion addObject:block];
//                    addToScore += 100;
//                }
//            }
//        }
        
        for (BlockView *block in self.blocks) {
            if ([item2 isEqual:block]) {
                if (block.backgroundColor == [UIColor redColor])
                {
                    block.backgroundColor = [UIColor yellowColor];
                    addToScore += 25;
                }
                else if (block.backgroundColor == [UIColor yellowColor])
                {
                    block.backgroundColor = [UIColor greenColor];
                    addToScore += 50;
                }
                else if (block.backgroundColor == [UIColor greenColor])
                {
                    [collisionBehavior removeItem:block];
                    [UIView animateWithDuration:0.5 animations:^{block.alpha = 0.0;}];
                    [markedForDeletion addObject:block];
                    addToScore += 100;
                }
            }
        }
        
        int scoreLabelInt = [self.scoreLabel.text intValue] + addToScore;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",scoreLabelInt];
        [self.blocks removeObjectsInArray:markedForDeletion];
    }
    
    // Checks if the game should start again
    if([self shouldStartAgain])
    {
        UIAlertView *winnerAlert = [[UIAlertView alloc] initWithTitle:@"Winner!"
                                                              message:[NSString stringWithFormat:@"You got %@ points!", self.scoreLabel.text]
                                                             delegate:self
                                                    cancelButtonTitle:@"Play again!"
                                                    otherButtonTitles:nil];
        [winnerAlert show];
        [self ballStop];
    };
}

#pragma mark - alertview delegate methods

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self gameStart];
}


@end
