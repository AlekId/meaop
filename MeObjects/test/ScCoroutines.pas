{*
  Classes de gestion de coroutines
  ScCoroutines propose deux classes principales. TCoroutine est la classe de
  base de gestion d'une coroutine. TCoroutineEnumerator en est une d�riv�e
  sp�cialis�e pour la cr�ation d'un �num�rateur en coroutine.
  Cette unit� a besoin d'un test sous Windows 95/98/Me pour l'agrandissement de
  la pile, car PAGE_GUARD n'est pas support� dans ces versions.
  @author sjrd, sur une id�e de Bart van der Werf
  @version 1.0
*}
unit ScCoroutines;

interface

uses
  Windows, SysUtils;

const
  /// Taille minimale de pile
  MinStackSize = $10000;

resourcestring
  SCoroutInvalidOpWhileRunning =
    'Op�ration invalide lorsque la coroutine est en ex�cution';
  SCoroutInvalidOpWhileNotRunning =
    'Op�ration invalide lorsque la coroutine n''est pas en ex�cution';
  SCoroutBadStackSize =
    'Taille de pile incorrecte (%d) : doit �tre multiple de 64 Ko';
  SCoroutTerminating =
    'La coroutine est en train de se terminer';
  SCoroutTerminated =
    'Impossible de continuer : la coroutine est termin�e';
  SCoroutNotTerminated =
    'Impossible de r�initialiser : la coroutine n''est pas termin�e';

type
  PTIB = ^TTIB;
  TTIB = packed record
    SEH: Pointer;
    StackTop: Pointer;
    StackBottom: Pointer;
  end;

  TRunningFrame = record
    SEH: Pointer;
    StackTop: Pointer;
    StackBottom: Pointer;
    StackPtr: Pointer;
    InstructionPtr: Pointer;
  end;

  {*
    Type de boucle de coroutine
    - clNoLoop : ex�cut�e une fois, ne boucle pas
    - clImmediate : relance imm�diatement jusqu'au premier Yield
    - clNextInvoke : relance lors du prochain appel � Invoke
  *}
  TCoroutineLoop = (clNoLoop, clImmediate, clNextInvoke);

  /// Erreur li�e � l'utilisation d'une coroutine
  ECoroutineError = class(Exception);

  /// Interruption pr�matur�e d'une coroutine
  ECoroutineTerminating = class(Exception);

  {*
    Classe de support des coroutines
    La m�thode Invoke ne peut avoir qu'une seule ex�cution � la fois. Elle ne
    peut ni �tre appel�e dans deux threads diff�rents en m�me temps ; ni �tre
    appel�e depuis Execute (ce qui constitue un appel r�cursif).
    En revanche, elle peut �tre appel�e successivement par deux threads
    diff�rents.

    La propri�t� Loop d�termine le comportement de bouclage de la coroutine.
    Celle-ci peut soit ne pas boucler (clNoLoop) : un appel � Invoke lorsque
    Terminated vaut True d�clenchera une exception. Soit boucler imm�diatement
    (clImmediate) : d�s que Execute se termine, elle est rappel�e sans revenir
    � l'appelant. Soit boucler au prochain Invoke : dans ce cas l'appelant
    reprend la main entre la fin d'une ex�cution et le d�but de la suivante.

    La proc�dure Execute devrait tester l'�tat de Terminating apr�s chaque
    appel � Yield, et se terminer proprement si cette propri�t� vaut True.
    Cette propri�t� sera positionn�e � True lorsque l'objet coroutine devra se
    lib�rer, avant de relancer l'ex�cution. Si un appel � Yield est fait dans
    cet �tat, une exception de type ECoroutineTerminating assure que celle-ci
    se termine imm�diatement.

    Le nombre d'instances simultan�es de TCoroutine ne peut jamais exc�der
    32 K, et ce dans le meilleur des cas, car chacune doit r�server une plage
    de m�moire virtuelle de taille minimum 64 Ko.

    @author sjrd, sur une id�e de Bart van der Werf
    @version 1.0
  *}
  TCoroutine = class(TObject)
  private
    FStackSize: Cardinal;  /// Taille maximale de la pile
    FStackBuffer: Pointer; /// Pile virtuelle totale
    FStack: Pointer;       /// D�but de la pile de la coroutine

    FLoop: TCoroutineLoop; /// Type de boucle de la coroutine

    FCoroutineRunning: Boolean; /// True si la coroutine est cours d'ex�cution
    FTerminating: Boolean;      /// True si la coroutine doit se terminer
    FTerminated: Boolean;       /// True si la coroutine est termin�e

    FCoroutineFrame: TRunningFrame; /// Cadre d'ex�cution de la coroutine
    FCallerFrame: TRunningFrame;    /// Cadre d'ex�cution de l'appelant

    FExceptObject: TObject;  /// Objet exception d�clench�e par la coroutine
    FExceptAddress: Pointer; /// Adresse de d�clenchement de l'exception

    procedure InitCoroutine;
    procedure Main;
    procedure SwitchRunningFrame;
    procedure Terminate;
  protected
    procedure Invoke;
    procedure Yield;
    procedure Reset;

    {*
      Coroutine � ex�cuter
      Surchargez Execute pour donner le code de la coroutine.
    *}
    procedure Execute; virtual; abstract;

    property Loop: TCoroutineLoop read FLoop write FLoop;

    property CoroutineRunning: Boolean read FCoroutineRunning;
    property Terminating: Boolean read FTerminating;
    property Terminated: Boolean read FTerminated;
  public
    constructor Create(ALoop: TCoroutineLoop = clNoLoop;
      StackSize: Cardinal = MinStackSize);
    destructor Destroy; override;

    procedure BeforeDestruction; override;

    class procedure Error(const Msg: string;
      Data: Integer = 0); overload; virtual;
    class procedure Error(Msg: PResStringRec; Data: Integer = 0); overload;
  end;

  {*
    �num�rateur en coroutine
    Pour obtenir un �num�rateur concret, il faut surcharger les m�thode Execute
    et SetNextValue, et d�finir une propri�t� Current. La m�thode Execute peut
    appeler plusieurs fois Yield avec une valeur quelconque en param�tre. La
    m�thode SetNextValue doit stocker cette valeur retransmise l� o� la
    propri�t� Current pourra la relire.
    @author sjrd, sur une id�e de Sergey Antonov
    @version 1.0
  *}
  TCoroutineEnumerator = class(TCoroutine)
  protected
    procedure Yield(const Value); reintroduce;

    {*
      Stocke une valeur envoy�e par Yield
      Surchargez SetNextValue pour stocker correctement Value selon son type.
      @param Value   Valeur � stocker
    *}
    procedure SetNextValue(const Value); virtual; abstract;
  public
    function MoveNext: Boolean;
  end;

