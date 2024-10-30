public with sharing class HomeSegurosEmpresasController {

    private static Map<String, Date> getStartAndEndDate(String timeframe) {
        Date today = Date.today();
        Date startDate;
        Date endDate;

        if (timeframe == 'day') {
            startDate = today;
            endDate = today;
        } else if (timeframe == 'week') {
            startDate = today.toStartOfWeek();
            endDate = today.toStartOfWeek().addDays(6);
        } else if (timeframe == 'month') {
            startDate = today.toStartOfMonth();
            endDate = today.toStartOfMonth().addMonths(1);
        } else {
            startDate = today;
            endDate = today;
        }

        Map<String, Date> dateMap = new Map<String, Date>();
        dateMap.put('startDate', startDate);
        dateMap.put('endDate', endDate);
        return dateMap;
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getFilteredCases(String timeframe, String recordTypeName) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        String query = 'SELECT Id, CaseNumber, Subject, Deadline__c, Status, ProcessStatus__c, RecordType.Name ' +
                       'FROM Case ' +
                       'WHERE AmITheOwner__c = true ' +
                       'AND Deadline__c >= :startDate AND Deadline__c <= :endDate';

        if (recordTypeName != null) {
            if (recordTypeName == 'Orden_de_trabajo_Seguros_de_Empresa') {
                query += ' AND RecordTypeId = :ordenDeTrabajoRTId';
            } else if (recordTypeName == 'Gestion_de_placement') {
                query += ' AND RecordTypeId = :gestionPlacementRTId';
            } else if (recordTypeName == 'Cartera') {
                query += ' AND RecordTypeId = :carteraRTId';
            }
        } else {
            query += ' AND (RecordTypeId = :ordenDeTrabajoRTId OR RecordTypeId = :gestionPlacementRTId OR RecordTypeId = :carteraRTId)';
        }

        return Database.query(query);
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getCaseCountsByRecordType(String timeframe) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        Integer ordenDeTrabajoCount = [SELECT COUNT() FROM Case 
                                       WHERE AmITheOwner__c = true 
                                       AND RecordTypeId = :ordenDeTrabajoRTId 
                                       AND Deadline__c >= :startDate
                                       AND Deadline__c <= :endDate];

        Integer gestionPlacementCount = [SELECT COUNT() FROM Case 
                                         WHERE AmITheOwner__c = true 
                                         AND RecordTypeId = :gestionPlacementRTId 
                                         AND Deadline__c >= :startDate
                                         AND Deadline__c <= :endDate];
                                         
        Integer carteraCount = [SELECT COUNT() FROM Case
                                WHERE AmITheOwner__c = true
                                AND RecordTypeId = :carteraRTId
                                AND Deadline__c >= :startDate
                                AND Deadline__c <= :endDate];

        Map<String, Integer> recordTypeCounts = new Map<String, Integer>();
        recordTypeCounts.put('Orden_de_trabajo_Seguros_de_Empresa', ordenDeTrabajoCount);
        recordTypeCounts.put('Gestion_de_placement', gestionPlacementCount);
        recordTypeCounts.put('Cartera', carteraCount);

        return recordTypeCounts;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getCaseCountsByRecordTypeWithScope(String timeframe) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        Integer ordenDeTrabajoCount = [SELECT COUNT() FROM Case 
                                       WHERE AmITheOwner__c = true 
                                       AND RecordTypeId = :ordenDeTrabajoRTId 
                                       AND SegEmp_MyScope__c = true
                                       AND Deadline__c >= :startDate
                                       AND Deadline__c <= :endDate];

        Integer gestionPlacementCount = [SELECT COUNT() FROM Case 
                                         WHERE AmITheOwner__c = true 
                                         AND RecordTypeId = :gestionPlacementRTId 
                                         AND SegEmp_MyScope__c = true
                                         AND Deadline__c >= :startDate
                                         AND Deadline__c <= :endDate];
                                         
        Integer carteraCount = [SELECT COUNT() FROM Case
                                WHERE AmITheOwner__c = true
                                AND RecordTypeId = :carteraRTId
                                AND SegEmp_MyScope__c = true
                                AND Deadline__c >= :startDate
                                AND Deadline__c <= :endDate];

        Map<String, Integer> recordTypeCounts = new Map<String, Integer>();
        recordTypeCounts.put('Orden_de_trabajo_Seguros_de_Empresa', ordenDeTrabajoCount);
        recordTypeCounts.put('Gestion_de_placement', gestionPlacementCount);
        recordTypeCounts.put('Cartera', carteraCount);

        return recordTypeCounts;
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getFilteredCasesWithScope(String timeframe, String recordTypeName) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        String query = 'SELECT Id, CaseNumber, Subject, Deadline__c, Status, ProcessStatus__c, RecordType.Name ' +
                       'FROM Case ' +
                       'WHERE SegEmp_MyScope__c = true ' +
                       'AND AmITheOwner__c = true ' +
                       'AND Deadline__c >= :startDate AND Deadline__c <= :endDate';

        if (recordTypeName != null) {
            if (recordTypeName == 'Orden_de_trabajo_Seguros_de_Empresa') {
                query += ' AND RecordTypeId = :ordenDeTrabajoRTId';
            } else if (recordTypeName == 'Gestion_de_placement') {
                query += ' AND RecordTypeId = :gestionPlacementRTId';
            } else if (recordTypeName == 'Cartera') {
                query += ' AND RecordTypeId = :carteraRTId';
            }
        } else {
            query += ' AND (RecordTypeId = :ordenDeTrabajoRTId OR RecordTypeId = :gestionPlacementRTId OR RecordTypeId = :carteraRTId)';
        }

        return Database.query(query);
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getAlertCountsByName(String timeframe) {
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        List<AggregateResult> alertCounts = [SELECT ABA_LIS_Nombre__c, COUNT(Id) total
                                             FROM ABA_OBJ_Gestion__c
                                             WHERE Fecha_Alerta__c >= :startDate AND Fecha_Alerta__c <= :endDate
                                             GROUP BY ABA_LIS_Nombre__c];

        Map<String, Integer> alertCountMap = new Map<String, Integer>();
        for (AggregateResult ar : alertCounts) {
            alertCountMap.put((String)ar.get('ABA_LIS_Nombre__c'), (Integer)ar.get('total'));
        }

        return alertCountMap;
    }

    @AuraEnabled(cacheable=false)
    public static List<ABA_OBJ_Gestion__c> getFilteredAlerts(String timeframe) {
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        String query = 'SELECT Id, ABA_LIS_Nombre__c, Fecha_Alerta__c FROM ABA_OBJ_Gestion__c WHERE Fecha_Alerta__c >= :startDate AND Fecha_Alerta__c <= :endDate';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=false)
    public static Integer getFormalizacionNuevoNegocioCount(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_de_nuevo_negocio').Id;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        Integer formalizacionSegurosCount = [SELECT COUNT() FROM Case 
                                              WHERE RecordTypeId = :formalizacionSegurosRTId 
                                              AND AmITheOwner__c = true 
                                              AND Status = 'Inicio de gestión'
                                              AND Deadline__c >= :startDate
                                              AND Deadline__c <= :endDate];

        return formalizacionSegurosCount;
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getFormalizacionNuevoNegocioCases(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_de_nuevo_negocio').Id;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        String query = 'SELECT Id, CaseNumber, Subject, Deadline__c, Status ' +
                       'FROM Case ' +
                       'WHERE RecordTypeId = :formalizacionSegurosRTId ' +
                       'AND AmITheOwner__c = true ' +
                       'AND Status = \'Inicio de gestión\' ' +
                       'AND Deadline__c >= :startDate AND Deadline__c <= :endDate';

        return Database.query(query);
    }

    @AuraEnabled(cacheable=false)
    public static Integer getAllFormalizacionSegurosCount(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_Seguros_de_Empresa').Id;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        Integer formalizacionSegurosCount = [SELECT COUNT() FROM Case 
                                            WHERE RecordTypeId = :formalizacionSegurosRTId 
                                            AND AmITheOwner__c = true 
                                            AND Deadline__c >= :startDate
                                            AND Deadline__c <= :endDate];

        return formalizacionSegurosCount;
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getAllFormalizacionSegurosCases(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_Seguros_de_Empresa').Id;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        String query = 'SELECT Id, CaseNumber, Subject, Deadline__c, Status ' +
                       'FROM Case ' +
                       'WHERE RecordTypeId = :formalizacionSegurosRTId ' +
                       'AND AmITheOwner__c = true ' +
                       'AND Deadline__c >= :startDate AND Deadline__c <= :endDate';

        return Database.query(query);
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getFilteredCasesByProcessStatus(String timeframe, String recordTypeName) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;
    
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        String query = 'SELECT Id, CaseNumber, Subject, Deadline__c, Status, ProcessStatus__c, RecordType.Name ' +
                       'FROM Case ' +
                       'WHERE ProcessStatus__c = \'Pdt. aseguradora\' ' +
                       'AND AmITheOwner__c = true ' +
                       'AND Deadline__c >= :startDate AND Deadline__c <= :endDate';
    
        if (recordTypeName != null) {
            if (recordTypeName == 'Orden_de_trabajo_Seguros_de_Empresa') {
                query += ' AND RecordTypeId = :ordenDeTrabajoRTId';
            } else if (recordTypeName == 'Gestion_de_placement') {
                query += ' AND RecordTypeId = :gestionPlacementRTId';
            } else if (recordTypeName == 'Cartera') {
                query += ' AND RecordTypeId = :carteraRTId';
            }
        } else {
            query += ' AND (RecordTypeId = :ordenDeTrabajoRTId OR RecordTypeId = :gestionPlacementRTId OR RecordTypeId = :carteraRTId)';
        }
    
        return Database.query(query);
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getCaseCountsByProcessStatus(String timeframe) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;
    
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        Integer ordenDeTrabajoCount = [SELECT COUNT() FROM Case 
                                       WHERE AmITheOwner__c = true 
                                       AND ProcessStatus__c = 'Pdt. aseguradora' 
                                       AND RecordTypeId = :ordenDeTrabajoRTId 
                                       AND Deadline__c >= :startDate
                                       AND Deadline__c <= :endDate];
    
        Integer gestionPlacementCount = [SELECT COUNT() FROM Case 
                                         WHERE AmITheOwner__c = true 
                                         AND ProcessStatus__c = 'Pdt. aseguradora' 
                                         AND RecordTypeId = :gestionPlacementRTId 
                                         AND Deadline__c >= :startDate
                                         AND Deadline__c <= :endDate];
    
        Integer carteraCount = [SELECT COUNT() FROM Case
                                WHERE AmITheOwner__c = true
                                AND ProcessStatus__c = 'Pdt. aseguradora'
                                AND RecordTypeId = :carteraRTId
                                AND Deadline__c >= :startDate
                                AND Deadline__c <= :endDate];
    
        Map<String, Integer> recordTypeCounts = new Map<String, Integer>();
        recordTypeCounts.put('Orden_de_trabajo_Seguros_de_Empresa', ordenDeTrabajoCount);
        recordTypeCounts.put('Gestion_de_placement', gestionPlacementCount);
        recordTypeCounts.put('Cartera', carteraCount);
    
        return recordTypeCounts;
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getFilteredCasesByGEEOrStatus(String timeframe, String recordTypeName) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;
    
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        String query = 'SELECT Id, CaseNumber, Subject, Deadline__c, Status, ProcessStatus__c, RecordType.Name ' +
                       'FROM Case ' +
                       'WHERE AmITheOwner__c = true ' +
                       'AND (ProcessStatus__c = \'Pdt. GEE\' OR Status IN (\'Propuestas habilitadas a comercial\', \'Presentada oferta\')) ' +
                       'AND Deadline__c >= :startDate AND Deadline__c <= :endDate';
    
        if (recordTypeName != null) {
            if (recordTypeName == 'Orden_de_trabajo_Seguros_de_Empresa') {
                query += ' AND RecordTypeId = :ordenDeTrabajoRTId';
            } else if (recordTypeName == 'Gestion_de_placement') {
                query += ' AND RecordTypeId = :gestionPlacementRTId';
            } else if (recordTypeName == 'Cartera') {
                query += ' AND RecordTypeId = :carteraRTId';
            }
        } else {
            query += ' AND (RecordTypeId = :ordenDeTrabajoRTId OR RecordTypeId = :gestionPlacementRTId OR RecordTypeId = :carteraRTId)';
        }
    
        return Database.query(query);
    }
    

    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getCaseCountsByGEEOrStatus(String timeframe) {
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;
    
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        Integer ordenDeTrabajoCount = [SELECT COUNT() FROM Case 
                                       WHERE AmITheOwner__c = true
                                       AND (ProcessStatus__c = 'Pdt. GEE' OR Status IN ('Propuestas habilitadas a comercial', 'Presentada oferta')) 
                                       AND RecordTypeId = :ordenDeTrabajoRTId 
                                       AND Deadline__c >= :startDate
                                       AND Deadline__c <= :endDate];
    
        Integer gestionPlacementCount = [SELECT COUNT() FROM Case 
                                         WHERE AmITheOwner__c = true
                                         AND (ProcessStatus__c = 'Pdt. GEE' OR Status IN ('Propuestas habilitadas a comercial', 'Presentada oferta')) 
                                         AND RecordTypeId = :gestionPlacementRTId 
                                         AND Deadline__c >= :startDate
                                         AND Deadline__c <= :endDate];
    
        Integer carteraCount = [SELECT COUNT() FROM Case
                                WHERE AmITheOwner__c = true
                                AND (ProcessStatus__c = 'Pdt. GEE' OR Status IN ('Propuestas habilitadas a comercial', 'Presentada oferta'))
                                AND RecordTypeId = :carteraRTId
                                AND Deadline__c >= :startDate
                                AND Deadline__c <= :endDate];
    
        Map<String, Integer> recordTypeCounts = new Map<String, Integer>();
        recordTypeCounts.put('Orden_de_trabajo_Seguros_de_Empresa', ordenDeTrabajoCount);
        recordTypeCounts.put('Gestion_de_placement', gestionPlacementCount);
        recordTypeCounts.put('Cartera', carteraCount);
    
        return recordTypeCounts;
    }

    @AuraEnabled(cacheable=false)
    public static Integer getFormalizacionNuevoNegocioCountByRamos(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_de_nuevo_negocio').Id;
    
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        String userRamos = [SELECT Ramos_NuevoNegocio__c FROM User WHERE Id = :UserInfo.getUserId()].Ramos_NuevoNegocio__c;
        List<String> userRamosList = userRamos != null ? userRamos.split(';') : new List<String>();
    
        Integer formalizacionSegurosCount = [SELECT COUNT() FROM Case 
                                             WHERE RecordTypeId = :formalizacionSegurosRTId 
                                             AND ABA_LIS_Ramo__c IN :userRamosList
                                             AND Status = 'Inicio de gestión'
                                             AND Deadline__c >= :startDate
                                             AND Deadline__c <= :endDate];
    
        return formalizacionSegurosCount;
    }
    
    
    

    @AuraEnabled(cacheable=false)
    public static List<Case> getFormalizacionNuevoNegocioCasesByRamos(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_de_nuevo_negocio').Id;
    
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        String userRamos = [SELECT Ramos_NuevoNegocio__c FROM User WHERE Id = :UserInfo.getUserId()].Ramos_NuevoNegocio__c;
        List<String> userRamosList = userRamos != null ? userRamos.split(';') : new List<String>();
    
        List<Case> formalizacionSegurosCases = [SELECT Id, CaseNumber, Subject, Deadline__c, Status, ABA_LIS_Ramo__c
                                                FROM Case 
                                                WHERE RecordTypeId = :formalizacionSegurosRTId
                                                AND ABA_LIS_Ramo__c IN :userRamosList
                                                AND Status = 'Inicio de gestión'
                                                AND Deadline__c >= :startDate
                                                AND Deadline__c <= :endDate];
    
        return formalizacionSegurosCases;
    }


    @AuraEnabled(cacheable=false)
    public static Map<String, Integer> getCaseCountsByRamosDuplicated(String timeframe) {
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;
        
        String userRamos = [SELECT Ramos_NuevoNegocio__c FROM User WHERE Id = :UserInfo.getUserId()].Ramos_NuevoNegocio__c;
        List<String> userRamosList = userRamos != null ? userRamos.split(';') : new List<String>();
    
        List<AggregateResult> ramoCounts = [SELECT ABA_LIS_Ramo__c, COUNT(Id) total
                                            FROM Case
                                            WHERE ABA_LIS_Ramo__c IN :userRamosList
                                            AND RecordTypeId IN (:ordenDeTrabajoRTId, :gestionPlacementRTId, :carteraRTId)
                                            AND Deadline__c >= :startDate
                                            AND Deadline__c <= :endDate
                                            GROUP BY ABA_LIS_Ramo__c];
    
        Map<String, Integer> recordTypeCountsDuplicated = new Map<String, Integer>();
        for (AggregateResult ar : ramoCounts) {
            recordTypeCountsDuplicated.put((String) ar.get('ABA_LIS_Ramo__c'), (Integer) ar.get('total'));
        }
        return recordTypeCountsDuplicated;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getFilteredCasesByRamossDuplicated(String ramo, String timeframe) {
        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');
    
        Id ordenDeTrabajoRTId = SegEmpUtil.NUEVONEGOCIO_Siniestro_RT_ID;
        Id gestionPlacementRTId = SegEmpUtil.NUEVONEGOCIO_GESTION_RT_ID;
        Id carteraRTId = SegEmpUtil.NUEVONEGOCIO_CARTERA_RT_ID;
    
        String userRamos = [SELECT Ramos_NuevoNegocio__c FROM User WHERE Id = :UserInfo.getUserId()].Ramos_NuevoNegocio__c;
        List<String> userRamosList = userRamos != null ? userRamos.split(';') : new List<String>();
    
        String query = 'SELECT Id, CaseNumber, Subject, Deadline__c, Status, ABA_LIS_Ramo__c, RecordType.Name ' +
                       'FROM Case ' +
                       'WHERE ABA_LIS_Ramo__c IN :userRamosList ' +
                       'AND RecordTypeId IN (:ordenDeTrabajoRTId, :gestionPlacementRTId, :carteraRTId) ' +
                       'AND Deadline__c >= :startDate AND Deadline__c <= :endDate';
    
        if (ramo != null && ramo != '') {
            query += ' AND ABA_LIS_Ramo__c = :ramo';
        }
    
        return Database.query(query);
    }


    @AuraEnabled(cacheable=false)
    public static Integer getFormalizacionNuevoNegocioCountAllRamos(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_de_nuevo_negocio').Id;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        Integer formalizacionSegurosCount = [SELECT COUNT() FROM Case 
                                            WHERE RecordTypeId = :formalizacionSegurosRTId 
                                            AND Status = 'Inicio de gestión'
                                            AND Deadline__c >= :startDate
                                            AND Deadline__c <= :endDate];

        return formalizacionSegurosCount;
}

    @AuraEnabled(cacheable=false)
    public static List<Case> getFormalizacionNuevoNegocioCasesAllRamos(String timeframe) {
        Id formalizacionSegurosRTId = CaseUtil.getRecordTypeByDeveloperName('Formalizacion_de_nuevo_negocio').Id;

        Map<String, Date> dates = getStartAndEndDate(timeframe);
        Date startDate = dates.get('startDate');
        Date endDate = dates.get('endDate');

        List<Case> formalizacionSegurosCases = [SELECT Id, CaseNumber, Subject, Deadline__c, Status, ABA_LIS_Ramo__c
                                                FROM Case 
                                                WHERE RecordTypeId = :formalizacionSegurosRTId
                                                AND Status = 'Inicio de gestión'
                                                AND Deadline__c >= :startDate
                                                AND Deadline__c <= :endDate];

        return formalizacionSegurosCases;
    }

    
    
    
    
    
    


    
    
    
    
}