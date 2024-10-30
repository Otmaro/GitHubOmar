public with sharing class QueueUtil {

    private static Map<String, Group> mQueuesByDevName;
    private static Map<String, Group> mQueuesById;
    private static Map<String, String> mDefaultRescheduleQueuesDevNamesByService;
    private static Map<String, Set<Reschedule_QueueByServicioTicket__mdt>> mAvailableRescheduleQueuesByService;
    private static Map<String, String> mNewResponse_mQueueByService;
    private static Map<String, Map<String, String>> mNewResponse_mQueueByServiceAndOrigin;
    private static Map<String, Map<String, String>> escalationQueueDevNameByTypeAndServicio;

    public static Group getQueueByDevName(String devName) {
        generatemQueues();
        return mQueuesByDevName.get(devName);
    }

    public static Group getQueueById(String queueId) {
        generatemQueues();
        return mQueuesById.get(queueId);
    }


    public static Group getWaitingQueue() {
        COR_Settings__mdt wq = COR_Settings__mdt.getInstance('WaitingQueue');
        if (wq != null) {
            generatemQueues();
            return mQueuesByDevName.get(wq.Value__c);
        } else {
            return null;
        }
    }

    public static Group getDefaultQueueForNewResponse(Case c) {
        Group response;
        setNewResponseMap();

        if (String.isNotBlank(c.Origin)) {
            response = getDefaultQueueForNewResponse(c.ABA_LIS_Servicio_del_Ticket__c, c.Origin);
        }

        if (response == null && String.isNotBlank(c.ABA_LIS_Servicio_del_Ticket__c)) {
            response = getDefaultQueueForNewResponse(c.ABA_LIS_Servicio_del_Ticket__c);
        }

        return response;
    }

    public static Group getDefaultQueueForNewResponse(String service, String origin) {

        setNewResponseMap();
        Group response;

        if (String.isNotBlank(service) && String.isNotBlank(origin)) {
            String queueDevName = mNewResponse_mQueueByServiceAndOrigin.get(service)?.get(origin);
            if (String.isNotBlank(queueDevName)) {
                response = getQueueByDevName(queueDevName);
            }
        }
        return response;
    }

    public static Group getDefaultQueueForNewResponse(String service) {
        Group response;
        setNewResponseMap();
        String queueDevName = mNewResponse_mQueueByService.get(service);
        if (String.isNotBlank(queueDevName)) {
            response = getQueueByDevName(queueDevName);
        }
        return response;
    }

    public static Set<String> getAvailableRescheduleQueuesDevNames(String service) {
        Set<String> response;
        setRescheduleQueuesAvailableMap();

        Set<Reschedule_QueueByServicioTicket__mdt> mdts = mAvailableRescheduleQueuesByService.get(service);
        if (mdts != null) {
            response = new Set<String>();
            for (Reschedule_QueueByServicioTicket__mdt mdt : mdts) {
                response.add(mdt.QueueDevName__c);
            }
        }
        return response;
    }
    public static String getDefaultRescheduleQueueDevName(String service) {
        setDefaultRescheduleQueuesMap();
        return mDefaultRescheduleQueuesDevNamesByService.get(service);
    }

    public static String getWorkingGroupByQueueId(String queueId) {
        String queueDevName = getQueueById(queueId)?.DeveloperName;
        WorkingGroupbyQueue__mdt wg = WorkingGroupbyQueue__mdt.getInstance(queueDevName);
        return wg?.WorkingGroup__c;
    }

    public static String getInternalEscalationQueueByService(String service) {
        String response;
        setInternalEscalationQueueDevNamesMap();
        String queueDevName = escalationQueueDevNameByTypeAndServicio.get('Escalado Interno')?.get(service);
        if (String.isNotBlank(queueDevName)) {
            response = getQueueByDevName(queueDevName)?.Id;
        }
        return response;
    }

    /****** Map generators ******/
    private static void generatemQueues() {

        if (mQueuesByDevName == null || mQueuesById == null) {
            mQueuesByDevName = new Map<String, Group>();
            mQueuesById = new Map<String, Group>();
            List<Group> lQueues = new List<Group>([SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue']);
            for (Group g : lQueues) {
                mQueuesByDevName.put(g.DeveloperName, g);
                mQueuesById.put(g.Id, g);
            }
        }
    }

    private static void setNewResponseMap() {
        if (mNewResponse_mQueueByService == null || mNewResponse_mQueueByServiceAndOrigin == null) {
            mNewResponse_mQueueByService = new Map<String, String>();
            mNewResponse_mQueueByServiceAndOrigin = new Map<String, Map<String, String>>();
            List<Asignacion_de_colas__c> lAsignacionDeColas = [SELECT Servicio__c, Origen__c, Cola__c FROM Asignacion_de_colas__c];

            for (Asignacion_de_colas__c adc : lAsignacionDeColas) {
                if (String.isNotBlank(adc.Servicio__c) && String.isNotBlank(adc.Cola__c)) {

                    if (String.isBlank(adc.Origen__c)) {
                        if (!mNewResponse_mQueueByService.containsKey(adc.Servicio__c)) {
                            mNewResponse_mQueueByService.put(adc.Servicio__c, adc.Cola__c);
                        }
                    } else {
                        if (!mNewResponse_mQueueByServiceAndOrigin.containsKey(adc.Servicio__c)) {
                            mNewResponse_mQueueByServiceAndOrigin.put(adc.Servicio__c, new Map<String, String>());
                        }
                        mNewResponse_mQueueByServiceAndOrigin.get(adc.Servicio__c).put(adc.Origen__c, adc.Cola__c);
                    }
                }
            }
        }
    }

    private static void setDefaultRescheduleQueuesMap() {
        if (mDefaultRescheduleQueuesDevNamesByService == null) {
            mDefaultRescheduleQueuesDevNamesByService = new Map<String, String>();
            Map<String, Reschedule_QueueByServicioTicket__mdt> metadataMap = Reschedule_QueueByServicioTicket__mdt.getAll();
            for (Reschedule_QueueByServicioTicket__mdt mdt : metadataMap.values()) {
                if (mdt.Default__c && String.isNotBlank(mdt.Service__c) && String.isNotBlank(mdt.QueueDevName__c)) {
                    mDefaultRescheduleQueuesDevNamesByService.put(mdt.Service__c, mdt.QueueDevName__c);
                }
            }
        }
    }

    private static void setRescheduleQueuesAvailableMap() {
        if (mAvailableRescheduleQueuesByService == null) {
            mAvailableRescheduleQueuesByService = new Map<String, Set<Reschedule_QueueByServicioTicket__mdt>>();
            Map<String, Reschedule_QueueByServicioTicket__mdt> medatadamap = Reschedule_QueueByServicioTicket__mdt.getAll();
            for (Reschedule_QueueByServicioTicket__mdt mdt : medatadamap.values()) {
                if (!mAvailableRescheduleQueuesByService.containsKey(mdt.Service__c)) {
                    mAvailableRescheduleQueuesByService.put(mdt.Service__c, new Set<Reschedule_QueueByServicioTicket__mdt>());
                }
                mAvailableRescheduleQueuesByService.get(mdt.Service__c).add(mdt);
            }
        }
    }

    private static void setInternalEscalationQueueDevNamesMap() {
        List<Escalation_QueuesByService__mdt> lEscalationQueuesByServices = Escalation_QueuesByService__mdt.getAll().values();
        escalationQueueDevNameByTypeAndServicio = new Map<String, Map<String, String>>();
        for (Escalation_QueuesByService__mdt eq : lEscalationQueuesByServices) {
            if (!escalationQueueDevNameByTypeAndServicio.containsKey(eq.Type__c)) {
                escalationQueueDevNameByTypeAndServicio.put(eq.Type__c, new Map<String, String>());
            }
            escalationQueueDevNameByTypeAndServicio.get(eq.Type__c).put(eq.Service__c, eq.QueueDevName__c);
        }
    }

}