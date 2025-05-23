unit AbZlibPrc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ZStream;

type
  TAbProgressStep = procedure (aPercentDone: Integer) of object;

  TCompressionLevel =
  (
    clNone      = 0,
    clSuperFast = 1,
    clFast      = 3,
    clNormal    = 6,
    clMaximum   = 9
  );

  { TAbDeflateHelper }

  TAbDeflateHelper = class
  public
    NormalSize: Int64;
    StreamSize: Int64;
    PartialSize: Int64;
    InflateChecksum: Boolean;
    OnProgressStep: TAbProgressStep;
    CompressionLevel: TCompressionLevel;
  end;

type

  { TDeflateStream }

  TDeflateStream = class(TCompressionStream)
  private
    FSize: Int64;
    FHash: UInt32;
    FOnProgressStep: TAbProgressStep;
  public
    constructor Create(ALevel: Integer; ADest: TStream);
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    property Hash: UInt32 read FHash;
  end;

  { TInflateStream }

  TInflateStream = class(TDecompressionStream)
  private
    FHash: UInt32;
    FChecksum: Boolean;
  public
    constructor Create(ASource: TStream; AChecksum: Boolean);
    function CopyInto(ATarget: TStream; ACount: Int64): Int64;
    function Read(var Buffer; Count: LongInt): LongInt; override;
  end;

function Deflate(aSource : TStream; aDest : TStream;
                 aHelper : TAbDeflateHelper) : longint;

function Inflate(aSource : TStream; aDest : TStream;
                 aHelper : TAbDeflateHelper) : longint;

implementation

uses
  Math, ZDeflate, ZBase, DCcrc32;

function Deflate(aSource : TStream; aDest : TStream;
                 aHelper : TAbDeflateHelper): longint;
var
  ALevel: Integer;
  ADeflateStream: TDeflateStream;
begin
  ALevel:= LongInt(aHelper.CompressionLevel);

  { if the helper's stream size <= 0, calculate
    the stream size from the stream itself }
  if (aHelper.StreamSize <= 0) then
    aHelper.StreamSize := aSource.Size;

  ADeflateStream:= TDeflateStream.Create(ALevel, aDest);
  try
    ADeflateStream.FSize:= aHelper.StreamSize;
    { attach progress notification method }
    ADeflateStream.FOnProgressStep:= aHelper.OnProgressStep;
    ADeflateStream.CopyFrom(aSource, aHelper.StreamSize);
    { save the uncompressed size }
    aHelper.NormalSize:= ADeflateStream.raw_written;
    { provide checksum value }
    Result := LongInt(ADeflateStream.FHash);
  finally
    ADeflateStream.Free;
  end;
end;

function Inflate(aSource: TStream; aDest: TStream;
                 aHelper: TAbDeflateHelper): longint;
var
  ACount: Int64;
  AInflateStream: TInflateStream;
begin
  AInflateStream:= TInflateStream.Create(aSource, aHelper.InflateChecksum);
  try
    if aHelper.PartialSize > 0 then
    begin
      ACount:= aHelper.PartialSize;
      aHelper.NormalSize:= AInflateStream.CopyInto(aDest, ACount);
    end
    else begin
      ACount:= aHelper.NormalSize;
      aHelper.NormalSize:= aDest.CopyFrom(AInflateStream, ACount);
    end;
    Result:= LongInt(AInflateStream.FHash);
  finally
    AInflateStream.Free;
  end;
end;

{ TInflateStream }

constructor TInflateStream.Create(ASource: TStream; AChecksum: Boolean);
begin
  FChecksum:= AChecksum;
  inherited Create(ASource, True);
end;

function TInflateStream.CopyInto(ATarget: TStream; ACount: Int64): Int64;
var
  ARead, ASize: Integer;
  ABuffer: array of Byte;
begin
  Result:= 0;
  ASize:= Min(ACount, $8000);
  SetLength(ABuffer, ASize);
  repeat
    if ACount < ASize then
    begin
      ASize:= ACount;
    end;
    ARead:= Read(ABuffer[0], ASize);
    if ARead > 0 then
    begin
      Dec(ACount, ARead);
      Inc(Result, ARead);
      ATarget.WriteBuffer(ABuffer[0], ARead);
    end;
  until (ARead < ASize) or (ACount = 0);
end;

function TInflateStream.Read(var Buffer; Count: LongInt): LongInt;
begin
  Result:= inherited Read(Buffer, Count);
  if FChecksum then
  begin
    FHash:= crc32_16bytes(@Buffer, Result, FHash);
  end;
  if (Result < Count) and (Fstream.avail_in > 0) then
  begin
    FSource.Seek(-Fstream.avail_in, soCurrent);
    Fstream.avail_in:= 0;
  end;
end;

{ TDeflateStream }

constructor TDeflateStream.Create(ALevel: Integer;
  ADest: TStream);
const
  BUF_SIZE = 16384;
var
  AError: Integer;
begin
  TOwnerStream(Self).Create(ADest);

  Fbuffer:= GetMem(BUF_SIZE);
  Fstream.next_out:= Fbuffer;
  Fstream.avail_out:= BUF_SIZE;

  AError:= deflateInit2(Fstream, ALevel, Z_DEFLATED, -MAX_WBITS, DEF_MEM_LEVEL, 0);

  if AError <> Z_OK then
    raise Ecompressionerror.Create(zerror(AError));
end;

function TDeflateStream.Write(const Buffer; Count: Longint): Longint;
begin
  FHash:= crc32_16bytes(@Buffer, Count, FHash);
  Result:= inherited Write(Buffer, Count);
  if Assigned(FOnProgressStep) then
  begin
    FOnProgressStep(raw_written * 100 div FSize);
  end;
end;

function TDeflateStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  if (Offset = 0) and (Origin = soCurrent) then
    Result:= raw_written
  else begin
    Result:= inherited Seek(Offset, Origin);
  end;
end;

end.

