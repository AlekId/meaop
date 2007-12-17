{## the VM instructions ## }
procedure VMNext; forward;

procedure VMNext(const aGlobalFunction: PMeScriptGlobalFunction);
var
  vInstruction: TMeVMInstruction; //the instruction.
  vProc: TMeVMInstructionProc;
begin
  with aGlobalFunction^ do
    {$IFDEF FPC}
    While (psRunning in TTurboProcessorStates(LongWord(States))) do
    {$ELSE Borland}
    While (psRunning in TTurboProcessorStates(States)) do
    {$ENDIF}
    begin
      vInstruction := PMeVMInstruction(FGlobalOptions._PC.Mem)^;
      Inc(FGlobalOptions._PC.Mem);
      vProc := GMeScriptCoreWords[vInstruction];
      if Assigned(vProc) then
      begin
        vProc(FGlobalOptions);
      end
      else begin
        //BadOpError
        _iVMHalt(errBadInstruction);
        //break;
      end;
    end;
end;


procedure VMAssignment;
{���������ں����ϵģ���δ���
  ��1�� ����ĳ������ʱ��ѹ��ԭ����_Func��_PC,��ֵ��ȫ�� _Func �� _PC. �޸ķ���ջ������Ϊ�� _Func, _PC���˳�������ԭԭ���ġ�
}
procedure VMCall;

procedure InitMeScriptCoreWordList;
begin
end;

