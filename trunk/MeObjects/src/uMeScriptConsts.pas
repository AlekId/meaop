unit uMeScriptConsts;

interface

{$I Setting.inc}

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF MSWINDOWS}
  SysUtils, Classes
  , uMeObject
  ;

const
  cMeScriptMaxReturnStackSize = 512;
  cMeScriptMaxDataStackSize   = 4096;

type
  tsInt = Integer;
  tsUInt = Longword;
  {
    @param cbmAutoBinding    ���øò�����Ϊ�Զ������Ƿ�Ϊǰ�ڻ��Ǻ��ڰ󶨣����ڱ���ʱ�����ҵ�attr�Ķ�����÷���ǰ�ڰ󶨣�����÷�����Ϊ���ڰ󶨴���
    @param cbmManualBinding  only xxx['attr'] means later-binding
                            ���øò��������xxx['attr']����ʽ��Ϊ���ڰ󶨣�xxx.attr����ǰ�ڰ󶨣��ڱ���ʱ���Ҳ���attr�򱨴���
    @param cbmLaterBinding   ���øò�����Ϊ���еķ���ȫ����Ϊ���ڰ󶨡�
  }
  TMeScriptCompilerBindingMode = (cbmAutoBinding, cbmManualBinding, cbmLaterBinding);
  {
  @param coHintFunctionArgCountError �������Ĳ���������ƥ���ʱ����ʾ��������ֹ��
  @param coAttributeReadClone        �������������ʱ���������ֻ������ProtoType����clone���Ƶ������У��������д��ʱ�������ơ�
  }
  TMeScriptCompilerOption = (coHintFunctionArgCountError, coAttributeReadClone);
  TMeScriptCompilerOptions = set of TMeScriptCompilerOption;
  TMeScriptTypeKind = (mtkUndefined, mtkNumber, mtkBoolean, mtkString, mtkFunction, mtkObject);
  TMeScriptAttributeKind = (akReadOnly, akDontEnum, akDontDelete);
  TMeScriptAttributeKinds = set of TMeScriptAttributeKind;
  TMeScriptProcessorState = (psHalt, psRunning, psStepping, psCompiling
     , psHaltError
  );
  TMeScriptProcessorStates = set of TMeScriptProcessorState;
  PTMeScriptProcessorErrorCode = ^ TMeScriptProcessorErrorCode;
  {
    @param errOutMem �������ڴ��޿��õĿռ�
    @param errOutOfMetaData MetaData�����޿��õĿռ�
  }
  TMeScriptProcessorErrorCode = (errNone, errBadInstruction, errInstructionBadParam, errDizZero
    , errModuleNotFound, errMethodNotFound, errTypeInfoNotFound
    , errStaticFieldNotFound, errFieldNotFound
    , errOutOfMem
    , errOutOfMetaData
    , errOutOfDataStack, errOutOfReturnStack
    , errAssertionFailed  
  );

  PMeVMInstruction = ^ TMeVMInstruction;
  TMeVMInstruction = (
    opNoop
    , opHalt       // ( -- )
    , opCallBlock   // opCallBlock pBlock (  --  )
    , opCallFunc    // opCallFunc pFunction ( Arguments -- pResultValue )
    , opCall        // opCall ( Arguments pFuncValue -- pResultValue )
    , opCallBind    // opCallBind <Len:byte>FuncNameStr ( Arguments -- pResultValue ) the runtime error raised if function is not exists at runtime
    , opObjectBind  // opObjectBind <Len:byte>ObjNameStr ( -- pObject)
    , opLoadAttrById   // opLoadAttrById ( pObject <Id:Int32> -- pValue)  if not found return nil
    , opLoadAttr // opLoadAttr ( pObject <Len:Byte>AttrNameStr -- pValue) if not found return nil
    , opAssign     // opAssign pVar ( pValue -- )
    , opPush       // opPush Int32 ( -- Int32)
    , opPushDouble // opPushDouble Double ( -- pValue)
    , opPushString // opPushString <cnt:Longword>string ( -- pValue)
    , opPushObject // opPushObject pObject ( -- pValue)
    , opPushFunction // opPushFunction pFunc ( -- pValue)
    , opPop        // opPop         (Int32 -- )
    , opLoadArg    // opLoadArg <index> ( -- pValue)  load local argument
    , opLoadArgFar // opLoadArgFar <stackIndex> <index> ( -- pValue)  load parent argument which argument in return stack:  FReturnStack[_RP - stackIndex].Arguments.Attributes[index]
    , opLoadVar    // opLoadVar <index> (-- pValue)  load loal varaible
    , opLoadVarFar // opLoadVarFar <stackIndex> <index> ( -- pValue)  load parent varaible which varaible in return stack:  FReturnStack[_RP - stackIndex].Varaibles.Items[index]
    , opLoadBind   // opCallBind <Len:byte>NameStr ( -- pValue ) the runtime error raised if function is not exists at runtime
  );

  PMeScriptCodeMemory = ^TMeScriptCodeMemory;
  TMeScriptCodeMemory = object(TMeDynamicMemory)
  public
    procedure AddOpCode(const aOpCode: TMeVMInstruction);overload;
    procedure AddOpCode(const aOpCode: TMeVMInstruction; const aValue: Integer);overload;
    procedure AddOpPushDouble(const aValue: Double);
    procedure AddOpBind(const aOpCode: TMeVMInstruction; const aName: string);
    procedure AddOpPushString(const aStr: string);
  end;

implementation

{TMeScriptCodeMemory}

procedure TMeScriptCodeMemory.AddOpPushString(const aStr: string);
begin
  AddOpCode(opPushString);
  AddInt(Length(aStr));
  if Length(aStr) > 0 then
  begin
  AddBuffer(aStr[1], Length(aStr));
  end;
end;

procedure TMeScriptCodeMemory.AddOpBind(const aOpCode: TMeVMInstruction; const aName: string);
var
  vLen: Byte;
begin
  AddOpCode(aOpCode);
  vLen := Length(aName);
  AddByte(vLen);
  AddBuffer(aName[1], vLen);
end;

procedure TMeScriptCodeMemory.AddOpCode(const aOpCode: TMeVMInstruction);
var
  p: pointer;
begin
  if (FUsedSize + SizeOf(aOpCode)) >= FSize then
    Grow(SizeOf(aOpCode));
  Assert(Assigned(FMemory), 'Err:FMemory is nil!!'+IntToStr(FSize));

  //writeln(FUsedSize, ':', FSize);
  p := Pointer(Integer(FMemory) + FUsedSize);
  PMeVMInstruction(P)^ := aOpCode;
  Inc(FUsedSize, SizeOf(TMeVMInstruction)); //}
end;

procedure TMeScriptCodeMemory.AddOpCode(const aOpCode: TMeVMInstruction; const aValue: Integer);
begin
  AddOpCode(aOpCode);
  AddInt(aValue);
end;

procedure TMeScriptCodeMemory.AddOpPushDouble(const aValue: Double);
begin
  AddOpCode(opPush);
  AddDouble(aValue);
end;

initialization
end.
