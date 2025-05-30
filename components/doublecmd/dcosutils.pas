{
    Double Commander
    -------------------------------------------------------------------------
    This unit contains platform dependent functions dealing with operating system.

    Copyright (C) 2006-2025 Alexander Koblov (alexx2000@mail.ru)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.
}

unit DCOSUtils;
 
{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, DynLibs, DCClassesUtf8, DCBasicTypes, DCConvertEncoding
{$IFDEF UNIX}
  , BaseUnix, DCUnix
{$ENDIF}
{$IFDEF LINUX}
  , DCLinux
{$ENDIF}
{$IFDEF HAIKU}
  , DCHaiku
{$ENDIF}
{$IFDEF MSWINDOWS}
  , JwaWinBase, Windows
{$ENDIF}
  ;

const
  fmOpenSync    = $10000;
  fmOpenDirect  = $20000;
  fmOpenNoATime = $40000;

{$IF DEFINED(UNIX)}
  ERROR_NOT_SAME_DEVICE = ESysEXDEV;
{$ELSE}
  ERROR_NOT_SAME_DEVICE = Windows.ERROR_NOT_SAME_DEVICE;
{$ENDIF}

type
  TFileMapRec = record
    FileHandle : System.THandle;
    FileSize : Int64;
{$IFDEF MSWINDOWS}
    MappingHandle : System.THandle;
{$ENDIF}
    MappedFile : Pointer;
  end;

  TFileAttributeData = packed record
    Size: Int64;
{$IF DEFINED(UNIX)}
    FindData: BaseUnix.Stat;
    property Attr: TUnixMode read FindData.st_mode;
    property PlatformTime: TUnixTime read FindData.st_ctime;
    property LastWriteTime: TUnixTime read FindData.st_mtime;
    property LastAccessTime: TUnixTime read FindData.st_atime;
{$ELSE}
    case Boolean of
      True: (
        FindData: Windows.TWin32FileAttributeData;
        );
      False: (
        Attr: TFileAttrs;
        PlatformTime: DCBasicTypes.TFileTime;
        LastAccessTime: DCBasicTypes.TFileTime;
        LastWriteTime: DCBasicTypes.TFileTime;
        );
{$ENDIF}
  end;

  TCopyAttributesOption = (caoCopyAttributes,
                           caoCopyTime,
                           caoCopyOwnership,
                           caoCopyPermissions,
                           caoCopyXattributes,
                           // Modifiers
                           caoCopyTimeEx,
                           caoCopyAttrEx,
                           caoRemoveReadOnlyAttr);
  TCopyAttributesOptions = set of TCopyAttributesOption;
  TCopyAttributesResult = array[TCopyAttributesOption] of Integer;
  PCopyAttributesResult = ^TCopyAttributesResult;

const
  faInvalidAttributes = TFileAttrs(-1);
  CopyAttributesOptionCopyAll = [caoCopyAttributes, caoCopyTime, caoCopyOwnership];

{en
   Is file a directory
   @param(iAttr File attributes)
   @returns(@true if file is a directory, @false otherwise)
}
function FPS_ISDIR(iAttr: TFileAttrs) : Boolean;
{en
   Is file a symbolic link
   @param(iAttr File attributes)
   @returns(@true if file is a symbolic link, @false otherwise)
}
function FPS_ISLNK(iAttr: TFileAttrs) : Boolean;
{en
   Is file a regular file
   @param(iAttr File attributes)
   @returns(@true if file is a regular file, @false otherwise)
}
function FPS_ISREG(iAttr: TFileAttrs) : Boolean;
{en
   Is file executable
   @param(sFileName File name)
   @returns(@true if file is executable, @false otherwise)
}
function FileIsExeLib(const sFileName : String) : Boolean;
{en
   Is file console executable
   @param(sFileName File name)
   @returns(@true if file is console executable, @false otherwise)
}
function FileIsConsoleExe(const FileName: String): Boolean;
{en
   Copies a file attributes (attributes, date/time, owner & group, permissions).
   @param(sSrc String expression that specifies the name of the file to be copied)
   @param(sDst String expression that specifies the target file name)
   @param(bDropReadOnlyFlag Drop read only attribute if @true)
   @returns(The function returns @true if successful, @false otherwise)
}
function FileIsReadOnly(iAttr: TFileAttrs): Boolean; inline;

{en
   Returns path to a temporary name. It ensures that returned path doesn't exist,
   i.e., there is no filesystem entry by that name.
   If it could not create a unique temporary name then it returns empty string.

   @param(PathPrefix
          This parameter is added at the beginning of each path that is tried.
          The directories in this path are not created if they don't exist.
          If it is empty then the system temporary directory is used.
          For example:
            If PathPrefix is '/tmp/myfile' then files '/tmp/myfile~XXXXXX.tmp' are tried.
            The path '/tmp' must already exist.)
}
function GetTempName(PathPrefix: String; Extension: String = 'tmp'): String;
{en
   Find file in the system PATH
}
function FindInSystemPath(var FileName: String): Boolean;
{en
   Extract file root directory
   @param(FileName File name)
}
function ExtractRootDir(const FileName: String): String;

(* File mapping/unmapping routines *)
{en
   Create memory map of a file
   @param(sFileName Name of file to mapping)
   @param(FileMapRec TFileMapRec structure)
   @returns(The function returns @true if successful, @false otherwise)
}
function MapFile(const sFileName : String; out FileMapRec : TFileMapRec) : Boolean;
{en
   Unmap previously mapped file
   @param(FileMapRec TFileMapRec structure)
}
procedure UnMapFile(var FileMapRec : TFileMapRec);

{en
   Convert from console to UTF8 encoding.
}
function ConsoleToUTF8(const Source: String): RawByteString;

{ File handling functions}
function mbFileOpen(const FileName: String; Mode: LongWord): System.THandle;
function mbFileCreate(const FileName: String): System.THandle; overload; inline;
function mbFileCreate(const FileName: String; Mode: LongWord): System.THandle; overload; inline;
function mbFileCreate(const FileName: String; Mode, Rights: LongWord): System.THandle; overload;
function mbFileAge(const FileName: String): DCBasicTypes.TFileTime;
function mbFileGetTime(const FileName: String): DCBasicTypes.TFileTimeEx;
// On success returns True.
// nanoseconds supported
function mbFileGetTime(const FileName: String;
                       var ModificationTime: DCBasicTypes.TFileTimeEx;
                       var CreationTime    : DCBasicTypes.TFileTimeEx;
                       var LastAccessTime  : DCBasicTypes.TFileTimeEx): Boolean;
// On success returns True.
function mbFileSetTime(const FileName: String;
                       ModificationTime: DCBasicTypes.TFileTime;
                       CreationTime    : DCBasicTypes.TFileTime = 0;
                       LastAccessTime  : DCBasicTypes.TFileTime = 0): Boolean;
// nanoseconds supported
function mbFileSetTimeEx(const FileName: String;
                         ModificationTime: DCBasicTypes.TFileTimeEx;
                         CreationTime    : DCBasicTypes.TFileTimeEx;
                         LastAccessTime  : DCBasicTypes.TFileTimeEx): Boolean;
{en
   Checks if a given file exists - it can be a real file or a link to a file,
   but it can be opened and read from.
   Even if the result is @false, we can't be sure a file by that name can be created,
   because there may still exist a directory or link by that name.
}
function mbFileExists(const FileName: String): Boolean;
function mbFileAccess(const FileName: String; Mode: Word): Boolean;
function mbFileGetAttr(const FileName: String): TFileAttrs; overload;
function mbFileGetAttr(const FileName: String; out Attr: TFileAttributeData): Boolean; overload;
function mbFileSetAttr(const FileName: String; Attr: TFileAttrs): Boolean;
{en
   If any operation in Options is performed and does not succeed it is included
   in the result set. If all performed operations succeed the function returns empty set.
   For example for Options=[caoCopyTime, caoCopyOwnership] setting ownership
   doesn't succeed then the function returns [caoCopyOwnership].
}
function mbFileCopyAttr(const sSrc, sDst: String;
                       Options: TCopyAttributesOptions;
                       Errors: PCopyAttributesResult = nil): TCopyAttributesOptions;
// Returns True on success.
function mbFileSetReadOnly(const FileName: String; ReadOnly: Boolean): Boolean;
function mbDeleteFile(const FileName: String): Boolean;

function mbRenameFile(const OldName: String; NewName: String): Boolean;
function mbFileSize(const FileName: String): Int64;
function FileGetSize(Handle: System.THandle): Int64;
function FileFlush(Handle: System.THandle): Boolean;
function FileFlushData(Handle: System.THandle): Boolean;
function FileIsReadOnlyEx(Handle: System.THandle): Boolean;
function FileAllocate(Handle: System.THandle; Size: Int64): Boolean;
{ Directory handling functions}
function mbGetCurrentDir: String;
function mbSetCurrentDir(const NewDir: String): Boolean;
{en
   Checks if a given directory exists - it may be a real directory or a link to directory.
   Even if the result is @false, we can't be sure a directory by that name can be created,
   because there may still exist a file or link by that name.
}
function mbDirectoryExists(const Directory : String) : Boolean;
function mbCreateDir(const NewDir: String): Boolean;
function mbRemoveDir(const Dir: String): Boolean;
{en
   Checks if any file system entry exists at given path.
   It can be file, directory, link, etc. (links are not followed).
}
function mbFileSystemEntryExists(const Path: String): Boolean;
function mbCompareFileNames(const FileName1, FileName2: String): Boolean;
function mbFileSame(const FileName1, FileName2: String): Boolean;
function mbFileSameVolume(const FileName1, FileName2: String) : Boolean;
{ Other functions }
function mbGetEnvironmentString(Index : Integer) : String;
{en
   Expands environment-variable strings and replaces
   them with the values defined for the current user
}
function mbExpandEnvironmentStrings(const FileName: String): String;
function mbGetEnvironmentVariable(const sName: String): String;
function mbSetEnvironmentVariable(const sName, sValue: String): Boolean;
function mbUnsetEnvironmentVariable(const sName: String): Boolean;
function mbSysErrorMessage: String; overload; inline;
function mbSysErrorMessage(ErrorCode: Integer): String; overload;
{en
   Get current module name
}
function mbGetModuleName(Address: Pointer = nil): String;
function mbLoadLibrary(const Name: String): TLibHandle;
function mbLoadLibraryEx(const Name: String): TLibHandle;
function SafeGetProcAddress(Lib: TLibHandle; const ProcName: AnsiString): Pointer;
{en
   Reads the concrete file's name that the link points to.
   If the link points to a link then it's resolved recursively
   until a valid file name that is not a link is found.
   @param(PathToLink Name of symbolic link (absolute path))
   @returns(The absolute filename the symbolic link name is pointing to,
            or an empty string when the link is invalid or
            the file it points to does not exist.)
}
function mbReadAllLinks(const PathToLink : String) : String;
{en
   If PathToLink points to a link then it returns file that the link points to (recursively).
   If PathToLink does not point to a link then PathToLink value is returned.
}
function mbCheckReadLinks(const PathToLink : String) : String;
{en
   Same as mbFileGetAttr, but dereferences any encountered links.
}
function mbFileGetAttrNoLinks(const FileName: String): TFileAttrs;
{en
   Create a hard link to a file
   @param(Path Name of file)
   @param(LinkName Name of hard link)
   @returns(The function returns @true if successful, @false otherwise)
}
function CreateHardLink(const Path, LinkName: String) : Boolean;
{en
   Create a symbolic link
   @param(Path Name of file)
   @param(LinkName Name of symbolic link)
   @returns(The function returns @true if successful, @false otherwise)
}
function CreateSymLink(const Path, LinkName: string; Attr: UInt32 = faInvalidAttributes) : Boolean;
{en
   Read destination of symbolic link
   @param(LinkName Name of symbolic link)
   @returns(The file name/path the symbolic link name is pointing to.
            The path may be relative to link's location.)
}
function ReadSymLink(const LinkName : String) : String;

{en
   Sets the last-error code for the calling thread
}
procedure SetLastOSError(LastError: Integer);

function GetTickCountEx: UInt64;

implementation

uses
{$IF DEFINED(MSWINDOWS)}
  DCDateTimeUtils, DCWindows, DCNtfsLinks,
{$ENDIF}
{$IF DEFINED(UNIX)}
  Unix, dl,
{$ENDIF}
  DCStrUtils, LazUTF8;

{$IFDEF UNIX}
function SetModeReadOnly(mode: TMode; ReadOnly: Boolean): TMode;
begin
  mode := mode and not (S_IWUSR or S_IWGRP or S_IWOTH);
  if ReadOnly = False then
  begin
    if (mode AND S_IRUSR) = S_IRUSR then
      mode := mode or S_IWUSR;
    if (mode AND S_IRGRP) = S_IRGRP then
      mode := mode or S_IWGRP;
    if (mode AND S_IROTH) = S_IROTH then
      mode := mode or S_IWOTH;
  end;
  Result := mode;
end;

{$ENDIF}

{$IF DEFINED(MSWINDOWS)}
const
  AccessModes: array[0..2] of DWORD  = (
                GENERIC_READ,
                GENERIC_WRITE,
                GENERIC_READ or GENERIC_WRITE);
  ShareModes: array[0..4] of DWORD = (
               0,
               0,
               FILE_SHARE_READ,
               FILE_SHARE_WRITE,
               FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE);
  OpenFlags: array[0..3] of DWORD  = (
                0,
                FILE_FLAG_WRITE_THROUGH,
                FILE_FLAG_NO_BUFFERING,
                FILE_FLAG_WRITE_THROUGH or FILE_FLAG_NO_BUFFERING);

var
  CurrentDirectory: String;
  PerformanceFrequency: LARGE_INTEGER;
{$ELSEIF DEFINED(UNIX)}
const

{$IF NOT DECLARED(O_SYNC)}
  O_SYNC   = 0;
{$ENDIF}

{$IF NOT DECLARED(O_DIRECT)}
  O_DIRECT = 0;
{$ENDIF}

  AccessModes: array[0..2] of cInt  = (
                O_RdOnly,
                O_WrOnly,
                O_RdWr);
  OpenFlags: array[0..3] of cInt  = (
                0,
                O_SYNC,
                O_DIRECT,
                O_SYNC or O_DIRECT);
{$ENDIF}

function  FPS_ISDIR(iAttr: TFileAttrs) : Boolean; inline;
{$IFDEF MSWINDOWS}
begin
  Result := (iAttr and FILE_ATTRIBUTE_DIRECTORY <> 0);
end;
{$ELSE}
begin
  Result := BaseUnix.FPS_ISDIR(TMode(iAttr));
end;
{$ENDIF}

function FPS_ISLNK(iAttr: TFileAttrs) : Boolean; inline;
{$IFDEF MSWINDOWS}
begin
  Result := (iAttr and FILE_ATTRIBUTE_REPARSE_POINT <> 0);
end;
{$ELSE}
begin
  Result := BaseUnix.FPS_ISLNK(TMode(iAttr));
end;
{$ENDIF}

function FPS_ISREG(iAttr: TFileAttrs) : Boolean; inline;
{$IFDEF MSWINDOWS}
begin
  Result := (iAttr and FILE_ATTRIBUTE_DIRECTORY = 0);
end;
{$ELSE}
begin
  Result := BaseUnix.FPS_ISREG(TMode(iAttr));
end;
{$ENDIF}

function FileIsExeLib(const sFileName : String) : Boolean;
var
  fsExeLib : TFileStreamEx;
{$IFDEF MSWINDOWS}
  Sign : Word;
{$ELSE}
  Sign : DWord;
{$ENDIF}
begin
  Result := False;
  if mbFileExists(sFileName) and (mbFileSize(sFileName) >= SizeOf(Sign)) then
  try
    fsExeLib := TFileStreamEx.Create(sFileName, fmOpenRead or fmShareDenyNone);
    try
      {$IFDEF MSWINDOWS}
      Sign := fsExeLib.ReadWord;
      Result := (Sign = $5A4D);
      {$ELSE}
      Sign := fsExeLib.ReadDWord;
      Result := (Sign = $464C457F);
      {$ENDIF}
    finally
      fsExeLib.Free;
    end;
  except
    Result := False;
  end;
end;

function FileIsConsoleExe(const FileName: String): Boolean;
{$IF DEFINED(UNIX)}
begin
  Result:= True;
end;
{$ELSE}
var
  fsFileStream: TFileStreamEx;
begin
  Result:= False;
  try
    fsFileStream:= TFileStreamEx.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      if fsFileStream.ReadWord = IMAGE_DOS_SIGNATURE then
      begin
        fsFileStream.Seek(60, soBeginning);
        fsFileStream.Seek(fsFileStream.ReadDWord, soBeginning);
        if fsFileStream.ReadDWord = IMAGE_NT_SIGNATURE then
        begin
          fsFileStream.Seek(88, soCurrent);
          Result:= (fsFileStream.ReadWord = IMAGE_SUBSYSTEM_WINDOWS_CUI);
        end;
      end;
    finally
      fsFileStream.Free;
    end;
  except
    Result:= False;
  end;
end;
{$ENDIF}

function FileIsReadOnly(iAttr: TFileAttrs): Boolean;
{$IFDEF MSWINDOWS}
begin
  Result:= (iAttr and (faReadOnly or faHidden or faSysFile)) <> 0;
end;
{$ELSE}
begin
  Result:= (((iAttr AND S_IRUSR) = S_IRUSR) and ((iAttr AND S_IWUSR) <> S_IWUSR));
end;
{$ENDIF}

function mbFileCopyAttr(const sSrc, sDst: String;
  Options: TCopyAttributesOptions; Errors: PCopyAttributesResult
  ): TCopyAttributesOptions;
{$IFDEF MSWINDOWS}
var
  Attr: TWin32FileAttributeData;
  Option: TCopyAttributesOption;
  ModificationTime, CreationTime, LastAccessTime: DCBasicTypes.TFileTime;
begin
  Result := [];

  if not GetFileAttributesExW(PWideChar(UTF16LongName(sSrc)), GetFileExInfoStandard, @Attr) then
  begin
    Result := Options;
    if Assigned(Errors) then
    begin
      for Option in Result do
        Errors^[Option]:= GetLastOSError;
    end;
    Exit;
  end;

  if [caoCopyAttributes, caoCopyAttrEx] * Options <> [] then
  begin
    if (not (caoCopyAttributes in Options)) and (Attr.dwFileAttributes and faDirectory = 0) then
      Attr.dwFileAttributes := (Attr.dwFileAttributes or faArchive);
    if (caoRemoveReadOnlyAttr in Options) and ((Attr.dwFileAttributes and faReadOnly) <> 0) then
      Attr.dwFileAttributes := (Attr.dwFileAttributes and not faReadOnly);
    if not mbFileSetAttr(sDst, Attr.dwFileAttributes) then
    begin
      Include(Result, caoCopyAttributes);
      if Assigned(Errors) then Errors^[caoCopyAttributes]:= GetLastOSError;
    end;
  end;

  if not FPS_ISLNK(Attr.dwFileAttributes) then
  begin
    if (caoCopyXattributes in Options) then
    begin
      if not mbFileCopyXattr(sSrc, sDst) then
      begin
        Include(Result, caoCopyXattributes);
        if Assigned(Errors) then Errors^[caoCopyXattributes]:= GetLastOSError;
      end;
    end;

    if ([caoCopyTime, caoCopyTimeEx] * Options <> []) then
    begin
      if not (caoCopyTime in Options) then
      begin
        CreationTime:= 0;
        LastAccessTime:= 0;
      end
      else begin
        CreationTime:= DCBasicTypes.TFileTime(Attr.ftCreationTime);
        LastAccessTime:= DCBasicTypes.TFileTime(Attr.ftLastAccessTime);
      end;
      ModificationTime:= DCBasicTypes.TFileTime(Attr.ftLastWriteTime);

      if not mbFileSetTime(sDst, ModificationTime, CreationTime, LastAccessTime) then
      begin
        Include(Result, caoCopyTime);
        if Assigned(Errors) then Errors^[caoCopyTime]:= GetLastOSError;
      end;
    end;
  end;

  if caoCopyPermissions in Options then
  begin
    if not CopyNtfsPermissions(sSrc, sDst) then
    begin
      Include(Result, caoCopyPermissions);
      if Assigned(Errors) then Errors^[caoCopyPermissions]:= GetLastOSError;
    end;
  end;
end;
{$ELSE}  // *nix
var
  Option: TCopyAttributesOption;
  StatInfo : TDCStat;
  modificationTime: TFileTimeEx;
  creationTime: TFileTimeEx;
  lastAccessTime: TFileTimeEx;
  mode : TMode;
begin
  if DC_fpLStat(UTF8ToSys(sSrc), StatInfo) < 0 then
  begin
    Result := Options;
    if Assigned(Errors) then
    begin
      for Option in Result do
        Errors^[Option]:= GetLastOSError;
    end;
  end
  else begin
    Result := [];
    if FPS_ISLNK(StatInfo.st_mode) then
    begin
      if caoCopyOwnership in Options then
      begin
        // Only group/owner can be set for links.
        if fpLChown(sDst, StatInfo.st_uid, StatInfo.st_gid) = -1 then
        begin
          Include(Result, caoCopyOwnership);
          if Assigned(Errors) then Errors^[caoCopyOwnership]:= GetLastOSError;
        end;
      end;
{$IF DEFINED(HAIKU)}
      if caoCopyXattributes in Options then
      begin
        if not mbFileCopyXattr(sSrc, sDst) then
        begin
          Include(Result, caoCopyXattributes);
          if Assigned(Errors) then Errors^[caoCopyXattributes]:= GetLastOSError;
        end;
      end;
{$ENDIF}
    end
    else
    begin
      if caoCopyTime in Options then
      begin
        modificationTime:= StatInfo.mtime;
        lastAccessTime:= StatInfo.atime;
        creationTime:= StatInfo.birthtime;
        if DC_FileSetTime(sDst, modificationTime, creationTime, lastAccessTime) = false then
        begin
          Include(Result, caoCopyTime);
          if Assigned(Errors) then Errors^[caoCopyTime]:= GetLastOSError;
        end;
      end;

      if caoCopyOwnership in Options then
      begin
        if fpChown(PChar(UTF8ToSys(sDst)), StatInfo.st_uid, StatInfo.st_gid) = -1 then
        begin
          Include(Result, caoCopyOwnership);
          if Assigned(Errors) then Errors^[caoCopyOwnership]:= GetLastOSError;
        end;
      end;

      if caoCopyAttributes in Options then
      begin
        mode := StatInfo.st_mode;
        if caoRemoveReadOnlyAttr in Options then
          mode := SetModeReadOnly(mode, False);
        if fpChmod(UTF8ToSys(sDst), mode) = -1 then
        begin
          Include(Result, caoCopyAttributes);
          if Assigned(Errors) then Errors^[caoCopyAttributes]:= GetLastOSError;
        end;
      end;

{$IF DEFINED(LINUX) or DEFINED(HAIKU)}
      if caoCopyXattributes in Options then
      begin
        if not mbFileCopyXattr(sSrc, sDst) then
        begin
          Include(Result, caoCopyXattributes);
          if Assigned(Errors) then Errors^[caoCopyXattributes]:= GetLastOSError;
        end;
      end;
{$ENDIF}
    end;
  end;
end;
{$ENDIF}

function GetTempName(PathPrefix: String; Extension: String): String;
const
  MaxTries = 100;
var
  FileName: String;
  TryNumber: Integer = 0;
begin
  if PathPrefix = '' then
    PathPrefix := GetTempDir
  else begin
    FileName:= ExtractOnlyFileName(PathPrefix);
    PathPrefix:= ExtractFilePath(PathPrefix);
    // Generated file name should be less the maximum file name length
    if (Length(FileName) > 0) then PathPrefix += UTF8Copy(FileName, 1, 48) + '~';
  end;
  if (Length(Extension) > 0) then
  begin
    if (not StrBegins(Extension, ExtensionSeparator)) then
      Extension := ExtensionSeparator + Extension;
  end;
  repeat
    Result := PathPrefix + IntToStr(System.Random(MaxInt)) + Extension;
    Inc(TryNumber);
    if TryNumber = MaxTries then
      Exit('');
  until not mbFileSystemEntryExists(Result);
end;

function FindInSystemPath(var FileName: String): Boolean;
var
  I: Integer;
  Path, FullName: String;
  Value: TDynamicStringArray;
begin
  Path:= mbGetEnvironmentVariable('PATH');
  Value:= SplitString(Path, PathSeparator);
  for I:= Low(Value) to High(Value) do
  begin
    FullName:= IncludeTrailingPathDelimiter(Value[I]) + FileName;
    if mbFileExists(FullName) then
    begin
      FileName:= FullName;
      Exit(True);
    end;
  end;
  Result:= False;
end;

function ExtractRootDir(const FileName: String): String;
{$IFDEF UNIX}
begin
  Result:= ExcludeTrailingPathDelimiter(FindMountPointPath(ExcludeTrailingPathDelimiter(FileName)));
end;
{$ELSE}
begin
  Result:= ExtractFileDrive(FileName);
end;
{$ENDIF}

function MapFile(const sFileName : String; out FileMapRec : TFileMapRec) : Boolean;
{$IFDEF MSWINDOWS}
begin
  Result := False;
  with FileMapRec do
    begin
      MappedFile := nil;
      MappingHandle := 0;

      FileHandle := mbFileOpen(sFileName, fmOpenRead);
      if FileHandle = feInvalidHandle then Exit;

      Int64Rec(FileSize).Lo := GetFileSize(FileHandle, @Int64Rec(FileSize).Hi);
      if FileSize = 0 then // Cannot map empty files
      begin
        UnMapFile(FileMapRec);
        Exit;
      end;

      MappingHandle := CreateFileMapping(FileHandle, nil, PAGE_READONLY, 0, 0, nil);
      if MappingHandle = 0 then
      begin
        UnMapFile(FileMapRec);
        Exit;
      end;

      MappedFile := MapViewOfFile(MappingHandle, FILE_MAP_READ, 0, 0, 0);
      if not Assigned(MappedFile) then
      begin
        UnMapFile(FileMapRec);
        Exit;
      end;
    end;
  Result := True;
end;
{$ELSE}
var
  StatInfo: BaseUnix.Stat;
begin
  Result:= False;
  with FileMapRec do
    begin
      MappedFile := nil;
      FileHandle:= mbFileOpen(sFileName, fmOpenRead);

      if FileHandle = feInvalidHandle then Exit;
      if fpfstat(FileHandle, StatInfo) <> 0 then
      begin
        UnMapFile(FileMapRec);
        Exit;
      end;

      FileSize := StatInfo.st_size;
      if FileSize = 0 then // Cannot map empty files
      begin
        UnMapFile(FileMapRec);
        Exit;
      end;

      MappedFile:= fpmmap(nil,FileSize,PROT_READ, MAP_PRIVATE{SHARED},FileHandle,0 );
      if MappedFile = MAP_FAILED then
      begin
        MappedFile := nil;
        UnMapFile(FileMapRec);
        Exit;
      end;
    end;
  Result := True;
end;
{$ENDIF}

procedure UnMapFile(var FileMapRec : TFileMapRec);
{$IFDEF MSWINDOWS}
begin
  with FileMapRec do
    begin
      if Assigned(MappedFile) then
      begin
        UnmapViewOfFile(MappedFile);
        MappedFile := nil;
      end;

      if MappingHandle <> 0 then
      begin
        CloseHandle(MappingHandle);
        MappingHandle := 0;
      end;

      if FileHandle <> feInvalidHandle then
      begin
        FileClose(FileHandle);
        FileHandle := feInvalidHandle;
      end;
    end;
end;
{$ELSE}
begin
  with FileMapRec do
    begin
      if FileHandle <> feInvalidHandle then
      begin
        fpClose(FileHandle);
        FileHandle := feInvalidHandle;
      end;

      if Assigned(MappedFile) then
      begin
        fpmunmap(MappedFile,FileSize);
        MappedFile := nil;
      end;
    end;
end;
{$ENDIF}  

function ConsoleToUTF8(const Source: String): RawByteString;
{$IFDEF MSWINDOWS}
begin
  Result:= CeOemToUtf8(Source);
end;
{$ELSE}
begin
  Result:= CeSysToUtf8(Source);
end;
{$ENDIF}

function mbFileOpen(const FileName: String; Mode: LongWord): System.THandle;
{$IFDEF MSWINDOWS}
const
  ft: TFileTime = ( dwLowDateTime: $FFFFFFFF; dwHighDateTime: $FFFFFFFF; );
begin
  Result:= CreateFileW(PWideChar(UTF16LongName(FileName)),
                       AccessModes[Mode and 3] or ((Mode and fmOpenNoATime) shr 10),
                       ShareModes[(Mode and $F0) shr 4], nil, OPEN_EXISTING,
                       FILE_ATTRIBUTE_NORMAL, OpenFlags[(Mode shr 16) and 3]);
  if (Mode and fmOpenNoATime <> 0) then
  begin
    if (Result <> feInvalidHandle) then
      SetFileTime(Result, nil, @ft, @ft)
    else if GetLastError = ERROR_ACCESS_DENIED then
      Result := mbFileOpen(FileName, Mode and not fmOpenNoATime);
  end;
end;
{$ELSE}
begin
  repeat
    Result:= fpOpen(UTF8ToSys(FileName), AccessModes[Mode and 3] or
                    OpenFlags[(Mode shr 16) and 3] or O_CLOEXEC);
  until (Result <> -1) or (fpgeterrno <> ESysEINTR);
  if Result <> feInvalidHandle then
  begin
    FileCloseOnExec(Result);
{$IF DEFINED(DARWIN)}
    if (Mode and (fmOpenSync or fmOpenDirect) <> 0) then
    begin
      if (FpFcntl(Result, F_NOCACHE, 1) = -1) then
      begin
        FileClose(Result);
        Exit(feInvalidHandle);
      end;
    end;
{$ENDIF}
    Result:= FileLock(Result, Mode and $FF);
  end;
end;
{$ENDIF}

function mbFileCreate(const FileName: String): System.THandle;
begin
  Result:= mbFileCreate(FileName, fmShareDenyWrite);
end;

function mbFileCreate(const FileName: String; Mode: LongWord): System.THandle;
begin
  Result:= mbFileCreate(FileName, Mode, 438); // 438 = 666 octal
end;

function mbFileCreate(const FileName: String; Mode, Rights: LongWord): System.THandle;
{$IFDEF MSWINDOWS}
begin
  Result:= CreateFileW(PWideChar(UTF16LongName(FileName)), GENERIC_READ or GENERIC_WRITE,
                       ShareModes[(Mode and $F0) shr 4], nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL,
                       OpenFlags[(Mode shr 16) and 3]);
end;
{$ELSE}
begin
  repeat
    Result:= fpOpen(UTF8ToSys(FileName), O_Creat or O_RdWr or O_Trunc or
                    OpenFlags[(Mode shr 16) and 3] or O_CLOEXEC, Rights);
  until (Result <> -1) or (fpgeterrno <> ESysEINTR);
  if Result <> feInvalidHandle then
  begin
    FileCloseOnExec(Result);
{$IF DEFINED(DARWIN)}
    if (Mode and (fmOpenSync or fmOpenDirect) <> 0) then
    begin
      if (FpFcntl(Result, F_NOCACHE, 1) = -1) then
      begin
        FileClose(Result);
        Exit(feInvalidHandle);
      end;
    end;
{$ENDIF}
    Result:= FileLock(Result, Mode and $FF);
  end;
end;
{$ENDIF}

function mbFileAge(const FileName: String): DCBasicTypes.TFileTime;
{$IFDEF MSWINDOWS}
var
  Handle: System.THandle;
  FindData: TWin32FindDataW;
begin
  Handle:= FindFirstFileW(PWideChar(UTF16LongName(FileName)), FindData);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    Windows.FindClose(Handle);
    Exit(DCBasicTypes.TFileTime(FindData.ftLastWriteTime));
  end;
  Result:= DCBasicTypes.TFileTime(-1);
end;
{$ELSE}
var
  Info: BaseUnix.Stat;
begin
  if fpStat(UTF8ToSys(FileName), Info) >= 0 then
    Result:= DCBasicTypes.TFileTime(Info.st_mtime)
  else begin
    Result:= DCBasicTypes.TFileTime(-1);
  end;
end;
{$ENDIF}

function mbFileGetTime(const FileName: String): DCBasicTypes.TFileTimeEx;
var
  CreationTime, LastAccessTime: DCBasicTypes.TFileTimeEx;
begin
  if not mbFileGetTime(FileName, Result, CreationTime, LastAccessTime) then
    Result:= TFileTimeExNull;
end;

function mbFileGetTime(const FileName: String;
                       var ModificationTime: DCBasicTypes.TFileTimeEx;
                       var CreationTime    : DCBasicTypes.TFileTimeEx;
                       var LastAccessTime  : DCBasicTypes.TFileTimeEx): Boolean;
{$IFDEF MSWINDOWS}
var
  Handle: System.THandle;
begin
  Handle := CreateFileW(PWideChar(UTF16LongName(FileName)),
                        FILE_READ_ATTRIBUTES,
                        FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
                        nil,
                        OPEN_EXISTING,
                        FILE_FLAG_BACKUP_SEMANTICS,  // needed for opening directories
                        0);

  if Handle <> INVALID_HANDLE_VALUE then
    begin
      Result := Windows.GetFileTime(Handle,
                                    @CreationTime,
                                    @LastAccessTime,
                                    @ModificationTime);
      CloseHandle(Handle);
    end
  else
    Result := False;
end;
{$ELSE}
var
  StatInfo : TDCStat;
begin
  Result := DC_fpLStat(UTF8ToSys(FileName), StatInfo) >= 0;
  if Result then
  begin
    ModificationTime:= StatInfo.mtime;
    LastAccessTime:= StatInfo.atime;
    {$IF DEFINED(DARWIN)}
    CreationTime:= StatInfo.birthtime;
    {$ELSE}
    CreationTime:= StatInfo.ctime;
    {$ENDIF}
  end;
end;
{$ENDIF}

function mbFileSetTime(const FileName: String;
                       ModificationTime: DCBasicTypes.TFileTime;
                       CreationTime    : DCBasicTypes.TFileTime = 0;
                       LastAccessTime  : DCBasicTypes.TFileTime = 0): Boolean;
{$IFDEF MSWINDOWS}
begin
  Result:= mbFileSetTimeEx(FileName, ModificationTime, CreationTime, LastAccessTime);
end;
{$ELSE}
var
  NewModificationTime: DCBasicTypes.TFileTimeEx;
  NewCreationTime    : DCBasicTypes.TFileTimeEx;
  NewLastAccessTime  : DCBasicTypes.TFileTimeEx;
begin
  NewModificationTime:= specialize IfThen<TFileTimeEx>(ModificationTime<>0, TFileTimeEx.create(ModificationTime), TFileTimeExNull);
  NewCreationTime:= specialize IfThen<TFileTimeEx>(CreationTime<>0, TFileTimeEx.create(CreationTime), TFileTimeExNull);
  NewLastAccessTime:= specialize IfThen<TFileTimeEx>(LastAccessTime<>0, TFileTimeEx.create(LastAccessTime), TFileTimeExNull);
  Result:= mbFileSetTimeEx(FileName, NewModificationTime, NewCreationTime, NewLastAccessTime);
end;
{$ENDIF}

function mbFileSetTimeEx(const FileName: String;
                         ModificationTime: DCBasicTypes.TFileTimeEx;
                         CreationTime    : DCBasicTypes.TFileTimeEx;
                         LastAccessTime  : DCBasicTypes.TFileTimeEx): Boolean;
{$IFDEF MSWINDOWS}
var
  Handle: System.THandle;
  PWinModificationTime: Windows.LPFILETIME = nil;
  PWinCreationTime: Windows.LPFILETIME = nil;
  PWinLastAccessTime: Windows.LPFILETIME = nil;
begin
  Handle := CreateFileW(PWideChar(UTF16LongName(FileName)),
                        FILE_WRITE_ATTRIBUTES,
                        FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
                        nil,
                        OPEN_EXISTING,
                        FILE_FLAG_BACKUP_SEMANTICS,  // needed for opening directories
                        0);

  if Handle <> INVALID_HANDLE_VALUE then
    begin
      if ModificationTime <> 0 then
      begin
        PWinModificationTime := @ModificationTime;
      end;
      if CreationTime <> 0 then
      begin
        PWinCreationTime := @CreationTime;
      end;
      if LastAccessTime <> 0 then
      begin
        PWinLastAccessTime := @LastAccessTime;
      end;

      Result := Windows.SetFileTime(Handle,
                                    PWinCreationTime,
                                    PWinLastAccessTime,
                                    PWinModificationTime);
      CloseHandle(Handle);
    end
  else
    Result := False;
end;
{$ELSE}
var
  CurrentModificationTime, CurrentCreationTime, CurrentLastAccessTime: DCBasicTypes.TFileTimeEx;
begin
  if mbFileGetTime(FileName, CurrentModificationTime, CurrentCreationTime, CurrentLastAccessTime) then
  begin
    if ModificationTime<>TFileTimeExNull then CurrentModificationTime:= ModificationTime;
    if CreationTime<>TFileTimeExNull then CurrentCreationTime:= CreationTime;
    if LastAccessTime<>TFileTimeExNull then CurrentLastAccessTime:= LastAccessTime;
    Result := DC_FileSetTime(FileName, CurrentModificationTime, CurrentCreationTime, CurrentLastAccessTime);
  end
  else
  begin
    Result:=False;
  end;
end;
{$ENDIF}

function mbFileExists(const FileName: String) : Boolean;
{$IFDEF MSWINDOWS}
var
  Attr: DWORD;
begin
  Attr:= GetFileAttributesW(PWideChar(UTF16LongName(FileName)));
  if Attr <> DWORD(-1) then
    Result:= (Attr and FILE_ATTRIBUTE_DIRECTORY) = 0
  else
    Result:=False;
end;
{$ELSE}
var
  Info: BaseUnix.Stat;
begin
  // Can use fpStat, because link to an existing filename can be opened as if it were a real file.
  if fpStat(UTF8ToSys(FileName), Info) >= 0 then
    Result:= fpS_ISREG(Info.st_mode)
  else
    Result:= False;
end;
{$ENDIF}

function mbFileAccess(const FileName: String; Mode: Word): Boolean;
{$IFDEF MSWINDOWS}
const
  AccessMode: array[0..2] of DWORD  = (
                GENERIC_READ,
                GENERIC_WRITE,
                GENERIC_READ or GENERIC_WRITE);
var
  hFile: System.THandle;
  dwDesiredAccess: DWORD;
  dwShareMode: DWORD = 0;
begin
  dwDesiredAccess := AccessMode[Mode and 3];
  if Mode = fmOpenRead then // If checking Read mode no sharing mode given
    Mode := Mode or fmShareDenyNone;
  dwShareMode := ShareModes[(Mode and $F0) shr 4];
  hFile:= CreateFileW(PWideChar(UTF16LongName(FileName)), dwDesiredAccess, dwShareMode,
                      nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
  Result := hFile <> INVALID_HANDLE_VALUE;
  if Result then
    FileClose(hFile);
end;
{$ELSE}
const
  AccessMode: array[0..2] of LongInt  = (
                R_OK,
                W_OK,
                R_OK or W_OK);
begin
  Result:= fpAccess(UTF8ToSys(FileName), AccessMode[Mode and 3]) = 0;
end;
{$ENDIF}

{$IFOPT R+}
{$DEFINE uOSUtilsRangeCheckOn}
{$R-}
{$ENDIF}

function mbFileGetAttr(const FileName: String): TFileAttrs;
{$IFDEF MSWINDOWS}
begin
  Result := GetFileAttributesW(PWideChar(UTF16LongName(FileName)));
end;
{$ELSE}
var
  Info: BaseUnix.Stat;
begin
  if fpLStat(UTF8ToSys(FileName), @Info) >= 0 then
    Result:= Info.st_mode
  else
    Result:= faInvalidAttributes;
end;
{$ENDIF}

function mbFileGetAttr(const FileName: String; out Attr: TFileAttributeData): Boolean;
{$IFDEF MSWINDOWS}
var
  Handle: THandle;
  fInfoLevelId: FINDEX_INFO_LEVELS;
  FileInfo: Windows.TWin32FindDataW;
begin
  if CheckWin32Version(6, 1) then
    fInfoLevelId:= FindExInfoBasic
  else begin
    fInfoLevelId:= FindExInfoStandard;
  end;
  Handle:= FindFirstFileExW(PWideChar(UTF16LongName(FileName)), fInfoLevelId,
                            @FileInfo, FindExSearchNameMatch, nil, 0);
  Result:= Handle <> INVALID_HANDLE_VALUE;
  if Result then
  begin
    FindClose(Handle);
    // If a reparse point tag is not a name surrogate then remove reparse point attribute
    // Fixes bug: http://doublecmd.sourceforge.net/mantisbt/view.php?id=531
    if (FileInfo.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT <> 0) then
    begin
      if (FileInfo.dwReserved0 and $20000000 = 0) then
        FileInfo.dwFileAttributes-= FILE_ATTRIBUTE_REPARSE_POINT;
    end;
    Int64Rec(Attr.Size).Lo:= FileInfo.nFileSizeLow;
    Int64Rec(Attr.Size).Hi:= FileInfo.nFileSizeHigh;
    Move(FileInfo, Attr.FindData, SizeOf(TWin32FileAttributeData));
  end;
end;
{$ELSE}
begin
  Result:= fpLStat(UTF8ToSys(FileName), Attr.FindData) >= 0;
  if Result then
  begin
    Attr.Size:= Attr.FindData.st_size;
  end;
end;
{$ENDIF}

function mbFileSetAttr(const FileName: String; Attr: TFileAttrs): Boolean;
{$IFDEF MSWINDOWS}
begin
  Result:= SetFileAttributesW(PWideChar(UTF16LongName(FileName)), Attr);
end;
{$ELSE}
begin
  Result:= fpchmod(UTF8ToSys(FileName), Attr) = 0;
end;
{$ENDIF}

{$IFDEF uOSUtilsRangeCheckOn}
{$R+}
{$UNDEF uOSUtilsRangeCheckOn}
{$ENDIF}

function mbFileSetReadOnly(const FileName: String; ReadOnly: Boolean): Boolean;
{$IFDEF MSWINDOWS}
var
  iAttr: DWORD;
  wFileName: UnicodeString;
begin
  wFileName:= UTF16LongName(FileName);
  iAttr := GetFileAttributesW(PWideChar(wFileName));
  if iAttr = DWORD(-1) then Exit(False);
  if ReadOnly then
    iAttr:= iAttr or faReadOnly
  else
    iAttr:= iAttr and not (faReadOnly or faHidden or faSysFile);
  Result:= SetFileAttributesW(PWideChar(wFileName), iAttr) = True;
end;
{$ELSE}
var
  StatInfo: BaseUnix.Stat;
  mode: TMode;
begin
  if fpStat(UTF8ToSys(FileName), StatInfo) <> 0 then Exit(False);
  mode := SetModeReadOnly(StatInfo.st_mode, ReadOnly);
  Result:= fpchmod(UTF8ToSys(FileName), mode) = 0;
end;
{$ENDIF}

function mbDeleteFile(const FileName: String): Boolean;
{$IFDEF MSWINDOWS}
begin
  Result:= Windows.DeleteFileW(PWideChar(UTF16LongName(FileName)));
  if not Result then Result:= (GetLastError = ERROR_FILE_NOT_FOUND);
end;
{$ELSE}
begin
  Result:= fpUnLink(UTF8ToSys(FileName)) = 0;
  if not Result then Result:= (fpgetErrNo = ESysENOENT);
end;
{$ENDIF}

function mbRenameFile(const OldName: String; NewName: String): Boolean;
{$IFDEF MSWINDOWS}
var
  wTmpName,
  wOldName, wNewName: UnicodeString;
begin
  wNewName:= UTF16LongName(NewName);
  wOldName:= UTF16LongName(OldName);
  // Workaround: Windows >= 10 can't change only filename case on the FAT
  if (Win32MajorVersion >= 10) and UnicodeSameText(wOldName, wNewName) then
  begin
    wTmpName:= GetFileSystemType(OldName);
    if UnicodeSameText('FAT32', wTmpName) or UnicodeSameText('exFAT', wTmpName) then
    begin
      wTmpName:= UTF16LongName(GetTempName(OldName));
      Result:= MoveFileExW(PWChar(wOldName), PWChar(wTmpName), 0);
      if Result then
      begin
        Result:= MoveFileExW(PWChar(wTmpName), PWChar(wNewName), 0);
        if not Result then MoveFileExW(PWChar(wTmpName), PWChar(wOldName), 0);
      end;
      Exit;
    end;
  end;
  Result:= MoveFileExW(PWChar(wOldName), PWChar(wNewName), MOVEFILE_REPLACE_EXISTING);
end;
{$ELSE}
var
  tmpFileName: String;
  OldFileStat, NewFileStat: stat;
begin
  if GetPathType(NewName) <> ptAbsolute then
    NewName := ExtractFilePath(OldName) + NewName;

  if OldName = NewName then
    Exit(True);

  if fpLstat(UTF8ToSys(OldName), OldFileStat) <> 0 then
    Exit(False);

  // Check if target file exists.
  if fpLstat(UTF8ToSys(NewName), NewFileStat) = 0 then
  begin
    // Check if source and target are the same files (same inode and same device).
    if (OldFileStat.st_ino = NewFileStat.st_ino) and
       (OldFileStat.st_dev = NewFileStat.st_dev) then
    begin
      // Check number of links.
      // If it is 1 then source and target names most probably differ only
      // by case on a case-insensitive filesystem. Direct rename() in such case
      // fails on Linux, so we use a temporary file name and rename in two stages.
      // If number of links is more than 1 then it's enough to simply unlink
      // the source file, since both files are technically identical.
      // (On Linux rename() returns success but doesn't do anything
      // if renaming a file to its hard link.)
      // We cannot use st_nlink for directories because it means "number of
      // subdirectories" ("number of all entries" under macOS) in that directory,
      // plus its special entries '.' and '..';
      // hard links to directories are not supported on Linux
      // or Windows anyway (on macOS they are). Therefore we always treat
      // directories as if they were a single link and rename them using temporary name.

      if (NewFileStat.st_nlink = 1) or BaseUnix.fpS_ISDIR(NewFileStat.st_mode) then
      begin
        tmpFileName := GetTempName(OldName);

        if FpRename(UTF8ToSys(OldName), UTF8ToSys(tmpFileName)) = 0 then
        begin
          if fpLstat(UTF8ToSys(NewName), NewFileStat) = 0 then
          begin
            // We have renamed the old file but the new file name still exists,
            // so this wasn't a single file on a case-insensitive filesystem
            // accessible by two names that differ by case.
            FpRename(UTF8ToSys(tmpFileName), UTF8ToSys(OldName));  // Restore old file.
            Result := False;
          end
          else if FpRename(UTF8ToSys(tmpFileName), UTF8ToSys(NewName)) = 0 then
          begin
            Result := True;
          end
          else
          begin
            FpRename(UTF8ToSys(tmpFileName), UTF8ToSys(OldName));  // Restore old file.
            Result := False;
          end;
        end
        else
          Result := False;
      end
      else
      begin
        // Multiple links - simply unlink the source file.
        Result := (fpUnLink(UTF8ToSys(OldName)) = 0);
      end;

      Exit;
    end;
  end;
  Result := FpRename(UTF8ToSys(OldName), UTF8ToSys(NewName)) = 0;
end;
{$ENDIF}

function mbFileSize(const FileName: String): Int64;
{$IFDEF MSWINDOWS}
var
  Handle: System.THandle;
  FindData: TWin32FindDataW;
begin
  Result:= 0;
  Handle := FindFirstFileW(PWideChar(UTF16LongName(FileName)), FindData);
  if Handle <> INVALID_HANDLE_VALUE then
    begin
      Windows.FindClose(Handle);
      if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
      begin
        Int64Rec(Result).Lo:= FindData.nFileSizeLow;
        Int64Rec(Result).Hi:= FindData.nFileSizeHigh;
      end;
    end;
end;
{$ELSE}
var
  Info: BaseUnix.Stat;
begin
  Result:= 0;
  if fpStat(UTF8ToSys(FileName), Info) >= 0 then
    Result:= Info.st_size;
end;
{$ENDIF}

function FileGetSize(Handle: System.THandle): Int64;
{$IFDEF MSWINDOWS}
begin
  Int64Rec(Result).Lo := GetFileSize(Handle, @Int64Rec(Result).Hi);
end;
{$ELSE}
var
  Info: BaseUnix.Stat;
begin
  if fpFStat(Handle, Info) < 0 then
    Result := -1
  else
    Result := Info.st_size;
end;
{$ENDIF}

function FileFlush(Handle: System.THandle): Boolean; inline;
{$IFDEF MSWINDOWS}
begin
  Result:= FlushFileBuffers(Handle);
end;
{$ELSE}  
begin
  Result:= (fpfsync(Handle) = 0);
end;  
{$ENDIF}

function FileFlushData(Handle: System.THandle): Boolean; inline;
{$IF DEFINED(LINUX)}
begin
  Result:= (fpFDataSync(Handle) = 0);
end;
{$ELSE}
begin
  Result:= FileFlush(Handle);
end;
{$ENDIF}

function FileIsReadOnlyEx(Handle: System.THandle): Boolean;
{$IF DEFINED(MSWINDOWS)}
var
  Info: BY_HANDLE_FILE_INFORMATION;
begin
  if GetFileInformationByHandle(Handle, Info) then
    Result:= (Info.dwFileAttributes and (faReadOnly or faHidden or faSysFile) <> 0)
  else
    Result:= False;
end;
{$ELSEIF DEFINED(LINUX)}
var
  Flags: UInt32;
begin
  if FileGetFlags(Handle, Flags) then
  begin
    if (Flags and (FS_IMMUTABLE_FL or FS_APPEND_FL) <> 0) then
      Exit(True);
  end;
  Result:= False;
end;
{$ELSE}
begin
  Result:= False;
end;
{$ENDIF}

function FileAllocate(Handle: System.THandle; Size: Int64): Boolean;
{$IF DEFINED(LINUX)}
var
  Ret: cint;
  Sta: TStat;
  StaFS: TStatFS;
begin
  if (Size > 0) then
  begin
    repeat
      Ret:= fpfStatFS(Handle, @StaFS);
    until (Ret <> -1) or (fpgeterrno <> ESysEINTR);
    // FAT32 does not support a fast allocation
    if (StaFS.fstype = MSDOS_SUPER_MAGIC) then
      Exit(False);
    repeat
      Ret:= fpFStat(Handle, Sta);
    until (Ret <> -1) or (fpgeterrno <> ESysEINTR);
    if (Ret = 0) and (Sta.st_size < Size) then
    begin
      // New size should be aligned to block size
      Sta.st_size:= (Size + Sta.st_blksize - 1) and not (Sta.st_blksize - 1);
      repeat
        Ret:= fpFAllocate(Handle, 0, 0, Sta.st_size);
      until (Ret <> -1) or (fpgeterrno <> ESysEINTR);
    end;
  end;
  Result:= FileTruncate(Handle, Size);
end;
{$ELSE}
begin
  Result:= FileTruncate(Handle, Size);
end;
{$ENDIF}

function mbGetCurrentDir: String;
{$IFDEF MSWINDOWS}
var
  dwSize: DWORD;
  wsDir: UnicodeString;
begin
  if Length(CurrentDirectory) > 0 then
    Result:= CurrentDirectory
  else
  begin
    dwSize:= GetCurrentDirectoryW(0, nil);
    if dwSize = 0 then
      Result:= EmptyStr
    else begin
      SetLength(wsDir, dwSize + 1);
      SetLength(wsDir, GetCurrentDirectoryW(dwSize, PWideChar(wsDir)));
      Result:= UTF16ToUTF8(wsDir);
    end;
  end;
end;
{$ELSE}
begin
  GetDir(0, Result);
  Result := SysToUTF8(Result);
end;
{$ENDIF}

function mbSetCurrentDir(const NewDir: String): Boolean;
{$IFDEF MSWINDOWS}
var
  Handle: THandle;
  wsNewDir: UnicodeString;
  FindData: TWin32FindDataW;
begin
  if (Pos('\\', NewDir) = 1) then
    Result:= True
  else begin
    wsNewDir:= UTF16LongName(IncludeTrailingBackslash(NewDir)) + '*';
    Handle:= FindFirstFileW(PWideChar(wsNewDir), FindData);
    Result:= (Handle <> INVALID_HANDLE_VALUE) or (GetLastError = ERROR_FILE_NOT_FOUND);
    if (Handle <> INVALID_HANDLE_VALUE) then FindClose(Handle);
  end;
  if Result then CurrentDirectory:= NewDir;
end;
{$ELSE}
begin
  Result:= fpChDir(UTF8ToSys(NewDir)) = 0;
end;
{$ENDIF}

function mbDirectoryExists(const Directory: String) : Boolean;
{$IFDEF MSWINDOWS}
var
  Attr: DWORD;
begin
  Attr:= GetFileAttributesW(PWideChar(UTF16LongName(Directory)));
  if Attr <> DWORD(-1) then
    Result:= (Attr and FILE_ATTRIBUTE_DIRECTORY) > 0
  else
    Result:= False;
end;
{$ELSE}
var
  Info: BaseUnix.Stat;
begin
  // We can use fpStat here instead of fpLstat, so that True is returned
  // when target is a directory or a link to an existing directory.
  // Note that same behaviour would be achieved by passing paths
  // that end with path delimiter to fpLstat.
  // Paths with links can be used the same way as if they were real directories.
  if fpStat(UTF8ToSys(Directory), Info) >= 0 then
    Result:= fpS_ISDIR(Info.st_mode)
  else
    Result:= False;
end;
{$ENDIF}

function mbCreateDir(const NewDir: String): Boolean;
{$IFDEF MSWINDOWS}
begin
  Result:= CreateDirectoryW(PWideChar(UTF16LongName(NewDir)), nil);
end;
{$ELSE}
begin
  Result:= fpMkDir(UTF8ToSys(NewDir), $1FF) = 0; // $1FF = &0777
end;
{$ENDIF}

function mbRemoveDir(const Dir: String): Boolean;
{$IFDEF MSWINDOWS}
begin
  Result:= RemoveDirectoryW(PWideChar(UTF16LongName(Dir)));
  if not Result then Result:= (GetLastError = ERROR_FILE_NOT_FOUND);
end;
{$ELSE}
begin
  Result:= fpRmDir(UTF8ToSys(Dir)) = 0;
  if not Result then Result:= (fpgetErrNo = ESysENOENT);
end;
{$ENDIF}

function mbFileSystemEntryExists(const Path: String): Boolean;
begin
  Result := mbFileGetAttr(Path) <> faInvalidAttributes;
end;

function mbCompareFileNames(const FileName1, FileName2: String): Boolean; inline;
{$IF DEFINED(WINDOWS) OR DEFINED(DARWIN)}
begin
  Result:= (UnicodeCompareText(CeUtf8ToUtf16(FileName1), CeUtf8ToUtf16(FileName2)) = 0);
end;
{$ELSE}
begin
  Result:= (UnicodeCompareStr(CeUtf8ToUtf16(FileName1), CeUtf8ToUtf16(FileName2)) = 0);
end;
{$ENDIF}

function mbFileSame(const FileName1, FileName2: String): Boolean;
{$IF DEFINED(MSWINDOWS)}
var
  Device1, Device2: TStringArray;
  FileHandle1, FileHandle2: System.THandle;
  FileInfo1, FileInfo2: BY_HANDLE_FILE_INFORMATION;
begin
  Result := mbCompareFileNames(FileName1, FileName2);

  if not Result then
  begin
    FileHandle1 := CreateFileW(PWideChar(UTF16LongName(FileName1)), FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
        nil, OPEN_EXISTING, 0, 0);

    if FileHandle1 <> INVALID_HANDLE_VALUE then
    begin
      FileHandle2 := CreateFileW(PWideChar(UTF16LongName(FileName2)), FILE_READ_ATTRIBUTES,
          FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
          nil, OPEN_EXISTING, 0, 0);

      if FileHandle2 <> INVALID_HANDLE_VALUE then
      begin
        if GetFileInformationByHandle(FileHandle1, FileInfo1) and
           GetFileInformationByHandle(FileHandle2, FileInfo2) then
        begin
          // Check if both files have the same index on the same volume.
          // This check is valid only while both files are open.
          Result := (FileInfo1.dwVolumeSerialNumber = FileInfo2.dwVolumeSerialNumber) and
                    (FileInfo1.nFileIndexHigh       = FileInfo2.nFileIndexHigh) and
                    (FileInfo1.nFileIndexLow        = FileInfo2.nFileIndexLow);
          // Check that both files on the same physical drive (bug 0001774)
          if Result then
          begin
            Device1:= AnsiString(GetFinalPathNameByHandle(FileHandle1)).Split([PathDelim]);
            Device2:= AnsiString(GetFinalPathNameByHandle(FileHandle2)).Split([PathDelim]);
            Result:= (Length(Device1) > 2) and (Length(Device2) > 2) and (Device1[2] = Device2[2]);
          end;
        end;
        CloseHandle(FileHandle2);
      end;
      CloseHandle(FileHandle1);
    end
  end;
end;
{$ELSEIF DEFINED(UNIX)}
var
  File1Stat, File2Stat: stat;
begin
  Result := mbCompareFileNames(FileName1, FileName2) or
            (
              (fpLstat(UTF8ToSys(FileName1), File1Stat) = 0) and
              (fpLstat(UTF8ToSys(FileName2), File2Stat) = 0) and
              (File1Stat.st_ino = File2Stat.st_ino) and
              (File1Stat.st_dev = File2Stat.st_dev)
            );
end;
{$ENDIF}

function mbFileSameVolume(const FileName1, FileName2: String): Boolean;
{$IF DEFINED(MSWINDOWS)}
var
  lpszVolumePathName1: array[0..maxSmallint] of WideChar;
  lpszVolumePathName2: array[0..maxSmallint] of WideChar;
begin
  Result:= GetVolumePathNameW(PWideChar(UTF16LongName(FileName1)), PWideChar(lpszVolumePathName1), maxSmallint) and
           GetVolumePathNameW(PWideChar(UTF16LongName(FileName2)), PWideChar(lpszVolumePathName2), maxSmallint) and
           WideSameText(ExtractFileDrive(lpszVolumePathName1), ExtractFileDrive(lpszVolumePathName2));
end;
{$ELSE}
var
  Stat1, Stat2: Stat;
begin
  Result:= (fpLStat(UTF8ToSys(FileName1), Stat1) = 0) and
           (fpLStat(UTF8ToSys(FileName2), Stat2) = 0) and
           (Stat1.st_dev = Stat2.st_dev);
end;
{$ENDIF}

function mbGetEnvironmentString(Index: Integer): String;
{$IFDEF MSWINDOWS}
var
  hp, p: PWideChar;
begin
  Result:= '';
  p:= GetEnvironmentStringsW;
  hp:= p;
  if (hp <> nil) then
    begin
      while (hp^ <> #0) and (Index > 1) do
        begin
          Dec(Index);
          hp:= hp + lstrlenW(hp) + 1;
        end;
      if (hp^ <> #0) then
        Result:= UTF16ToUTF8(UnicodeString(hp));
    end;
  FreeEnvironmentStringsW(p);
end;
{$ELSE}
begin
  Result:= SysToUTF8(GetEnvironmentString(Index));
end;
{$ENDIF}

function mbExpandEnvironmentStrings(const FileName: String): String;
{$IF DEFINED(MSWINDOWS)}
var
  dwSize: DWORD;
  wsResult: UnicodeString;
begin
  SetLength(wsResult, MaxSmallInt + 1);
  dwSize:= ExpandEnvironmentStringsW(PWideChar(CeUtf8ToUtf16(FileName)), PWideChar(wsResult), MaxSmallInt);
  if (dwSize = 0) or (dwSize > MaxSmallInt) then
    Result:= FileName
  else begin
    SetLength(wsResult, dwSize - 1);
    Result:= UTF16ToUTF8(wsResult);
  end;
end;
{$ELSE}
var
  Index: Integer = 1;
  EnvCnt, EqualPos: Integer;
  EnvVar, EnvName, EnvValue: String;
begin
  Result:= FileName;
  EnvCnt:= GetEnvironmentVariableCount;
  while (Index <= EnvCnt) and (Pos('$', Result) > 0) do
  begin
    EnvVar:= mbGetEnvironmentString(Index);
    EqualPos:= Pos('=', EnvVar);
    if EqualPos = 0 then Continue;
    EnvName:= Copy(EnvVar, 1, EqualPos - 1);
    EnvValue:= Copy(EnvVar, EqualPos + 1, MaxInt);
    Result:= StringReplace(Result, '$' + EnvName, EnvValue, [rfReplaceAll]);
    Inc(Index);
  end;
end;
{$ENDIF}

function mbGetEnvironmentVariable(const sName: String): String;
{$IFDEF MSWINDOWS}
var
  wsName: UnicodeString;
  smallBuf: array[0..1023] of WideChar;
  largeBuf: PWideChar;
  dwResult: DWORD;
begin
  Result := EmptyStr;
  wsName := CeUtf8ToUtf16(sName);
  dwResult := GetEnvironmentVariableW(PWideChar(wsName), @smallBuf[0], Length(smallBuf));
  if dwResult > Length(smallBuf) then
  begin
    // Buffer not large enough.
    largeBuf := GetMem(SizeOf(WideChar) * dwResult);
    if Assigned(largeBuf) then
    try
      dwResult := GetEnvironmentVariableW(PWideChar(wsName), largeBuf, dwResult);
      if dwResult > 0 then
        Result := UTF16ToUTF8(UnicodeString(largeBuf));
    finally
      FreeMem(largeBuf);
    end;
  end
  else if dwResult > 0 then
    Result := UTF16ToUTF8(UnicodeString(smallBuf));
end;
{$ELSE}
begin
  Result:= CeSysToUtf8(getenv(PAnsiChar(CeUtf8ToSys(sName))));
end;
{$ENDIF}

function mbSetEnvironmentVariable(const sName, sValue: String): Boolean;
{$IFDEF MSWINDOWS}
var
  wsName,
  wsValue: UnicodeString;
begin
  wsName:= CeUtf8ToUtf16(sName);
  wsValue:= CeUtf8ToUtf16(sValue);
  Result:= SetEnvironmentVariableW(PWideChar(wsName), PWideChar(wsValue));
end;
{$ELSE}
begin
  Result:= (setenv(PAnsiChar(CeUtf8ToSys(sName)), PAnsiChar(CeUtf8ToSys(sValue)), 1) = 0);
end;
{$ENDIF}

function mbUnsetEnvironmentVariable(const sName: String): Boolean;
{$IFDEF MSWINDOWS}
var
  wsName: UnicodeString;
begin
  wsName:= CeUtf8ToUtf16(sName);
  Result:= SetEnvironmentVariableW(PWideChar(wsName), NIL);
end;
{$ELSE}
begin
  Result:= (unsetenv(PAnsiChar(CeUtf8ToSys(sName))) = 0);
end;
{$ENDIF}

function mbSysErrorMessage: String;
begin
  Result := mbSysErrorMessage(GetLastOSError);
end;

function mbSysErrorMessage(ErrorCode: Integer): String;
begin
  Result := SysErrorMessage(ErrorCode);
{$IF (FPC_FULLVERSION < 30004)}
  Result := CeSysToUtf8(Result);
{$ENDIF}
end;

function mbGetModuleName(Address: Pointer): String;
const
  Dummy: Boolean = False;
{$IFDEF UNIX}
var
  dlinfo: dl_info;
begin
  if Address = nil then Address:= @Dummy;
  FillChar({%H-}dlinfo, SizeOf(dlinfo), #0);
  if dladdr(Address, @dlinfo) = 0 then
    Result:= EmptyStr
  else begin
    Result:= CeSysToUtf8(dlinfo.dli_fname);
  end;
end;
{$ELSE}
var
  ModuleName: UnicodeString;
  lpBuffer: TMemoryBasicInformation;
begin
  if Address = nil then Address:= @Dummy;
  if VirtualQuery(Address, @lpBuffer, SizeOf(lpBuffer)) <> SizeOf(lpBuffer) then
    Result:= EmptyStr
  else begin
    SetLength(ModuleName, MAX_PATH + 1);
    SetLength(ModuleName, GetModuleFileNameW({%H-}THandle(lpBuffer.AllocationBase),
                                             PWideChar(ModuleName), MAX_PATH));
    Result:= UTF16ToUTF8(ModuleName);
  end;
end;
{$ENDIF}

function mbLoadLibrary(const Name: String): TLibHandle;
{$IFDEF MSWINDOWS}
var
  dwMode: DWORD;
  dwErrCode: DWORD;
  sRememberPath: String;
begin
  dwMode:= SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOOPENFILEERRORBOX);
  try
    // Some plugins using DLL(s) in their directory are loaded correctly only if "CurrentDir" is poining their location.
    // Also, TC switch "CurrentDir" to their directory when loading them. So let's do the same.
    sRememberPath:= GetCurrentDir;
    SetCurrentDir(ExtractFileDir(Name));
    Result:= SafeLoadLibrary(CeUtf8ToUtf16(Name));
    dwErrCode:= GetLastError;
  finally
    SetErrorMode(dwMode);
    SetCurrentDir(sRememberPath);
    SetLastError(dwErrCode);
  end;
end;
{$ELSE}
begin
  Result:= SafeLoadLibrary(CeUtf8ToSys(Name));
end;
{$ENDIF}

function mbLoadLibraryEx(const Name: String): TLibHandle;
{$IF DEFINED(MSWINDOWS)}
const
  PATH_ENV = 'PATH';
var
  dwFlags:DWORD;
  APath: String;
  APathType: TPathType;
  usName: UnicodeString;
begin
  usName:= CeUtf8ToUtf16(Name);
  APathType:= GetPathType(Name);

  if CheckWin32Version(10) or (GetProcAddress(GetModuleHandleW(Kernel32), 'AddDllDirectory') <> nil) then
  begin
    if APathType <> ptAbsolute then
      dwFlags:= 0
    else begin
      dwFlags:= LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR;
    end;
    Result:= LoadLibraryExW(PWideChar(usName), 0, dwFlags or LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
  end
  else begin
    APath:= mbGetEnvironmentVariable(PATH_ENV);
    try
      if APathType <> ptAbsolute then
        SetDllDirectoryW(PWideChar(''))
      else begin
        SetDllDirectoryW(PWideChar(ExtractFileDir(usName)));
      end;
      try
        SetEnvironmentVariableW(PATH_ENV, nil);
        Result:= LoadLibraryW(PWideChar(usName));
      finally
        SetDllDirectoryW(nil);
      end;
    finally
      mbSetEnvironmentVariable(PATH_ENV, APath);
    end;
  end;
end;
{$ELSE}
begin
  Result:= SafeLoadLibrary(CeUtf8ToSys(Name));
end;
{$ENDIF}

function SafeGetProcAddress(Lib: TLibHandle; const ProcName: AnsiString): Pointer;
begin
  Result:= GetProcedureAddress(Lib, ProcName);
  if (Result = nil) then raise Exception.Create(ProcName);
end;

function mbReadAllLinks(const PathToLink: String) : String;
var
  Attrs: TFileAttrs;
  LinkTargets: TStringList;  // A list of encountered filenames (for detecting cycles)

  function mbReadAllLinksRec(const PathToLink: String): String;
  begin
    Result := ReadSymLink(PathToLink);
    if Result <> '' then
    begin
      if GetPathType(Result) <> ptAbsolute then
        Result := GetAbsoluteFileName(ExtractFilePath(PathToLink), Result);

      if LinkTargets.IndexOf(Result) >= 0 then
      begin
        // Link already encountered - links form a cycle.
        Result := '';
{$IFDEF UNIX}
        fpseterrno(ESysELOOP);
{$ENDIF}
        Exit;
      end;

      Attrs := mbFileGetAttr(Result);
      if (Attrs <> faInvalidAttributes) then
      begin
        if FPS_ISLNK(Attrs) then
        begin
          // Points to a link - read recursively.
          LinkTargets.Add(Result);
          Result := mbReadAllLinksRec(Result);
        end;
        // else points to a file/dir
      end
      else
      begin
        Result := '';  // Target of link doesn't exist
{$IFDEF UNIX}
        fpseterrno(ESysENOENT);
{$ENDIF}
      end;
    end;
  end;

begin
  LinkTargets := TStringList.Create;
  try
    Result := mbReadAllLinksRec(PathToLink);
  finally
    FreeAndNil(LinkTargets);
  end;
end;

function mbCheckReadLinks(const PathToLink : String): String;
var
  Attrs: TFileAttrs;
begin
  Attrs := mbFileGetAttr(PathToLink);
  if (Attrs <> faInvalidAttributes) and FPS_ISLNK(Attrs) then
    Result := mbReadAllLinks(PathToLink)
  else
    Result := PathToLink;
end;

function mbFileGetAttrNoLinks(const FileName: String): TFileAttrs;
{$IFDEF UNIX}
var
  Info: BaseUnix.Stat;
begin
  if fpStat(UTF8ToSys(FileName), Info) >= 0 then
    Result := Info.st_mode
  else
    Result := faInvalidAttributes;
end;
{$ELSE}
var
  LinkTarget: String;
begin
  LinkTarget := mbReadAllLinks(FileName);
  if LinkTarget <> '' then
    Result := mbFileGetAttr(LinkTarget)
  else
    Result := faInvalidAttributes;
end;
{$ENDIF}

function CreateHardLink(const Path, LinkName: String) : Boolean;
{$IFDEF MSWINDOWS}
var
  wsPath, wsLinkName: UnicodeString;
begin
  wsPath:= UTF16LongName(Path);
  wsLinkName:= UTF16LongName(LinkName);
  Result:= DCNtfsLinks.CreateHardlink(wsPath, wsLinkName);
end;
{$ELSE}
begin
  Result := (fplink(PAnsiChar(CeUtf8ToSys(Path)),PAnsiChar(CeUtf8ToSys(LinkName)))=0);
end;
{$ENDIF}

function CreateSymLink(const Path, LinkName: string; Attr: UInt32): Boolean;
{$IFDEF MSWINDOWS}
var
  wsPath, wsLinkName: UnicodeString;
begin
  wsPath:= CeUtf8ToUtf16(Path);
  wsLinkName:= UTF16LongName(LinkName);
  Result:= DCNtfsLinks.CreateSymlink(wsPath, wsLinkName, Attr);
end;
{$ELSE}
begin
  Result := (fpsymlink(PAnsiChar(CeUtf8ToSys(Path)), PAnsiChar(CeUtf8ToSys(LinkName)))=0);
end;
{$ENDIF}

function ReadSymLink(const LinkName : String) : String;
{$IFDEF MSWINDOWS}
var
  wsLinkName, wsTarget: UnicodeString;
begin
  wsLinkName:= UTF16LongName(LinkName);
  if DCNtfsLinks.ReadSymLink(wsLinkName, wsTarget) then
    Result := UTF16ToUTF8(wsTarget)
  else
    Result := EmptyStr;
end;
{$ELSE}
begin
  Result := SysToUTF8(fpReadlink(UTF8ToSys(LinkName)));
end;
{$ENDIF}

procedure SetLastOSError(LastError: Integer);
{$IFDEF MSWINDOWS}
begin
  SetLastError(UInt32(LastError));
end;
{$ELSE}
begin
  fpseterrno(LastError);
end;
{$ENDIF}

function GetTickCountEx: UInt64;
begin
{$IF DEFINED(MSWINDOWS)}
  if QueryPerformanceCounter(PLARGE_INTEGER(@Result)) then
    Result:= Result div PerformanceFrequency.QuadPart
  else
{$ENDIF}
  begin
    Result:= SysUtils.GetTickCount64;
  end;
end;

{$IFDEF MSWINDOWS}
initialization
  if QueryPerformanceFrequency(@PerformanceFrequency) then
    PerformanceFrequency.QuadPart := PerformanceFrequency.QuadPart div 1000;
{$ENDIF}

end.
