/**
 * Created by omontero on 30/04/2021.
 */

@IsTest
public with sharing class EntitlementManagementUtilTest {
    static Map<String, Profile> mProfiles = TestUtil.initializeProfilesMap();

    @TestSetup
    static void setup(){
        Account acc = (Account) TestFactory.createSObject(new Account(), true);
        List<SLAsByService__mdt> lSlAsByServices = [SELECT Id, Service__c, EntitlementName__c, BussinessHoursName__c FROM SLAsByService__mdt];
        Map<String, SLAsByService__mdt> mSlAsByEntitlementName = (Map<String, SLAsByService__mdt>) CollectionUtils.stringMapFromCollectionByKey('EntitlementName__c', lSlAsByServices);
        List<SlaProcess> lSLAs = [SELECT Id,Name FROM SlaProcess WHERE Name IN :mSlAsByEntitlementName.keySet()];
        List<Entitlement> lEntitlementsToInsert = new List<Entitlement>();
        for (SlaProcess sla : lSLAs){
            lEntitlementsToInsert.add((Entitlement) TestFactory.createSObject(new Entitlement(AccountId = acc.Id, Name = sla.Name, SlaProcessId = sla.Id , StartDate = System.now().addDays(-1).date()), false));
        }

        insert lEntitlementsToInsert;
    }
    @IsTest
    static void changeStatus(){

        User adminUser = ABA_TEST_createDataTest.createUser('userAdmin', 'test', 'userAdmin.test@invalid.com', mProfiles.get('System Administrator'));
        adminUser.FederationIdentifier = 'XXXXX';
        adminUser.LocaleSidKey = 'en_US';
        adminUser.LanguageLocaleKey = 'en_US';

        insert adminUser;

        List<Case> lCasesToInsert = new List<Case>();

        Case c1 = new Case(
                RecordTypeId = CaseUtil.getRecordTypeByDeveloperName('CCS_Operational').Id,
                Subject = 'Case Soporte',
                ABA_LIS_Servicio_del_Ticket__c = 'CCS_SegurosGenerales',
//                ABA_PR_LIS_Origen_AD__c = 'Email',
                CCS_channel__c = 'Email',
                Status = 'Nuevo'
        );
        lCasesToInsert.add(c1);
        Case c2 = new Case(
                RecordTypeId = CaseUtil.getRecordTypeByDeveloperName('CCS_Sales').Id,
                Subject = 'Case Comercial',
                ABA_LIS_Servicio_del_Ticket__c = 'CCS_AVidaYPensiones',
//                ABA_PR_LIS_Origen_AD__c = 'Email',
                CCS_channel__c = 'Email',
                Status = 'Escalado',
                ABA_LIS_Motivo_del_Estado__c = 'Escalado Interno'
        );
        lCasesToInsert.add(c2);


            insert lCasesToInsert;


//        User adminUser = [SELECT Id FROM User WHERE Email = 'userAdmin.test@invalid.com' LIMIT 1];
        c1 = [SELECT Id, EntitlementId FROM Case WHERE Id = :lCasesToInsert[0].Id LIMIT 1];
        c2 = [SELECT Id, EntitlementId FROM Case WHERE Id = :lCasesToInsert[1].Id LIMIT 1];

        System.runAs(adminUser){
            //Test1
            Test.startTest();
            c1.Status = 'En curso';
            update c1;
            c2.Status = 'En curso';
            c2.ABA_LIS_Motivo_del_Estado__c = '';
            update c2;
            Test.stopTest();

            List<CaseMilestone> lCMs = new List<CaseMilestone>([SELECT Id,IsCompleted FROM CaseMilestone WHERE CaseId = :c1.Id]);
            List<CaseMilestone> lCMsCompleted = new List<CaseMilestone>();
            List<CaseMilestone> lCMsNotCompleted = new List<CaseMilestone>();

            for (CaseMilestone cm : lCMs){
                if (cm.IsCompleted){
                    lCMsCompleted.add(cm);
                } else {
                    lCMsNotCompleted.add(cm);
                }
            }

            System.assertEquals(3, lCMs.size());
            System.assertEquals(2, lCMsNotCompleted.size());
            System.assertEquals(1, lCMsCompleted.size());


            lCMs = new List<CaseMilestone>([SELECT Id,MilestoneType.Name, IsCompleted FROM CaseMilestone WHERE CaseId = :c2.Id]);
            lCMsCompleted = new List<CaseMilestone>();
            lCMsNotCompleted = new List<CaseMilestone>();
            for (CaseMilestone cm : lCMs){
                if (cm.IsCompleted){
                    lCMsCompleted.add(cm);
                } else {
                    lCMsNotCompleted.add(cm);
                }
            }

            System.assertEquals(3, lCMs.size());
            System.assertEquals(2, lCMsNotCompleted.size());
            System.assertEquals(1, lCMsCompleted.size());
        }
    }

    @IsTest
    static void test_milestonePrimerContacto(){
        String emAddress = 'test@invalid.com';
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<SLAsByService__mdt> lSlAsByServices = [SELECT Id, Service__c, EntitlementName__c, BussinessHoursName__c FROM SLAsByService__mdt];
        Map<String, SLAsByService__mdt> mSlAsByService = (Map<String, SLAsByService__mdt>) CollectionUtils.stringMapFromCollectionByKey('Service__c', lSlAsByServices);
        List<SlaProcess> lSLAs = [SELECT Id FROM SlaProcess WHERE Name = :mSlAsByService.get('Ticket Abanca Digital').EntitlementName__c AND IsActive = TRUE];
        TestFactory.createSObject(new Entitlement(AccountId = acc.Id, Name = mSlAsByService.get('Ticket Abanca Digital').EntitlementName__c, SlaProcessId = lSLAs[0].Id , StartDate = System.now().addDays(-1).date()), true);


        Case c = (Case) TestFactory.createSObject(new Case(SuppliedEmail = emAddress,ABA_LIS_Servicio_del_Ticket__c = 'Ticket Abanca Digital', CCS_channel__c = 'Email', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Ticket_Abanca_Digital').getRecordTypeId()), true);
        Test.startTest();
        EmailMessage em = (EmailMessage) TestFactory.createSObject(new EmailMessage(Status = '3', Incoming = false, ParentId = c.Id, ToAddress = emAddress, FromAddress = 'test@abanca.com'), true);
        Test.stopTest();
        List<CaseMilestone> lMilestones = [SELECT Id, MilestoneType.Name, CompletionDate FROM CaseMilestone WHERE CaseId = :c.Id];
        Boolean milestoneFoundClosed = false;
        for (CaseMilestone cm : lMilestones){
            if (cm.MilestoneType.Name.toUpperCase() == 'Primera respuesta contacto escrito'.toUpperCase() && cm.CompletionDate != null) {
                milestoneFoundClosed = true;
            }
        }
        System.assertEquals(true, milestoneFoundClosed);
    }

    @IsTest
    static void test_milestoneStatus(){
        String emAddress = 'test@invalid.com';
        Case c = (Case) TestFactory.createSObject(new Case(Status = 'Nuevo', SuppliedEmail = emAddress,ABA_LIS_Servicio_del_Ticket__c = 'Ticket Abanca Digital', CCS_channel__c = 'Email', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Ticket_Abanca_Digital').getRecordTypeId()), true);
        Test.startTest();
        c.Status = 'En Curso';
        update c;
        Test.stopTest();
        List<CaseMilestone> lMilestones = [SELECT Id, MilestoneType.Name, CompletionDate FROM CaseMilestone WHERE CaseId = :c.Id];
        Boolean milestoneFoundClosed = false;
        Boolean milestoneFoundOpen = false;
        for (CaseMilestone cm : lMilestones){

            if (cm.MilestoneType.Name.toUpperCase() == 'Tiempo en Nuevo'.toUpperCase() && cm.CompletionDate != null) {
                milestoneFoundClosed = true;
            }
            if (cm.MilestoneType.Name.toUpperCase() == 'Tiempo en Curso'.toUpperCase() && cm.CompletionDate == null) {
                milestoneFoundOpen = true;
            }
        }
        System.assertEquals(true, milestoneFoundClosed);
        System.assertEquals(true, milestoneFoundOpen);
    }

}