implementation

var
  PageSize: Cardinal = 4096;

{-----------------}
{ Global routines }
{-----------------}

{*
  Initialise les variables globales
*}
procedure InitGlobalVars;
var
  SystemInfo: TSystemInfo;
begin
  GetSystemInfo(SystemInfo);
  PageSize := SystemInfo.dwPageSize;
end;

{------------------------------------}
{ Global routines used by TCoroutine }
{------------------------------------}

{*
  Restaure un �tat serein d'ex�cution de code Delphi et trouve le TIB
  @return Adresse lin�aire du TIB
*}
function CleanUpAndGetTIB: PTIB;
const
  TIBSelfPointer = $18;
asm
        // Clear Direction flag
        CLD

        // Reinitialize the FPU - see System._FpuInit
        FNINIT
        FWAIT
        FLDCW Default8087CW

        // Get TIB
        MOV     EAX,TIBSelfPointer
        MOV     EAX,FS:[EAX]
end;

{*
  Pop tous les registres de la pile
  PopRegisters est utilis�e comme point de retour dans SaveRunningFrame.
*}
procedure PopRegisters;
asm
        POPAD
end;

{*
  Sauvegarde le cadre d'ex�cution courant
  @param TIB     Pointeur sur le TIB
  @param Frame   O� stocker le cadre d'ex�cution
  @return Pointeur sur le TIB
*}
function SaveRunningFrame(TIB: PTIB; var Frame: TRunningFrame): PTIB;
asm
        { ->    EAX     Pointer to TIB
                EDX     Pointer to frame
          <-    EAX     Pointer to TIB   }

        // TIB
        MOV     ECX,[EAX].TTIB.SEH
        MOV     [EDX].TRunningFrame.SEH,ECX
        MOV     ECX,[EAX].TTIB.StackTop
        MOV     [EDX].TRunningFrame.StackTop,ECX
        MOV     ECX,[EAX].TTIB.StackBottom
        MOV     [EDX].TRunningFrame.StackBottom,ECX

        // ESP
        LEA     ECX,[ESP+4] // +4 because of return address
        MOV     [EDX].TRunningFrame.StackPtr,ECX

        // Return address
        MOV     [EDX].TRunningFrame.InstructionPtr,OFFSET PopRegisters
end;

