//
//  RGTagspaceView.m
//  Imgtree
//
//  Created by Sanford Chase Gabrielle on 5/11/17.
//  Copyright © 2017 ImgTree, inc. All rights reserved.
//

#import "RGTagspaceView.h"
#import "UIColor+HexAdditions.h"
#import "postClass.h"

@implementation RGTagspaceView

int const Y_POSITION_FOR_TAGS = 7;

#pragma mark - Layout methods

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self tagSpaceInit];

    //set frames of subviews
    [_textField setFrame:CGRectMake(6, 35, 275, 40)];
    [_scrollView setFrame:CGRectMake(0, 0, 321, 35)];
    [_button setFrame:CGRectMake(281, 35, 40, 40)];

    [self addSubview:_textField];
    [self addSubview:_scrollView];
    [self addSubview:_button];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        //[self tagSpaceInit];
    }

    return self;
}

- (void)tagSpaceInit
{
    //alloc-init arrays
    _tagArray = [[NSMutableArray alloc] init];
    _textWords = [[NSMutableArray alloc] init];

    NSLog(@"Heres the _tagSpaceEditable:%d",_tagSpaceEditable);

    //alloc-init objs
    if(_tagSpaceEditable)
    {
        _textField = [[UITextField alloc] init];
        _button = [[UIButton alloc] init];
        //frame is set already by storyboard

    }else
    {
        //tagSpace is not editable
    }

    _scrollView = [[UIScrollView alloc] init];

    self.textField.delegate = self;
    self.textField.backgroundColor = [UIColor blackColor];
    self.textField.returnKeyType = UIReturnKeyDone;

    //customize
    [_textField setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
    [_textField setTextAlignment:NSTextAlignmentLeft];
    [_textField setBorderStyle:UITextBorderStyleNone];
    [_textField setPlaceholder:@"add tags.."];
    [_textField setBackgroundColor:[UIColor colorWithHexString:@"FFFFFF"]];

    [_button setBackgroundColor:[UIColor colorWithHexString:@"669900"]];
    [_button setImage:[UIImage imageNamed:@"addTagImage.png"] forState:UIControlStateNormal];
}

-(void)tagFieldDidChange:(NSString *)tagSpaceString
{
    //make sure theres been at least one space
    if ([tagSpaceString containsString:@" "])
    {
        _textWords = [[tagSpaceString componentsSeparatedByString:@" "] mutableCopy];
        [_textWords removeObjectAtIndex:_textWords.count - 1];

        if(_textWords.count > _lastTagArrayCount)
        {
            UIButton *lastTag;
            float nextXPosition;
            UIButton *newTag;

            //We have to check - Is there a tag in tagArray?
            if(_lastTagArrayCount >= 1)
            {
                lastTag = _tagArray[_textWords.count - 2];
                nextXPosition = [self findNextTagXPosition:lastTag];
                newTag = [self createTag:_textWords[_textWords.count - 1] withXPosition:nextXPosition];
            }
            else
            {
                //the tag to create is the first tag in tagSpace
                newTag = [self createTag:_textWords[_textWords.count - 1] withXPosition:5];
            }


            _lastTagArrayCount++;
            [_tagArray addObject:newTag];
            [_scrollView addSubview:newTag];

        }

    }

}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range
replacementString: (NSString*) string
{
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: [UIColor blackColor]};
    const CGSize quickCharSize = [string sizeWithAttributes: userAttributes];
    float quickWidth = quickCharSize.width;

    //NSLog(@"Here is the replacement string: %@", string);
    NSString *catchString = _textField.text;
    NSString *stringConstruct = [catchString stringByAppendingString:string];
    [self tagFieldDidChange:stringConstruct]; //grab the tagSpaceTextField's current string and add the replacementString on

    //The user is attempting a backspace, let them
    if (quickWidth == 0)
    {
        //grabs the char that's about to be deleted
        NSString *charToChange  = [[textField text] substringWithRange:range];

        if ([charToChange isEqual: @" "])
        {
            //We want to delete entire tag - check chars backwards until hitting a space or range.location == 0
            int i;
            NSString *tempStr = @"";
            NSRange *tempRange = &range;

            //This for-loop grabs the substring behind the textfield cursor
            for (i = 1; i <= textField.text.length; i++)
            {
                if ([tempStr isEqualToString:@" "])
                {
                    tempRange->location = (tempRange->location + 1);
                    tempRange->length = i - 1; //set the length to i so we grab the full word
                    break; //exit the for loop if we run into another space or the beginning of textField
                }else if (range.location == 0)
                {
                    tempRange->length = i;
                    break;
                }

                tempRange->location = (tempRange->location - 1);

                tempStr = [[textField text] substringWithRange:*tempRange];
            }

            //grab the full word
            NSString *stringToRemove = [[textField text] substringWithRange:*tempRange];

            //remove the string from the textfield
            NSString *regexFormat = [[NSArray arrayWithObjects:@"\\b",stringToRemove, nil] componentsJoinedByString:@""];
            NSString *catchString = textField.text;
            NSError *error = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexFormat options:NSRegularExpressionCaseInsensitive error:&error];
            NSString *modifiedString = [regex stringByReplacingMatchesInString:catchString options:0 range:NSMakeRange(0, [catchString length]) withTemplate:@""];

            textField.text = modifiedString;

            //delete the appropriate tag
            stringToRemove = [stringToRemove stringByReplacingOccurrencesOfString:@" " withString:@""];
            for (int i = 0; i < _tagArray.count; i++)
                if ( [((UIButton *)_tagArray[i]).titleLabel.text isEqualToString:stringToRemove] )
                    [self deleteTag:_tagArray[i]]; //found the matching button - remove it

            [self reframeContent:_scrollView];

            return NO;
        }

        return YES;
    }

    //Prevents "undo" crash - see the web
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }

    //limits the user to 10 tags
    if (_lastTagArrayCount == 10)
        return NO;

    //Make sure there's at least one tag
    if (_tagArray.count > 0)
    {
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                         NSForegroundColorAttributeName: [UIColor blackColor]};
        const CGSize charSize = [string sizeWithAttributes: userAttributes];
        const CGSize lastWordSize = [_textWords[_textWords.count - 1] sizeWithAttributes:userAttributes];
        float totalWordWidth = lastWordSize.width + charSize.width;

        float desiredTagWidth = 0.0;
        //determine the dynamic width to be used for the tag
        if (totalWordWidth <= 12.0 && totalWordWidth > 9) {
            desiredTagWidth = totalWordWidth + 16;
        }
        else if (totalWordWidth <= 9)
        {
            desiredTagWidth = totalWordWidth + 19;
        }
        else{
            desiredTagWidth = totalWordWidth + 10;
        }

        //  UIButton *catchLastTagButton = tagArray[tagArray.count - 1];
        //        float totalWidth = (catchLastTagButton.frame.origin.x + catchLastTagButton.frame.size.width + 5 + desiredTagWidth + 5);
        [self reframeContent:_scrollView];
        //        if([tagArray count] > 0){
        //            [self.tagSpace setContentOffset:CGPointMake(((UIButton *)[tagArray objectAtIndex:[tagArray count]-1]).frame.origin.x,((UIButton *)[tagArray objectAtIndex:[tagArray count]-1]).frame.origin.y) animated:YES];
        //        }

        return YES;

    }
    else
    {
        //If there's not even one tag, we just return YES
        return YES;
    }

    //[self reframeContent:_scrollView];

}

