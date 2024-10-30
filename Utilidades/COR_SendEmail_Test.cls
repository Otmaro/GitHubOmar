@IsTest
private class COR_SendEmail_Test {
    @IsTest
    static void test_SendExceptionEmail() {
        User u = [SELECT Id, Name, Username FROM User WHERE Username LIKE 'automatedcase%' LIMIT 1];
        Test.startTest();
        System.runAs(u) {
            COR_SendEmail.sendExceptionEmail('testsubject', 'testbody');
        }
        Test.stopTest();
    }
}