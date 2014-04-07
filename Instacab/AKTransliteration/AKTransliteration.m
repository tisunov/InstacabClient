//
// AKTransliteration.m
//
// Copyright (c) 2012 Aleksey Kozhevnikov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AKTransliteration.h"

@interface AKTransliteration ()

@property(nonatomic, strong) NSArray* sortedKeys;
@property(nonatomic, strong) NSDictionary* firstLetterIndex;
@property(nonatomic, strong) NSDictionary* rules;

@end

@implementation AKTransliteration

-(id)initForDirection:(e_TransliterateDirection)direction
{
  self = [super init];
  if( !self ) {
    return nil;
  }
  NSString* path = [[NSBundle mainBundle] pathForResource:[AKTransliteration rulesFileNameForDirection:direction]
                                                   ofType:@"plist"];
  self.rules = [NSDictionary dictionaryWithContentsOfFile:path];
  self.sortedKeys = [[self.rules allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
    // 'ab' should be before 'a'
    if( [obj1 hasPrefix:obj2] ) {
      return NSOrderedAscending;
    } else if( [obj2 hasPrefix:obj1] ) {
      return NSOrderedDescending;
    } else {
      return [obj1 compare:obj2];
    }
  }];
  NSMutableDictionary* firstLetterIndex = [NSMutableDictionary dictionary];
  for( int i = 0; i < self.sortedKeys.count; ++i ) {
    NSString* key = self.sortedKeys[i];
    NSString* firstLetter = [key substringToIndex:1];
    if( ![firstLetterIndex objectForKey:firstLetter] ) {
      [firstLetterIndex setObject:@(i) forKey:firstLetter];
    }
  }
  self.firstLetterIndex = firstLetterIndex;
  return self;
}

-(void)dealloc
{
  self.firstLetterIndex = nil;
  self.sortedKeys = nil;
  self.rules = nil;
}

+(NSString*)rulesFileNameForDirection:(e_TransliterateDirection)direction
{
  switch( direction ) {
    case TD_RuEn:
      return @"RuEnRules";
    case TD_EnRu:
      return @"EnRuRules";
    default:
      return @"RuEnRules";
  }
  return nil;
}

-(NSString*)transliterate:(NSString*)string
{
  NSString* result = nil;
  [self transliterate:string into:&result];
  return result;
}

-(BOOL)transliterate:(NSString*)string into:(NSString**)returnResult
{
  BOOL success = YES;
  NSCharacterSet* letters = [NSCharacterSet letterCharacterSet];
  NSCharacterSet* uppercaseLetters = [NSCharacterSet uppercaseLetterCharacterSet];
  NSMutableString* result = [[NSMutableString alloc] initWithCapacity:string.length];
  for( int i = 0; i < string.length; ++i ) {
    unichar character = [string characterAtIndex:i];
    NSString* characterString = [[NSString stringWithCharacters:&character length:1] lowercaseString];
    // Find first match
    NSInteger keyIndex = NSNotFound;
    NSNumber* startSearchIndex = self.firstLetterIndex[characterString];
    if( startSearchIndex ) {
      for( int k = [startSearchIndex intValue]; k < self.sortedKeys.count; ++k ) {
        NSString* key = self.sortedKeys[k];
        if( i + key.length <= string.length
           && [[string substringWithRange:NSMakeRange(i, key.length)] caseInsensitiveCompare:key] == NSOrderedSame )
        {
          keyIndex = k;
          break;
        }
      }
    }
    // Append right rule part to result
    if( keyIndex == NSNotFound ) {
      if( [letters characterIsMember:character] ) {
        success = NO;
      }
      [result appendString:characterString];
    } else {
      NSString* toAppend = nil;
      id value = [self.rules valueForKey:[self.sortedKeys objectAtIndex:keyIndex]];
      if( !value ) {
        continue;
      }
      if( [value isKindOfClass:[NSString class]] ) {
        toAppend = value;
      } else if( [value isKindOfClass:[NSArray class]] ) {
        toAppend = [value objectAtIndex:0];
      } else {
        NSAssert( NO, @"Right part of rule should be string or array of strings." );
      }
      if( [uppercaseLetters characterIsMember:character] ) {
        toAppend = [toAppend capitalizedString];
      }
      [result appendString:toAppend];
      // If left rule part is more than one symbol
      i += ((NSString*)[self.sortedKeys objectAtIndex:keyIndex]).length - 1;
    }
  }
  if( returnResult ) {
    *returnResult = result;
  }
  return success;
}

@end
