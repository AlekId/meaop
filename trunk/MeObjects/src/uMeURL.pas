
{Summary the abstract Uniform/Universal Resource Locator class and factory..}
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
    * The Original Code is $RCSfile: uMeURL.pas,v $.
    * The Initial Developers of the Original Code are Riceball LEE.
    * Portions created by Riceball LEE is Copyright (C) 2008
    * All rights reserved.

    * Contributor(s):
}
unit uMeURL;

interface

{$I MeSetting.inc}

uses
  SysUtils,
  uMeObject
  , uMeStream
  //, uMeURI
  ;

const
  cDefaultTimeout = 30 * 60 * 1000; //30 min

type
  TMeResourceResult = (rrOk, rrUnkownError, rrNoSuchProtocol, rrNoSupports, rrNoSuchResource, rrNoPermission);
  TMeResourceSupport = (rsfGet, rsfPut, rsfDelete, rsfHead);
  TMeResourceSupports = set of TMeResourceSupport;

  TMeResourceRequestDone = procedure (const Sender : TObject;
                              const RqType : TMeResourceSupport;
                              const Error  : TMeResourceResult) of object;

  PMeResourceLocator = ^ TMeResourceLocator;
  TMeResourceLocator = object(TMeDynamicObject)
  protected
    //the current protocol.
    FProtocol: string;
    FURL: string;
    FLocalBaseDir: string;

    procedure SetURL(const aURL: string);

    //���ظ� Locator ֧�ֵĲ�������
    class function Supports: TMeResourceSupports; virtual; abstract;
    //list this connection supports protocols, seperate by ";"
    //eg, http;https
    class function Protocols: string; virtual; abstract;

    //��������URL����URL���ı丳ֵ��ʱ�򱻵��ã��������Ϊ�٣���ʾ����ʧ�ܣ���ôURL�����ᱻ�ı䡣
    function UpdateURL(Var Value: string): Boolean; virtual;
    //�ڲ�ȡ�ļ���Դ��ͷ��Ϣ������Ϊ0��ʾ�ɹ��������������
    function iGetHeader(const aInfo: PMeStrings): TMeResourceResult; virtual; abstract;
    function iGet(var aStream: PMeStream): TMeResourceResult; virtual; abstract;
    function iPut(const aStream: PMeStream): TMeResourceResult; virtual; abstract;
    function iDelete(): TMeResourceResult; virtual; abstract;

    //���Ը� Locator �Ƿ�֧�� aProtocol Э�顣
    function CanProcessed(const aProtocol: string): Boolean;
  public
    destructor Destroy; virtual; {override}

    { Summary: ���ȼ���Locator�Ƿ�֧�ָò��������֧�ֲ�ȥ���� iGetHeader. }
    {
      Return the ResourceInfo in aInfo: AttributeName=value
        Such as:
        Author=XX
        Size=XX
        Date=XX
        Revision=
    }
    function GetResourceHeader(const aInfo: PMeStrings): TMeResourceResult;
    //���ȼ���Locator�Ƿ�֧�ָò��������֧�ֲ�ȥ���� iGet.
    function GetResource(var aStream: PMeStream): TMeResourceResult;
    //���ȼ���Locator�Ƿ�֧�ָò��������֧�ֲ�ȥ���� iPut.
    function PutResource(const aStream: PMeStream): TMeResourceResult;
    //���ȼ���Locator�Ƿ�֧�ָò��������֧�ֲ�ȥ���� iDelete.
    function DeleteResource(): TMeResourceResult;


    //�������µ�URLֵ��ʱ�����Э�鱻�ı�Ϊ�ǲ�����ǰLocator֧�ֵģ���ô�ı䲻��ɹ���
    property URL: string read FURL write SetURL;
    property Protocol: string read FProtocol;
    property LocalBaseDir: string read FLocalBaseDir write FLocalBaseDir;
  end;

  PMeResourceLocatorAsyn = ^ TMeResourceLocatorAsyn;
  TMeResourceLocatorAsyn = object(TMeResourceLocator)
  protected
    FTimeout: Longword;
  public
    property Timeout: Longword read FTimeout write FTimeout;
  end;

  { Summary: the abstract file resource. }
  {
    the file resource MUST like this: "Protocol://[user:passwd@][/folder/../]filename:/folder/../rsource.txt"
    pack://user:pwd@/test/aFile.pak:/folder/test.txt
    
    FFileName: /test/aFile.pak
    FResourceName:  /folder/test.txt
    Note: ֻ֧�����Ŀ¼��
  }
  TMeCustomFileLocator = object(TMeResourceLocator)
  protected
    FFileName: string;
    FResourceName: string;
    FUserName: string;
    FPassword: string;

    function UpdateURL(Var Value: string): Boolean; virtual; {override;}
    function GetFileName: string;
  public
    destructor Destroy; virtual; {override}

    //the data(packed) file name.
    property FileName: string read GetFileName;
  end;

{ the registered resource Locator classes }
function GResourceLocatorClasses: PMeList;