-(UIButton *)createTag:(NSString *)word withXPosition:(float)xPositionToUse
{
    UIButton *tag;
    float widthToUse = 0.0;

    UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: [UIColor blackColor]};
    const CGSize textSize = [word sizeWithAttributes: userAttributes];
    float grabWidth = textSize.width;

    if (grabWidth <= 12.0 && grabWidth > 9) {
        widthToUse = grabWidth + 16;
    }
    else if (grabWidth <= 9)
    {
        widthToUse = grabWidth + 19;
    }
    else{
        widthToUse = grabWidth + 10;
    }

    tag = [[UIButton alloc] initWithFrame:CGRectMake(xPositionToUse, Y_POSITION_FOR_TAGS, widthToUse, 25)];
    tag.backgroundColor = [UIColor colorWithHexString:@"669900"];
    tag.layer.borderColor = [UIColor colorWithHexString:@"669900"].CGColor;
    tag.layer.borderWidth = 1.0;
    tag.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    tag.layer.cornerRadius = 12.5; //12
    [tag addTarget:self action:@selector(deleteTag:) forControlEvents:UIControlEventTouchUpInside];
    [tag setTitle:word forState:UIControlStateNormal];

    return tag;
}

-(float)findNextTagXPosition:(UIButton *)lastTag
{
    float nextXPosition = 0.0;

    nextXPosition = (lastTag.frame.origin.x + lastTag.frame.size.width + 5);

    return nextXPosition;
}

-(void) reframeContent:(UIScrollView *)scrollView
{
    CGRect contentRect = CGRectZero;

    for (UIView *view in scrollView.subviews)
        contentRect = CGRectUnion(contentRect, view.frame);

    scrollView.contentSize = contentRect.size;
}

-(void)deleteTag:(UIButton *)sender
{
    //grab sender and delete
    [sender removeFromSuperview];

    NSString *stringToReplace = [[NSArray arrayWithObjects:@"\\b",sender.titleLabel.text,@" ", nil] componentsJoinedByString:@""];
    NSString *catchString = _textField.text;
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:stringToReplace options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:catchString options:0 range:NSMakeRange(0, [catchString length]) withTemplate:@""];

    _textField.text = modifiedString;

    //call shift here
    int indexOfDeletedTag = (int)[_tagArray indexOfObject:sender]; //to check for last tag
    if (_lastTagArrayCount >= 2 && !((indexOfDeletedTag == (_tagArray.count - 1))) ) {
        [self shiftAllTagsOnDeletion:sender];
    }


    [_tagArray removeObject:sender];
    _lastTagArrayCount--;
}

