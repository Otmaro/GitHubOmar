@IsTest
public with sharing class EmailMessageService_Test {

    @TestSetup
    static void setup() {
        List<sObject> ls = Test.loadData(Asignacion_de_colas__c.sObjectType, 'Test_AsignacionesDeColas');
    }

    @IsTest
    static void test_Comercios_Pending() {
        Group waitingQueue = QueueUtil.getWaitingQueue();
        Case c = (Case) TestFactory.createSObject(new Case(
                RecordTypeId = CaseUtil.getRecordTypeByDeveloperName('Ticket_Comercios').Id,
                ABA_LIS_Servicio_del_Ticket__c = 'Ticket Comercios',
                Status = 'Pendiente',
                ABA_LIS_Motivo_del_Estado__c = 'Pendiente Oficina',
                OwnerId = waitingQueue.Id
        ), true);
        c = getCase(c.Id);
        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('Pendiente', c.Status);
        Assert.areEqual('Pendiente Oficina', c.ABA_LIS_Motivo_del_Estado__c);
        Assert.areEqual(waitingQueue.Id, c.OwnerId);

        Group defaultqueue = QueueUtil.getDefaultQueueForNewResponse(c);
        Test.startTest();
        EmailMessage em = (EmailMessage) TestFactory.createSObject(new EmailMessage(
                ParentId = c.Id,
                Incoming = true,
                COR_EmailServiceIncoming__c = false
        ), true);
        Test.stopTest();

        c = getCase(c.Id);
        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('Nuevo', c.Status);
        Assert.areEqual('Respuesta', c.ABA_LIS_Subestado__c);
        Assert.isNull(c.ABA_LIS_Motivo_del_Estado__c);
        Assert.isNull(c.ABA_LIS_Situacion__c);
        Assert.areEqual(defaultqueue.Id, c.OwnerId);
    }
    @IsTest
    static void test_Comercios_InProgress() {
        User u = (User) TestFactory.createSObject(new User(ProfileId = UserInfo.getProfileId()), true);
        Case c = (Case) TestFactory.createSObject(new Case(
                RecordTypeId = CaseUtil.getRecordTypeByDeveloperName('Ticket_Comercios').Id,
                ABA_LIS_Servicio_del_Ticket__c = 'Ticket Comercios',
                Status = 'Nuevo',
                OwnerId = u.Id
        ), true);
        c.Status = 'En Curso';
        update c;
        c.OwnerId = u.Id;
        update c;
        c = getCase(c.Id);
        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('En Curso', c.Status);
        Assert.areEqual(u.Id, c.OwnerId);
        Assert.areEqual('User', c.OwnerId.getSobjectType().getDescribe().getName());

        Test.startTest();
        EmailMessage em = (EmailMessage) TestFactory.createSObject(new EmailMessage(
                ParentId = c.Id,
                Incoming = true,
                COR_EmailServiceIncoming__c = false
        ), true);
        Test.stopTest();

        c = getCase(c.Id);

        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('En Curso', c.Status);
        Assert.areEqual(u.Id, c.OwnerId);

    }


    @IsTest
    static void test_Comercios_Rescheduled() {
        Group waitingQueue = QueueUtil.getWaitingQueue();
        Case c = (Case) TestFactory.createSObject(new Case(
                RecordTypeId = CaseUtil.getRecordTypeByDeveloperName('Ticket_Comercios').Id,
                ABA_LIS_Servicio_del_Ticket__c = 'Ticket Comercios',
                ABA_LIS_Cola_reprogramacion__c = 'Comercios',
                ABA_LIS_Motivo_de_reprogramacion__c = 'Aplazado Oficina',
                ABA_DT_Fecha_reprogramacion__c = System.now().addDays(1),
                Status = 'Pendiente',
                ABA_LIS_Motivo_del_Estado__c = 'Pendiente Oficina',
                OwnerId = waitingQueue.Id
        ), true);
        c = getCase(c.Id);
        Group defaultqueue = QueueUtil.getDefaultQueueForNewResponse(c);
        c.Last_queue_id__c = defaultqueue.Id;
        update c;
        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('Pendiente', c.Status);
        Assert.areEqual('Pendiente Oficina', c.ABA_LIS_Motivo_del_Estado__c);
        Assert.areEqual(waitingQueue.Id, c.OwnerId);


        Test.startTest();
        EmailMessage em = (EmailMessage) TestFactory.createSObject(new EmailMessage(
                ParentId = c.Id,
                Incoming = true,
                COR_EmailServiceIncoming__c = false
        ), true);
        Test.stopTest();

        c = getCase(c.Id);
        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('Nuevo', c.Status);
        Assert.areEqual('Respuesta', c.ABA_LIS_Subestado__c);
        Assert.isNull(c.ABA_LIS_Motivo_del_Estado__c);
        Assert.isNull(c.ABA_DT_Fecha_reprogramacion__c);
        Assert.isNull(c.ABA_LIS_Motivo_de_reprogramacion__c);
        Assert.isNull(c.ABA_LIS_Situacion__c);
        Assert.areEqual(defaultqueue.Id, c.OwnerId);

        List<CaseComment> lCaseComments = [SELECT Id FROM CaseComment WHERE ParentId = :c.Id];
        Assert.isTrue((!lCaseComments.isEmpty()));
    }

    @IsTest
    static void test_Comercios_Closed() {
        Case c = (Case) TestFactory.createSObject(new Case(
                RecordTypeId = CaseUtil.getRecordTypeByDeveloperName('Ticket_Comercios').Id,
                ABA_LIS_Servicio_del_Ticket__c = 'Ticket Comercios',
                Origin = 'Buzón Epasarela',
                Status = 'Nuevo'
        ), true);
        c.Status = 'Cerrado';
        c.ABA_LIS_Motivo_del_Estado__c = 'Gestionado OK';
        CaseTipificationUtil.setValidTipificationForCase(c);
        update c;
        c = getCase(c.Id);
        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('Cerrado', c.Status);
        Assert.areEqual('Gestionado OK', c.ABA_LIS_Motivo_del_Estado__c);
        Assert.areEqual('Buzón Epasarela', c.Origin);


        Group defaultqueue = QueueUtil.getDefaultQueueForNewResponse(c);
        Test.startTest();
        EmailMessage em = (EmailMessage) TestFactory.createSObject(new EmailMessage(
                ParentId = c.Id,
                Incoming = true,
                COR_EmailServiceIncoming__c = false
        ), true);
        Test.stopTest();

        c = getCase(c.Id);
        Assert.areEqual('Ticket Comercios', c.ABA_LIS_Servicio_del_Ticket__c);
        Assert.areEqual('Nuevo', c.Status);
        Assert.areEqual('Reaperturado', c.ABA_LIS_Subestado__c);
        Assert.isTrue(c.COR_Reopened__c);
        Assert.isNull(c.ABA_LIS_Motivo_del_Estado__c);
        Assert.isNull(c.ABA_LIS_Situacion__c);
        Assert.areEqual(defaultqueue.Id, c.OwnerId);
    }

    private static Case getCase(String caseId) {
        return [SELECT Id, OwnerId, Status, ABA_LIS_Servicio_del_Ticket__c, ABA_LIS_Motivo_del_Estado__c,ABA_LIS_Situacion__c, ABA_LIS_Subestado__c, ABA_LIS_Cola_reprogramacion__c, ABA_LIS_Motivo_de_reprogramacion__c, ABA_DT_Fecha_reprogramacion__c, ABA_BOL_Reprogramado__c, COR_Reopened__c, Origin, ABA_LIS_Origen_del_Ticket__c  FROM Case WHERE Id = :caseId LIMIT 1];
    }
}