{ Summary: find the index of the protocol class in the GResourceLocatorClasses, if not found return -1}
{ ����URL�е�Э�����Class���б��е�λ�ã�û���ҵ�����Ϊ-1������Ϊ���б��е������š� }
function IndexOfLocatorClass(const aURL: string): Integer;
//����aURL���ͣ�����Locator�๤����������־ʹ�����Locator�����򷵻�nil.
function CreateLocator(const aURL: string; const aLocalBaseDir: string = ''): PMeResourceLocator;

function GetResourceHeader(const aURL: string; const aInfo: PMeStrings; const aLocalBaseDir: string = ''): TMeResourceResult;
function GetResource(const aURL: string; var aStream: PMeStream; const aLocalBaseDir: string = ''): TMeResourceResult;
function PutResource(const aURL: string; const aStream: PMeStream; const aLocalBaseDir: string = ''): TMeResourceResult;
function DeleteResource(const aURL: string; const aLocalBaseDir: string = ''): TMeResourceResult; 

//��Locator��ע�ᵽlocator�๤����
procedure Register(const aLocatorClass: TMeClass);

//get the aLocatorClass supports protocols.
function GetLocatorProtocols(const aLocatorClass: TMeClass): string;
//���ظ� Locator ֧�ֵĲ�������
function GetLocatorSupports(const aLocatorClass: TMeClass): TMeResourceSupports;
//test whether this Protocol can be processed.
//���Ը� Locator �Ƿ�֧�� aProtocol Э�顣
function ProtocolCanProcessed(const aLocatorClass: TMeClass; const aProtocol: string): Boolean;

implementation

uses
  uMeStrUtils;

type
  PMeVMTResourceLocator = ^ TMeVMTResourceLocator;
  TMeVMTResourceLocator = object(TMeVMT)
  public
    Supports: Pointer;
    Protocols: Pointer;
  end;

var
  FResourceLocatorClasses: PMeList;

function GResourceLocatorClasses: PMeList;
begin
  if not Assigned(FResourceLocatorClasses) then
    New(FResourceLocatorClasses, Create);
  Result := FResourceLocatorClasses;
end;


function GetLocatorSupports(const aLocatorClass: TMeClass): TMeResourceSupports;
var
  vFunc: function(Self: Pointer): TMeResourceSupports;
begin
  //if MeInheritsFrom(aLocatorClass, TypeOf(TMeResourceLocator)) then
  if Assigned(aLocatorClass) then
  begin
    @vFunc := PMeVMTResourceLocator(aLocatorClass).Supports;
    Result := vFunc(aLocatorClass);
  end
  else
    Result := [];
end;

function GetLocatorProtocols(const aLocatorClass: TMeClass): string;
var
  vFunc: function(Self: Pointer): string;
begin
  if MeInheritsFrom(aLocatorClass, TypeOf(TMeResourceLocator)) then
  begin
    @vFunc := PMeVMTResourceLocator(aLocatorClass).Protocols;
    Result := vFunc(aLocatorClass);
  end
  else
    Result := '';
end;

function ProtocolCanProcessed(const aLocatorClass: TMeClass; const aProtocol: string): Boolean;
var
  s: string;
begin
  s := GetLocatorProtocols(aLocatorClass);
  Result := False;
  while (s <> '') and not Result do
  begin
    Result := AnsiCompareText(StrFetch(s, ';', True), aProtocol) = 0;
  end;
end;

procedure Register(const aLocatorClass: TMeClass);
begin
  with GResourceLocatorClasses^ do
    if IndexOf(aLocatorClass) < 0 then
      Add(aLocatorClass);
end;

function IndexOfLocatorClass(const aURL: string): Integer;
var
  vProtocol: string;
begin
  Result := AnsiPos(':', aURL);
  if Result > 0 then
  begin
    vProtocol := Copy(aURL, 1, Result - 1);
    with GResourceLocatorClasses^ do
      for Result := 0 to Count -1 do
        if AnsiCompareText(vProtocol, GetLocatorProtocols(Items[Result])) = 0 then
          exit;
  end;
  Result := -1;
end;

function CreateLocator(const aURL: string; const aLocalBaseDir: string = ''): PMeResourceLocator;
var
  i: Integer;
begin
  i := IndexOfLocatorClass(aURL);
  if i >= 0 then
  begin
    Result := PMeResourceLocator(NewMeObject(GResourceLocatorClasses.Items[i]));
    Result.URL := aURL;
    Result.LocalBaseDir := aLocalBaseDir;
  end
  else
    Result := nil;
end;

function GetResourceHeader(const aURL: string; const aInfo: PMeStrings; const aLocalBaseDir: string = ''): TMeResourceResult;
var
  vLocator: PMeResourceLocator;
begin
  vLocator := CreateLocator(aURL, aLocalBaseDir);
  if Assigned(vLocator) then
  try
    Result := vLocator.GetResourceHeader(aInfo);
  finally
    vLocator.Free;
  end
  else
    Result := rrNoSuchProtocol;  
end;

