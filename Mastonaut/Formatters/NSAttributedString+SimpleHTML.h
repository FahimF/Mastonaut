//
//  NSAttributedString+SimpleHTML.h
//  Mastonaut
//
//  Created by Bruno Philipe on 06.01.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (SimpleHTML)

@property (readonly) NSAttributedString *attributedStringRemovingLinks NS_SWIFT_NAME(removingLinks);

+ (NSAttributedString *)attributedStringWithSimpleHTML:(NSString *)htmlString;
+ (NSAttributedString *)attributedStringWithSimpleHTML:(NSString *)htmlString removingTrailingUrl:(nullable NSURL *)url removingInvisibleSpans:(BOOL)removeInvisibles;

@end

NS_ASSUME_NONNULL_END
