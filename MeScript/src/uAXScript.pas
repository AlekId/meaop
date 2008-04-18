

{ Summary: the AX Script Interface Declaration

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
    * The Original Code is $RCSfile: uAXScript.pas,v $.
    * The Initial Developers of the Original Code are Serhiy Perevoznyk.
    * Portions created by Serhiy Perevoznyk is Copyright (C) 2001-2004
    * Portions created by Riceball LEE is Copyright (C) 2007-2008
    * All rights reserved.
    * Contributor(s):
    *  Serhiy Perevoznyk
    *  Riceball LEE
}

unit uAXScript;

interface

uses
  Windows, SysUtils, ActiveX, ComObj, Contnrs, Classes
  //, Forms
  {$IFDEF COMPILER5_UP}
  , Variants
  {$ENDIF}
  , uAXScriptInf
  ;


type
  TOnActiveScriptError = procedure(Sender : TObject; Line, Pos : integer; ASrc : string; ADescription : string) of object;

  TAXScriptGlobalObjects = class(TObject)
  private
    FIntfList: IInterfaceList;
    FNamedList: TStrings;
  public
    constructor Create;
    function GetNamedItemCount: Integer;
    function GetNamedItemName(I: Integer): string;
    procedure AddNamedIntf(const AName: string; AIntf: IUnknown);
    function FindNamedItemIntf(const AName: string): IUnknown;
    destructor Destroy; override;
    property NamedItemCount: Integer read GetNamedItemCount;
    property NamedItemName[I: Integer]: string read GetNamedItemName;
  end;

  TAXScriptSite = class({$IFDEF UseComp}TComponent{$ELSE}TInterfacedObject{$ENDIF}, IActiveScriptSite)
  protected
    FUseSafeSubset : boolean;
    FGlobalObjects : TAXScriptGlobalObjects;
    FOnError : TOnActiveScriptError;
    FEngine: IActiveScript;
    FParser: IActiveScriptParse;
    FScriptLanguage : string;
    procedure CreateScriptEngine(const Language: string);
    procedure SetScriptLanguage(const Value: string);
  protected
    { IActiveScriptSite }
    function  GetLCID(out plcid: LongWord): HResult; stdcall;
    function GetItemInfo(
      pstrName: LPCOLESTR;
      dwReturnMask: DWORD;
      out ppiunkItem: IUnknown;
      out ppti: ITypeInfo): HResult; stdcall;
    function  GetDocVersionString(out pbstrVersion: WideString): HResult; stdcall;
    function  OnScriptTerminate(var pvarResult: OleVariant; var pexcepinfo: EXCEPINFO): HResult; stdcall;
    function  OnStateChange(ssScriptState: tagSCRIPTSTATE): HResult; stdcall;
    function  OnScriptError(const pscripterror: IActiveScriptError): HResult; stdcall;
    function  OnEnterScript: HResult; stdcall;
    function  OnLeaveScript: HResult; stdcall;
  public
    constructor Create({$IFDEF UseComp}aOwner: TComponent = nil{$ENDIF}); {$IFDEF UseComp}override;{$ELSE}virtual;{$ENDIF}
    destructor Destroy; override;
    function Release: Integer;
    function RunExpression(ACode : Widestring) : string;
    procedure  Execute(ACode : WideString);
    procedure CloseScriptEngine;
    procedure AddNamedItem(AName : string; AIntf : IUnknown);
  published
    property ScriptLanguage : string read FScriptLanguage write SetScriptLanguage;
    property OnError : TOnActiveScriptError read FOnError write FOnError;
    property UseSafeSubset : boolean read FUseSafeSubset write FUseSafeSubset default false;
  end;

  TAXScriptSiteWindow = class(TAXScriptSite, IActiveScriptSiteWindow)
  protected
    FWindowHandle: HWND;
    {IActiveSriptSiteWindow}
    function GetWindow(out phwnd: HWND): HResult; stdcall;
    function EnableModeless(fEnable: BOOL): HResult; stdcall;
  public
    property WindowHandle: HWND read FWindowHandle write FWindowHandle;
  end;

