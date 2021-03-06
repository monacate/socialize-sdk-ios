/*
 * SocializeEntityService.m
 * SocializeSDK
 *
 * Created on 6/17/11.
 * 
 * Copyright (c) 2011 Socialize, Inc.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "SocializeEntityService.h"
#import "SocializeObjectFactory.h"
#import "SocializeProvider.h"
#import "SocializeEntity.h"


#define ENTITY_GET_ENDPOINT     @"entity/"
#define ENTITY_CREATE_ENDPOINT  @"entity/"
#define ENTITY_LIST_ENDPOINT    @"entity/list/"

#define IDS_KEY @"ids"
#define ENTRY_KEY @"key"
#define ENTITY_KEY @"entity"
#define COMMENT_KEY @"text"


@interface SocializeEntityService()
@end

@implementation SocializeEntityService


-(void) dealloc
{
    [super dealloc];
}

-(Protocol *)ProtocolType
{
    return  @protocol(SocializeEntity);
}

-(void)entityWithKey:(NSString *)keyOfEntity
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:keyOfEntity,ENTRY_KEY, nil];
    [_provider requestWithMethodName:ENTITY_GET_ENDPOINT andParams:params  expectedJSONFormat:SocializeDictionaryWIthListAndErrors andHttpMethod:@"GET" andDelegate:self]; 
}

-(void)createEntities:(NSArray *)entities expectedResponseFormat:(ExpectedResponseFormat)expectedFormat
{
    NSString * stringRepresentation =  [_objectCreator createStringRepresentationOfArray:entities]; 
    NSMutableDictionary* params = [self genereteParamsFromJsonString:stringRepresentation];
    [_provider requestWithMethodName:ENTITY_CREATE_ENDPOINT andParams:params  expectedJSONFormat:SocializeDictionaryWIthListAndErrors andHttpMethod:@"POST" andDelegate:self];
}

-(void)createEntity:(id<SocializeEntity>)entity
{
    [self createEntities:[NSArray arrayWithObject:entity]];
}


//-(void)fetchEntity:(NSString*)key
//{
//    NSMutableDictionary*  params = [[[NSMutableDictionary alloc] init] autorelease]; 
//    [params setObject:key forKey:@"id"];
//    NSString* updatedResource = [NSString stringWithFormat:@"%@%@/", ENTITY_KEY, key]; 
//    [_provider requestWithMethodName:updatedResource andParams:params  expectedJSONFormat:SocializeDictionaryWIthListAndErrors andHttpMethod:@"GET" andDelegate:self];
//}

-(void)createEntityWithKey:(NSString *)keyOfEntity andName:(NSString *)nameOfEntity
{
    id<SocializeEntity> entity = (id<SocializeEntity>)[_objectCreator createObjectForProtocol:@protocol(SocializeEntity)];
   
    entity.key = keyOfEntity;
    entity.name = nameOfEntity;
   
    [self createEntity:entity];
}

-(void)createEntities:(NSArray *)entities
{
    [self createEntities:entities expectedResponseFormat:SocializeDictionaryWIthListAndErrors];
}

@end
