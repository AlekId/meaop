= MeRemote Layer: =

== MeTransport ==
  MeStreamFormater -- convert the atreamable the types to any format.
MeTransportClasses -- manage the registered transport classes

TODO: transport object define.
the transport object will transfer the type data from here to there.
the transport can wrap(wrap links) the data before transfering, and unwrap it after transfered.
1.Compress;2.Encrypt;3.Data Format
��Ϣ��������Ϣ(publisher)��������Ϣ(subscriber)
    ��Ϣ = MSG.ServiceName.Subject (��ǿ�Ƶģ����Դ��ڿ�Service����Ϣ)
      ��һ����Ϊ��Ϣ�����ͣ�
      �����ߣ�ĳService +  ���ţ� Subject,�����ӿ�����"."�ָ���
      �������б�
      ���ݣ�
    ����Զ�̷�����ԣ���Ϣ��һ���ֿ��Ա��ŵ�transport�С���ȫ��Service���롣


== MeRemoteInvoker ==
MeRemoteInvoker
  MeRemoteObject

TRemoteObject: ���Ժͷ�������Զ��
TRemoteObject  �����Ŀ����Ϊ�˱�֤Զ�����ԵĴ�����Ҫ��һЩԼ��������������"R"��ͷ�ĳ������Բ��ұ������������Եķ�����
���߳���ĳ��淽��ΪԶ�̷��������Ե�д����Ϊ���󷽷���ΪԶ�̷��������������û�б�Ҫ��Զ�̶����ָ������������

TRemoteInvokerFeature: ע�������ĳЩԼ���ĳ��󷽷����Զ��ִ�е�������Singleton.
  GRemoteInvokerFeature.Transport : the default transport.
  GRemoteInvokerFeature.Add(aClass, aTransport = nil); aTransport is nil means the default transport used.

Class Specifiction:
 * the abstract published methods in the aClass are the remote invoke methods.

TRemoteObjectFeature = Class(TRemoteInvokerFeature)

Class Specifiction:
 * the remote properties
   * write to the remote [Cache mechism?]
   * read from the remote when changed.
   * confiction resolve.

���Է���ע���֧�֣������ԣ���������[]��

= MeService Layer =
MeService -- interfaced object for others
 collects the public functions and events(messages) provides to others.
Properties:
  //## ServiceInfo: 
  //Service Name
  Class Property Name: string    
  //Service Author
  Class Property Author: string  
  Class Property Enabled: Boolean;
  Class Property MinCount: Integer;
  Class Property MaxCount: Integer;
  Class Property MaxIdleTime: Integer;
  Class Property Flags: TMeServiceFlags; //set of (msfListed, msfRunRequireAuth, msfListRequireAuth, msfStateful, msfPersistent)
  Class Property Instances: TThreadList;

  //the service instance startup time.
  Property StartupTime: TDateTime;
  Property Host: PMeServiceHost;
Methods:
  //Class Method GetFunctionList(const aList: PFunctionList); //I can use the Inventory Service to do so.

TMeServiceInfo -- the service type info: the basic service information and manage the instances of the service
  Property Name: string    
  Property Author: string  
  Property Enabled: Boolean;
  Property MinCount: Integer;
  Property MaxCount: Integer;
  Property MaxIdleTime: Integer;
  Property Instances: IMeServiceList;
  Method CreateService: IMeService;
TMeService -- //all published functions are service functions.
  //the service instance startup time.
  Property StartupTime: TDateTime;
  Property Host: IMeServiceHost;
  Property Info: IMeServiceInfo;

TMeRegisteredServices -- manage the registered service classes

  MeServiceHost -- host the services here.
  //the host is about shutting down 
  {
   Should be respected by the service to stop long running operations. 
   if not respected the service will eventually be killed by the host after a certain graceperiod.
  }
  Property IsShuttingDown: Boolean; 

MeServices  -- manage the service instances.
  MeServicePool

The MeService Library is a general service system framework.
 * TMeServiceMgr(TMeRegisteredServices): the service list, manage the service.
   the TMeServiceMgr mediates the communication between services. the services and events are registered to TMeServiceMgr.
 * TMeService: 

