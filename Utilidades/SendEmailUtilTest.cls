@IsTest
private class SendEmailUtilTest {

    @IsTest
    static void test_SendSingleEmail_1() {
        List<String> lAddresses = new List<String>{'test.to@invalid.com', 'test.to2@invalid.com'};
        List<String> lCCAddresses = new List<String>{'test.cc@invalid.com'};
        List<String> lBCCAddresses = new List<String>{'test.cc@invalid.com'};
        String subject = 'test subject';
        String body = 'test body';
        Test.startTest();
        SendEmailUtil.sendSingleEmail(lAddresses, lCCAddresses, lBCCAddresses, subject, body, true);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        Assert.areEqual(1, invocations, 'An email should be sent');
        EmailMessage em = [SELECT Id, Subject, Incoming FROM EmailMessage LIMIT 1];
        Assert.areEqual(false, em.Incoming);
        Assert.areEqual(subject, em.Subject);
    }

    @IsTest
    static void test_SendSingleEmail_2() {
        List<String> lAddresses = new List<String>{'test.to@invalid.com', 'test.to2@invalid.com'};
        List<String> lCCAddresses = new List<String>{'test.cc@invalid.com'};
        List<String> lBCCAddresses = new List<String>{'test.cc@invalid.com'};
        String subject = 'test subject';
        String body = 'test body';
        Test.startTest();
        SendEmailUtil.sendSingleEmail(SendEmailUtil.composeEmail(lAddresses, lCCAddresses, lBCCAddresses, subject, body, true));
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        Assert.areEqual(1, invocations, 'An email should be sent');
        EmailMessage em = [SELECT Id, Subject, Incoming FROM EmailMessage LIMIT 1];
        Assert.areEqual(false, em.Incoming);
        Assert.areEqual(subject, em.Subject);
    }

    @IsTest
    static void test_SendEmailList_2() {
        List<String> lAddresses = new List<String>{'test.to@invalid.com', 'test.to2@invalid.com'};
        List<String> lCCAddresses = new List<String>{'test.cc@invalid.com'};
        List<String> lBCCAddresses = new List<String>{'test.cc@invalid.com'};
        String subject = 'test subject';
        String body = 'test body';
        List<Messaging.SingleEmailMessage> lEmailMessages = new List<Messaging.SingleEmailMessage>{
                SendEmailUtil.composeEmail(lAddresses, lCCAddresses, lBCCAddresses, subject, body, true),
                SendEmailUtil.composeEmail(lAddresses, lCCAddresses, lBCCAddresses, subject, body, true)
        };
        Test.startTest();
        SendEmailUtil.sendEmailList(lEmailMessages);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        Assert.areEqual(1, invocations);
        List<EmailMessage> lEmailMessages2 = [SELECT Id from EmailMessage];
        Assert.areEqual(2, lEmailMessages2.size());
    }



}