-(void)shiftAllTagsOnDeletion:(UIButton *)deletedTag
{
    //First, grab the next sequential tag
    int indexOfDeletedTag = (int)[_tagArray indexOfObject:deletedTag];

    UIButton *catchNextButton = [_tagArray objectAtIndex:((int)indexOfDeletedTag + 1)];
    float nextXPosition = 0.0;

    //We know the deleted tag was first tag
    if (indexOfDeletedTag == 0)
    {
        //set frame of next button because its the first tag
        [UIView animateWithDuration:0.5f delay:0.0f options:0
                         animations:^{
                             [catchNextButton setFrame:CGRectMake(0, Y_POSITION_FOR_TAGS, catchNextButton.frame.size.width, catchNextButton.frame.size.height)];
                         }completion:nil];

        for (int i = 0; i < (_tagArray.count - 2); i++)
        {
            catchNextButton = [_tagArray objectAtIndex:(indexOfDeletedTag + 2 + i)];

            nextXPosition = [self findNextTagXPosition:_tagArray[indexOfDeletedTag + 1 + i]];
            //            nextYPosition = [self findNextTagYPosition:tagArray[indexOfDeletedTag + 1 + i] stringOfNewTag:catchNextButton.titleLabel.text widthOfTagSpace:widthOfTagSpace];

            [UIView animateWithDuration:0.5f delay:0.0f options:0
                             animations:^{
                                 [catchNextButton setFrame:CGRectMake(nextXPosition, Y_POSITION_FOR_TAGS, catchNextButton.frame.size.width, catchNextButton.frame.size.height)];
                             }completion:nil];
        }

    }
    else
    {
        catchNextButton = [_tagArray objectAtIndex:(indexOfDeletedTag + 1)];

        nextXPosition = [self findNextTagXPosition:_tagArray[indexOfDeletedTag - 1]];


        [UIView animateWithDuration:0.5f delay:0.0f options:0
                         animations:^{
                             [catchNextButton setFrame:CGRectMake(nextXPosition, Y_POSITION_FOR_TAGS, catchNextButton.frame.size.width, catchNextButton.frame.size.height)];
                         }completion:nil];

        for (int i = 0; i < ( _tagArray.count - (indexOfDeletedTag + 1) - 1 ); i++)
        {
            catchNextButton = [_tagArray objectAtIndex:(indexOfDeletedTag + 2 + i)];

            nextXPosition = [self findNextTagXPosition:_tagArray[indexOfDeletedTag + 1 + i]];

            [UIView animateWithDuration:0.5f delay:0.0f options:0
                             animations:^{
                                 [catchNextButton setFrame:CGRectMake(nextXPosition, Y_POSITION_FOR_TAGS, catchNextButton.frame.size.width, catchNextButton.frame.size.height)];
                             }completion:nil];
        }

    }

}

#pragma mark - Internal calls - generating tags and populating tagSpace remotely

-(void)createTagsForPost:(postClass *)p
{
    float widthOfTagSpace = 0.0;
    widthOfTagSpace = 320;

    UIButton *lastTag;
    float nextXPosition;
    UIButton *newTag;

    //Generate all tags
    for(int i=0; i<[p.tags count]; i++){

        //If more than one tag we look at the previous tag for the new position
        if(i >= 1)
        {
            lastTag = p.tagButtons[i-1];
            nextXPosition = [self findNextTagXPosition:lastTag];
            newTag = [self createTag:p.tags[i] withXPosition:nextXPosition];
        }
        else
        {
            //the tag to create is the first tag in tagSpace
            newTag = [self createTag:p.tags[i] withXPosition:5];

        }

        [p.tagButtons addObject:newTag];
    }

    p.tagsCreated = YES;

}

-(void)putTagsFrom:(postClass *)p inSpace:(UIView *)tagSpace
{
    for(int i=0; i < [p.tagButtons count]; i++){
        [tagSpace addSubview:[p.tagButtons objectAtIndex:i]];
    }
}


#pragma mark - UITextFieldDelegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidBeginEditing triggered");
    [self.textField becomeFirstResponder];
}


-(void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidEndEditing triggered");
}


-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textFieldShouldReturn triggered");
    [textField resignFirstResponder];

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    //    for (UIView *subView in tagSpace.subviews)
    //        [subView removeFromSuperview];

    //    [tagArray removeAllObjects];
    //    lastTagArrayCount = 0;

    return YES;
}


@end
