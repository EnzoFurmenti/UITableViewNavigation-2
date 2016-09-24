//
//  ViewController.m
//  UITableViewNavigation-2
//
//  Created by EnzoF on 23.09.16.
//  Copyright © 2016 EnzoF. All rights reserved.
//

#import "TableViewController.h"
#import "TableViewFileCell.h"
#import "TableViewDirectoryCell.h"
#import "UIView+ParentCell.h"

typedef enum{
    ViewControllerSizeOfFileByte = 1,
    ViewControllerSizeOfFileKByte = 1024,
    ViewControllerSizeOfFileMByte = 1048576,
    ViewControllerSizeOfFileGByte = 1073741824
}ViewControllerSizeOfFileType;

@interface TableViewController ()

@property(strong,nonatomic) NSString *path;
@property(strong,nonatomic) NSArray *content;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];  
    if(!self.path)
    {
        self.path = @"/Users/EnzoF/Desktop/fileManager";
    }
    if([self.navigationController.viewControllers count] > 1)
    {
        UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"Back to Again" style:UIBarButtonItemStyleDone target:self action:@selector(actionBackToRoot:)];
        self.navigationItem.rightBarButtonItem = item;
    }
}
-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController setToolbarHidden:NO];
    [self.navigationController.toolbar setBarStyle:UIBarStyleDefault];
    [self setToolbarItems:[self toolBarItemsWithEditButton:UIBarButtonSystemItemEdit]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Lazy initialization
-(void)setContent:(NSArray *)content{
    void (^sortBlock)(void) = ^{
        
        NSURL *url = [[NSURL alloc] initFileURLWithPath:self.path];
        NSEnumerator *arrayContent = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants  errorHandler:nil];
        NSMutableArray *filtredMArray = [[NSMutableArray alloc]init];
        for (NSURL *curretnURL in [arrayContent allObjects])
        {
            NSString *fileName = [curretnURL.path lastPathComponent];
            [filtredMArray addObject:fileName];
        }
        
        
        NSMutableArray *mSortedArray = [[NSMutableArray alloc]initWithArray:filtredMArray];
        [mSortedArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *name1 = (NSString*)obj1;
            NSString *name2 = (NSString*)obj2;
            return [name1 caseInsensitiveCompare:name2];
        }];
        
        [mSortedArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *type1;
            NSString *type2;
            type1 = [self isDirectoryFileName:(NSString*)obj1] ? @"A" : @"B";
            type2 = [self isDirectoryFileName:(NSString*)obj2] ? @"A" : @"B";
            return [type1 compare:type2];
        }];
        _content = [[NSArray alloc]initWithArray:mSortedArray];
    };
    sortBlock();
}


-(void)setPath:(NSString *)path{
    _path = path;
    NSError *error = nil;
    self.content = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:self.path error:&error];
    if(error)
    {
        NSLog(@"%@",[error localizedDescription]);
    }
    [self.tableView reloadData];
    self.navigationItem.title = [self.path lastPathComponent];
}
#pragma mark - action
-(void)actionBackToRoot:(UIBarButtonItem*)barButton{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)actionAdd:(UIBarButtonItem*)barButton{
    NSError *error = nil;
    NSString *titleOfHeader = [NSString stringWithFormat:@"Папка-%u",[self.content count] + 1];
    NSString *newPath = [self.path stringByAppendingPathComponent:titleOfHeader];
    [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:NO attributes:nil error:&error];
    if(error)
    {
        NSLog(@"ошибка %@",[error localizedDescription]);
    }
    
    self.content = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:self.path error:nil];
    NSInteger newFileIndex = [self.content indexOfObject:titleOfHeader];
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:newFileIndex inSection:0];
    NSArray<NSIndexPath*>*arrayIndexSet = [[NSArray alloc]initWithObjects:newIndexPath,nil];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:arrayIndexSet withRowAnimation:UITableViewRowAnimationLeft];
    [self.tableView endUpdates];
    [[UIApplication sharedApplication]beginIgnoringInteractionEvents];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        if([app isIgnoringInteractionEvents])
        {
            [app endIgnoringInteractionEvents];
        }
    });
    
    
}


-(void)actionEdit:(UIBarButtonItem*)barButton{
    
    UIBarButtonSystemItem itemOption = self.tableView.editing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
    [self.tableView setEditing:self.tableView.editing ? NO : YES animated:YES];
    [self setToolbarItems:[self toolBarItemsWithEditButton:itemOption]];
}

