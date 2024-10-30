@isTest
private class QueueUtilTest
{
    
    @isTest
    static void test_getQueueIdByDevName(){
        Group c = (Group) TestFactory.createSObject(new Group(), 'TestFactoryDefaults.GroupsDefaults');
        insert c;
        test.startTest();
        
        Id x=queueUtil.getQueueIdByDevName('test');

        test.stopTest();

        System.assertEquals(x, c.id);


    }
    @isTest
    static void test_getQueuesMapById(){
        Group c = (Group) TestFactory.createSObject(new Group(), 'TestFactoryDefaults.GroupsDefaults');
        insert c;
        Map<String, Group> mQueuesById=new Map<String, Group>();
        test.startTest();
        mQueuesById=QueueUtil.getQueuesMapById();
        String x=mQueuesById.get(c.id).DeveloperName;

        test.stopTest();

        System.assertEquals(x, c.DeveloperName);


    }

    @isTest
    static void test_getQueuesMapByDeveloperName(){
        Group c = (Group) TestFactory.createSObject(new Group(), 'TestFactoryDefaults.GroupsDefaults');
        insert c;
        Map<String, Group> mQueuesByDevName=new Map<String, Group>();
        test.startTest();
        mQueuesByDevName=QueueUtil.getQueuesMapByDeveloperName();
        Id  x=mQueuesByDevName.get('test').id;
        test.stopTest();
        System.assertEquals(x, c.id);

    }

}