//
//  BleOTAUtils.m
//  itest
//
//  Created by fby on 2021/10/29.
//

#import "BleOTAUtils.h"
#import "EspCRC16.h"

@implementation BleOTAUtils

+ (NSArray<NSData *> *)generateSectors:(NSData *)bin {
    NSMutableArray<NSData *> *sectors = [[NSMutableArray alloc] init];
    NSInputStream *stream = [[NSInputStream alloc] initWithData:bin];
    uint8_t buf[4096];
    [stream open];
    while ([stream hasBytesAvailable]) {
        NSUInteger read = [stream read:buf maxLength:4096];
        NSData *sector = [[NSData alloc] initWithBytes:buf length:read];
        [sectors addObject:sector];
    }
    [stream close];
    
    return sectors;
}

+ (NSData *)generateBinPakcet:(Byte *)data dataLength:(NSUInteger)dataLength index:(NSUInteger)index sequence:(int)sequence crc:(UInt16)crc {
    NSMutableData *packet = [[NSMutableData alloc] init];
    Byte buf[3] = {
        index & 0xff,
        index >> 8 & 0xff,
        sequence & 0xff
    };
    [packet appendBytes:buf length:3];
    [packet appendBytes:data length:dataLength];
    if (sequence < 0) {
        Byte crcBytes[2] = {
            crc & 0xff,
            crc >> 8 & 0xff
        };
        [packet appendBytes:crcBytes length:2];
    }
    
    return packet;
}

+ (NSData *)generateCommandPacket:(int)commandId payload:(NSData *)payload {
    NSMutableData *packet = [[NSMutableData alloc] init];
    Byte idBytes[2] = {
        commandId & 0xff,
        commandId >> 8 & 0xff
    };
    [packet appendBytes:idBytes length:2];
    [packet appendData:payload];
    NSUInteger paddingLen = 18 - packet.length;
    if (paddingLen > 0) {
        NSData *padding = [[NSMutableData alloc] initWithLength:paddingLen];
        [packet appendData:padding];
    }
    UInt16 crc = [EspCRC16 crc:packet];
    Byte crcBytes[2] = {
        crc & 0xff,
        crc >> 8 & 0xff
    };
    [packet appendBytes:crcBytes length:2];
    
    return packet;
}

#pragma mark - 原有START命令（仅binSize，保留兼容）
+ (NSData *)generateStartCommandPacket:(NSUInteger)binSize {
    Byte bytes[4] = {
        binSize & 0xff,
        binSize >> 8 & 0xff,
        binSize >> 16 & 0xff,
        binSize >> 24 & 0xff
    };
    NSData *payload = [[NSData alloc] initWithBytes:bytes length:4];
    return [BleOTAUtils generateCommandPacket:COMMAND_ID_START payload:payload];
}

#pragma mark - 新增：完整START命令（与Android BleOTAClient.postCommandStart 一致）
/**
 * 生成18字节完整payload的START命令
 *
 * payload格式（与Android完全一致）：
 * [0-3]   4字节：binSize (固件大小)
 * [4]     1字节：upgradeType (升级类型: 0=APP, 1=SPIFFS)
 * [5]     1字节：partitionNumber (分区号，SPIFS时有效)
 * [6]     1字节：isDeltaUpgrade (是否差分升级: 0/1)
 * [7]     1字节：partitionType (分区类型)
 * [8]     1字节：partitionSubtype (分区子类型)
 * [9]     1字节：isSpecMode (是否spec模式: 0/1)
 * [10]    1字节：bootPartition (启动分区)
 * [11-17] 7字节：填充0
 */
+ (NSData *)generateStartCommandPacketWithSize:(NSUInteger)binSize
                                   upgradeType:(UpgradeType)upgradeType
                                partitionNumber:(NSInteger)partitionNumber
                                 isDeltaUpgrade:(BOOL)isDeltaUpgrade
                                   partitionType:(NSInteger)partitionType
                               partitionSubtype:(NSInteger)partitionSubtype
                                      isSpecMode:(BOOL)isSpecMode
                                   bootPartition:(NSInteger)bootPartition {
    
    Byte payload[18] = {0};
    
    // [0-3] 前4字节：binSize
    payload[0] = (binSize & 0xff);
    payload[1] = (binSize >> 8 & 0xff);
    payload[2] = (binSize >> 16 & 0xff);
    payload[3] = (binSize >> 24 & 0xff);
    
    // [4] 第5字节：upgradeType（升级类型）
    payload[4] = (Byte)(upgradeType & 0xff);
    
    // [5] 第6字节：partitionNumber（分区号）
    payload[5] = (Byte)(partitionNumber & 0xff);
    
    // [6] 第7字节：isDeltaUpgrade（是否差分升级）
    payload[6] = isDeltaUpgrade ? 1 : 0;
    
    // [7] 第8字节：partitionType（分区类型）
    payload[7] = (Byte)(partitionType & 0xff);
    
    // [8] 第9字节：partitionSubtype（分区子类型）
    payload[8] = (Byte)(partitionSubtype & 0xff);
    
    // [9] 第10字节：isSpecMode（是否为spec模式）
    payload[9] = isSpecMode ? 1 : 0;
    
    // [10] 第11字节：bootPartition（启动分区）
    payload[10] = (Byte)(bootPartition & 0xff);
    
    // [11-17] 剩余7字节填充0（已初始化为0）
    
    NSData *payloadData = [[NSData alloc] initWithBytes:payload length:18];
    return [BleOTAUtils generateCommandPacket:COMMAND_ID_START payload:payloadData];
}