function GetResource(const aURL: string; var aStream: PMeStream; const aLocalBaseDir: string = ''): TMeResourceResult;
var
  vLocator: PMeResourceLocator;
begin
  vLocator := CreateLocator(aURL, aLocalBaseDir);
  if Assigned(vLocator) then
  try
    Result := vLocator.GetResource(aStream);
  finally
    vLocator.Free;
  end
  else
    Result := rrNoSuchProtocol;  
end;

function PutResource(const aURL: string; const aStream: PMeStream; const aLocalBaseDir: string = ''): TMeResourceResult;
var
  vLocator: PMeResourceLocator;
begin
  vLocator := CreateLocator(aURL, aLocalBaseDir);
  if Assigned(vLocator) then
  try
    Result := vLocator.PutResource(aStream);
  finally
    vLocator.Free;
  end
  else
    Result := rrNoSuchProtocol;  
end;

function DeleteResource(const aURL: string; const aLocalBaseDir: string = ''): TMeResourceResult;
var
  vLocator: PMeResourceLocator;
begin
  vLocator := CreateLocator(aURL, aLocalBaseDir);
  if Assigned(vLocator) then
  try
    Result := vLocator.DeleteResource();
  finally
    vLocator.Free;
  end
  else
    Result := rrNoSuchProtocol;  
end;

{ TMeResourceLocator }
destructor TMeResourceLocator.Destroy;
begin
  FURL := '';
  FLocalBaseDir := '';
  FProtocol := '';
  inherited;
end;

function TMeResourceLocator.CanProcessed(const aProtocol: string): Boolean;
var
  s: string;
begin
  s := Protocols;
  Result := False;
  while (s <> '') and not Result do
  begin
    Result := AnsiCompareText(StrFetch(s, ';', True), aProtocol) = 0;
  end;
end;

procedure TMeResourceLocator.SetURL(const aURL: string);
var
  s: string;
begin
  if FURL <> aURL then
  begin
    s := aURL;
    if UpdateURL(s) then
      FURL := aURL;
  end;
end;

function TMeResourceLocator.GetResourceHeader(const aInfo: PMeStrings): TMeResourceResult;
begin
  if rsfHead in Supports then
    Result := iGetHeader(aInfo)
  else
    Result := rrNoSupports;
end;

function TMeResourceLocator.GetResource(var aStream: PMeStream): TMeResourceResult;
begin
  if rsfGet in Supports then
    Result := iGet(aStream)
  else
    Result := rrNoSupports;
end;

function TMeResourceLocator.PutResource(const aStream: PMeStream): TMeResourceResult;
begin
  if rsfPut in Supports then
    Result := iPut(aStream)
  else
    Result := rrNoSupports;
end;

function TMeResourceLocator.DeleteResource(): TMeResourceResult;
begin
  if rsfDelete in Supports then
    Result := iDelete()
  else
    Result := rrNoSupports;
end;

function TMeResourceLocator.UpdateURL(Var Value: string): Boolean;
begin
  FProtocol := StrFetch(Value, ':', True);
  Result := (FProtocol <> '') and CanProcessed(FProtocol);
  //if not Result then FProtocol := '';
end;

{ TMeCustomFileLocator }
destructor TMeCustomFileLocator.Destroy;
begin
  FFileName:= '';
  FResourceName:='';
  FUserName:='';
  FPassword:='';
  inherited;
end;

function TMeCustomFileLocator.GetFileName: string;
begin
  if FLocalBaseDir <> '' then
    Result := IncludeTrailingPathDelimiter(FLocalBaseDir)
  else
    Result := ExtractFilePath(ParamStr(0));
  Result := Result + FFileName;
end;

function TMeCustomFileLocator.UpdateURL(Var Value: string): Boolean;
Var
  s: string;
begin
  Result := inherited UpdateURL(Value);
  if Result then
  begin
    s := StrRFetch(Value, ':', True);
    Result := s <> '';
    if Result then
    begin
      FFileName := s;
      FResourceName := Value;
      if AnsiPos( '@', s) > 0 then
      begin
        s := StrFetch(FFileName, '@', True);
        FUserName := s;
        if AnsiPos( ':', s) > 0 then
          FPassword := StrFetch(FUserName, ':', True)
        else
          FPassword := '';
      end;
    end
    else
      Result := False;
  end;
end;

initialization
  {$IFDEF MeRTTI_SUPPORT}
  //Make the ovtVmtClassName point to PShortString class name
  SetMeVirtualMethod(TypeOf(TMeResourceLocator), ovtVmtClassName, nil);
  SetMeVirtualMethod(TypeOf(TMeCustomFileLocator), ovtVmtClassName, nil);
  {$ENDIF}
  SetMeVirtualMethod(TypeOf(TMeResourceLocator), ovtVmtParent, TypeOf(TMeDynamicObject));
  SetMeVirtualMethod(TypeOf(TMeCustomFileLocator), ovtVmtParent, TypeOf(TMeResourceLocator));
finalization
  MeFreeAndNil(FResourceLocatorClasses);
end.
