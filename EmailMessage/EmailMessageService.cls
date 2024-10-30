public with sharing class EmailMessageService {

    public class emailMessageServiceException extends Exception {
    }
    private static CustomNotificationType notificationType;

    public static void manageResponseEmail(List<EmailMessage> lEmailMessages) {
        Map<String, String> mCasesByEmail = new Map<String, String>();
        List<EmailMessage> lEmailMessagesToManage = new List<EmailMessage>();
        String errorMessage = '';

        try {
            for (EmailMessage em : lEmailMessages) {
                if (em.Incoming == true && em.ParentId != null && !em.COR_EmailServiceIncoming__c) {
                    mCasesByEmail.put(em.Id, em.ParentId);
                    lEmailMessagesToManage.add(em);
                }
            }


            if (!lEmailMessagesToManage.isEmpty()) {
                List<Case> lCasesToUpdate = new List<Case>();
                List<CaseComment> lCaseCommentsToInsert = new List<CaseComment>();
                Map<Id, Case> mCases = new Map<Id, Case>([SELECT Id, CaseNumber, Status, OwnerId, Owner.IsActive, Last_queue_id__c, ABA_BOL_Reprogramado__c, ABA_LIS_Servicio_del_Ticket__c, Origin FROM Case WHERE Id IN :mCasesByEmail.values()]);

                for (EmailMessage em : lEmailMessagesToManage) {
                    Case c = mCases.get(em.ParentId);
                    if (c.Status == 'En Curso' && c.OwnerId.getSobjectType().getDescribe().getName() == 'User' && c.Owner.IsActive) {
                        CustomNotificationType cmt = getCustomNotification();
                        if (cmt != null) {
                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            String title = String.format(System.Label.NewResponse_InProgress_Title,
                                    new List<Object>{
                                            c.CaseNumber
                                    });
                            String body = String.format(System.Label.NewResponse_InProgress_Body,
                                    new List<Object>{
                                            c.CaseNumber
                                    });
                            notification.setTitle(title);
                            notification.setBody(body);
                            notification.setNotificationTypeId(notificationType.Id);
                            notification.setTargetId(c.Id);
                            notification.send(new Set <String>{
                                    c.OwnerId
                            });
                        } else {
                            errorMessage = errorMessage + 'Notification type was not found to notify about case ' + c.CaseNumber + '\n';
                        }

                    } else if (c.Status != 'Nuevo') {
                        String currentStatus = c.Status;
                        c.Status = 'Nuevo';
                        c.ABA_LIS_Motivo_del_Estado__c = null;
                        c.ABA_LIS_Situacion__c = null;
                        if (c.Last_queue_id__c != null) {
                            c.OwnerId = c.Last_queue_id__c;
                        } else if (String.isNotBlank(c.ABA_LIS_Servicio_del_Ticket__c) && QueueUtil.getDefaultQueueForNewResponse(c) != null) {
                            c.OwnerId = QueueUtil.getDefaultQueueForNewResponse(c).Id;
                        } else {
                            errorMessage = errorMessage + 'Owner was not changed for case ' + c.CaseNumber + '\n';
                        }

                        if (CaseUtil.isCaseStatusClosed(currentStatus)) {
                            c.COR_Reopened__c = true;
                            c.ABA_LIS_Subestado__c = 'Reaperturado';
                        } else {
                            c.ABA_LIS_Subestado__c = 'Respuesta';
                        }

                        if (c.ABA_BOL_Reprogramado__c) {
                            c.ABA_DT_Fecha_reprogramacion__c = null;
                            c.ABA_LIS_Motivo_de_reprogramacion__c = null;
                            lCaseCommentsToInsert.add(new CaseComment(ParentId = c.Id, CommentBody = System.Label.RescheduleErasedByNewResponse));
                        }
                        lCasesToUpdate.add(c);
                    }
                }

                if (!lCasesToUpdate.isEmpty()) {
                    List<Database.SaveResult> lResults = Database.update(lCasesToUpdate, false);
                    for (Database.SaveResult sr : lResults) {
                        if (!sr.success) {
                            errorMessage = errorMessage + sr.getId() + ' - ' + sr.getErrors() + '\n';
                        }
                    }
                }

                if (!lCaseCommentsToInsert.isEmpty()) {
                    List<Database.SaveResult> lResults = Database.insert(lCaseCommentsToInsert, false);
                    for (Database.SaveResult sr : lResults) {
                        if (!sr.success) {
                            errorMessage = errorMessage + sr.getId() + ' - ' + sr.getErrors() + '\n';
                        }
                    }
                }
                if (String.isNotBlank(errorMessage)) {
                    System.debug(LoggingLevel.ERROR, 'Email-to-Case error: ' + errorMessage);

                    COR_SendEmail.sendExceptionEmail('Email-to-Case error notification', errorMessage);
                }
            }
        } catch (Exception e) {
            errorMessage = '\nIssued emails:\n';
            for (EmailMessage em : lEmailMessages){
                errorMessage = errorMessage+em.MessageDate+' * FROM: '+em.FromAddress+' * TO: '+em.ToAddress + ' * CC: '+em.CcAddress+'\n';
            }
            System.debug(LoggingLevel.ERROR, 'Email-to-Case error: ' + e.getMessage());
            COR_SendEmail.sendExceptionEmail('Email-to-Case error notification', e.getMessage()+errorMessage);
        }
    }



    public static CustomNotificationType getCustomNotification() {
        if (notificationType == null) {
            List<CustomNotificationType>lCustomNotificationTypes = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'NewResponse'];
            if (!lCustomNotificationTypes.isEmpty()) {
                notificationType = lCustomNotificationTypes[0];
            }
        }
        return notificationType;
    }


}