-(IBAction)actionInfo:(UIButton *)sender{
    UITableViewCell *currentCell = [sender superCell];
    if(currentCell)
    {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:currentCell];
        currentCell = [self.tableView cellForRowAtIndexPath:indexPath];
        if([currentCell isKindOfClass:[TableViewFileCell class]])
        {
            TableViewFileCell *cell = (TableViewFileCell*)currentCell;
            NSError *error = nil;
            NSString *path = [self.path stringByAppendingPathComponent:cell.fileName.text];
            NSDictionary *atributesDictionary = [[NSFileManager defaultManager]attributesOfItemAtPath:path error:&error];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:@"dd MM YYYY hh:mm:ss"];
            
            NSString *dateOfCreation =[dateFormatter stringFromDate:[atributesDictionary objectForKey:NSFileCreationDate]];
            NSString *dateMoficate =[dateFormatter stringFromDate:[atributesDictionary objectForKey:NSFileModificationDate]];
            NSInteger referenceCount = [[atributesDictionary objectForKey:NSFileReferenceCount] integerValue];
            NSString *type = [atributesDictionary objectForKey:NSFileType];
            NSString *owner = [atributesDictionary objectForKey:NSFileOwnerAccountName];
            
            if(!error)
            {
                NSLog(@"%@",[error localizedDescription]);
            }
        
                    NSString *title = [NSString stringWithFormat:@"Инфа о файле %@,",cell.fileName.text];
                    NSString *infoMessage = [NSString stringWithFormat:@"Дата создания: %@\n"
                                             "Дата модификации:%@\n"
                                             "Тип файла:%@\n"
                                             "Владелец:%@\n"
                                             "Количество ссылок:%d\n",
                                             dateOfCreation,
                                             dateMoficate,
                                             type,
                                             owner,
                                             referenceCount];
                    UIAlertController *allertInfo = [UIAlertController alertControllerWithTitle:title
                                                                                        message:infoMessage
                                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {}];
                    
                    [allertInfo addAction:defaultAction];
                    [self presentViewController:allertInfo animated:YES completion:nil];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.content count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifierCellFile = @"FileCell";
    static NSString *identifierCellDirectory = @"DirectoryCell";
    NSString *fileName = [self.content objectAtIndex:indexPath.row];
    if([self isDirectoryAtIndexPath:indexPath])
    {
        TableViewDirectoryCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierCellDirectory];
        NSString *path = [self.path stringByAppendingPathComponent:fileName];
        NSError *error = nil;
        NSArray<NSString*> *arrayFileNames = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:path error:&error];
        if(error)
        {
            NSLog(@"ошибка %@",[error localizedDescription]);
        }
        cell.size.text  = [self sizeOfDirectory:path withArrayFileName:arrayFileNames];
        cell.fileName.text = fileName;
        return cell;
    }
    else{
        TableViewFileCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierCellFile];
            cell.size.text  = [self sizeOfFile:fileName];
            cell.fileName.text = fileName;
        
        return cell;
    }    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if([self isDirectoryAtIndexPath:indexPath])
    {

        NSString *fileName = [self.content objectAtIndex:indexPath.row];
        NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
        TableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"TableViewController"];
        vc.path = filePath;
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSError *error = nil;
        NSString *fileName = [self.content objectAtIndex:indexPath.row];
        NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if(error)
        {
            NSLog(@"%@",[error localizedDescription]);
        }
        
        self.content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section];
        NSArray *arrayIndexPath = [[NSArray alloc]initWithObjects:newIndexPath, nil];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:arrayIndexPath withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView endUpdates];
        
        [[UIApplication sharedApplication]beginIgnoringInteractionEvents];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIApplication *app = [UIApplication sharedApplication];
            if([app isIgnoringInteractionEvents])
            {
                [app endIgnoringInteractionEvents];
            }
        });
    }
}


#pragma mark - metods
-(BOOL)isDirectoryAtIndexPath:(NSIndexPath*)indexPath{
    
    NSString *fileName = [self.content objectAtIndex:indexPath.row];
    NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
    BOOL isDirectory = YES;
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    return isDirectory;
}

