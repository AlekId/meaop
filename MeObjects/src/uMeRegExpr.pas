
{Summary the RegExpr object .}
{
   @author  Riceball LEE(riceballl@hotmail.com)
   @version $Revision: 1.00 $

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
    * The Original Code is $RCSfile: uMeRegExpr.pas,v $.
    * The Initial Developers of the Original Code are Riceball LEE.
    * Portions created by Andrey V. Sorokin, St.Petersburg, Russia is Copyright (C) 1999-2004
    * Portions created by Riceball LEE is Copyright (C) 2003-2008
    * All rights reserved.

    * Contributor(s):
        Andrey V. Sorokin(RegExpr)
                                http://RegExpStudio.com
                                mailto:anso@mail.ru
}
unit uMeRegExpr;

interface

{$I MeSetting.inc}

uses
{$IFDEF MSWINDOWS}
  Windows, 
{$ENDIF}
  //TypInfo,
  SysUtils
  , RegExpr
  , uMeConsts
  , uMeSystem
  , uMeObject
  {$IFDEF DEBUG}
  , DbugIntf
  {$ENDIF}
  ;

type
{
�����е�������ʽ������һ��
  Content=/():Count SearchListBegin ():SearchList SearchListEnd ():NextPageURL/:1
  SearchListBegin = //
  SearchList = /():Field1 ():Field2/:n

ð�ź�������ֱ�ʾִ��ƥ�������Ĵ����������n��ʾһֱ����ֱ��û��ƥ������ݡ�
���ʡ������ð�ź����֣���ʾ�˱��ʽֻ����1�Ρ�

֧��Ƕ��ƥ���Լ�ƥ�������
�Ⱥŷָ�ƥ�䶨�������Լ�ƥ������: Name=Content[:n]
���ContentΪ�������ݣ���ʾΪ���ַ���ƥ�䣨֧��*�ź�?��ͨ����ţ�ת�����Ϊ\���� Name='my*.*':1
���ContentΪ"/"б������ģ����ʾΪ����ƥ�䣬���Զ������ֶ�
�磺 Name =/hello(.*):myfield/:n


��һ�����ӵ����ӣ�
<table>
<tr><th>�Ա�</th><th>����</th><th>����</th></tr>
<tr><td>Male</td><td>13</td><td>Rose</td></tr>
<tr><td>Female</td><td>20</td><td>Jacky</td></tr>
</table>

Content=//[ListBegin]/ Good /[List]//
ListBegin=/<tr><th>(.*):Sex</th><th>(.*):Age</th><th>(.*):Name</th></tr>/:1
List=/<tr><td>(.*):$[ListBegin.Sex]</td><td>(.*):$[ListBegin.Age]</td><td>(.*):$[ListBegin.Name]</td></tr>/:n

/[ListBegin]/ Ϊ�ӱ��ʽ
}
  PMeCustomSimpleRegExpr = ^ TMeCustomSimpleRegExpr;

  TMeRegExprFoundEvent = procedure(const Sender: PMeCustomSimpleRegExpr);
  TMeCustomSimpleRegExpr = object(TMeNamedObject)
  protected
    FRegExpr: TRegExpr;
    FExecCount: Integer;
    FOnFound: TMeRegExprFoundEvent;
    procedure Init; virtual; //override;

    function GetRegExpr: TRegExpr;
    function GetExpression: RegExprString; virtual;
    procedure SetExpression(const Value: RegExprString); virtual;
    procedure Init; virtual; //override;
  public
    destructor Destroy; virtual; //override;

    property Expression : RegExprString read GetExpression write SetExpression;
    property RegExpr: TRegExpr read GetRegExpr;
    //the exec count for the expression, -1 means for ever until end.
    //the default is 1.
    property ExecCount: Integer read FExecCount write FExecCount;
    property OnFound: TMeRegExprFoundEvent read FOnFound write FOnFound;
  end;

  TMeCustomRegExpr = object(TMeCustomSimpleRegExpr)
  protected
    FOrgExpression : RegExprString;
    //this is Regular Expressions to run
    FSubRegExprs: PMeNamedObjects; //of TMeCustomSimpleRegExpr
    //this is added Expressions
    FExpressions: PMeNamedObjects; //of TMeCustomRegExpr

    function GetExpression: RegExprString; virtual; //override
    procedure SetExpression(const Value: RegExprString); virtual; //override
    procedure Init; virtual; //override;
  public
    destructor Destroy; virtual; //override;
    procedure Add(const aName: string; const aExpression: RegExprString; const aExecCount: Integer = 1);
  end;

