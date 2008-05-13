
{Summary the Indy Net Task class ..}
{
   @author  Riceball LEE(riceballl@hotmail.com)
   @version $Revision: 1.10 $

  License:
    * The contents of this file are released under a dual \license, and
    * you may choose to use it under either the Mozilla Public License
    * 1.1 (MPL 1.1, available from http://www.mozilla.org/MPL/MPL-1.1.html)
    * or the GNU Lesser General Public License 2.1 (LGPL 2.1, available from
    * http://www.opensource.org/licenses/lgpl-license.php).
    * Software distributed under the License is distributed on an "AS
    * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
    * implied. See the License for the specific language governing
    * rights and limitations under the \license.
    * The Original Code is $RCSfile: uMeIndyTask.pas,v $.
    * The Initial Developers of the Original Code are Riceball LEE.
    * Portions created by Riceball LEE is Copyright (C) 2008
    * All rights reserved.

    * Contributor(s):
}
unit uMeIndyTask;

interface

{$I MeSetting.inc}

uses
  SysUtils, Classes //TStream
  uMeObject
  , uMeStream
  , uMeThread
  , uMeURI

  //, IdGlobal
  //, IdGlobalProtocols //GMTXXX
  , IdAuthenticationDigest //MD5-Digest authentication
  , IdURI, IdCookie, IdCookieManager
  , IdHTTPHeaderInfo    //for HTTP request and response info.
  , IdHTTP
  , IdCompressorZLib
  {$ifdef UseOpenSsl}
  ,  IdSSLOpenSSL  //ssl
  ,  IdAuthenticationNTLM //NTLM - uses OpenSSL libraries
  {$endif}
  ;

const
  cDefaultTimeout = 30 * 60 * 1000; //30 min
  cDefaultUserAgent = 'Mozilla/4.0 (Windows; zh-CN) Gecko';

  //Global
  IdTimeoutDefault = -1;
  IdTimeoutInfinite = -2;

type
  PMeDownloadTask = ^ TMeDownloadTask;
  PMeDownloadPartTask = ^ TMeDownloadPartTask;

{
Client send this request to server:
http.Request.Range := '0-'; //ȡ���е����ݡ�
Rangeͷ���������ʵ���һ�����߶���ӷ�Χ�����磬   
������ʾͷ500���ֽڣ�bytes=0-499   
������ʾ�ڶ���500�ֽڣ�bytes=500-999   
������ʾ���500���ֽڣ�bytes=-500   
������ʾ500�ֽ��Ժ�ķ�Χ��bytes=500-   
������һ�������һ���ֽڣ�bytes=0-0,-1   
����ͬʱָ��������Χ��bytes=500-600,601-999   

�������Ƿ��������Ժ��Դ�����ͷ�����������GET����Range����ͷ����Ӧ����״̬��206��PartialContent�����ض�������200   ��OK��
    ���֧�֣���ô�����������أ� /���������ΪInstance����
     content-range: bytes 1-65536/102400
     content-range: bytes */102400
     content-range: bytes 1-65536/*
  when read or connection timeout, this should re-connection it.
}
  TMeDownloadTask = object(TMeTask)
  protected
    // the header properties is inited or not.
    FHeaderInited: Boolean;
    FMaxParts: Integer;
    FURI: PMeURI;
    FContentLength: Int64;
    FHasContentLength: Boolean;
    //the response to tell the client it can be resume by unit:
    // Accept-Ranges: bytes
    FAcceptRanges: string;
    (*
    lValue := Values['Expires']; {do not localize}
    if IsNumeric(lValue) then
    begin
      // This is happening when expires is an integer number in seconds
      LSecs := IndyStrToInt(lValue);
      // RLebeau 01/23/2005 - IIS sometimes sends an 'Expires: -1' header
      if LSecs >= 0 then begin
        FExpires := Now +  (LSecs / SecsPerDay);
      end else begin
        FExpires := 0.0;
      end;
    end else
    begin
      FExpires := GMTToLocalDateTime(lValue);
    end;
    *)
    FExpires: TDateTime;
    //GMTToLocalDateTime(Values['Date'])
    FDate: TDateTime;
    //GMTToLocalDateTime(Values['Last-Modified'])
    FLastModified: TDateTime;
    //'Content-Version'
    FRevision: string; 
    FCanResume: Boolean;
    FConnectTimeout: Integer;
    FReadTimeout: Integer;
    //collect the TMeDownloadPartTask.
    FParts: PMeThreadSafeList;

    procedure DoPartTaskDone(const aPart: PMeDownloadPartTask);
    procedure BeforeRun; virtual; //override
    procedure Init; virtual; //override
  public
    destructor Destroy; virtual; //override

    //the MaxParts default is 1.
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property ReadTimeout: Integer read FReadTimeout write FReadTimeout;
    property MaxParts: Integer read FMaxParts write FMaxParts;
    property Parts: PMeThreadSafeList read FParts;
  end;

  //abstract DownloadPart task
  TMeDownloadPartTask = object(TMeTask)
  protected
    FURL: string;
    FStream: TMemoryStream;
    //owner
    FOwner: PMeDownloadTask;
    FContentRangeEnd: Int64;
    FContentRangeStart: Int64;
    //the real downloaded size.
    FContentRangeInstanceLength: Int64;

    procedure DoHeadersAvailable(Sender: TObject; aHeaders: TIdHeaderList; var vContinue: Boolean);

    //procedure AfterRun; virtual; //override
    //procedure BeforeRun; virtual; //override
    //function Run: Boolean; virtual; //override
    procedure HandleException(const Sender: PMeCustomThread; const aException: Exception); virtual;//override
    procedure Init; virtual; //override
    procedure BeforeRun; virtual; //override
  public
    constructor Create(const Owner: PMeDownloadTask);
    destructor Destroy; virtual; //override

    property Stream: TMemoryStream read FStream;
    property URL: string read FURL write FURL;
  end;

  TMeHttpDownloadPartTask = object(TMeDownloadPartTask)
  protected
    FHttp: TIdHTTP;
   {$ifdef UseOpenSsl}
    FIOSSL : TIdSSLIOHandlerSocketOpenSSL;
   {$endif}
    procedure BeforeRun; virtual; //override
    function Run: Boolean; virtual; //override
    procedure Init; virtual; //override
  public
    destructor Destroy; virtual; //override
  end;


implementation

uses
  uMeStrUtils;

var
  LCompressor: TIdCompressorZLib;
  LCookieManager: TIdCookieManager;

{ TMeDownloadTask }
procedure TMeDownloadTask.Init;
begin
  inherited;
  New(FParts, Create);
  New(FURI, Create);
  FContentLength := -1;
  FMaxParts := 1;
  FReadTimeout := IdTimeoutDefault;
  FConnectTimeout := IdTimeoutDefault;
end;

destructor TMeDownloadTask.Destroy;
begin
  FParts.FreeMeObjects;
  MeFreeAndNil(FParts);
  MeFreeAndNil(FURI);
  FRevision := '';
  FAcceptRanges := '';
  inherited;
end;

procedure TMeDownloadTask.BeforeRun;
begin
end;

{ TMeDownloadPartTask }
constructor TMeDownloadPartTask.Create(const Owner: PMeDownloadTask);
Begin
  inherited Create;
  FOwner := Owner;
  if Assigned(Owner) then
  begin
    FURL := Owner.FURI.URI;
  end;
end;

procedure TMeDownloadPartTask.Init;
begin
  inherited;
  FStream := TMemoryStream.Create;
end;

destructor TMeDownloadPartTask.Destroy;
begin
  FreeAndNil(FStream);
  FURL := '';
  inherited;
end;

procedure TMeDownloadPartTask.BeforeRun;
begin
  FStream.Clear;
end;

{ TMeHttpDownloadPartTask }
procedure TMeHttpDownloadPartTask.Init;
begin
  inherited;
  FHttp := TIdHTTP.Create(nil);
  {$ifdef UseOpenSsl}
  FIOSSL := TIdSSLIOHandlerSocketOpenSSL.Create;
  FHttp.IOHandler := FIOSSL;
  {$endif}
  //MUST decode manually!!
  //FHttp.Compressor := LCompressor;
  FHttp.CookieManager := LCookieManager;
  FHttp.RedirectMaximum := 5;
  FHttp.HandleRedirects := True;
  FHTTP.OnHeadersAvailable := DoHeadersAvailable;
  FHTTP.Request.UserAgent := cDefaultUserAgent;
end;

destructor TMeHttpDownloadPartTask.Destroy;
begin
  {$ifdef UseOpenSsl}
   FreeAndNil(FIOSSL);
  {$endif}
  FreeAndNil(FHttp);
end;

procedure TMeHttpDownloadPartTask.BeforeRun;
begin
  inherited;
  if Assigned(FOwner) and FOwner.FCanResume and (FContentRangeEnd > 0) then
  begin
    FHTTP.Request.Range := 'bytes=';
    if FContentRangeStart > 0 then
      FHTTP.Request.Range := FHTTP.Request.Range + IntToStr(FContentRangeStart);
    FHTTP.Request.Range := FHTTP.Request.Range + '-' + IntToStr(FContentRangeEnd);
    FHTTP.ConnectTimeout := FOwner.FConnectTimeout;
    FHTTP.ReadTimeout := FOwner.FReadTimeout;
  end;
end;

procedure TMeHttpDownloadPartTask.DoHeadersAvailable(Sender: TObject; aHeaders: TIdHeaderList; var vContinue: Boolean);
begin
  if Assigned(FOwner) and not FOwner.FHeaderInited then 
  with FOwner^ do
  begin
    FContentLength := (Sender as TIdCustomHTTP).Response.ContentLength;
    FHasContentLength := FContentLength > 0;
    FDate := (Sender as TIdCustomHTTP).Response.Date;
    FLastModified := (Sender as TIdCustomHTTP).Response.LastModified;
    FHttp.Request.LastModified := LastModified;
    FExpires := (Sender as TIdCustomHTTP).Response.Expires;

    FAcceptRanges := (Sender as TIdCustomHTTP).Response.AcceptRanges;
    FCanResume := FAcceptRanges <> '';

    { tell the client this connection what the download range 
     handle content-range headers, like:

     content-range: bytes 1-65536/102400
     content-range: bytes */102400
     content-range: bytes 1-65536/*
    }
    FContentRangeStart := (Sender as TIdCustomHTTP).Response.ContentRangeStart;
    FContentRangeEnd := (Sender as TIdCustomHTTP).Response.ContentRangeEnd;
    //FContentRangeInstanceLength := (Sender as TIdCustomHTTP).Response.ContentRangeInstanceLength;

    FHeaderInited := True;
  end;
end;

procedure TMeHttpDownloadPartTask.HandleException(const Sender: PMeCustomThread; const aException: Exception);
begin
  ///for re-use EIdConnClosedGracefully, EIdReadTimeout, EIdConnectTimeout, EIdReadLnMaxLineLengthExceeded, EIdReadLnWaitMaxAttemptsExceeded, 
end;

function TMeHttpDownloadPartTask.Run: Boolean;
begin
  FHttp.Get(FURL, FStream);
end;

initialization
  {$IFDEF MeRTTI_SUPPORT}
  //Make the ovtVmtClassName point to PShortString class name
  SetMeVirtualMethod(TypeOf(TMeDownloadTask), ovtVmtClassName, nil);
  SetMeVirtualMethod(TypeOf(TMeDownloadPartTask), ovtVmtClassName, nil);
  SetMeVirtualMethod(TypeOf(TMeHttpDownloadPartTask), ovtVmtClassName, nil);
  {$ENDIF}
  SetMeVirtualMethod(TypeOf(TMeDownloadTask), ovtVmtParent, TypeOf(TMeTask));
  SetMeVirtualMethod(TypeOf(TMeDownloadPartTask), ovtVmtParent, TypeOf(TMeTask));
  SetMeVirtualMethod(TypeOf(TMeHttpDownloadPartTask), ovtVmtParent, TypeOf(TMeDownloadPartTask));


   LCompressor:= TIdCompressorZLib.Create(nil);
   LCookieManager:= TIdCookieManager.Create(nil);
finalization
   FreeAndNil(LCompressor);
   FreeAndNil(LCookieManager);
end.