procedure GetActiveScriptParse(List: TStrings);


implementation

procedure GetActiveScriptParse(List: TStrings);
var
  ProgID: string;

  function ValidProgID: Boolean;
  var
    PID: string;
  begin
     if Length(ProgID) > 7 then
       Result := AnsiCompareStr('.Encode', Copy(ProgID, Length(ProgID)-6, 7)) <> 0
     else
       Result := True;
     // Exclude XML script engine
     if CompareText(Copy(ProgID, 1, 3), 'XML') = 0 then
       Result := False;
     // Exclude "signed" script engines
     PID := UpperCase(ProgID);
     if Pos('SIGNED', PID) <> 0 then
       Result := False;
  end;
var
  EnumGUID: IEnumGUID;
  Fetched: Cardinal;
  Guid: TGUID;
  Rslt: HResult;
  CatInfo: ICatInformation;
  I, BufSize: Integer;
  ClassIDKey: HKey;
  S: string;
  Buffer: array[0..255] of Char;
begin
  List.Clear;
  Rslt := CoCreateInstance(CLSID_StdComponentCategoryMgr, nil,
    CLSCTX_INPROC_SERVER, ICatInformation, CatInfo);
  if Succeeded(Rslt) then
  begin
    OleCheck(CatInfo.EnumClassesOfCategories(1, @CATID_ActiveScriptParse, 0, nil, EnumGUID));
    while EnumGUID.Next(1, Guid, Fetched) = S_OK do
    begin
      try
        ProgID := ClassIDToProgID(Guid);
        if ValidProgID then
          List.Add(ProgID);
      except
        ProgID := ClassIDToProgID(StringToGUID(Buffer));
        List.Add('Invalid Entry In Categories');
      end;
    end;
  end else
  begin
    if RegOpenKey(HKEY_CLASSES_ROOT, 'CLSID', ClassIDKey) <> 0 then
      try
        I := 0;
        while RegEnumKey(ClassIDKey, I, Buffer, SizeOf(Buffer)) = 0 do
        begin
          S := Format('%s\Implemented Categories\%s',[Buffer,  { do not localize }
            GUIDToString(CATID_ActiveScriptParse)]);
          if RegQueryValue(ClassIDKey, PChar(S), nil, BufSize) = 0 then
          begin
            ProgID := ClassIDToProgID(StringToGUID(Buffer));
            if ValidProgID then
              List.Add(ProgID);
          end;
          Inc(I);
        end;
      finally
        RegCloseKey(ClassIDKey);
      end;
  end;
end;

{ TAXScriptSite }


constructor TAXScriptSite.Create;
begin
  inherited;
  FScriptLanguage := 'VBScript';
  FGlobalObjects := TAXScriptGlobalObjects.Create;
  FUseSafeSubset := false;
end;

destructor TAXScriptSite.Destroy;
begin
  //CloseScriptEngine;
  FParser := nil;
  FEngine := nil;
  FGlobalObjects.Free;
  inherited;
end;

function TAXScriptSite.Release: Integer;
begin
  Result := _Release;
  {$IFDEF UseComp} 
  Free;
  {$ENDIF}
end;

procedure TAXScriptSite.AddNamedItem(AName: string;
  AIntf: IUnknown);
begin
  FGlobalObjects.AddNamedIntf(AName, AIntf);
end;



procedure TAXScriptSite.CreateScriptEngine(const Language: string);
const
  NULL_GUID: TGUID = '{00000000-0000-0000-0000-000000000000}';
var
  ScriptCLSID : TGUID;
  LanguageW : WideString;
  hr : HRESULT;
  i : integer;
  pOs : IObjectSafety;
  dwSupported : DWORD;
  dwEnabled : DWORD;
  vIntf: IInterface;
