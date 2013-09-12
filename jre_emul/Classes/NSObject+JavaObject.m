// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  NSObject+JavaObject.m
//  JreEmulation
//
//  Created by Tom Ball on 8/15/11.
//

#import "NSObject+JavaObject.h"
#import "IOSClass.h"
#import "java/lang/ClassCastException.h"
#import "java/lang/CloneNotSupportedException.h"
#import "java/lang/IllegalArgumentException.h"
#import "java/lang/IllegalMonitorStateException.h"
#import "java/lang/InternalError.h"
#import "java/lang/NullPointerException.h"
#import "objc-sync.h"

// A category that adds Java Object-compatible methods to NSObject.
@implementation NSObject (JavaObject)

- (id)clone {
  if (![self conformsToProtocol:@protocol(NSCopying)] &&
      ![self conformsToProtocol:@protocol(NSMutableCopying)]) {
    id exception = [[JavaLangCloneNotSupportedException alloc] init];
#if ! __has_feature(objc_arc)
    [exception autorelease];
#endif
    @throw exception;
  }
  // Deliberately not calling "init" on the cloned object. It is expected that
  // any object implementing Cloneable, and all of it's superclasses, will
  // contain a valid implementation of copyAllFieldsTo as is generated by J2ObjC
  // translation.
  id clone = AUTORELEASE([[self class] alloc]);
  [self copyAllFieldsTo:clone];
  return clone;
}

- (IOSClass *)getClass {
  return [IOSClass classWithClass:[self class]];
}

- (int)compareToWithId:(id)other {
#if __has_feature(objc_arc)
  @throw [[JavaLangClassCastException alloc] init];
#else
  @throw [[[JavaLangClassCastException alloc] init] autorelease];
#endif
  return 0;
}

- (void)notify {
  int result = objc_sync_notify(self);
  if (result == OBJC_SYNC_SUCCESS) {  // Test most likely outcome first.
    return;
  }
  if (result == OBJC_SYNC_NOT_OWNING_THREAD_ERROR) {
    @throw AUTORELEASE([[JavaLangIllegalMonitorStateException alloc] init]);
  } else {
    NSString *msg = [NSString stringWithFormat:@"system error %d", result];
    @throw AUTORELEASE([[JavaLangInternalError alloc] initWithNSString:msg]);
  }
}

- (void)notifyAll {
  int result = objc_sync_notifyAll(self);
  if (result == OBJC_SYNC_SUCCESS) {  // Test most likely outcome first.
    return;
  }
  if (result == OBJC_SYNC_NOT_OWNING_THREAD_ERROR) {
    @throw AUTORELEASE([[JavaLangIllegalMonitorStateException alloc] init]);
  } else {
    NSString *msg = [NSString stringWithFormat:@"system error %d", result];
    @throw AUTORELEASE([[JavaLangInternalError alloc] initWithNSString:msg]);
  }
}

static void doWait(id obj, long long timeout) {
  if (timeout < 0) {
    @throw AUTORELEASE([[JavaLangIllegalArgumentException alloc] init]);
  }
  int result = objc_sync_wait(obj, timeout);
  if (result == OBJC_SYNC_SUCCESS || result == OBJC_SYNC_TIMED_OUT) {
    return;
  }
  if (result == OBJC_SYNC_NOT_OWNING_THREAD_ERROR) {
    @throw AUTORELEASE([[JavaLangIllegalMonitorStateException alloc] init]);
  } else {
    NSString *msg = [NSString stringWithFormat:@"system error %d", result];
    @throw AUTORELEASE([[JavaLangInternalError alloc] initWithNSString:msg]);
  }
}

- (void)wait {
  doWait(self, 0LL);
}

- (void)waitWithLong:(long long)timeout {
  doWait(self, timeout);
}

- (void)waitWithLong:(long long)timeout withInt:(int)nanos {
  if (nanos < 0) {
    @throw AUTORELEASE([[JavaLangIllegalArgumentException alloc] init]);
  }
  doWait(self, timeout + (nanos == 0 ? 0 : 1));
}

+ (id)throwClassCastException {
  @throw AUTORELEASE([[JavaLangClassCastException alloc] init]);
  return nil;
}

- (void)copyAllFieldsTo:(id)other {
}

- (NSArray *)memDebugStrongReferences {
  return [NSArray array];
}

+ (NSArray *)memDebugStaticReferences {
  return nil;
}

// Unimplemented private methods for java.lang.ref.Reference. The methods'
// implementations are set when swizzling the Reference's referent class.
- (void)_java_lang_ref_original_dealloc {}
- (void)_java_lang_ref_original_release {}

@end
