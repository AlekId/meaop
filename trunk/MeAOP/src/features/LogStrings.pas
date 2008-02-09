{ Description
  ##$Id: LogStrings.pas,v 1.1 2008/02/08 15:48:50 riceball Exp $
  ##Initial Date: 2003
  
    

  
    �õ�Ԫ����ϸ˵����

  See Also
    ����

  Bugs
    ��֪���⡣

  Internal
    �ڲ�������Ա���ģ�������⡣

  TODO
    �������

  Author
    Riceball LEE(riceball@cq118.com)
    Riceball LEE(riceballl@hotmail.com)

  Copyright
    Copyright(C) 2003-2006-5-14 by Riceball LEE

  Current Version
    $Revision: 1.1 $
    <Pre>
       Last Modified by $Author: riceball $ 
       $Date: 2008/02/08 15:48:50 $ 
    </Pre>

  History
    <Pre>
    $Log: LogStrings.pas,v $
    Revision 1.1  2008/02/08 15:48:50  riceball
    *** empty log message ***

    Revision 1.3  2006/05/14 11:58:39  riceball
    *** empty log message ***

    </Pre>
}
unit LogStrings;

interface

uses
  SysUtils, Classes,
  CustomLogBase;

type
  TLogStringList = class(TCustomLogBase)
  private
    FStrings: TStrings;
    procedure SetStrings(Value: TStrings);
  protected
    procedure WriteLog(aMsg: string); override;
  public
    procedure Open; override;
    property Strings: TStrings read FStrings write SetStrings;
  end;
  

implementation

{
******************************** TLogStringList ********************************
}
procedure TLogStringList.Open;
begin
  inherited Open;
  FStrings.Clear;
end;

procedure TLogStringList.SetStrings(Value: TStrings);
begin
  if Value <> FStrings then
  begin
    Active := False;
    FStrings := Value;
  end;
end;

procedure TLogStringList.WriteLog(aMsg: string);
begin
  FStrings.Add(aMsg);
end;


initialization
finalization
end.
