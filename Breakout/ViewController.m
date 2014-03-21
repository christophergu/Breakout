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
    UIDynamicItemBehavior *wallDynamicBehavior;
    UIDynamicItemBehavior *bottomSideDynamicBehavior;
    UIDynamicItemBehavior *blockDynamicBehavior;
}

@property (strong, nonatomic) IBOutlet UIView *paddleView;
@property (strong, nonatomic) IBOutlet UIView *ballView;
@property (strong, nonatomic) IBOutlet UIView *topSide;
@property (strong, nonatomic) IBOutlet UIView *leftSide;
@property (strong, nonatomic) IBOutlet UIView *rightSide;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;

@property (strong, nonatomic) NSMutableArray *blocks;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self gameStart];
}

#pragma mark - game start methods

- (void)gameStart
{
    dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.ballView] mode:UIPushBehaviorModeInstantaneous];
    collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView, self.topSide, self.leftSide, self.rightSide]];
    ballDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    paddleDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    wallDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.topSide, self.leftSide, self.rightSide]];
    
    self.ballView.center = self.view.center;

    pushBehavior.pushDirection = CGVectorMake(0.5, 1.0);
    pushBehavior.active = YES;
    pushBehavior.magnitude = 0.15;
    [dynamicAnimator addBehavior:pushBehavior];
    
    paddleDynamicBehavior.allowsRotation = NO;
    paddleDynamicBehavior.density = 10000;
    [dynamicAnimator addBehavior:paddleDynamicBehavior];
    
    wallDynamicBehavior.allowsRotation = NO;
    wallDynamicBehavior.density = 99999;
    [dynamicAnimator addBehavior:wallDynamicBehavior];
    
    bottomSideDynamicBehavior.allowsRotation = YES;
    bottomSideDynamicBehavior.density = 0;
    [dynamicAnimator addBehavior:bottomSideDynamicBehavior];
    
    ballDynamicBehavior.allowsRotation = NO;
    ballDynamicBehavior.elasticity = 1.0;
    ballDynamicBehavior.friction = 0.0;
    ballDynamicBehavior.resistance = 0.0;
    ballDynamicBehavior.angularResistance = 0.0;
    [dynamicAnimator addBehavior:ballDynamicBehavior];
    
    collisionBehavior.collisionMode = UICollisionBehaviorModeItems;
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    collisionBehavior.collisionDelegate = self;
    [dynamicAnimator addBehavior:collisionBehavior];
    

    self.blocks = [NSMutableArray new];
    self.scoreLabel.text = @"0";
    
    [self blockCreator];
    [self gameStartBlockResetHelper];
}

- (void)gameStartBlockResetHelper
{
    for (BlockView *block in self.blocks) {
        block.alpha = 1.0;
    }
}

- (void)blockCreator
{
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

#pragma mark - collider methods

- (IBAction)dragPaddle:(UIPanGestureRecognizer *)panGestureRecognizer
{
    self.paddleView.center = CGPointMake([panGestureRecognizer locationInView:self.view].x, self.paddleView.center.y);
    [dynamicAnimator updateItemUsingCurrentState:self.paddleView];
}

-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    if (self.ballView.frame.origin.y > self.view.frame.size.height-15) {
        self.ballView.center = self.view.center;
    }
    
    [dynamicAnimator updateItemUsingCurrentState:self.ballView];
}

-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2 atPoint:(CGPoint)p
{
    if ([item1 isKindOfClass:[BallView class]] && [item2 isKindOfClass:[BlockView class]]) {
        
        int addToScore = 0;
        
        NSMutableArray *markedForDeletion = [NSMutableArray new];
        
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
    
    
    if([self shouldStartAgain])
    {
        dynamicAnimator = nil;
        UIAlertView *winnerAlert = [[UIAlertView alloc] initWithTitle:@"Winner!"
                                                              message:[NSString stringWithFormat:@"You got %@ points!", self.scoreLabel.text]
                                                             delegate:self
                                                    cancelButtonTitle:@"Play again!"
                                                    otherButtonTitles:nil];
        [winnerAlert show];
    };
}

#pragma mark - alertview delegate methods

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self gameStart];
}


@end
