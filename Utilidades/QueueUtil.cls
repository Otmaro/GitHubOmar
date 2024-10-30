
public with sharing class QueueUtil {

    private static Map<String, Group> mQueuesByDevName;
    private static Map<String, Group> mQueuesById;

    public static Map<String, Group> getQueuesMapByDeveloperName() {
        if (mQueuesByDevName == null || mQueuesByDevName.isEmpty()) {
            fillQueueMaps();
        }
        return mQueuesByDevName;
    }


    public static Map<String, Group> getQueuesMapById() {
        if (mQueuesById == null || mQueuesById.isEmpty()) {
            fillQueueMaps();
        }
        return mQueuesById;
    }

    public static String getQueueIdByDevName(String queueDevName) {
        if (mQueuesByDevName == null || mQueuesByDevName.isEmpty()) {
            fillQueueMaps();
        }
        return mQueuesByDevName?.get(queueDevName)?.Id;
    }

    private static void fillQueueMaps() {
        mQueuesByDevName = new Map<String, Group >();
        mQueuesById = new Map<String, Group >();

        List< Group > lGroups = new List< Group >([SELECT DeveloperName, Id, Name FROM Group WHERE Type = 'Queue']);
        mQueuesByDevName = (Map<String, Group >) CollectionUtils.stringMapFromCollectionByKey('DeveloperName', lGroups);
        mQueuesById = (Map<String, Group >) CollectionUtils.stringMapFromCollectionByKey('Id', lGroups);

    }

}