�ڱ��� Service�� TMeServiceFunction ���� Exported DLL ��������Ҫ����ľ��� Events��
�������Delphi��ͨ��Published�����Ϳ��Բ��ر�¶��������ô����������ô�죬�����������Կ���ͨ���ӿڣ�ֻҪ�����service�Ľӿڹ�񼴿ɡ�
Event��
Keypoint��
  Spec:
    ֻҪ�ǳ���ķ�����Ϊ ServiceFunctions?
    ���ԣ� 
      ������¼�����Ϊ Service �¼���ע���¼����Ա�����"On"��ͷ: OnChangedEvent: TServiceEvent; [ֻ�ڱ��ط�����ʵ��]
        ���غ���CoreServiceά�������ߡ�
      �ڱ��ط����У�����ʵ����ô���ӵ���Ϣ���ơ����¼������㹻��
�ɲ������ô� MeObject��ʵ��MeService��Ȼ��������ʱ�̶�̬���������ɽӿڣ�Ӧ���ǿ��еġ�
�������ȫ���� MeObject����ôPublished���ò����ˡ� only depend the CoreService

One Host can include mnay services.
CoreService: this service must have in the host. its functionality are:
  iRegisterFunction(const aProc: Pointer; const aProcType: PMeProcType); //only for delphi
  RegisterFunction(const aProc: Pointer; const aProcDesc: PChar); stdcall; //for all other language

CoreLocalService
  RegisterEvent()
  Subscribe/UnSubscribe Event

InventoryService: Informs clients about which services and functionality is available.
 * List all services
 * list all functions of a service 
 * list all messages of a service

MeRemoteService

CoreRemoteService














Interface instance variable:
[VMTAddr]  the records...  [MTAddr]
   |                          |
 TObject                   Interface

MTAddr:
  Adjust Self paramater directive
JMP XXXX
...
83442404F0 add dword ptr [esp+4], -$10 //����Self����ָ���λ�ã���Delphi��Ϊ - ʵ����¼���� - 4��
JMP TInterfacedObject.QueryInterface
83442404F0 add dword ptr [esp+4], -$10
JMP TInterfacedObject._AddRef
83442404F0 add dword ptr [esp+4], -$10
JMP TInterfacedObject._Release


//Get the offset of the self object to IMT.
function GetPIMTOffset(const I: IInterface): integer;
// PIMT = Pointer to Interface Method Table
const
  AddByte = $04244483; // opcode for ADD DWORD PTR [ESP+4], Shortint
  AddLong = $04244481; // opcode for ADD DWORD PTR [ESP+4], Longint
type
  //adjust self pointer parameter
  PAdjustSelfThunk = ^TAdjustSelfThunk;
  TAdjustSelfThunk = packed record
    case AddInstruction: longint of
      AddByte : (AdjustmentByte: shortint);
      AddLong : (AdjustmentLong: longint);
  end;
  PInterfaceMT = ^TInterfaceMT;
  TInterfaceMT = packed record
    QueryInterfaceThunk: PAdjustSelfThunk;
  end;
  TInterfaceRef = ^PInterfaceMT;
var
  QueryInterfaceThunk: PAdjustSelfThunk;
begin
  Result := -1;
  if Assigned(Pointer(I)) then
    try
      QueryInterfaceThunk := TInterfaceRef(I)^.QueryInterfaceThunk;
      case QueryInterfaceThunk.AddInstruction of
        AddByte: Result := -QueryInterfaceThunk.AdjustmentByte;  //һ�㶼�Ǹ�ƫ�����������ֵ��
        AddLong: Result := -QueryInterfaceThunk.AdjustmentLong;
      end;
    except
      // Protect against non-Delphi or invalid interface references
    end;
end;


function GetImplementingObject(const I: IInterface): TObject;
var
  Offset: integer;
begin
  Offset := GetPIMTOffset(I);
  if Offset > 0 
  then Result := TObject(PChar(I) - Offset)
  else Result := nil;  
end;

We're still only the first step towards getting the interface GUID (or IID which is the formally correct name). Now we're able to get the PIMT offset, but the offset by itself isn't very useful. What makes it useful is that we can use the offset to compare it with the offsets stored as part of the InterfaceEntry records the compiler generates for all the interfaces a class implements. As indicated above, we can use the TObject class function called GetInterfaceTable to get a pointer to this table. With that knowledge, let's write a function that tries to find the InterfaceEntry of an interface reference.

function GetInterfaceEntry(const I: IInterface): PInterfaceEntry;
var
  Offset: integer;
  Instance: TObject;
  InterfaceTable: PInterfaceTable;
  j: integer;
  CurrentClass: TClass;
