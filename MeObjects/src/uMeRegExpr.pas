
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
  TMeRegEx = object(TMeDynamicObject)
  protected
    FOrgExpression : RegExprString;
    FSubRegExprs: PMeSubRegExprs; //of TMeRegEx
    FExpressions: PMeStrings;
    FName: RegExprString;
  public
    //the current execute Expression.
    property Expression : RegExprString read GetExpression write SetExpression;
    property Name: RegExprString;
  end;

implementation

uses 
  RTLConsts, SysConst;

procedure TMeRegEx.SetExpression(const Value: RegExprString);
var
  s: RegExprString;
begin  
      1. AnsiExtractQuotedStr(var s: PChar; Quote: Char = '/'): string;
         s := AnsiExtractQuotedStr(PChar(Value), '/');
      2. Search all the sub RegExpressions: 
        inherited Expression := '\/\[(.+?):SubRegEx:\]\/';
        if Exec(s) then
        REPEAT
          vRegEx := TMeRegEx.Create;
        UNTIL not ExecNext;
end;

initialization
  SetMeVirtualMethod(TypeOf(TMeRegEx), ovtVmtParent, TypeOf(TMeDynamicObject));

  {$IFDEF MeRTTI_SUPPORT}
  SetMeVirtualMethod(TypeOf(TMeRegEx), ovtVmtClassName, nil);
  {$ENDIF}
end.