{*
  Met en place un cadre d'ex�cution
  Cette proc�dure ne retourne jamais : elle continue l'ex�cution �
  l'instruction point�e par Frame.InstructionPtr.
  @param TIB     Pointeur sur le TIB
  @param Frame   Informations sur le cadre � mettre en place
*}
procedure SetupRunningFrame(TIB: PTIB; const Frame: TRunningFrame);
asm
        { Make sure you do a *JMP* to this procedure, not a *CALL*, because it
          won't get back and musn't get the return address in the stack. }

        { ->    EAX     Pointer to TIB
                EDX     Pointer to frame
                EBX     Value for EAX just before the jump }

        // TIB
        MOV     ECX,[EDX].TRunningFrame.SEH
        MOV     [EAX].TTIB.SEH,ECX
        MOV     ECX,[EDX].TRunningFrame.StackBottom
        MOV     [EAX].TTIB.StackBottom,ECX
        MOV     ECX,[EDX].TRunningFrame.StackTop
        MOV     [EAX].TTIB.StackTop,ECX

        // ESP
        MOV     ESP,[EDX].TRunningFrame.StackPtr

        // Jump to the instruction
        MOV     EAX,EBX
        MOV     ECX,[EDX].TRunningFrame.InstructionPtr
        JMP     ECX
end;

{------------------}
{ TCoroutine class }
{------------------}

{*
  Cr�e une coroutine avec une taille de pile donn�e
  @param ALoop       Type de boucle de la coroutine (d�faut : clNoLoop)
  @param StackSize   Taille de la pile (d�faut et minimum : MinStackSize)
*}
constructor TCoroutine.Create(ALoop: TCoroutineLoop = clNoLoop;
  StackSize: Cardinal = MinStackSize);
begin
  inherited Create;

  // Check stack size
  if (StackSize < MinStackSize) or (StackSize mod MinStackSize <> 0) then
    Error(@SCoroutBadStackSize, StackSize);

  // Reserve stack address space
  FStackSize := StackSize;
  FStackBuffer := VirtualAlloc(nil, FStackSize, MEM_RESERVE, PAGE_READWRITE);
  if not Assigned(FStackBuffer) then
    RaiseLastOSError;
  FStack := Pointer(Cardinal(FStackBuffer) + FStackSize);

  // Allocate base stack
  if not Assigned(VirtualAlloc(Pointer(Cardinal(FStack) - PageSize),
    PageSize, MEM_COMMIT, PAGE_READWRITE)) then
    RaiseLastOSError;
  if not Assigned(VirtualAlloc(Pointer(Cardinal(FStack) - 2*PageSize),
    PageSize, MEM_COMMIT, PAGE_READWRITE or PAGE_GUARD)) then
    RaiseLastOSError;

  // Set up configuration
  FLoop := ALoop;

  // Set up original state
  FCoroutineRunning := False;
  FTerminating := False;
  FTerminated := False;

  // Initialize coroutine
  InitCoroutine;
end;

{*
  D�truit l'instance
*}
destructor TCoroutine.Destroy;
begin
  // Release stack address space
  if Assigned(FStackBuffer) then
    if not VirtualFree(FStackBuffer, 0, MEM_RELEASE) then
      RaiseLastOSError;

  inherited;
end;

{*
  Initialise la coroutine avant sa premi�re ex�cution
*}
procedure TCoroutine.InitCoroutine;
begin
  with FCoroutineFrame do
  begin
    SEH := nil;
    StackTop := FStack;
    StackBottom := FStackBuffer;
    StackPtr := FStack;
    InstructionPtr := @TCoroutine.Main;
  end;

  FExceptObject := nil;
end;

{*
  M�thode principale de la coroutine
*}
procedure TCoroutine.Main;
begin
  if not Terminating then
  try
    repeat
      Execute;
      if (Loop = clNextInvoke) and (not Terminating) then
        Yield;
    until (Loop = clNoLoop) or Terminating;
  except
    FExceptObject := AcquireExceptionObject;
    FExceptAddress := ExceptAddr;
  end;

  Terminate;
end;

{*
  Switche entre les deux cadres d'ex�cution (appelant-coroutine et vice versa)
*}
procedure TCoroutine.SwitchRunningFrame;
asm
        { ->    EAX     Self }

        // Save all registers
        PUSHAD
        MOV     EBX,EAX

        // Get CoroutineRunning value into CF then switch it
        BTC     WORD PTR [EBX].TCoroutine.FCoroutineRunning,0

        // Get frame addresses
        LEA     ESI,[EBX].TCoroutine.FCoroutineFrame
        LEA     EDI,[EBX].TCoroutine.FCallerFrame
        JC      @@running // from BTC
        XCHG    ESI,EDI
@@running:

        // Clean up and get TIB
        CALL    CleanUpAndGetTIB

        // Save current running frame
        MOV     EDX,ESI
        CALL    SaveRunningFrame

        // Set up new running frame
        MOV     EDX,EDI
        JMP     SetupRunningFrame
end;

