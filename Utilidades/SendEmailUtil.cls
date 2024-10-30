public with sharing class SendEmailUtil {

    private static OrgWideEmailAddress defaultNoReplyOWA;

    /**
     * @param addresses
     * @param bccAddresses
     * @param subject
     * @param htmlBody
     * @param useDefaultNoReplyAddress If true, uses default no reply address, if false, uses user email.
     *
     * @return
     */
    public static Messaging.SingleEmailMessage composeEmail(List<String> addresses, List<String> ccAddresses, List<String> bccAddresses, String subject, String htmlBody, Boolean useDefaultNoReplyAddress) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (addresses != null && !addresses.isEmpty()) {
            mail.setToAddresses(addresses);
        }
        if (ccAddresses != null && !ccAddresses.isEmpty()) {
            mail.setCcAddresses(ccAddresses);
        }
        if (bccAddresses != null && !bccAddresses.isEmpty()) {
            mail.setCcAddresses(bccAddresses);
        }
        if (useDefaultNoReplyAddress && getDefaultNoReplyAddress() != null) {
            mail.setOrgWideEmailAddressId(getDefaultNoReplyAddress().Id);
        }
        mail.setSubject(!String.isBlank(subject) && subject.length() > 255 ? subject.substring(0, 255) : subject);
        mail.setHtmlBody(!String.isBlank(htmlBody) && htmlBody.length() > 3000 ? htmlBody.substring(0, 3000) : htmlBody);
        return mail;
    }

    public static void sendSingleEmail(List<String> addresses, List<String> ccAddresses, List<String> bccAddresses, String subject, String htmlBody, Boolean useDefaultNoReplyAddress) {
            sendSingleEmail(composeEmail(addresses, ccAddresses, bccAddresses, subject, htmlBody, useDefaultNoReplyAddress));
    }

    public static void sendSingleEmail(Messaging.SingleEmailMessage em) {
        sendEmailList(new List<Messaging.SingleEmailMessage>{
                em
        });
    }

    public static void sendEmailList(List<Messaging.SingleEmailMessage> lEmailMessages) {
        if (lEmailMessages != null && !lEmailMessages.isEmpty()) {
            try {
                Messaging.sendEmail(lEmailMessages);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error sending mails: ' + ex.getMessage());
            }
        } else {

        }
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

}