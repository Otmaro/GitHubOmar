public with sharing class EmailServicesUtil {

    public class AttachedFilesException extends Exception {
    }

    public static EmailMessage generateEmailMessageFromInboundEmailMessage(Messaging.InboundEmail email, String relatedToId) {

        String toAddress = null;
        if (email.toAddresses != null) {
            for (String mail : email.toAddresses) {
                if (toAddress == null) {
                    toAddress = mail;
                } else {
                    toAddress = toAddress + ' ; ' + mail;
                }
            }
        }

        String textBody = '';
        if (email.plainTextBody != null) {
            if (email.plainTextBody.length() > 32000) {
                textBody = email.plainTextBody.substring(0, 31990);
            } else {
                textBody = email.plainTextBody;
            }
        }

        String htmlBody = '';
        if (email.htmlBody != null) {
            if (email.htmlBody.length() > 32000) {
                htmlBody = email.htmlBody.substring(0, 31990);
            } else {
                htmlBody = email.htmlBody;
            }
        } else {
            htmlBody = textBody;
        }

        String direccionesCC = null;
        if (email.ccAddresses != null) {
            for (String item : email.ccAddresses) {
                if (direccionesCC == null) {
                    direccionesCC = item;
                } else {
                    direccionesCC = direccionesCC + ' ; ' + item;
                }
            }
        }

        Id inReplyTo;
        String threadIdentifier = '';
        if (!String.isBlank(email.inReplyTo)) {
            List<EmailMessage> lEmailAux = new List<EmailMessage>([SELECT Id, ThreadIdentifier FROM EmailMessage WHERE MessageIdentifier = :email.inReplyTo]);
            if (!lEmailAux.isEmpty()) {
                inReplyTo = lEmailAux[0].Id;
                threadIdentifier = lEmailAux[0].ThreadIdentifier;
            }
        }

        String headers = '';
        if (email != null && email.headers != null && !email.headers.isEmpty()) {
            for (Messaging.InboundEmail.Header h : email.headers) {
                headers = headers + ' ' + String.valueOf(h);
            }
        }

        if (headers != null && headers.length() > 32000) {
            headers = headers.substring(0, 31990);
        }

        String subject;
        if (email?.subject != null) {
            if (email.subject.length() > 3000) {
                subject = email.subject.substring(0, 2990);
            } else {
                subject = email.subject;
            }
        }

        EmailMessage newEmail = new EmailMessage(
                Status = '0',
                COR_EmailServiceIncoming__c = true,
                FromAddress = email.fromAddress,
                FromName = email.fromName,
                ToAddress = toAddress,
                Subject = subject,
                TextBody = textBody,
                HtmlBody = htmlBody,
                RelatedToId = relatedToId,
                Incoming = true,
                MessageDate = System.now(),
                ReplyToEmailMessageId = inReplyTo,
                MessageIdentifier = email.messageId,
                ThreadIdentifier = threadIdentifier,
                CcAddress = direccionesCC,
                Headers = headers
        );

        return newEmail;
    }

    public static void handleAttachments(Messaging.InboundEmail email, EmailMessage em) {

        List<ContentVersion> lAttsToInsert = new List<ContentVersion>();
        Boolean insertError = false;
        String insertErrorText = '';
        try {
            List<EmailMessage> lEmailMessages = new List<EmailMessage>([SELECT Id, ActivityId, RelatedToId, ParentId FROM EmailMessage WHERE Id = :em.Id LIMIT 1]);
            if (lEmailMessages != null && !lEmailMessages.isEmpty()) {
                em = lEmailMessages[0];
                Boolean hasAttachments = false;
                if (email.textAttachments != null) {
                    hasAttachments = true;
                    for (Messaging.InboundEmail.TextAttachment tAttachment : email.textAttachments) {
                        ContentVersion cv = new ContentVersion();
                        cv.VersionData = (tAttachment?.body != null ? Blob.valueOf(tAttachment.body) : null);
                        cv.ContentLocation = 'S';
                        cv.Title = tAttachment.fileName;
                        cv.PathOnClient = tAttachment.fileName;
                        cv.FirstPublishLocationId = em.Id;
                        lAttsToInsert.add(cv);
                    }
                }
                if (email.binaryAttachments != null) {
                    hasAttachments = true;
                    for (Messaging.InboundEmail.BinaryAttachment bAttachment : email.binaryAttachments) {
                        ContentVersion cv = new ContentVersion();
                        cv.VersionData = bAttachment.body;
                        cv.ContentLocation = 'S';
                        cv.Title = bAttachment.fileName;
                        cv.PathOnClient = bAttachment.fileName;
                        cv.FirstPublishLocationId = em.Id;
                        lAttsToInsert.add(cv);
                    }
                }


                if (lAttsToInsert.size() > 0) {
                    List<Database.SaveResult> srList = Database.insert(lAttsToInsert, false);
                    Set<String> sIds = new Set<String>();

                    for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            sIds.add(sr.getId());
                        } else {
                            insertError = true;
                            for (Database.Error err : sr.getErrors()) {
                                insertErrorText = insertErrorText + err.getStatusCode() + ': ' + err.getMessage() + '\n';
                            }
                        }
                    }

                    lAttsToInsert = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :sIds];

                    List<ContentDocumentLink> lCDLs = new List<ContentDocumentLink>();

                    for (ContentVersion cv : lAttsToInsert) {
                        if (em.ParentId != null) {
                            lCDLs.add(new ContentDocumentLink(LinkedEntityId = em.ParentId, ContentDocumentId = cv.ContentDocumentId, ShareType = 'v'));
                        } else if (em.RelatedToId != null) {
                            lCDLs.add(new ContentDocumentLink(LinkedEntityId = em.RelatedToId, ContentDocumentId = cv.ContentDocumentId, ShareType = 'v'));
                        }
                        if (em.ActivityId != null) {
                            lCDLs.add(new ContentDocumentLink(LinkedEntityId = em.ActivityId, ContentDocumentId = cv.ContentDocumentId, ShareType = 'v'));
                        }
                    }

                    if (!lCDLs.isEmpty()) {
                        List<Database.SaveResult> srCDLsList = Database.insert(lCDLs, false);
                        for (Database.SaveResult sr : srCDLsList) {
                            if (!sr.isSuccess()) {
                                insertError = true;
                                for (Database.Error err : sr.getErrors()) {
                                    insertErrorText = insertErrorText + err.getStatusCode() + ': ' + err.getMessage() + '\n';
                                }
                            }
                        }
                    }
                }

                if (insertError) {
                    System.debug(LoggingLevel.ERROR, 'Insertion error. Throwing custom exception');
                    throw new AttachedFilesException('Errores en inserción de archivos adjuntos: ' + insertErrorText);
                }
            }

        } catch (Exception e) {
            System.debug('Error when handling mail attachments: ' + e.getMessage());
            COR_SendEmail.sendExceptionEmail('Email Service error notification',
                        					'Please see below data from affected email. '
                                                    + '\n From address: ' + email.fromAddress
                                                    + '\n To addresses: ' + email.toAddresses
                                                    + '\n CC Addresses: ' + email.ccAddresses
                                                    + '\n Email subject: ' + email.subject
                                                    + '\n Notification Date/time: ' + System.now()
                                                    + '\n\n Error when handling mail attachments: '
                                                    + '\n ' + e.getTypeName() + ' on ' + e.getLineNumber()
                                                    + '\n ' + e.getStackTraceString()
                                                    + '\n ' + e.getMessage());
            

            try {
                List<EmailMessage> emailAuxiliarList = new List<EmailMessage>([SELECT Id, HtmlBody, TextBody FROM EmailMessage WHERE Id = :em.Id LIMIT 1]);
                if (!emailAuxiliarList.isEmpty()) {
                    String errorText = 'El mensaje original podría contener adjuntos que no se han podido subir a este registro, por favor revise dicho correo en el buzón de entrada \n ----------------- \n';
                    EmailMessage emAux = emailAuxiliarList[0];
                    String descripcionHtml = errorText + emAux.HtmlBody;
                    String descripcionPlain = errorText + emAux.TextBody;
                    emAux.HtmlBody = (!String.isBlank(descripcionHtml) && descripcionHtml.length() > 32000 ? descripcionHtml.substring(0, 32000) : descripcionHtml);
                    emAux.TextBody = (!String.isBlank(descripcionPlain) && descripcionPlain.length() > 32000 ? descripcionPlain.substring(0, 32000) : descripcionPlain);
                    update emAux;
                }
            } catch (Exception ex2) {
                System.debug(LoggingLevel.ERROR, 'Error updating email with attached files notification error: ' + ex2.getMessage());
            }
        }
    }
}