{*
  Termine la coroutine
*}
procedure TCoroutine.Terminate;
asm
        { ->    EAX     Self }

        // Update state
        MOV     [EAX].TCoroutine.FTerminated,1
        MOV     [EAX].TCoroutine.FCoroutineRunning,0

        // Go back to caller running frame
        LEA     EDX,[EAX].TCoroutine.FCallerFrame
        CALL    CleanUpAndGetTIB
        JMP     SetupRunningFrame
end;

{*
  Ex�cute la coroutine jusqu'au prochain appel � Yield
*}
procedure TCoroutine.Invoke;
var
  TempError: TObject;
begin
  if CoroutineRunning then
    Error(@SCoroutInvalidOpWhileRunning);
  if Terminated then
    Error(@SCoroutTerminated);

  // Enter the coroutine
  SwitchRunningFrame;

  if Assigned(FExceptObject) then
  begin
    {$WARN SYMBOL_DEPRECATED OFF} // EStackOverflow is deprecated
    if FExceptObject is EStackOverflow then
    try
      // Reset guard in our stack - in case of upcoming call to Reset
      if not Assigned(VirtualAlloc(FStackBuffer, PageSize, MEM_COMMIT,
        PAGE_READWRITE or PAGE_GUARD)) then
        RaiseLastOSError;
    except
      FExceptObject.Free;
      raise;
    end;
    {$WARN SYMBOL_DEPRECATED ON}

    // Re-raise exception
    TempError := FExceptObject;
    FExceptObject := nil;
    raise TempError at FExceptAddress;
  end;
end;

{*
  Rend la main � l'appelant - retournera lors du prochain appel � Invoke
*}
procedure TCoroutine.Yield;
begin
  if not CoroutineRunning then
    Error(@SCoroutInvalidOpWhileNotRunning);
  if Terminating then
    raise ECoroutineTerminating.CreateRes(@SCoroutTerminating);

  SwitchRunningFrame;
end;

{*
  R�initialise compl�tement la coroutine
  La coroutine doit �tre termin�e pour appeler Reset (Terminated = True).
  Reset peut �galement �tre appel�e si la coroutine s'est termin�e � cause
  d'une exception.
*}
procedure TCoroutine.Reset;
begin
  if CoroutineRunning then
    Error(@SCoroutInvalidOpWhileRunning);
  if not Terminated then
    Error(@SCoroutNotTerminated);

  FTerminated := False;
  InitCoroutine;
end;

{*
  Appel� juste avant le premier destructeur
  BeforeDestruction assure qu'on n'essaie pas de d�truire l'objet coroutine
  depuis le code de la coroutine.
  Si la coroutine n'a pas termin� son ex�cution lors du dernier appel � Invoke,
  BeforeDestruction tente de la faire se terminer correctement. Si un appel �
  Yield survient, une exception ECoroutineTerminating est d�clench�e pour
  forcer la coroutine � se terminer.
*}
procedure TCoroutine.BeforeDestruction;
begin
  if FCoroutineRunning then
    Error(@SCoroutInvalidOpWhileRunning);

  FTerminating := True;

  if not Terminated then
  begin
    SwitchRunningFrame;
    if Assigned(FExceptObject) then
      FExceptObject.Free;
  end;

  inherited;
end;

{*
  D�clenche une erreur ECoroutineError
  @param Msg    Cha�ne de format du message
  @param Data   Param�tre du format
*}
class procedure TCoroutine.Error(const Msg: string; Data: Integer = 0);

  function ReturnAddr: Pointer;
  asm
        MOV     EAX,[EBP+4]
  end;

begin
  raise ECoroutineError.CreateFmt(Msg, [Data]) at ReturnAddr;
end;

{*
  D�clenche une erreur ECoroutineError
  @param Msg    Cha�ne de ressource de format du message
  @param Data   Param�tre du format
*}
class procedure TCoroutine.Error(Msg: PResStringRec; Data: Integer = 0);
begin
  Error(LoadResString(Msg), Data);
end;

{----------------------}
{ TYieldIterator class }
{----------------------}

{*
  Renvoie une valeur interm�diaire
  Yield utilise SetNextValue pour stocker la valeur, qui devra ensuite �tre
  accessible via la d�finition d'une propri�t� Current.
  @param Value   Valeur � renvoyer
*}
procedure TCoroutineEnumerator.Yield(const Value);
begin
  SetNextValue(Value);
  inherited Yield;
end;

{*
  Passe � l'�l�ment suivant de l'�num�rateur
  @return True s'il y a encore un �l�ment, False si l'�num�rateur est termin�
*}
function TCoroutineEnumerator.MoveNext: Boolean;
begin
  if not Terminated then
    Invoke;
  Result := not Terminated;
end;

initialization
  InitGlobalVars;
end.