implementation

uses 
  RTLConsts, SysConst;

{ TMeCustomSimpleRegExpr }
procedure TMeCustomSimpleRegExpr.Init;
begin
  inherited;
  FExecCount := 1;
end;

destructor TMeCustomSimpleRegExpr.Destroy;
begin
  FreeAndNil(FRegExpr);
  inherited;
end;

function TMeCustomSimpleRegExpr.GetExpression: RegExprString;
begin
  Result := RegExpr.Expression;
end;

function TMeCustomSimpleRegExpr.GetRegExpr: TRegExpr;
begin
  if not Assigned(FRegExpr) then
    FRegExpr := TRegExpr.Create;
  Result := FRegExpr;
end;

procedure TMeCustomSimpleRegExpr.SetExpression(const Value: RegExprString);
begin  
  RegExpr.Expression := Value;
end;

{ TMeCustomRegExpr }
procedure TMeCustomRegExpr.Init;
begin
  inherited;
  New(FSubRegExprs, Create);
  New(FExpressions, Create);
end;

destructor TMeCustomRegExpr.Destroy;
begin
  FOrgExpression := '';
  MeFreeAndNil(FSubRegExprs);
  MeFreeAndNil(FExpressions);
  inherited;
end;

function TMeCustomRegExpr.GetExpression: RegExprString;
begin
  Result := FOrgExpression;
end;

procedure TMeCustomRegExpr.SetExpression(const Value: RegExprString);
var
  s: RegExprString;
  vRegExpr: PMeCustomSimpleRegExpr;
  vExpr: PMeCustomRegExpr;
  vExecCount: Integer;
begin  
  if FOrgExpression <> Value then
  begin
    FSubRegExprs.Clear;
  //1. AnsiExtractQuotedStr(var s: PChar; Quote: Char = '/'): string;
    with RegExpr do
    begin
      Expression := '\/(.+?):Expression:\/(|\:(\d+|n):ExecCount:)';
      if Exec(Value) then
      begin
        s := Match[1];
        vExecCount := StrToIntDef(Match[2], -1);
      end
      else
        Raise EMeError.Create('TMeCustomRegExpr.SetExpression: the  RegExprString format is error!');
      //s := AnsiExtractQuotedStr(PChar(Value), '/');
    end;
  //2. Search all the sub RegExpressions: 
    RegExpr.Expression := '\/\[(.+?):SubRegEx:\]\/';
    if FRegExpr.Exec(s) then
    repeat
      s := Trim(FRegExpr.Match[1]);
      if s <> '' then
      begin
        vExpr := PMeCustomRegExpr(FExpressions.Find(s));
        if not Assigned(vExpr) then
          Raise EMeError.Create('TMeCustomRegExpr.SetExpression: No Such SubRegExpression found:' + s);
        New(vRegExpr, Create);
      end;
    until not FRegExpr.ExecNext;
    FOrgExpression := Value;
  end;
end;

initialization
  SetMeVirtualMethod(TypeOf(TMeCustomSimpleRegExpr), ovtVmtParent, TypeOf(TMeNamedObject));
  SetMeVirtualMethod(TypeOf(TMeCustomRegExpr), ovtVmtParent, TypeOf(TMeCustomSimpleRegExpr));

  {$IFDEF MeRTTI_SUPPORT}
  SetMeVirtualMethod(TypeOf(TMeCustomSimpleRegExpr), ovtVmtClassName, nil);
  SetMeVirtualMethod(TypeOf(TMeCustomRegExpr), ovtVmtClassName, nil);
  {$ENDIF}
end.
