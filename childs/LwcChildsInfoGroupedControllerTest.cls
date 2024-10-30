
@IsTest
private class LwcChildsInfoGroupedControllerTest {

    @TestSetup
    static void setup() {
        Case c_ot = (Case) TestFactory.createSObject(new Case(RecordTypeId = SegEmpUtil.NUEVONEGOCIO_ORDENDETRABAJO_RT_ID), true);
        Case c_gest = (Case) TestFactory.createSObject(new Case(RecordTypeId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID, ParentId = c_ot.Id), true);
//        Case c_gest = [ SELECT ID FROM CASE WHERE RecordTypeId = :CaseService.NUEVONEGOCIO_GESTION_RT_ID LIMIT 1];
        Case c_sol_1 = (Case) TestFactory.createSObject(new Case(RecordTypeId = SegEmpUtil.NUEVONEGOCIO_SOLICITUD_RT_ID, ParentId = c_gest.Id), false);
        Case c_sol_2 = (Case) TestFactory.createSObject(new Case(RecordTypeId = SegEmpUtil.NUEVONEGOCIO_SOLICITUD_RT_ID, ParentId = c_gest.Id), false);
        insert new List<Case> {c_sol_1, c_sol_2};

        EmailMessage em_1 = (EmailMessage) TestFactory.createSObject(new EmailMessage(ParentId = c_sol_1.Id), false);
        EmailMessage em_2 = (EmailMessage) TestFactory.createSObject(new EmailMessage(ParentId = c_sol_1.Id), false);
        EmailMessage em_3 = (EmailMessage) TestFactory.createSObject(new EmailMessage(ParentId = c_sol_2.Id), false);
        insert new List<EmailMessage> {em_1, em_2, em_3};

        CaseComment cc_1 = (CaseComment) TestFactory.createSObject(new CaseComment(ParentId = c_sol_1.Id), false);
        CaseComment cc_2 = (CaseComment) TestFactory.createSObject(new CaseComment(ParentId = c_sol_1.Id), false);
        CaseComment cc_3 = (CaseComment) TestFactory.createSObject(new CaseComment(ParentId = c_sol_2.Id), false);
        insert new List<CaseComment> {cc_1, cc_2, cc_3};


        FeedItem fi_1 = (FeedItem) TestFactory.createSObject(new FeedItem(Type = 'TextPost', ParentId = c_sol_1.Id, Body = 'Test'), false);
        FeedItem fi_2 = (FeedItem) TestFactory.createSObject(new FeedItem(Type = 'TextPost', ParentId = c_sol_1.Id, Body = 'Test'), false);
        FeedItem fi_3 = (FeedItem) TestFactory.createSObject(new FeedItem(Type = 'TextPost', ParentId = c_sol_2.Id, Body = 'Test'), false);
        insert  new List<FeedItem> {fi_1, fi_2, fi_3};

        FeedComment fc_1 = (FeedComment) TestFactory.createSObject(new FeedComment(FeedItemId = fi_1.Id, CommentBody = 'Test'), false);
        FeedComment fc_2 = (FeedComment) TestFactory.createSObject(new FeedComment(FeedItemId = fi_1.Id, CommentBody = 'Test'), false);
        insert new List<FeedComment> {fc_1, fc_2};

        ContentVersion cv1 = (ContentVersion) TestFactory.createSObject(new ContentVersion(Title = 'test', PathOnClient='test', VersionData = Blob.valueOf('test'), FirstPublishLocationId = c_sol_1.Id), false);
        ContentVersion cv2 = (ContentVersion) TestFactory.createSObject(new ContentVersion(Title = 'test', PathOnClient='test', VersionData = Blob.valueOf('test'), FirstPublishLocationId = c_sol_1.Id), false);
        ContentVersion cv3 = (ContentVersion) TestFactory.createSObject(new ContentVersion(Title = 'test', PathOnClient='test', VersionData = Blob.valueOf('test'), FirstPublishLocationId = c_sol_2.Id), false);
        insert new List<ContentVersion> {cv1, cv2, cv3};


    }

    @IsTest
    static void test() {
        Case c = [SELECT Id FROM Case WHERE RecordTypeId = :SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID LIMIT 1];
        List<Case> lCases = [SELECT Id, CaseNumber, Parent.CaseNumber, RecordType.DeveloperName FROM Case ORDER BY CreatedDate ASC];
        for (case cAux : lCases) {
            System.debug('** '+cAux.CaseNumber + ' - ' + cAux.RecordType.DeveloperName + ' - ' +cAux.Parent.CaseNumber);
        }
        Test.startTest();
        List<LwcChildsInfoGroupedController.DataPerChild> result = LwcChildsInfoGroupedController.getInitData(c.Id);
        Test.stopTest();
        Assert.areEqual(2, result.size());
        Boolean feedCommentsReceived = false;
        for (LwcChildsInfoGroupedController.DataPerChild dpc : result) {
            Assert.areNotEqual(null, dpc.childCase);
            Assert.areEqual(true, dpc.lCaseComments.size() > 0);
            Assert.areEqual(true, dpc.lEmailMessages.size() > 0);
            Assert.areEqual(true, dpc.lFeedItems.size() > 0);
            Assert.areEqual(true, dpc.lFiles.size() > 0);
            for (LwcChildsInfoGroupedController.DataPerFeedItem dpfi : dpc.lFeedItems) {
                Assert.areNotEqual(null, dpfi.Id);
                Assert.areNotEqual(null, dpfi);
                if (dpfi.lFeedComments.size() > 0) {
                    feedCommentsReceived = true;
                }
            }
        }
        Assert.areEqual(true, feedCommentsReceived);
    }
}