+ (NSData *)generateEndCommandPacket {
    NSData *payload = [[NSMutableData alloc] initWithLength:1];
    return [BleOTAUtils generateCommandPacket:COMMAND_ID_END payload:payload];
}

+ (OTAMessage *)parseCommandPacket:(NSData *)data checksum:(BOOL)checksum {
    Byte *bytes = (Byte *)[data bytes];
    if (checksum) {
        UInt16 srcCRC = bytes[18] | (bytes[19] << 8);
        UInt16 calcCRC = [EspCRC16 crc:data offset:0 length:18];
        if (srcCRC != calcCRC) {
            NSLog(@"parseCommandPacket checksum error: %d, expect %d", srcCRC, calcCRC);
            return nil;
        }
    }
    
    int commandId = bytes[0] | (bytes[1] << 8);
    if (commandId == COMMAND_ID_ACK) {
        int ackId = bytes[2] | (bytes[3] << 8);
        int ackStatus = bytes[4] | (bytes[5] << 8);
        return [[OTAMessage alloc] initWithId:ackId status:ackStatus];
    }
    
    return nil;
}

+ (OTAMessage *)parseBinAckPacket:(NSData *)data {
    Byte *bytes = (Byte *)[data bytes];
    int ackIndex = bytes[0] | (bytes[1] << 8);
    int ackStatus = bytes[2] | (bytes[3] << 8);
    OTAMessage *message = [[OTAMessage alloc] initWithId:COMMAND_ID_ACK status:ackStatus];
    message.index = ackIndex;
    return message;
}

#pragma mark - 文件名解析功能（与Android BleOTAScanActivity.parsePartitionType 一致）

/**
 * 解析固件文件名，提取升级参数
 *
 * 文件名规则（与Android一致）：
 * 1. 以 "delta_" 开头 → isDeltaUpgrade = true
 * 2. 匹配 "spec_X_Y_Z_" 格式 → isSpecMode=true, partitionType=X, partitionSubtype=Y, bootPartition=Z
 * 3. 匹配 "spiffs_N.bin" → upgradeType = SPIFFS, partitionNumber = N
 * 4. 包含 "app" 或以 "delta_"/"spec_" 开头 → APP固件
 *
 * @param fileName 固件文件名（如 "app_v1.0.bin", "delta_app.bin", "spec_0_0_1_app.bin", "spiffs_1.bin"）
 * @return NSDictionary 包含所有解析出的参数
 */
+ (NSDictionary *)parseFirmwareFileName:(NSString *)fileName {
    NSString *lowerName = [fileName lowercaseString];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    result[@"fileName"] = fileName;
    result[@"originalFileName"] = fileName;
    
    // 默认值
    result[@"upgradeType"] = @(UpgradeTypeApp);
    result[@"partitionNumber"] = @0;
    result[@"isDeltaUpgrade"] = @NO;
    result[@"partitionType"] = @0;
    result[@"partitionSubtype"] = @0;
    result[@"isSpecMode"] = @NO;
    result[@"bootPartition"] = @0;
    
    // 1. 检查是否为差分升级（delta_ 开头）
    if ([lowerName hasPrefix:@"delta_"]) {
        result[@"isDeltaUpgrade"] = @YES;
    }
    
    // 2. 解析 spec 模式（spec_X_Y_Z_ 格式）
    NSError *error = nil;
    NSRegularExpression *specRegex = [NSRegularExpression regularExpressionWithPattern:@"spec_(\\d+)_(\\d+)_(\\d+)_" options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *specMatch = [specRegex firstMatchInString:lowerName options:0 range:NSMakeRange(0, lowerName.length)];
    if (specMatch && specMatch.numberOfRanges >= 4) {
        NSString *typeStr = [lowerName substringWithRange:[specMatch rangeAtIndex:1]];
        NSString *subTypeStr = [lowerName substringWithRange:[specMatch rangeAtIndex:2]];
        NSString *bootStr = [lowerName substringWithRange:[specMatch rangeAtIndex:3]];
        
        result[@"partitionType"] = @([typeStr integerValue]);
        result[@"partitionSubtype"] = @([subTypeStr integerValue]);
        result[@"isSpecMode"] = @YES;
        result[@"bootPartition"] = @([bootStr integerValue]);
    }
    
    // 3. 解析 SPIFS 分区号（spiffs_N.bin 格式）
    NSRegularExpression *spiffsRegex = [NSRegularExpression regularExpressionWithPattern:@"spiffs_(\\d+)\\.bin" options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *spiffsMatch = [spiffsRegex firstMatchInString:lowerName options:0 range:NSMakeRange(0, lowerName.length)];
    if (spiffsMatch && spiffsMatch.numberOfRanges >= 2) {
        NSString *partNumStr = [lowerName substringWithRange:[spiffsMatch rangeAtIndex:1]];
        result[@"upgradeType"] = @(UpgradeTypeSPIFFS);
        result[@"partitionNumber"] = @([partNumStr integerValue]);
    }
    
    NSLog(@"[BleOTAUtils] parseFirmwareFileName: %@ -> %@", fileName, result);
    
    return [result copy];
}

@end