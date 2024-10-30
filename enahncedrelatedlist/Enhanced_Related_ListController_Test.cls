/**
 * @description       : Clase de test para el controlador de Enhanced list
 * @author            : Clarcat
 * @group             : 
 * @last modified on  : 02-24-2022
 * @last modified by  : Clarcat
**/
@isTest
private class Enhanced_Related_ListController_Test {
    
    @isTest
    static void Demonstrate_InitDataMethod() {
        Account acc = (Account) TestFactory.createSObject(new Account(Name = 'Nombre'), true);
        Contact con = (Contact) TestFactory.createSObject(new Contact(Lastname = 'apellido', AccountId = acc.Id), true);
        Case c = (Case) TestFactory.createSObject(new Case(ContactId = con.Id, AccountId = acc.Id), true);

        Test.startTest();
            String response = Enhanced_Related_ListController.initData(acc.Id, 'RecordForTestClass', 5, false);
        Test.stopTest();

        // Assertions
        
    }

    @isTest
    static void Demonstrate_deleteRecord() {
        Account acc = (Account) TestFactory.createSObject(new Account(Name = 'Nombre'), true);

        Test.startTest();
            Enhanced_Related_ListController.deleteRecord(acc.Id);
        Test.stopTest();

        // Assertions
        
    }
}