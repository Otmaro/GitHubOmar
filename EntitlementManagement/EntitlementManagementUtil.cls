public with sharing class EntitlementManagementUtil {
    public static void setEntitlement(List<Case> newList, Map<Id, Case> oldMap, Boolean isInsert) {

        Boolean assignEntitlement = false;
        for (Case c : newList) {
            if (isInsert && String.isNotBlank(c.ABA_LIS_Servicio_del_Ticket__c)) {
                assignEntitlement = true;
                break;
            } else if (!isInsert && String.isNotBlank(c.ABA_LIS_Servicio_del_Ticket__c) && c.ABA_LIS_Servicio_del_Ticket__c != oldMap.get(c.Id).ABA_LIS_Servicio_del_Ticket__c) {
                assignEntitlement = true;
                break;
            }
        }

        if (assignEntitlement) {
            List<SLAsByService__mdt> lSlAsByServices = [SELECT Id, Service__c, EntitlementName__c, BussinessHoursName__c FROM SLAsByService__mdt];
            List<Entitlement> lEntitlements = new List<Entitlement>([SELECT Id, Name FROM Entitlement WHERE StartDate <= TODAY AND (EndDate = NULL OR EndDate >= TODAY)]);
            List<BusinessHours> lBHs = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE IsActive = TRUE]);
            if (!lSlAsByServices.isEmpty() && !lEntitlements.isEmpty() && !lBHs.isEmpty()){
                Map<String, SLAsByService__mdt> mSlAsByService = (Map<String, SLAsByService__mdt>) CollectionUtils.stringMapFromCollectionByKey('Service__c', lSlAsByServices);
                Map<String, Entitlement> mEntitlementsByName = (Map<String, Entitlement>) CollectionUtils.stringMapFromCollectionByKey('Name', lEntitlements);
                Map<String, BusinessHours> mBusinessHoursByName = (Map<String, BusinessHours>) CollectionUtils.stringMapFromCollectionByKey('Name', lBHs);


                for (Case c : newList) {
                    if (mSlAsByService.containsKey(c.ABA_LIS_Servicio_del_Ticket__c)) {
                        SLAsByService__mdt sla = mSlAsByService.get(c.ABA_LIS_Servicio_del_Ticket__c);
                        c.EntitlementId = mEntitlementsByName?.get(sla.EntitlementName__c)?.Id;
                        c.BusinessHoursId = mBusinessHoursByName?.get(sla.BussinessHoursName__c)?.Id;

                    }
                }
            }
        }
    }

    public static void handleMilestones(List<Case> newList, Map<Id, Case> oldMap) {
        try {
            Map<String, Map<String, CaseMilestone>> mMilestones = getMilestoneMap(newList);
            Map<String, String> mMilestonesGroups = getMilestonesGroupsMap();
            List<CaseMilestone> lCaseMilestonesToUpdate = new List<CaseMilestone>();
            for (Case c : newList) {
                if (c.IsClosed && c.IsClosed != oldMap?.get(c.Id)?.IsClosed) {
                    if (mMilestonesGroups?.get('OpenStatus'.toUpperCase())?.split(';') != null){
                        List<String> lMilestones = mMilestonesGroups?.get('OpenStatus'.toUpperCase())?.split(';');
                        for (String s : lMilestones) {
                            CaseMilestone cm = mMilestones?.get(c.Id)?.get(s.toUpperCase());
                            if (cm != null) {
                                cm.CompletionDate = System.now();
                                lCaseMilestonesToUpdate.add(cm);
                            }
                        }
                    }
                }

                String milestoneGroup = mMilestonesGroups?.get(oldMap.get(c.Id)?.Status?.toUpperCase())?.toUpperCase();
                if (c.Status != oldMap?.get(c.Id)?.Status && !String.isBlank(milestoneGroup)) {
                    List<String> lMilestones = milestoneGroup.split(';');
                    for (String s : lMilestones) {
                        CaseMilestone cm = mMilestones?.get(c.Id)?.get(s);
                        if (cm != null) {
                            cm.CompletionDate = System.now();
                            lCaseMilestonesToUpdate.add(cm);
                        }
                    }


                }

                milestoneGroup = mMilestonesGroups?.get(oldMap.get(c.Id)?.ABA_LIS_Motivo_del_Estado__c?.toUpperCase())?.toUpperCase();
                if (c.ABA_LIS_Motivo_del_Estado__c != oldMap?.get(c.Id)?.ABA_LIS_Motivo_del_Estado__c && !String.isBlank(milestoneGroup)) {
                    List<String> lMilestones = milestoneGroup.split(';');
                    for (String s : lMilestones) {
                        CaseMilestone cm = mMilestones?.get(c.Id)?.get(s);
                        if (cm != null) {
                            cm.CompletionDate = System.now();
                            lCaseMilestonesToUpdate.add(cm);
                        }
                    }
                }
            }
            update lCaseMilestonesToUpdate;

        } catch (Exception e) {
            System.debug('Error method handleMilestones: ' + e.getMessage());
        }
    }

    private static Map<String, Map<String, CaseMilestone>> getMilestoneMap(List<Case> newList) {
        Map<String, Map<String, CaseMilestone>> response = new Map<String, Map<String, CaseMilestone>>();
        Set<String> sCaseIds = new Set<String>();
        List<Case> lccsCases = new List<Case>();
        List<CaseMilestone> lMilestones = new List<CaseMilestone>();
        for (Case c : newList) {
            if (String.isNotBlank(c.EntitlementId)) {
                sCaseIds.add(c.Id);
                lccsCases.add(c);
            }
        }

        lMilestones = [SELECT Id, MilestoneType.Name, CaseId FROM CaseMilestone WHERE CaseId IN :sCaseIds AND IsCompleted = FALSE];

        for (Case c : lccsCases) {
            Map<String, CaseMilestone> mMilestonesPerCase = new Map<String, CaseMilestone>();
            for (CaseMilestone cm : lMilestones) {
                if (cm.CaseId == c.Id) {
                    mMilestonesPerCase.put(cm.MilestoneType.Name.toUpperCase(), cm);
                }
            }
            response.put(c.Id, mMilestonesPerCase);
        }

        return response;
    }

    private static Map<String, String> getMilestonesGroupsMap() {
        Map<String, String> mResponse = new Map<String, String>();
        List<MilestonesGroups__mdt> lMilestonesGroups = new List<MilestonesGroups__mdt>([SELECT Id, KeyValue__c, GroupName__c FROM MilestonesGroups__mdt WHERE KeyValue__c != '' AND GroupName__c != '']);
        for (MilestonesGroups__mdt mg : lMilestonesGroups) {
            mResponse.put(mg.KeyValue__c.toUpperCase(), mg.GroupName__c);
        }
        return mResponse;
    }

    public static void closeFirstContactMilestone(List<EmailMessage> lEmailMessages, Map<Id, EmailMessage> oldMap, Boolean isInsert) {
        Map<String, EmailMessage> mEmailMessageByParentId = new Map<String, EmailMessage>();
        for (EmailMessage em : lEmailMessages) {
            if (em.Incoming == false && em.ParentId != null && (isInsert || (em.Status != 'Draft' && em.Status != oldMap.get(em.Id).Status))) {
                mEmailMessageByParentId.put(em.ParentId, em);
            }
        }
        if (!mEmailMessageByParentId.isEmpty()) {
            List<Case> lCases = [SELECT Id, SuppliedEmail FROM Case WHERE Id IN :mEmailMessageByParentId.keySet() AND SuppliedEmail != NULL];
            if (!lCases.isEmpty()){
                Map<String, Case> mCases = (Map<String, Case>) CollectionUtils.stringMapFromCollectionByKey('Id', lCases);
                List<CaseMilestone> lCaseMilestones = [SELECT Id, CaseId FROM CaseMilestone WHERE MilestoneType.Name = 'Primera respuesta contacto escrito' AND IsCompleted = FALSE AND CaseId IN :mCases.keySet()];
                List<CaseMilestone> lCaseMilestonesToUpdate = new List<CaseMilestone>();
                for (CaseMilestone cm : lCaseMilestones) {
                    if (mCases?.get(cm.CaseId)?.SuppliedEmail == mEmailMessageByParentId?.get(cm.CaseId).ToAddress) {
                        cm.CompletionDate = System.now();
                        lCaseMilestonesToUpdate.add(cm);
                    }
                }
                update lCaseMilestonesToUpdate;
            }
        }
    }

}