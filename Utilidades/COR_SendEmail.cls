public with sharing class COR_SendEmail {

    private static OrgWideEmailAddress defaultNoReplyOWA;
    private static List<String> lWarningAddresses;
    public static Messaging.SingleEmailMessage createEmail(List<String> addresses, String OWAId, String subject, String plainBody){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(addresses);
        mail.setOrgWideEmailAddressId(OWAId);
        mail.setSubject(!String.isBlank(subject) && subject.length() > 255 ? subject.substring(0, 255): subject);
        mail.setPlainTextBody(!String.isBlank(plainBody) && plainBody.length() >3000 ? plainBody.substring(0,3000) : plainBody);
        return mail;
    }

    public static Messaging.SingleEmailMessage createEmail(List<String> addresses, String OWAId, String subject, String plainBody, Boolean isActivity, String replyTo) {
        Messaging.SingleEmailMessage mail = createEmail(addresses, OWAId, subject, plainBody);
        mail.setSaveAsActivity(isActivity);
        mail.setReplyTo(replyTo);
        return mail;
    }

    public static OrgWideEmailAddress getDefaultNoReplyAddress() {
        if (defaultNoReplyOWA == null) {
            List<OrgWideEmailAddress> lOWAs = new List<OrgWideEmailAddress>([SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE Purpose = 'DefaultNoreply' AND IsVerified = TRUE LIMIT 1]);
            if (lOWAs != null && !lOWAs.isEmpty()) {
                defaultNoReplyOWA = lOWAs[0];
            }
        }
        return defaultNoReplyOWA;
    }

    public static List<String> getWarningEmailAddressList() {
        if (lWarningAddresses == null) {
            COR_Settings__mdt se = COR_Settings__mdt.getInstance('WarningEmailAddressList');
            if (se?.Value__c != null) {
                lWarningAddresses = se.Value__c.split(';');
            }
        }
        return lWarningAddresses;
    }

    public static void sendExceptionEmail(String emailSubject, String emailBody) {
        List<Messaging.SingleEmailMessage> lEmailsToSend = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress dnr = getDefaultNoReplyAddress();
        List<String> lAddresses = getWarningEmailAddressList();

        if (lAddresses != null && !lAddresses.isEmpty() && dnr != null) {

            lEmailsToSend.add(createEmail(
                    lAddresses,
                    dnr.Id,
                    emailSubject,
                    emailBody
            ));

            if (lEmailsToSend != null && !lEmailsToSend.isEmpty()) {
                try {
                    Messaging.sendEmail(lEmailsToSend);
                } catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR, 'Error sending mails: ' + ex.getMessage());
                }
            }
        }
    }
}