begin
  Offset := GetPIMTOffset(I);
  Instance := GetImplementingObject(I);
  if (Offset >= 0) and Assigned(Instance) then
  begin
    CurrentClass := Instance.ClassType;
    while Assigned(CurrentClass) do
    begin
      InterfaceTable := CurrentClass.GetInterfaceTable;
      if Assigned(InterfaceTable) then
        for j := 0 to InterfaceTable.EntryCount-1 do
        begin
          Result := @InterfaceTable.Entries[j];
          if Result.IOffset = Offset then
            Exit;
        end;  
      CurrentClass := CurrentClass.ClassParent
    end;    
  end;
  Result := nil;  
end;


First we use the the utility functions above to get both the object instance and the offset of the PIMT field. Then we loop across this class and all parent classes looking for an InterfaceEntry that has the same offset as our PIMT field. When we find a match, we return a pointer to the InterfaceEntry record. This record contains both the PIMT offset and the IID. Let's write a simple wrapper function to extract the IID.

function GetInterfaceIID(const I: IInterface; var IID: TGUID): boolean;
var
  InterfaceEntry: PInterfaceEntry;
begin
  InterfaceEntry := GetInterfaceEntry(I);
  Result := Assigned(InterfaceEntry);
  if Result then
    IID := InterfaceEntry.IID;
end;

______________
SOA

���Ռ���ܘ�(Service-Oriented Architecture��SOA) ����

���Կ͞��𡹵ĺ��ĸ���ṩ�W·���Ն�λ����һ���ߏ��ԡ������}ʹ�õ������Խ��棬�����_���W·����������Ŀ�ˡ�

ǰ��
SOA��һ�N�ܘ�ģ�ͣ��ɾWվ���ռ��g�Ș˜ʻ�Ԫ���M�ɣ�Ŀ���Ǟ���I���WУ���ṩ�W·���Ն�λ����һ���ߏ��ԡ������}ʹ�õ������Խ��棬���M���ⲿ��Ȳ����ó�ʽ���Ñ����c���T(ϵ��)�����P��λ�����Ĝ�ͨ���M���_���W·����������Ŀ�ˡ�

���^SOA?
�҂����� Information Technology (IT)�a�I�ļܘ����M����1980��������C(mainframe)�ܘ�����1990���������ʽ(client server)�ܘ�����1999��r��network centric�ܘ�������2004��r���}�s�����^�� Service-Oriented Architecture�ܘ�(SOA�����Ռ���ܘ�) ������Ҳ�����������I�������@���ܘ�����I��δ��͕��]�и���������ˣ����Č�ᘌ�SOA���\�@�ĺ��飬Ҳϣ��͸�^���ĵĽ�B����춱�У�Wվ���ռ��g(web services) δ��ļܘ�����������
����׌�҂����һЩSOA����˼�����_���f [1]��

   1.

      SOA���������⣺����ǰ�����YӍ���T��˾�ɹ�����SOA��ʽ�������\�Б��ó�ʽ���Ү��rXML��web service����δ�����
   2.

      SOA���ǷN���g�����ǷN�������M���ķ������Á������ó�ʽ���\�Эh�����Լ�׌�WУ�ĘI�ճ�ʽ���ԡ����ܻ�����ʽ�lչ���۷e��
   3.

      ����ُ�I���µ�XML��web services�aƷ�����_�l���ߡ�����ƽ̨��ܛ�wԪ���ȣ���Ҳ����ʾ�Ϳ��Խ�����SOAʽ�đ��ó�ʽ��

���΁��f��SOA��һ�N��ѭ�习����ᘌ��WУ����I�ȑ��ó�ʽ���OӋ���_�l���ѽ����������������ѭ�习�����YӍ���g������ԣ�һ�����ЌWУ����I�I�յđ��ó�ʽ�Q��һ�������ġ�߉݋��λ���������WУ����I�I�\������Ԅt�ɷQ��һ헡����ա�������I�����w�\��h���оʹ���������������߉݋���I�շ��ա�������Ҫ�����M�������OӋ���_�l���ѽ�������ȣ�Ҳ�����Ҫ���з��Ռ���ܘ���SOA����

