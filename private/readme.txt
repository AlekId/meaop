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
  RegisterFunction();

CoreLocalService
  RegisterEvent()
  Subscribe/UnSubscribe Event

InventoryService: Informs clients about which services and functionality is available.
 * List all services
 * list all functions of a service 
 * list all messages of a service

MeRemoteService

CoreRemoteService
