public with sharing class EmailMessageTriggerHandler {

    public static void handleAction(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, List<EmailMessage> newList, Map<Id, EmailMessage> newMap, List<EmailMessage> oldList, Map<Id, EmailMessage> oldMap) {
        if (isBefore) {
            if (isInsert) {

            } else if (isUpdate) {
            } else if (isDelete) {
                LCUtil_CLS.checkPermission(oldList, 'Deshabilitir_borrado_de_archivos');

            }
        }
        if (isAfter) {
            if (isInsert) {
                EmailMessageService.manageResponseEmail(newList);
                EntitlementManagementUtil.closeFirstContactMilestone(newList, null, isInsert);
                ABA_HND_Interacciones.AgregarCorreosElectronicos(newList);
            } else if (isUpdate) {
                EntitlementManagementUtil.closeFirstContactMilestone(newList, oldMap, isInsert);
            } else if (isDelete) {
            }
        }
    }
}