Ҫ���FSOA����Ҫ�WУ����I�ĳ�ʽ�OӋ���Ē񡸳��m�۷e���ա����^���c�Ƕȁ��_�l���ó�ʽ�������@�N���ڶ̕r�g�ȿ������@����̎����ʽ��߀�Ǳ����Ó����Խ�^�������ó�ʽ���뷨�����ԡ����з��տɷ����\�ã��������ǡ��ܷ���������ͬ���_�l�^�ķ����ٽ����������^�c���挦��ʽ�_�l��

SOA ��������ʽ�_�l���g���c����ʽ�����������Ľ���K�ã�����Ƃ�Ӎ��ͨ������������������ġ��I�շ��ա��M���B�Y���Դˁ팍�Fһ���µđ��ó�ʽ�����ǡ����^�_�l����͸�^�m���ĳ�ʽ�M������Ӎʽ�ĳ�ʽ�B�Y����׌�WУ����I�����򑪌W�����Ñ��������c��׃���µđ��ó�ʽֻҪ͸�^����Ӎ΢�{�����Ɍ��F�����ǡ�����׫������

SOA ����ֻ�ǳ�ʽ�_�l�ķ���Փ��Ҳ�ṩ��������������ѭ���������K�����ԑ��ó�ʽ���w��Ƕȁ��M�й�������ֱ�ӌ��^����ʽ���_�l���ĳ�ʽҕ�顸���ա���������������ա��g�ġ����ӂ�Ӎ���M�з�����SOA���׌��ʽ�OӋ���T�����ܲt��Εrԓ�����Ă��I��߉݋���Լ����Ҫ���У�����YӍ�������c��������Ɍ����ճ����M����ѻ��{�m��

SOA����\��?
SOA���Ռ���ܘ���һ�N���d��ϵ�y�ܘ�ģ�ͣ���Ҫ������ᘌ��WУ����I����M�϶��ɵ�һ�Mܛ�wԪ�����M�ϵ�Ԫ��ͨ��������ܛ�wԪ�������ռ������������ݡ����WУ����I�挦�ⲿҪ��r������ؓ؟���x�ⲿҪ���̎���E�����հ����ض����E�����г�ʽԪ������ܛ�wԪ���tؓ؟���й����ĳ�ʽ��SOA �ѳɞ�F��ܛ�w�lչ����Ҫ���g��͸�^ SOA ׌���|ϵ�y����׃�����ף���ʽ��ʹ�ö�Ҳ��ߡ����������_�l��������г�ʽԪ�����lչ�߿���ҕ����Ҫ�M�ϾW·����õķ��ա���������ض��S�̵ĮaƷ���ܻ���ƽ̨���_���������_����(Openness)���ķ�ɢʽԪ���ܘ��� SOA�����ϣ�SOA ��ͬ�������ܛ�wԪ����ܛ�w���gһ�㣬�\��С����M���M�ϳɑ���ϵ�y���� SOA ���{������Ό��˴��P�S�ɢ�đ���ϵ�y����Ԫ���ھW·�ϰl�С��M�ϼ�ʹ�á�SOA �������м��g����[2]��

   1.

      ��ɢʽ�ܘ� (distributed)��SOA �ĽM��Ԫ�������S���ɢ�ھW·�ϵ�ϵ�y�M�϶��������ǅ^��W·��Ҳ�����ǁ��ԏV��W·������Wվ���ռ��g (web services) �����\�� HTTP���໥�B�Y�� SOA����˵�������Ҳʹ�þWվ���ռ��g�ܿ�ľͳɞ�����֧Ԯ�W�H�W·��ϵ�yƽ̨����ʹ�õļ��g��
   2.

      �P�S�ɢ�Ľ��� (loosely coupled)�����y��ϵ�y��Ҫ�ǌ�����ϵ�y���������и���໥�P��С��M����ģ�M�������Ԫ�����lչ��Ҫ���M�O��������˽���M��������OӋ��ʹ�ã��Դ_�������`����M���B���P�S���ơ����һ����Ҫ�Բ�ͬ��M����Qԭʼ�OӋ���ͳɞ�һ�����y���¡�SOA ���������Խ���˜ʁ�M��ϵ�y��ֻҪ���Ͻ���Ҫ����M������������Q��������ϵ�y׃���ď��Զȡ�
   3.

      �����_�ŵĘ˜� (Open standard)��ʹ���_�Ř˜��� SOA �ĺ�����ɫ���^ȥ��ܛ�wԪ��ƽ̨�� CORBA��DCOM��RMI��J2EE ���Ì��مf������Ԫ���B�Y��Ҏ����ʹ�ò�ͬƽ̨��Ԫ���o����ͨ��SOA �t����춘˜��c�����ԣ����ɱ��ⲻͬƽ̨ (.NET web services �c Java web services) �_�l��ʽ�g�໥���ϵ����_��
   4.

      �����̽Ƕȳ��l (process centric)���ڽ���ϵ�y�r�������˽��ض�����������Ҫ�󣬁K�����и�ɷ��ս���(����ݔ���cݔ���Y�ϸ�ʽ)����������İlչ�߾Ϳ����������ս����_�l (���x��) ���m��Ԫ������ɹ�����

�����eһ���WУ���õ����Ӂ��f��SOA�ڌ��H�����ώ���Ŀ����ԡ����O�҂�Ҫ����һ������Ͷ��ľWվ���Wվ�ṩ�ķ��հ����˾���Ͷ�����I��Փ�ķ������I��Փ�Č������I�������]�Լ��������I�ȡ����y�ķ�ʽ�҂���������һ����ƵľWվ���ك��쌢������ƾWվ��ԭʼ�a(source code)�Á��޸ģ���������ƾWվ��ԭʼ�a�����е�ƽ̨�п��ܲ��Ǽ�վ������Ϥ�����Iϵ�y����Ҫ׌��վ����һ�����u�����K�����Լ�Ͷ�����}�ľ���Ͷ��ľWվ������Ҫ��Ϥ�@��ƽ̨�K�޸ľW퓼��yԇ���ټ��τe�˵ľWվ������һЩbug�����Ҫ�������o���}�����e�r�g����Ҫ���������µĕr�g�����ǣ�����҂�����SOA�ļܘ���Ԓ�����܌���ֻҪ���M���������I����ģ�M�����������Ԫ������Ȼ�ጢ�������ϵ��Wվ�м��ɣ�����Ҫ�ٻ��M�r�g���YԴ�Լ�ȥ�S�oһ������Ͷ��ľWվ��Ҳ����Ҫ�����н������Y�ώ��B�Y����������C�Ƶȡ��@���Wվ�����ǽ�����SOA�ϣ��������@Щweb servicesԪ����һ�����ó�ʽϵ�y������Ҫ���ǣ�͸�^��http��XML��SOAP �Ȯa�I�˜��_��ʽ�f�������ؓ����@Щ����ʹ�����Nƽ̨�����N���g����������������и��õķ��ջ�����ṩ�ߕr��Ҳ�����p�׵Č����ո��Q����¡���ϵ�y�_�l�߁��v�����Կ����p�Č�ϵ�y������ɣ�����˼��ע��Ҏ�����á������Ƶ�ϵ�y�ϣ��������ṩ�߶��ԣ�ֻҪ���OӋ��һ���õķ��գ����ĝ���ʹ�����Ј��������ܵ�ʹ����ƽ̨�����ƶ��Пo�޵Ŀ��ܡ��ξ��@������ʬF�������h������ԓ���Խ�ጞ�ʲ�N����̎ ��������ՄՓSOA�ˡ�

��� SOA �Č��������ǌ����г�ʽ߉݋�����Ճ���ȫ�������ڷ��ՃȲ����K����һ���˜ʵĽ����c�ⲿ����ͨ���@�N���������y��Ԫ�����������ǳ���ƣ�Ψһ�Ĳ�e�ǽ��涨�x�ķ�ʽ���Y�ϸ�ʽ���c��ͨ�ܵ�����Ǯa�I�˜� (http��XML��SOAP ��)�� Ҳ�����fֻҪ�܌������@�ӵĽ��棬��Փ����������ʲ�N������ʹ�ɞ� SOA��
��

�YՓ
�C�����ϵĽ�B��SOA�܎���Ď����������º�̎��
1.������Iӯ�գ��������WУ�ķ���Ʒ�|��
2.�ṩ��׃�ӵľW·�����͑B��
3.���͌WУ����I�ĳɱ���
4.�����_�l���յĕr�g��
5.���όWУ����I�ľW·���ռ��g�YԴ��
6.�������w�L�U�����⡣
��

�����īI
[1] http://dev2dev.bea.com.tw/techdoc/07soa/07soa_040812_01.htm
[2] http://www.microsoft.com/taiwan/msdn/columns/soa/SOA_overview_2004112901.htm

