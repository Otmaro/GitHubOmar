/**
 * @description       : Controlador del componente de la lista relacionada extendida
 * @author            : Clarcat
 * @group             : 
 * @last modified on  : 03-17-2022
 * @last modified by  : Clarcat
**/
public with sharing class Enhanced_Related_ListController {
    /**
     * @Author Clarcat 
     * @Date  20-08-2019
     * @Description recupera los datos del custom metadata a usar en la lista
     * @param String recordId --> the id of the record
     * @param String metadataConfig --> Nombre del custom metadata usado en la lista
     * @param Boolean isCommunity --> Indica si es el componente es parte de una community o no 
     * @return String --> Un JSON convertido a String con toda la información necesaria para el componente
     **/
    @AuraEnabled(cacheable=true)
    public static String initData(String recordId, String metadataConfig, Integer num, Boolean seeAll) {

        Related_List__mdt mtd = [SELECT Json_Config__c FROM Related_List__mdt WHERE DeveloperName = :metadataConfig];
        Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(mtd.Json_Config__c); 
        
        String query =  (String)root.get('query');

        Datetime currentTime=System.now();
        List<Sobject> sObjectTotalList = Database.query(query);

        SObjectAccessDecision decision = Security.stripInaccessible(
	                                   AccessType.READABLE,
	                                   sObjectTotalList);

        List<Sobject> sObjectLimitList = new List<Sobject>();

        if(decision.getRecords().size()>0){
            Integer limitfor = (num <= decision.getRecords().size()) ? num : decision.getRecords().size();
            for(integer i=0;i<limitfor;i++){
                sObjectLimitList.add(decision.getRecords()[i]);
            }
        }
        
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put('records', sObjectLimitList);
        responseMap.put('allRecords',decision.getRecords());
        responseMap.put('showAllLinks',seeAll == true ? false: true);
        responseMap.put('datatableType', root.get('datatableType'));
        responseMap.put('iconName', root.get('iconName'));
        responseMap.put('title', root.get('title'));
        responseMap.put('phoneTitle', root.get('phoneTitle'));
        System.debug(JSON.serialize(responseMap));
        return JSON.serialize(responseMap);
    }

    /**
    * @description Método para la descarga de un fichero adjunto
    * @author Clarcat | 11-29-2021 
    * @param Id DownloadAttachmentID --> El Id del documento
    * @return string --> La URL del documento 
    **/
    @AuraEnabled
    public static string downLoadAttachment(Id DownloadAttachmentID){
        ContentVersion oldCV = [Select Id,Title, ContentDocument.LatestPublishedVersionId from ContentVersion Where ContentDocumentId=:DownloadAttachmentID and IsLatest = true ];
        String idx = String.valueOf(oldCV.ContentDocumentId).substring(0,15);
        //CC_Integration__c intCC = CC_Integration__c.getValues('Community Url');
        //String URlDownload = intCC.Endpoint__c + '/sfc/servlet.shepherd/document/download/' + idx + '?operationContext=S1';
        String URlDownload = '';
        return URlDownload;
    } 

    /**
    * @description Método para eliminar un fichero adjunto
    * @author Clarcat | 11-29-2021 
    * @param Id attachId --> Id del fichero a eliminar
    **/
    @AuraEnabled
    public static void deleteAttachment(Id attachId){
        ContentDocument cDoc = new ContentDocument();
        cDoc.Id = attachId;
        delete cDoc;
    }

    /**
    * @description Método para eliminar el record 
    * @author Clarcat | 11-29-2021 
    * @param Id recordId --> Id del registro a eliminar
    **/
    @AuraEnabled(cacheable=false)
    public static void deleteRecord(Id recordId){
        Database.delete(recordId);
    }
}