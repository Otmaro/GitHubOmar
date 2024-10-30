

@IsTest
private class LwcSegEmpWorkPannelControllerTest {

    private static final String GEE_USERNAME = 'gee@invalid.com';
    private static final String GEE_PROFILENAME = 'Comercial Seguros ABANCA';
    private static final String BO_USERNAME = 'bo@invalid.com';
    private static final String BO_PROFILENAME = 'BackOffice Seguros ABANCA';


    @TestSetup
    static void setup() {
        User gee_User = (User) TestFactory.createSObject(new User(Username = GEE_USERNAME), false);
        User bo_User = (User) TestFactory.createSObject(new User(Username = BO_USERNAME), false);
        List<Profile> lProfiles = [SELECT Id, Name FROM Profile WHERE Name IN (:BO_PROFILENAME, :GEE_PROFILENAME)];
        Assert.areEqual(2, lProfiles.size());
        for (Profile p : lProfiles) {
            if (p.Name == BO_PROFILENAME) {
                bo_User.ProfileId = p.Id;
            } else if (p.Name == GEE_PROFILENAME) {
                gee_User.ProfileId = p.Id;
            }
        }
        insert new List<User>{
                gee_User, bo_User
        };
        Account acc = (Account) TestFactory.createSObject(new Account(), false);
        Account aseguradora = (Account) TestFactory.createSObject(new Account(ABA_BOL_Aseguradora__c = true), false);
        insert new List<Account>{
                acc, aseguradora
        };
        Product2 p = (Product2) TestFactory.createSObject(new Product2(ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.ProductSegEmpDefaults', true);
        p = [SELECT Id, ABA_PIC_Ramo__c, Name FROM Product2 WHERE Id = :p.Id LIMIT 1];
        Opportunity opp = (Opportunity) TestFactory.createSObject(new Opportunity(AccountId = acc.Id, OwnerId = gee_User.Id, ABA_LIS_Ramo__c = p.ABA_PIC_Ramo__c), 'TestFactoryDefaults.OpportunityNuevoNegocioDefaults', true);
        Case orden = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, AccountId = acc.Id, OwnerId = bo_User.Id, ABA_LIS_Ramo__c = p.ABA_PIC_Ramo__c), 'TestFactoryDefaults.CaseOrdenNuevoNegocioDefaults', true);
        Case gestion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = orden.Id, AccountId = acc.Id, OwnerId = bo_User.Id, ABA_LIS_Ramo__c = p.ABA_PIC_Ramo__c), 'TestFactoryDefaults.CaseGestionNuevoNegocioDefaults', true);
    }

    @IsTest
    static void test_getDataTree() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);

        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false, Accepted__c = true), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);
        ABA_Poliza__c poliza = (ABA_Poliza__c) TestFactory.createSObject(new ABA_Poliza__c( Name = 'Test poliza', RecordTypeId = SegEmpUtil.POLIZA_SEGUROS_RT_ID, OpportunityId__c = dataTree.opp.Id, ABA_Cliente__c = dataTree.gestion.AccountId), true);

        Test.startTest();
        System.runAs(bo_User) {
            dataTree = LwcSegEmpWorkPannelController.getDataTree(opp.Id);
        }
        Test.stopTest();

        Assert.areNotEqual(null, dataTree.opp);
        Assert.areNotEqual(null, dataTree.orden);
        Assert.areNotEqual(null, dataTree.gestion);
        Assert.areNotEqual(null, dataTree.formalizacion);
        Assert.areNotEqual(null, dataTree.lSolicitudes);
        Assert.areEqual(1, dataTree.lSolicitudes.size());
        Assert.areNotEqual(null, dataTree.mPresupuestosByCase);
        Assert.areEqual(1, dataTree.mPresupuestosByCase.keySet().size());
        Assert.areNotEqual(null, dataTree.quote);
        Assert.areNotEqual(null, dataTree.poliza);

    }

    @IsTest
    static void test_assignCasesToMe() {
        User bo_User = getBoUser();
        User gee_User = getGeeUser();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = (Opportunity) TestFactory.createSObject(new Opportunity(AccountId = acc.Id, OwnerId = gee_User.Id, Name = 'test_assignCasesToMe'), 'TestFactoryDefaults.OpportunityNuevoNegocioDefaults', true);
        Case orden = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, AccountId = acc.Id), 'TestFactoryDefaults.CaseOrdenNuevoNegocioDefaults', true);
        Case gestion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = orden.Id, AccountId = acc.Id), 'TestFactoryDefaults.CaseGestionNuevoNegocioDefaults', true);

        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areNotEqual(bo_User.Id, dataTree.orden.OwnerId);
        Assert.areNotEqual(bo_User.Id, dataTree.gestion.OwnerId);
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.assignCasesToMe(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areNotEqual(bo_User.Id, dataTree.opp.OwnerId);
        Assert.areEqual(bo_User.Id, dataTree.orden.OwnerId);
        Assert.areEqual(bo_User.Id, dataTree.gestion.OwnerId);
    }

    @IsTest
    static void test_setAsVisto() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsVisto(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_VISTO, dataTree.orden.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_VISTO, dataTree.gestion.Status);
    }

    @IsTest
    static void test_setAsEstudio() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsEstudio(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_ESTUDIO, dataTree.orden.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_ESTUDIO, dataTree.gestion.Status);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO));
    }

    @IsTest
    static void test_finishEstudio() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.finishEstudio(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areEqual(SegEmpUtil.OPP_STATUS_COTIZACION, dataTree.opp.StageName);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_COTIZACION, dataTree.orden.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_SOLICITUD_MERCADO, dataTree.gestion.Status);
    }

    @IsTest
    static void test_setAsPdtGEE() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        System.debug(solicitud1);
        System.debug(solicitud1.Id);
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsPdtGEE(opp.Id, solicitud1.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        System.debug(dataTree.lSolicitudes[0]);
        System.debug(dataTree.lSolicitudes[0].Id);
        System.debug(dataTree.lSolicitudes[0].ProcessStatus__c);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GEE));

    }

    @IsTest
    static void test_removePdtGEE() {
        User gee_User = getGeeUser();
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.setAsPdtGEE(opp.Id, solicitud1.Id);

        Test.startTest();
        System.runAs(gee_User) {
            LwcSegEmpWorkPannelController.removePdtGEE(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GEE));

    }


    @IsTest
    static void test_setAsPdtCliente() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        System.debug(solicitud1);
        System.debug(solicitud1.Id);
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsPdtCliente(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        System.debug(dataTree.lSolicitudes[0]);
        System.debug(dataTree.lSolicitudes[0].Id);
        System.debug(dataTree.lSolicitudes[0].ProcessStatus__c);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE));

    }

    @IsTest
    static void test_removePdtCliente() {
        User gee_User = getGeeUser();
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.setAsPdtCliente(opp.Id);

        Test.startTest();
        System.runAs(gee_User) {
            LwcSegEmpWorkPannelController.removePdtCliente(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE));
    }

    @IsTest
    static void test_ordenRevised_isOk() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.setAsPdtGEE(opp.Id, solicitud1.Id);
        LwcSegEmpWorkPannelController.removePdtGEE(opp.Id);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.ordenRevised(opp.Id, true);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT));

    }

    @IsTest
    static void test_ordenRevised_isNotOk() {
        User bo_user = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.setAsPdtGEE(opp.Id, solicitud1.Id);
        LwcSegEmpWorkPannelController.removePdtGEE(opp.Id);

        Test.startTest();
        System.runAs(bo_user) {
            LwcSegEmpWorkPannelController.ordenRevised(opp.Id, false);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GEE));

    }

    @IsTest
    static void test_startWork() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ProcessStatus__c = SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
        update dataTree.gestion;
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.startWork(opp.Id, solicitud1.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_ENCURSO));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT));

    }

    @IsTest
    static void test_stopWork() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.startWork(opp.Id, solicitud1.Id);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.stopWork(opp.Id, solicitud1.Id, true);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_ENCURSO));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT));

    }

    @IsTest
    static void test_setAsPdtAseguradora() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsPdtAseguradora(opp.Id, solicitud1.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);


        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENGESTIONCONASEGURADORA, dataTree.lSolicitudes[0].Status);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA));

    }

    @IsTest
    static void test_removePdtAseguradora() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.setAsPdtAseguradora(opp.Id, solicitud1.Id);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.removePdtAseguradora(opp.Id, solicitud1.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);


        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA));

    }

    @IsTest
    static void test_infoAseguradoraRevised() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ProcessStatus__c = SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.setAsPdtAseguradora(opp.Id, solicitud1.Id);

        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA);
        update dataTree.gestion;

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.infoAseguradoraRevised(opp.Id, solicitud1.Id, true, true);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);


        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA));
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA));

    }

    @IsTest
    static void test_proposalRevised() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ProcessStatus__c = SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        LwcSegEmpWorkPannelController.setAsPdtAseguradora(opp.Id, solicitud1.Id);

        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA);
        update dataTree.gestion;

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.proposalRevised(opp.Id, solicitud1.Id, true);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);


        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA));
        Assert.areEqual(SegEmpUtil.CASE_PROPOSALSTATUS_VALIDA, dataTree.lSolicitudes[0].ProposalStatus__c);
        Assert.areEqual(false, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA));

    }

    @IsTest
    static void test_generateQuote() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);

        String json = '{"fechaEfecto":"' + System.today().addDays(1) + '","fechaVencimiento":"' + System.today().addDays(1) + '","tasa":"1","impuesto":"1","primaNeta":"1","importePrimaTotal":"1","comentario":"test comment"}';

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.generateQuote(opp.Id, solicitud1.Id, json);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(SegEmpUtil.CASE_STATUS_GENERACIONPRESUPUESTO, dataTree.gestion.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_GENERACIONPRESUPUESTO, dataTree.lSolicitudes[0].Status);
        Assert.areEqual(SegEmpUtil.QUOTE_STATUS_ENGENERACION, dataTree.quote.Status);
        Assert.areEqual(1, dataTree.mPresupuestosByCase.get(dataTree.lSolicitudes[0].Id).size());

    }

    @IsTest
    static void test_getPresupuestosPresentados() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), false);
        ABA_Detalle_presupuesto__c presupuesto2 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = true), false);
        insert new List<ABA_Detalle_presupuesto__c>{
                presupuesto2, presupuesto1
        };

        List<ABA_Detalle_presupuesto__c> lPresupuestos;
        Test.startTest();
        System.runAs(bo_User) {
            lPresupuestos = LwcSegEmpWorkPannelController.getPresupuestosPresentados(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(1, lPresupuestos.size());

    }


    @IsTest
    static void test_notifyPlacement_accepted() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), false);
        insert presupuesto1;
        String json = '{"ABA_TXT_Oficina_asociada__c":"Test oficina gestora",' +
                '"ABA_Fecha_primer_efecto__c":"' + System.today().addDays(1) + '",' +
                '"ABA_LIS_Periodicidad_cobro__c":"Renovable",' +
                '"Forma_de_pago__c":"Anual","N_de_cuenta__c":"453453",' +
                '"ABA_TXT_Tipo_riesgo__c":"test","ABA_TXT_Descripci_n_riesgo__c":"test",' +
                '"ABA_DT_Fecha_de_emisi_n__c":"' + System.today().addDays(1) + '","ABA_TXT_Prestamo__c":"test",' +
                '"ABA_TXT_Entidad_Beneficiaria__c":"test"}';
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.notifyPlacement(opp.Id, 'accepted', presupuesto1.Id, json);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);


        Assert.areEqual(SegEmpUtil.OPP_STATUS_ORDENEMISION, dataTree.opp.StageName);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_ORDENEMISION, dataTree.orden.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_ORDENEMISION, dataTree.gestion.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_ORDENEMISION, dataTree.lSolicitudes[0].Status);
        Assert.areEqual(SegEmpUtil.QUOTE_STATUS_ACEPTADO, dataTree.quote.Status);

        List<ABA_Poliza__c> lPolizas = [SELECT id from ABA_Poliza__c WHERE OpportunityId__c = :opp.Id];
        Assert.areEqual(1, lPolizas.size());
        Assert.areNotEqual(null, dataTree.formalizacion?.Id);


    }

    @IsTest
    static void test_notifyPlacement_info() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];


        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.notifyPlacement(opp.Id, 'infoRequest', null, null);
        }
        Test.stopTest();
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE));

    }

    @IsTest
    static void test_quoteModification() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.quoteModification(opp.Id, solicitud1.Id, 'recotizar');
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);


        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENGESTIONCONASEGURADORA, dataTree.lSolicitudes[0].Status);
        Assert.areEqual(SegEmpUtil.CASE_PROPOSALSTATUS_PDT_RECOTIZACION, dataTree.lSolicitudes[0].ProposalStatus__c);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_RECOTIZACION));

        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_RECOTIZACION));
        Assert.areEqual(SegEmpUtil.CASE_PROPOSALSTATUS_INVALIDA, dataTree.gestion.ProposalStatus__c);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_SOLICITUD_MERCADO, dataTree.gestion.Status);

        Assert.areEqual(SegEmpUtil.OPP_STATUS_COTIZACION, dataTree.opp.StageName);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_COTIZACION, dataTree.orden.Status);

        Assert.areEqual(SegEmpUtil.QUOTE_STATUS_ENGENERACION, dataTree.quote.Status);

    }

    @IsTest
    static void test_reopenSolicitud() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        solicitud1.Status = SegEmpUtil.CASE_STATUS_CERRADO;
        update solicitud1;
        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.reopenSolicitud(opp.Id, solicitud1.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);


        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENGESTIONCONASEGURADORA, dataTree.lSolicitudes[0].Status);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.lSolicitudes[0], SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT));

    }

    @IsTest
    static void test_coberturaFinished_received() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.opp.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.coberturaFinished(opp.Id, true);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENREVISIONDOC, dataTree.formalizacion.Status);

    }

    @IsTest
    static void test_coberturaFinished_notReceived() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.coberturaFinished(opp.Id, false);

        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_COBERTURAACEPTADA_PENDIENTEDOC, dataTree.formalizacion.Status);
    }

    @IsTest
    static void test_coberturaReceivedDoc() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.opp.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);
        formalizacion.Status = SegEmpUtil.CASE_STATUS_COBERTURAACEPTADA_PENDIENTEDOC;
        update formalizacion;

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.coberturaReceivedDoc(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENREVISIONDOC, dataTree.formalizacion.Status);

    }

    @IsTest
    static void test_setAsComputado_manual() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);
        ABA_Poliza__c poliza = (ABA_Poliza__c) TestFactory.createSObject(new ABA_Poliza__c( Name = 'Test poliza', RecordTypeId = SegEmpUtil.POLIZA_SEGUROS_RT_ID, OpportunityId__c = dataTree.opp.Id, ABA_Cliente__c = dataTree.gestion.AccountId), true);


        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsComputado(opp.Id, true);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_COMPUTADO));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_COMPUTADO));
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_COMPUTADO));
        Assert.areEqual(System.today(), dataTree.poliza.Fecha_de_env_o_a_Visual_SEG__c);

    }

    @IsTest
    static void test_setAsComputado_notManual() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);
        ABA_Poliza__c poliza = (ABA_Poliza__c) TestFactory.createSObject(new ABA_Poliza__c( Name = 'Test poliza', RecordTypeId = SegEmpUtil.POLIZA_SEGUROS_RT_ID, OpportunityId__c = dataTree.opp.Id, ABA_Cliente__c = dataTree.gestion.AccountId), true);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsComputado(opp.Id, false);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENTREGADAPOLIZA, dataTree.opp.StageName);

        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENTREGADAPOLIZA, dataTree.orden.Status);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_COMPUTADO));

        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENTREGADAPOLIZA, dataTree.gestion.Status);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_COMPUTADO));

        Assert.areEqual(SegEmpUtil.CASE_STATUS_ENTREGADAPOLIZA, dataTree.formalizacion.Status);
        Assert.areEqual(true, SegEmpUtil.isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_COMPUTADO));

        Assert.areEqual(System.today(), dataTree.poliza.Fecha_de_env_o_a_Visual_SEG__c);

    }

    @IsTest
    static void test_setPolizaAsRevisedByGEE() {
        User bo_User = getBoUser();
        User gee_User = getGeeUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);
        ABA_Poliza__c poliza = (ABA_Poliza__c) TestFactory.createSObject(new ABA_Poliza__c( Name = 'Test poliza', RecordTypeId = SegEmpUtil.POLIZA_SEGUROS_RT_ID, OpportunityId__c = dataTree.opp.Id, ABA_Cliente__c = dataTree.gestion.AccountId), true);

        Test.startTest();
        System.runAs(gee_User) {
            LwcSegEmpWorkPannelController.setPolizaAsRevisedByGEE(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(SegEmpUtil.OPP_STATUS_POLIZAREVISADAGEE, dataTree.opp.StageName);
        Assert.areEqual(SegEmpUtil.OPP_STATUS_POLIZAREVISADAGEE, dataTree.orden.Status);
        Assert.areEqual(SegEmpUtil.OPP_STATUS_POLIZAREVISADAGEE, dataTree.gestion.Status);
        Assert.areEqual(SegEmpUtil.OPP_STATUS_POLIZAREVISADAGEE, dataTree.formalizacion.Status);

    }

    @IsTest
    static void test_setAsFormalizado() {
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false, Accepted__c = true), true);
        Case formalizacion = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId), 'TestFactoryDefaults.CaseFormalizacionNuevoNegocioDefaults', true);
        ABA_Poliza__c poliza = (ABA_Poliza__c) TestFactory.createSObject(new ABA_Poliza__c( Name = 'Test poliza', RecordTypeId = SegEmpUtil.POLIZA_SEGUROS_RT_ID, OpportunityId__c = dataTree.opp.Id, ABA_Cliente__c = dataTree.gestion.AccountId), true);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.setAsFormalizado(opp.Id);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual(SegEmpUtil.OPP_STATUS_FORMALIZADA, dataTree.opp.StageName);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_FORMALIZADA, dataTree.orden.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_FORMALIZADA, dataTree.gestion.Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_FORMALIZADA, dataTree.lSolicitudes[0].Status);
        Assert.areEqual(SegEmpUtil.CASE_STATUS_FORMALIZADA, dataTree.formalizacion.Status);

    }

    @IsTest
    static void test_closeCases() {
        String status = SegEmpUtil.CASE_STATUS_CERRADO;
        String motivo = 'Riesgo rechazado';
        String situacion = 'Por el mercado';
        String comment = 'Test comment';
        String json = '{"Status":"'+status+'","ABA_LIS_Motivo_del_Estado__c":"'+motivo+'","ABA_LIS_Situacion__c":"'+situacion+'","ABA_TX_Comentarios_Estado__c":"'+comment+'"}';
        User bo_User = getBoUser();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account aseguradora = [SELECT Id FROM Account WHERE ABA_BOL_Aseguradora__c = true LIMIT 1];
        SegEmpUtil.FullTree dataTree = SegEmpUtil.getDataTree(opp.Id);
        Case solicitud1 = (Case) TestFactory.createSObject(new Case(ABA_Opportunity__c = opp.Id, ParentId = dataTree.gestion.Id, AccountId = dataTree.gestion.AccountId, OwnerId = bo_User.Id, ABA_Aseguradora__c = aseguradora.Id), 'TestFactoryDefaults.CaseSolicitudNuevoNegocioDefaults', true);
        Quote quote = (Quote) TestFactory.createSObject(new Quote(OpportunityId = opp.Id), 'TestFactoryDefaults.QuoteSegEmpDefaults', true);
        ABA_Detalle_presupuesto__c presupuesto1 = (ABA_Detalle_presupuesto__c) TestFactory.createSObject(new ABA_Detalle_presupuesto__c(ABA_Aseguradora__c = aseguradora.Id, ABA_MD_Quote__c = quote.Id, Case__c = solicitud1.Id, ABA_BO_Seleccionado__c = true, ABA_BO_Presentado_Cliente__c = true, Outdated__c = false), true);

        Test.startTest();
        System.runAs(bo_User) {
            LwcSegEmpWorkPannelController.closeCases(opp.Id, dataTree.orden.Id, json);
        }
        Test.stopTest();
        dataTree = SegEmpUtil.getDataTree(opp.Id);

        Assert.areEqual('Cancelado', dataTree.opp.StageName);
        Assert.areEqual(motivo, dataTree.opp.ABA_FLD_P_motivoCerradaPerdida__c);
        Assert.areEqual(situacion, dataTree.opp.Situacion__c);

        Assert.areEqual(status, dataTree.orden.Status);
        Assert.areEqual(motivo, dataTree.orden.ABA_LIS_Motivo_del_Estado__c);
        Assert.areEqual(situacion, dataTree.orden.ABA_LIS_Situacion__c);
        Assert.areEqual(true, String.isNotBlank(dataTree.orden.ABA_TX_Comentarios_Estado__c));

        Assert.areEqual(status, dataTree.gestion.Status);
        Assert.areEqual(motivo, dataTree.gestion.ABA_LIS_Motivo_del_Estado__c);
        Assert.areEqual(situacion, dataTree.gestion.ABA_LIS_Situacion__c);
        Assert.areEqual(true, String.isNotBlank(dataTree.gestion.ABA_TX_Comentarios_Estado__c));

        Assert.areEqual(status, dataTree.lSolicitudes[0].Status);
        Assert.areEqual(motivo, dataTree.lSolicitudes[0].ABA_LIS_Motivo_del_Estado__c);
        Assert.areEqual(situacion, dataTree.lSolicitudes[0].ABA_LIS_Situacion__c);
        Assert.areEqual(true, String.isNotBlank(dataTree.lSolicitudes[0].ABA_TX_Comentarios_Estado__c));
        Assert.areEqual(true, dataTree.mPresupuestosByCase.get(solicitud1.Id)[0].Outdated__c);


    }

    private static User getGeeUser() {
        Map<String, User> mUsers = getUsers();
        return mUsers.get('gee');
    }

    private static User getBoUser() {
        Map<String, User> mUsers = getUsers();
        return mUsers.get('bo');
    }

    private static Map<String, User> getUsers() {
        Map<String, User> response = new Map<String, User>();
        List<User> lUsers = [SELECT Id, Username FROM User WHERE Username IN (:BO_USERNAME, :GEE_USERNAME)];
        for (User u : lUsers) {
            if (u.Username == BO_USERNAME) {
                response.put('bo', u);
            } else if (u.Username == GEE_USERNAME) {
                response.put('gee', u);
            }
        }
        return response;
    }

}