-(NSArray<UIBarButtonItem*>*)toolBarItemsWithEditButton:(UIBarButtonSystemItem)barButtonSystemItem{
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionAdd:)];
    
    UIBarButtonItem *itemFlexible = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:barButtonSystemItem target:self action:@selector(actionEdit:)];
    return [[NSArray alloc]initWithObjects:item1,itemFlexible,item2, nil];
}

-(void)sortedContent{
    NSMutableArray *mSortedArray = [[NSMutableArray alloc]initWithArray:self.content];
    [mSortedArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *name1 = obj1;
        NSString *name2 = obj2;
        return [name1 compare:name2];
    }];
    
    [mSortedArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *type1;
        NSString *type2;
        type1 = [self isDirectoryFileName:obj1] ? @"A" : @"B";
        type2 = [self isDirectoryFileName:obj2] ? @"A" : @"B";
        return [type1 compare:type2];
    }];
    self.content = [[NSArray alloc]initWithArray:mSortedArray];
}

-(BOOL)isDirectoryFileName:(NSString*)fileName{
    BOOL isDirectory = NO;
    
    NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    return isDirectory;
}

-(BOOL)isDirectoryPath:(NSString*)path{
    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    return isDirectory;
}

-(NSString*)sizeOfFile:(NSString*)fileName{
    NSString *path = [self.path stringByAppendingPathComponent:fileName];
    NSError *error = nil;
    NSDictionary<NSString *, id> *atributesDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if(error)
    {
        NSLog(@"%@",[error localizedDescription]);
    }
    NSInteger size = [[atributesDict objectForKey:NSFileSize] integerValue];
    return [self invertInMetricalStr:size];
}

-(NSString*)sizeOfDirectory:(NSString*)pathDir withArrayFileName:(NSArray*)fileNames{
    NSInteger allSizeFiles = [self countOfFilesAtDirectory:pathDir withArray:fileNames withIndexOfFile:0];
    return [self invertInMetricalStr:allSizeFiles];
    
}

-(NSInteger)countOfFilesAtDirectory:(NSString*)pathDir withArray:(NSArray*)fileNames withIndexOfFile:(NSInteger)indexOfFile{
    NSInteger fileSize  = 0;
    if(indexOfFile < [fileNames count])
    {
        NSString *path = [pathDir stringByAppendingPathComponent:[fileNames objectAtIndex:indexOfFile]];
        if([self isDirectoryPath:path])
        {
            NSArray<NSString*> *currentFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
            fileSize += [self countOfFilesAtDirectory:path withArray:currentFileNames withIndexOfFile:0];
        }
        NSError *error = nil;
        NSDictionary<NSString *, id> *atributesDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        if(error)
        {
            NSLog(@"%@",[error localizedDescription]);
        }
        NSInteger currentIndexOfFile = indexOfFile + 1;
        fileSize += [[atributesDict objectForKey:NSFileSize] integerValue];
        fileSize += [self countOfFilesAtDirectory:pathDir withArray:fileNames withIndexOfFile:currentIndexOfFile];
    }
    return fileSize;
}

-(NSString*)invertInMetricalStr:(NSInteger)size{
    NSString *sizeOfFileStr;
    CGFloat sizeOfFile;
    if(size / ViewControllerSizeOfFileGByte != 0)
    {
        sizeOfFile = size / (CGFloat)ViewControllerSizeOfFileGByte;
        sizeOfFileStr = [NSString stringWithFormat:@"%1.2f GB",sizeOfFile];
        
    }else if(size / ViewControllerSizeOfFileMByte !=0){
        
        sizeOfFile = size / (CGFloat)ViewControllerSizeOfFileMByte;
        sizeOfFileStr = [NSString stringWithFormat:@"%1.2f MB",sizeOfFile];
        
    }else if(size / ViewControllerSizeOfFileKByte !=0){
        
        sizeOfFile = size / (CGFloat)ViewControllerSizeOfFileKByte;
        sizeOfFileStr = [NSString stringWithFormat:@"%1.2f KB",sizeOfFile];
        
    }else if(size / ViewControllerSizeOfFileByte !=0){
        
        sizeOfFile = size / (CGFloat)ViewControllerSizeOfFileByte;
        sizeOfFileStr = [NSString stringWithFormat:@"%ld B",(long)size];
        sizeOfFile = size;
    }
    else
    {
        sizeOfFileStr = @"< 1B";
    }
    return sizeOfFileStr;
}
@end
