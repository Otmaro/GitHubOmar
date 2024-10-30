
public without sharing class LwcChildsInfoGroupedController {

    @AuraEnabled(cacheable=false)
    public static List<DataPerChild> getInitData(Id caseId) {
        Map<String, List<CaseComment>> mCaseCommentsByCaseId = new Map<String, List<CaseComment>>();
        Map<String, List<EmailMessage>> mEmailMessagesByCaseId = new Map<String, List<EmailMessage>>();
        Map<String, List<ContentDocumentLink>> mFilesByCaseId = new Map<String, List<ContentDocumentLink>>();
        Map<String, List<ABA_OBJ_FileManagerLink__c>> mArchivedFilesByCaseId = new Map<String, List<ABA_OBJ_FileManagerLink__c>>();
        Map<String, List<FeedItem>> mFeedItemsByCaseId = new Map<String, List<FeedItem>>();
        Map<String, List<FeedComment>> mFeedCommentsByFeedItemId = new Map<String, List<FeedComment>>();
        Map<String, ABA_Detalle_presupuesto__c> mActivePresupuestoByCaseId = new Map<String, ABA_Detalle_presupuesto__c>();
        List<DataPerChild> response = new List<DataPerChild>();

        List<Case> lChildCases = [SELECT Id, CaseNumber, Subject, Status, ProcessStatus__c, ProposalStatus__c, RecordTypeId, RecordType.DeveloperName, RiskVerificationStatus__c, ABA_Aseguradora__r.Name FROM Case WHERE ParentId = :caseId ORDER BY CreatedDate DESC ];
        Set<String> sChildCaseIds = new Set<String>();
        for (Case c : lChildCases) {
            sChildCaseIds.add(c.Id);

            if (!mCaseCommentsByCaseId.containsKey(c.Id)) {
                mCaseCommentsByCaseId.put(c.Id, new List<CaseComment>());
            }
            if (!mEmailMessagesByCaseId.containsKey(c.Id)) {
                mEmailMessagesByCaseId.put(c.Id, new List<EmailMessage>());
            }
            if (!mFilesByCaseId.containsKey(c.Id)) {
                mFilesByCaseId.put(c.Id, new List<ContentDocumentLink>());
            }
            if (!mArchivedFilesByCaseId.containsKey(c.Id)) {
                mArchivedFilesByCaseId.put(c.Id, new List<ABA_OBJ_FileManagerLink__c>());
            }
            if (!mFeedItemsByCaseId.containsKey(c.Id)) {
                mFeedItemsByCaseId.put(c.Id, new List<FeedItem>());
            }

        }
        if (!sChildCaseIds.isEmpty()) {
            List<CaseComment> lCaseComments = [SELECT Id, CommentBody, CreatedDate, CreatedBy.Name, ParentId FROM CaseComment WHERE ParentId IN :sChildCaseIds ORDER BY CreatedDate DESC];
            for (CaseComment cc : lCaseComments) {
                mCaseCommentsByCaseId.get(cc.ParentId).add(cc);
            }

            List<EmailMessage> lEmailMessages = [SELECT Id, Subject, TextBody, HtmlBody, FromAddress, ToAddress, ParentId, Incoming, CreatedDate FROM EmailMessage WHERE ParentId IN :sChildCaseIds ORDER BY CreatedDate DESC];
            for (EmailMessage em : lEmailMessages) {
                mEmailMessagesByCaseId.get(em.ParentId).add(em);
            }

            List<ContentDocumentLink> lFiles = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.CreatedDate, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :sChildCaseIds ORDER BY ContentDocument.CreatedDate DESC];
            for (ContentDocumentLink cdl : lFiles) {
                mFilesByCaseId.get(cdl.LinkedEntityId).add(cdl);
            }

            List<ABA_OBJ_FileManagerLink__c> lFMLs = [
                    SELECT Id, ABA_FLD_MD_FileManager__r.Id, ABA_FLD_MD_FileManager__r.CreatedBy.Name, ABA_FLD_MD_FileManager__r.CreatedDate, ABA_FLD_MD_FileManager__r.ABA_FLD_T_FileName__c, ABA_FLD_MD_FileManager__r.ABA_FLD_T_DocumentManagerId__c, ABA_FLD_T_LinkedEntityId__c
                    FROM ABA_OBJ_FileManagerLink__c
                    WHERE ABA_FLD_T_LinkedEntityId__c IN :sChildCaseIds
                    ORDER BY ABA_FLD_MD_FileManager__r.CreatedDate DESC
            ];
            for (ABA_OBJ_FileManagerLink__c fml: lFMLs) {
                mArchivedFilesByCaseId.get(fml.ABA_FLD_T_LinkedEntityId__c).add(fml);
            }
            //todo se tuvo que poner withouth sharing porque daba error de que requiers a filter by id. Revisar.
            List<FeedItem> lFeedItems = [SELECT Id, Body, CreatedDate, CreatedBy.Name, ParentId, CommentCount FROM FeedItem WHERE ParentId IN :sChildCaseIds AND Type = 'TextPost' ORDER BY CreatedDate DESC];
            Set<String> sFeedItemIds = new Set<String>();
            for (FeedItem fi : lFeedItems) {
                mFeedItemsByCaseId.get(fi.ParentId).add(fi);
                sFeedItemIds.add(fi.Id);
                if (!mFeedCommentsByFeedItemId.containsKey(fi.Id)) {
                    mFeedCommentsByFeedItemId.put(fi.Id, new List<FeedComment>());
                }
            }
            if (!sFeedItemIds.isEmpty()) {
                List<FeedComment> lFeedComments = [SELECT Id, CreatedBy.Name, CreatedDate, CommentBody, FeedItemId FROM FeedComment WHERE FeedItemId IN :sFeedItemIds ORDER BY CreatedDate ASC];
                for (FeedComment fc : lFeedComments) {
                    mFeedCommentsByFeedItemId.get(fc.FeedItemId).add(fc);
                }
            }

            List<ABA_Detalle_presupuesto__c> lPresupuestos = [SELECT Id, Case__c, ABA_DIV_Prima_Neta__c, ABA_DIV_Importe_Total_prima__c FROM ABA_Detalle_presupuesto__c WHERE Case__c IN :sChildCaseIds AND Outdated__c = FALSE];
            for (ABA_Detalle_presupuesto__c p : lPresupuestos) {
                mActivePresupuestoByCaseId.put(p.Case__c, p);
            }
        }

        for (Case c : lChildCases) {
            DataPerChild dpc = new DataPerChild();
            dpc.childCase = c;
            if (String.isNotBlank(c.ProcessStatus__c)) {
                dpc.lChildCaseProcessStatus = c.ProcessStatus__c.split(';');
            } else {
                dpc.lChildCaseProcessStatus = new List<String>();
            }
            dpc.lCaseComments = mCaseCommentsByCaseId.get(c.Id);
            dpc.lEmailMessages = mEmailMessagesByCaseId.get(c.Id);
            dpc.lFiles = mFilesByCaseId.get(c.Id);
            dpc.lArchivedFiles = mArchivedFilesByCaseId.get(c.Id);
            dpc.lFeedItems = new List<DataPerFeedItem>();
            for (FeedItem fi : mFeedItemsByCaseId.get(c.Id)) {
                DataPerFeedItem dpf = new DataPerFeedItem();
                dpf.feedItem = fi;
                dpf.Id = fi.Id;
                dpf.lFeedComments = mFeedCommentsByFeedItemId.get(fi.Id);
                dpc.lFeedItems.add(dpf);
            }
            dpc.activePresupuesto = mActivePresupuestoByCaseId.get(c.Id);

            response.add(dpc);
        }
        return response;

    }

    public class DataPerChild {
        @AuraEnabled
        public Case childCase;
        @AuraEnabled
        public List<String> lChildCaseProcessStatus;
        @AuraEnabled
        public List<CaseComment> lCaseComments;
        @AuraEnabled
        public List<EmailMessage> lEmailMessages;
        @AuraEnabled
        public List<ContentDocumentLink> lFiles;
        @AuraEnabled
        public List<ABA_OBJ_FileManagerLink__c> lArchivedFiles;
        @AuraEnabled
        public ABA_Detalle_presupuesto__c activePresupuesto;
        @AuraEnabled
        public List<DataPerFeedItem> lFeedItems;
    }

    public class DataPerFeedItem {
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public FeedItem feedItem;
        @AuraEnabled
        public List<FeedComment> lFeedComments;
    }
}