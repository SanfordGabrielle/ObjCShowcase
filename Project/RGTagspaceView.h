//
//  RGTagspaceView.h
//  Imgtree
//
//  Created by Sanford Chase Gabrielle on 5/11/17.
//  Copyright © 2017 ImgTree, inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "postClass.h"

@interface RGTagspaceView : UIView <UITextFieldDelegate>

//primary subobjects
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UITextField *textField;
@property (strong, nonatomic) UIButton *button;

//arrays
@property (atomic, retain) NSMutableArray *tags;
@property (atomic, retain) NSMutableArray *tagButtons;
@property (nonatomic, retain) NSMutableArray *tagArray;
@property (nonatomic, retain) NSMutableArray *textWords;

//other properties
@property (nonatomic, assign) NSInteger lastTagArrayCount;
@property (nonatomic, assign) BOOL postTagFieldShouldEdit;
@property (nonatomic, assign) BOOL tagSpaceEditable;


//Method headers
-(void)createTagsForPost:(postClass *)p;
-(void)putTagsFrom:(postClass *)p inSpace:(UIView *)tagSpace;


@end