begin
  CloseScriptEngine;
  LanguageW := Language;

  if CLSIDFromProgID(PWideChar(LanguageW), ScriptCLSID) <> S_OK then 
  begin
    ScriptCLSID := NULL_GUID;
    Raise Exception.Create('no such lang');
  end;

  hr := ActiveX.CoCreateInstance(ScriptCLSID, nil, CLSCTX_SERVER, IUnknown, vIntf);
  OLECHECK(hr);
  //vIntf  := CreateComObject(ScriptCLSID);
  //vIntf :=GetActiveOleObject(Language);
  //FEngine := CreateComObject(ScriptCLSID) as IActiveScript;
  hr := vIntf.QueryInterface(IActiveScript, FEngine);
  OLECHECK(hr);

  if FUseSafeSubset then
   begin
     dwSupported := 0;
     dwEnabled := 0;
     FEngine.QueryInterface(IObjectSafety, pOS);
     if Assigned(pOS) then
      begin
        pOS.GetInterfaceSafetyOptions(IDispatch, @dwSupported, @dwEnabled);
          if (INTERFACE_USES_SECURITY_MANAGER and dwSupported) = INTERFACE_USES_SECURITY_MANAGER then
           begin
             dwEnabled := dwEnabled or INTERFACE_USES_SECURITY_MANAGER;
           end;
         pOS.SetInterfaceSafetyOptions(IDispatch, INTERFACE_USES_SECURITY_MANAGER, dwEnabled);
      end;
    end;

  hr := FEngine.QueryInterface(IActiveScriptParse, FParser);
  OLECHECK(hr);

  hr := FEngine.SetScriptSite(Self);
  OLECHECK(hr);

  hr := FParser.InitNew();
  OLECHECK(hr);

  for I := 0 to FGlobalObjects.NamedItemCount - 1 do
    FEngine.AddNamedItem(PWideChar(WideString(FGlobalObjects.NamedItemName[I])), SCRIPTITEM_ISVISIBLE or SCRIPTITEM_GLOBALMEMBERS);

  {
  //!! the tamarin egine has no GetScriptDispatch interface!
  FEngine.GetScriptDispatch('', Disp);
  OLECHECK(hr);
  writeln(3);
  FDisp := Disp; //}
end;


procedure TAXScriptSite.CloseScriptEngine;
begin
  FParser := nil;
  //FEngine.Close: it will call TAXScriptSite._Release
  //if FEngine <> nil then FEngine.Close;
  FEngine := nil;
end;

function TAXScriptSite.RunExpression(ACode: WideString): string;
var
  AResult: OleVariant;
  ExcepInfo: TEXCEPINFO;
begin
  if not Assigned(FEngine) then
    CreateScriptEngine(FScriptLanguage);
  if FParser.ParseScriptText(PWideChar(ACode), nil, nil, nil, 0, 0,
    SCRIPTTEXT_ISEXPRESSION, AResult, ExcepInfo) = S_OK
    then
      Result := AResult
        else
          Result := '';
end;

procedure TAXScriptSite.Execute(ACode: Widestring);
var
  Result: OleVariant;
  ExcepInfo: TEXCEPINFO;
begin
  if not Assigned(FEngine) then
    CreateScriptEngine(FScriptLanguage);
  //FEngine.SetScriptState(SCRIPTSTATE_INITIALIZED);
  FParser.ParseScriptText(PWideChar(ACode), nil, nil, nil, 0, 0, 0, Result, ExcepInfo);
  FEngine.SetScriptState(SCRIPTSTATE_CONNECTED);
end;

function TAXScriptSite.GetDocVersionString(
  out pbstrVersion: WideString): HResult;
begin
  pbstrVersion := 'AX Script host 1.0';
  Result := S_OK;
  //Result := E_NOTIMPL;
end;

function TAXScriptSite.GetItemInfo(pstrName: LPCOLESTR;
      dwReturnMask: DWORD;
      out ppiunkItem: IUnknown;
      out ppti: ITypeInfo): HResult; stdcall;
var
  s: string;
begin
  if @ppiunkItem <> nil then Pointer(ppiunkItem) := nil;
  if @ppti <> nil then Pointer(ppti) := nil;
  if (dwReturnMask and SCRIPTINFO_IUNKNOWN) <> 0
    then ppiunkItem := FGlobalObjects.FindNamedItemIntf(pstrName);
  s := pstrName;
  //writeln(s, ' Get Item ppiunkItem=', Assigned(ppiunkItem));
  Result := S_OK;
end;

function TAXScriptSite.GetLCID(out plcid: LongWord): HResult;
begin
  plcid := GetSystemDefaultLCID;
  Result := S_OK;
end;

function TAXScriptSite.OnEnterScript: HResult;
begin
  result := S_OK;
end;

function TAXScriptSite.OnLeaveScript: HResult;
begin
  result := S_OK;
end;

function TAXScriptSite.OnScriptError(
  const pscripterror: IActiveScriptError): HResult;
var
  wCookie   : Dword;
  ExcepInfo : TExcepInfo;
  CharNo    : integer;
  LineNo    : DWORD;
  SourceLineW : WideString;
  SourceLine : string;
  Desc : string;
begin
  Result := S_OK;
  wCookie := 0;
  LineNo  := 0;
  CharNo  := 0;
  if Assigned(pscripterror) then
    begin
      pscripterror.GetExceptionInfo(ExcepInfo);
      Desc := ExcepInfo.bstrDescription;
      pscripterror.GetSourcePosition(wCookie, LineNo, CharNo);
      pscripterror.GetSourceLineText(SourceLineW);
      SourceLine := SourceLineW;
      if Assigned(FOnError) then
        FOnError(Self, LineNo, CharNo, SourceLine, Desc);
    end;
end;

function TAXScriptSite.OnScriptTerminate(var pvarResult: OleVariant;
  var pexcepinfo: EXCEPINFO): HResult;
begin
  Result := S_OK;
end;

function TAXScriptSite.OnStateChange(
  ssScriptState: tagSCRIPTSTATE): HResult;
begin
   case ssScriptState of
     SCRIPTSTATE_UNINITIALIZED:;
     SCRIPTSTATE_INITIALIZED:;
     SCRIPTSTATE_STARTED:;
     SCRIPTSTATE_CONNECTED:;
     SCRIPTSTATE_DISCONNECTED:;
     SCRIPTSTATE_CLOSED:;
   end;
  //writeln('ssScriptState:', ssScriptState);
   Result := S_OK;

end;

procedure TAXScriptSite.SetScriptLanguage(const Value: string);
begin
  if FScriptLanguage <> Value then
  begin
    FScriptLanguage := Value;
  end;
end;

{ TAXScriptSiteWindow }

function TAXScriptSiteWindow.EnableModeless(fEnable: BOOL): HResult;
begin
  Result := S_OK;
end;

function TAXScriptSiteWindow.GetWindow(out phwnd: HWND): HResult;
begin
    phwnd := FWindowHandle;
    Result := S_OK;
    //Result := S_FALSE;
end;


{ TAXScriptGlobalObjects }

procedure TAXScriptGlobalObjects.AddNamedIntf(const AName: string; AIntf: IUnknown);
begin
  FNamedList.Add(AName);
  FIntfList.Add(AIntf);
end;

constructor TAXScriptGlobalObjects.Create;
begin
  inherited Create;
  FNamedList := TStringList.Create;
  FIntfList := TInterfaceList.Create;
end;

destructor TAXScriptGlobalObjects.Destroy;
begin
  FNamedList.Free;
  inherited;
end;

function TAXScriptGlobalObjects.FindNamedItemIntf(const AName: string): IUnknown;
var
  I: Integer;
begin
  I := FNamedList.IndexOf(AName);
  if I >= 0 then
    Result := FIntfList[I]
  else
    Result := nil;
end;

function TAXScriptGlobalObjects.GetNamedItemCount: Integer;
begin
  Result := FNamedList.Count;
end;

function TAXScriptGlobalObjects.GetNamedItemName(I: Integer): string;
begin
  Result := FNamedList[I];
end;

end.
