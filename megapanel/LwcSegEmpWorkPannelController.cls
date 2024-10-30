public without sharing class LwcSegEmpWorkPannelController {

    public static SegEmpUtil.FullTree dataTree;

    public class LwcSegEmpWorkPannelControllerException extends Exception {
    }

    @AuraEnabled(Cacheable=false)
    public static SegEmpUtil.FullTree getDataTree(String opportunityId) {
        return SegEmpUtil.getDataTree(opportunityId);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult assignCasesToMe(String opportunityId) {
        DMLResult response = new DMLResult();
        if (String.isNotBlank(opportunityId)) {
            List<Case> lCases = [SELECT Id FROM Case WHERE ABA_Opportunity__c = :opportunityId];

            if (!lCases.isEmpty()) {
                for (Case c : lCases) {
                    c.OwnerId = UserInfo.getUserId();
                }
                try {
                    update lCases;
                    response.isSuccess = true;
                } catch (Exception e) {
                    response.isSuccess = false;
                    response.message = e.getMessage() + ' - ' + e.getStackTraceString();
                }
            }
        }
        return response;
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setAsVisto(String opportunityId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        dataTree.orden.Status = SegEmpUtil.CASE_STATUS_VISTO;
        dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_VISTO;

        return updateRecords(null, new List<Case>{
                dataTree.orden, dataTree.gestion
        });
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setAsEstudio(String opportunityId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        dataTree.orden.Status = SegEmpUtil.CASE_STATUS_ESTUDIO;
        dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_ESTUDIO;
        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO);

        return updateRecords(null, new List<Case>{
                dataTree.orden, dataTree.gestion
        });

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult finishEstudio(String opportunityId) {
        DMLResult response = new DMLResult();
        dataTree = SegEmpUtil.getDataTree(opportunityId);

        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        dataTree.opp.StageName = SegEmpUtil.OPP_STATUS_COTIZACION;
        lOppsToUpdate.add(dataTree.opp);

        List<Case> lCasesToUpdate = new List<Case>();
        dataTree.orden.Status = SegEmpUtil.CASE_STATUS_COTIZACION;
        lCasesToUpdate.add(dataTree.orden);
        dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_SOLICITUD_MERCADO;
        lCasesToUpdate.add(dataTree.gestion);

        Savepoint sp = Database.setSavepoint();
        try {
            if (!lOppsToUpdate.isEmpty()) {
                update lOppsToUpdate;
            }
            if (!lCasesToUpdate.isEmpty()) {
                update lCasesToUpdate;
            }
            response.isSuccess = true;

        } catch (Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.message = e.getMessage() + ' - ' + e.getStackTraceString();
        }

        return response;
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setAsPdtGEE(String opportunityId, String caseId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);

        List<Opportunity> lOppsToUpdate = new List<Opportunity>();

        if (!isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_GEE)) {
            SegEmpUtil.addProcessStatus(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
            lOppsToUpdate.add(dataTree.opp);
        }

        List<Case> lCasesToUpdate = new List<Case>();
        if (!isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_GEE)) {
            SegEmpUtil.addProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
            lCasesToUpdate.add(dataTree.orden);
        }

        if (!isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GEE)) {
            SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
            lCasesToUpdate.add(dataTree.gestion);
        }

        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
                lCasesToUpdate.add(c);
            }
        }

        if (dataTree.formalizacion?.Id == caseId) {
            SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
            lCasesToUpdate.add(dataTree.formalizacion);
        }

        return updateRecords(lOppsToUpdate, lCasesToUpdate);

    }

    /**
     * @param opportunityId
     * @description This method is run when the opportunity owner answer doubts in
     * ordenes de trabajo which are in Pdt. GEE process status.
     * @return
     */
    @AuraEnabled(Cacheable=false)
    public static DMLResult removePdtGEE(String opportunityId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);

        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        SegEmpUtil.removeProcessStatus(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
        lOppsToUpdate.add(dataTree.opp);
        List<Case> lCasesToUpdate = new List<Case>();
        SegEmpUtil.removeProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
        SegEmpUtil.addProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
        lCasesToUpdate.add(dataTree.orden);
        SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
        lCasesToUpdate.add(dataTree.gestion);

        return updateRecords(lOppsToUpdate, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setAsPdtCliente(String opportunityId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);

        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        List<Case> lCasesToUpdate = new List<Case>();

        if (!SegEmpUtil.isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE)) {
            SegEmpUtil.addProcessStatus(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE);
            lOppsToUpdate.add(dataTree.opp);
        }

        if (!SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE)) {
            SegEmpUtil.addProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE);
            lCasesToUpdate.add(dataTree.orden);
        }

        return updateRecords(lOppsToUpdate, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult removePdtCliente(String opportunityId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);

        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        List<Case> lCasesToUpdate = new List<Case>();

        if (SegEmpUtil.isPSContained(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE)) {
            SegEmpUtil.removeProcessStatus(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE);
            lOppsToUpdate.add(dataTree.opp);
        }

        if (SegEmpUtil.isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE)) {
            SegEmpUtil.removeProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_CLIENTE);
            lCasesToUpdate.add(dataTree.orden);
        }

        return updateRecords(lOppsToUpdate, lCasesToUpdate);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult ordenRevised(String opportunityId, Boolean isOk) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();

        List<Case> lCasesToUpdate = new List<Case>();
        SegEmpUtil.removeProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
        SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
        if (isOk && !isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
            SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
        } else if (!isOk) {
            SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GEE);

            SegEmpUtil.addProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
            SegEmpUtil.addProcessStatus(dataTree.opp, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
            lOppsToUpdate.add(dataTree.opp);
        }
        lCasesToUpdate.add(dataTree.orden);
        lCasesToUpdate.add(dataTree.gestion);

        if (isOk) {
            for (Case c : dataTree.lSolicitudes) {
                if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_PDT_GEE)) {
                    SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
                    if (!isPSContained(c, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                        SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    }
                    lCasesToUpdate.add(c);
                } else if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE)) {
                    SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
                    if (!isPSContained(c, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                        SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    }
                    lCasesToUpdate.add(c);
                }
            }

            if (dataTree.formalizacion?.Id != null) {
                if (isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GEE)) {
                    SegEmpUtil.removeProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GEE);
                    if (!isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                        SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    }
                    lCasesToUpdate.add(dataTree.formalizacion);
                } else if (isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE)) {
                    SegEmpUtil.removeProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
                    if (!isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                        SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    }
                    lCasesToUpdate.add(dataTree.formalizacion);
                }
            }
        }

        return updateRecords(lOppsToUpdate, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult startWork(String opportunityId, String caseId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        if (dataTree.gestion.Id == caseId) {
            SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
        } else {
            Boolean areThereMorePendingSolicitudes = false;
            for (Case c : dataTree.lSolicitudes) {
                if (c.Id == caseId) {
                    SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_ENCURSO);
                    lCasesToUpdate.add(c);
                } else if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT)) {
                    areThereMorePendingSolicitudes = true;
                }
            }
            if (dataTree.formalizacion?.Id == caseId) {
                SegEmpUtil.removeProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_ENCURSO);

                lCasesToUpdate.add(dataTree.formalizacion);
            } else if (isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT)) {
                areThereMorePendingSolicitudes = true;
            }

            if (!areThereMorePendingSolicitudes) {
                SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
            }


        }

        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO);
        lCasesToUpdate.add(dataTree.gestion);

        return updateRecords(null, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult stopWork(String opportunityId, String caseId, Boolean pendingState) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        if (dataTree.gestion.Id == caseId) {
            SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO);
            if (pendingState) {
                SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
            }
            lCasesToUpdate.add(dataTree.gestion);

            for (Case c : dataTree.lSolicitudes) {
                if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                    SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_ENCURSO);
                    if (pendingState) {
                        SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    }
                    lCasesToUpdate.add(c);
                }
            }

        } else {
            Boolean areThereMoreInProgressSolicitudes = false;
            for (Case c : dataTree.lSolicitudes) {
                if (c.Id == caseId) {
                    SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_ENCURSO);
                    if (pendingState) {
                        SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    }
                    lCasesToUpdate.add(c);
                } else if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                    areThereMoreInProgressSolicitudes = true;
                }
            }
            if (dataTree.formalizacion?.Id == caseId) {
                SegEmpUtil.removeProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_ENCURSO);
                if (pendingState) {
                    SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                }
                lCasesToUpdate.add(dataTree.formalizacion);
            } else if (isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                areThereMoreInProgressSolicitudes = true;
            }

            if (!areThereMoreInProgressSolicitudes) {
                SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO);
                if (pendingState) {
                    SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                }
                lCasesToUpdate.add(dataTree.gestion);
            }
        }

        return updateRecords(null, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setAsPdtAseguradora(String opportunityId, String caseId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        List<Case> lCasesToUpdate = new List<Case>();

        Boolean ordenMod = false;

        if (dataTree.formalizacion?.Id == caseId) {
            dataTree.opp.StageName = SegEmpUtil.OPP_STATUS_ENFORMALIZACION;
            lOppsToUpdate.add(dataTree.opp);

            SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
            if (dataTree.formalizacion.Status == SegEmpUtil.CASE_STATUS_INICIOGESTION) {
                dataTree.formalizacion.Status = SegEmpUtil.CASE_STATUS_SOLICITUDDECOBERTURA;
                dataTree.orden.Status = SegEmpUtil.CASE_STATUS_FORMALIZANDO;
                ordenMod = true;
                dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_FORMALIZANDO;
                for (Case c : dataTree.lSolicitudes) {
                    if (dataTree.mPresupuestosByCase?.get(c.Id) != null) {
                        for (ABA_Detalle_presupuesto__c p : dataTree.mPresupuestosByCase.get(c.Id)) {
                            if (p.Accepted__c) {
                                c.Status = SegEmpUtil.CASE_STATUS_FORMALIZANDO;
                                lCasesToUpdate.add(c);
                            }
                        }
                    }
                }
            }
            lCasesToUpdate.add(dataTree.formalizacion);
        }

        if (ordenMod) {
            lCasesToUpdate.add(dataTree.orden);
        }

        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
        lCasesToUpdate.add(dataTree.gestion);

        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
                if (c.Status == SegEmpUtil.CASE_STATUS_INICIOGESTION) {
                    c.Status = SegEmpUtil.CASE_STATUS_ENGESTIONCONASEGURADORA;
                }
                lCasesToUpdate.add(c);
            }
        }


        return updateRecords(lOppsToUpdate, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult removePdtAseguradora(String opportunityId, String caseId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();

        Boolean areThereMorePendingSolicitudes = false;
        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
                SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA);
                lCasesToUpdate.add(c);
            } else if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA)) {
                areThereMorePendingSolicitudes = true;
            }
        }
        if (dataTree.formalizacion?.Id == caseId) {
            SegEmpUtil.removeProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
            SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA);
            lCasesToUpdate.add(dataTree.formalizacion);
        } else if (isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA)) {
            areThereMorePendingSolicitudes = true;
        }
        if (!areThereMorePendingSolicitudes) {
            SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
        }
        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA);
        lCasesToUpdate.add(dataTree.gestion);

        return updateRecords(null, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult infoAseguradoraRevised(String opportunityId, String caseId, Boolean isOk, Boolean isProposal) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        Boolean areThereMorePendingRevision = false;
        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA);
                if (isOk) {
                    if (isProposal) {
                        SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA);
                    } else if (!isPSContained(c, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                        SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                    }
                } else {
                    SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
                }
                lCasesToUpdate.add(c);
            } else if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA)) {
                areThereMorePendingRevision = true;
            }
        }
        if (dataTree.formalizacion?.Id == caseId) {
            SegEmpUtil.removeProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA);
            if (isOk) {
                if (isProposal) {
                    SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA);
                } else if (!isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                    SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                }
            } else {
                SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
            }
            lCasesToUpdate.add(dataTree.formalizacion);
        } else if (isPSContained(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA)) {
            areThereMorePendingRevision = true;
        }

        if (isOk) {
            Boolean aux1 = false;
            Boolean aux2 = false;
            if (!areThereMorePendingRevision) {
                aux1 = SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOASEGURADORA);
            }

            if (isProposal) {
                aux2 = SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA);
            } else if (!isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO)) {
                aux2 = SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
            }

            if (aux1 || aux2) {
                lCasesToUpdate.add(dataTree.gestion);
            }
        } else if (!isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA)) {
            SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_ASEGURADORA);
            lCasesToUpdate.add(dataTree.gestion);
        }

        return updateRecords(null, lCasesToUpdate);

    }

    //TODO: It is possible to change from valid to non-valid? If so, other proposals must be verified.
    @AuraEnabled(Cacheable=false)
    public static DMLResult proposalRevised(String opportunityId, String caseId, Boolean isOk) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        Boolean areThereMorePendingRevision = false;
        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA);
                if (isOk) {
                    c.ProposalStatus__c = SegEmpUtil.CASE_PROPOSALSTATUS_VALIDA;
                } else {
                    c.ProposalStatus__c = SegEmpUtil.CASE_PROPOSALSTATUS_INVALIDA;
                }
                lCasesToUpdate.add(c);
            } else if (isPSContained(c, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA)) {
                areThereMorePendingRevision = true;
            }
        }

        Boolean aux1 = false;
        Boolean aux2 = false;
        if (!areThereMorePendingRevision) {
            aux1 = SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_PROPUESTA);
        }

        if (isOk && dataTree.gestion.ProposalStatus__c != SegEmpUtil.CASE_PROPOSALSTATUS_VALIDA) {
            dataTree.gestion.ProposalStatus__c = SegEmpUtil.CASE_PROPOSALSTATUS_VALIDA;
            aux2 = true;
        } else if (!isOk && dataTree.gestion.ProposalStatus__c == SegEmpUtil.CASE_PROPOSALSTATUS_SINPROPUESTA) {
            dataTree.gestion.ProposalStatus__c = SegEmpUtil.CASE_PROPOSALSTATUS_INVALIDA;
            aux2 = true;
        }

        if (aux1 || aux2) {
            lCasesToUpdate.add(dataTree.gestion);
        }

        return updateRecords(null, lCasesToUpdate);

    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult generateQuote(String opportunityId, String caseId, String jsonPresupuesto) {
        DMLResult response = new DMLResult();
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_GENERACIONPRESUPUESTO;
        lCasesToUpdate.add(dataTree.gestion);


        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                c.Status = SegEmpUtil.CASE_STATUS_GENERACIONPRESUPUESTO;
                lCasesToUpdate.add(c);
                Savepoint sp = Database.setSavepoint();

                if (dataTree.quote == null) {
                    dataTree.quote = new Quote(
                            RecordTypeId = Schema.getGlobalDescribe().get('Quote').getDescribe().getRecordTypeInfosByDeveloperName().get('SegEmpPresupuesto').getRecordTypeId(),
                            Name = dataTree.opp.Name,
                            OpportunityId = dataTree.opp.Id,
                            Status = SegEmpUtil.QUOTE_STATUS_ENGENERACION,
                            CaseId__c = dataTree.gestion.Id
                    );
                    try {
                        insert dataTree.quote;
                    } catch (Exception e) {
                        Database.rollback(sp);
                        response.isSuccess = false;
                        response.message = e.getMessage() + ' - ' + e.getStackTraceString();
                    }
                } else {
                    dataTree.quote.Status = SegEmpUtil.QUOTE_STATUS_ENGENERACION;
                    try {
                        update dataTree.quote;
                    } catch (Exception e) {
                        Database.rollback(sp);
                        response.isSuccess = false;
                        response.message = e.getMessage() + ' - ' + e.getStackTraceString();
                    }
                }
                try {

                    List<ABA_Detalle_presupuesto__c> lPresupuestosToUpdate = new List<ABA_Detalle_presupuesto__c>();
                    if (dataTree.mPresupuestosByCase?.get(caseId) != null) {
                        for (ABA_Detalle_presupuesto__c p : dataTree.mPresupuestosByCase.get(caseId)) {
                            if (!p.Outdated__c) {
                                p.Outdated__c = true;
                                lPresupuestosToUpdate.add(p);
                            }
                        }
                    }

                    Map<String, Object> presupuesto = (Map<String, Object>) JSON.deserializeUntyped(jsonPresupuesto);
                    ABA_Detalle_presupuesto__c p = new ABA_Detalle_presupuesto__c();
                    p.ABA_Aseguradora__c = (String) c.ABA_Aseguradora__c;
                    p.ABA_DT_Fecha_de_efecto__c = Date.valueOf((String) presupuesto.get('fechaEfecto'));
                    p.ABA_DT_Fecha_de_vencimiento__c = Date.valueOf((String) presupuesto.get('fechaVencimiento'));
                    p.ABA_POR_Tasa__c = Decimal.valueOf((String) presupuesto.get('tasa'));
                    p.ABA_DIV_Impuesto_y_Consorcio__c = Decimal.valueOf((String) presupuesto.get('impuesto'));
                    p.ABA_DIV_Prima_Neta__c = Decimal.valueOf((String) presupuesto.get('primaNeta'));
                    p.ABA_DIV_Importe_Total_prima__c = Decimal.valueOf((String) presupuesto.get('importePrimaTotal'));
                    p.ABA_TXT_Comentario_BackOffice__c = (String) presupuesto.get('comentario');
                    p.Name = c.CaseNumber + '-DT-' + c.ABA_Aseguradora__r.Name;
                    p.ABA_MD_Quote__c = dataTree.quote.Id;
                    p.Case__c = c.Id;
                    p.ABA_BO_Presentado_Cliente__c = false;
                    p.ABA_BO_Seleccionado__c = false;
                    insert p;
                    if (dataTree.mPresupuestosByCase == null) {
                        dataTree.mPresupuestosByCase = new Map<String, List<ABA_Detalle_presupuesto__c>>();
                    }
                    if (!dataTree.mPresupuestosByCase.containsKey(c.Id)) {
                        dataTree.mPresupuestosByCase.put(c.Id, new List<ABA_Detalle_presupuesto__c>());
                    }
                    dataTree.mPresupuestosByCase.get(c.Id).add(p);

                    response = updateRecords(null, lCasesToUpdate, null, lPresupuestosToUpdate);
                    if (response.isSuccess == false) {
                        Database.rollback(sp);
                    }
                } catch (Exception e) {
                    Database.rollback(sp);
                    response.isSuccess = false;
                    response.message = e.getMessage() + ' - ' + e.getStackTraceString();
                }
            }
        }

        return response;
    }

    @AuraEnabled(Cacheable=false)
    public static List<ABA_Detalle_presupuesto__c> getPresupuestosPresentados(String opportunityId) {
        List<ABA_Detalle_presupuesto__c> response = [
                SELECT Id, Name
                FROM ABA_Detalle_presupuesto__c
                WHERE ABA_BO_Presentado_Cliente__c = TRUE AND Outdated__c = FALSE
                AND ABA_MD_Quote__r.OpportunityId = :opportunityId
        ];
        return response;
    }

    @AuraEnabled(Cacheable=false)
    public static String getPolizaRecordTypeId() {
        return SegEmpUtil.POLIZA_SEGUROS_RT_ID;
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult notifyPlacement(String opportunityId, String notificationType, String acceptedPresupuestoId, String jsonPoliza) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        List<Case> lCasesToUpdate = new List<Case>();
        List<Quote> lQuotesToUpdate = new List<Quote>();
        if (notificationType == 'infoRequest') {
            if (!isPSContained(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE)) {
                SegEmpUtil.addProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
                lCasesToUpdate.add(dataTree.orden);
            }
            if (!isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE)) {
                SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_PDT_REVISION_INFOGEE);
                lCasesToUpdate.add(dataTree.gestion);
            }
        } else if (notificationType == 'accepted') {
            return createPoliza(acceptedPresupuestoId, jsonPoliza);
        }

        return updateRecords(lOppsToUpdate, lCasesToUpdate, lQuotesToUpdate, null);
    }

    public static DMLResult createPoliza(String acceptedPresupuestoId, String jsonPoliza) {
        DMLResult response = new DMLResult();
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        List<Case> lCasesToUpdate = new List<Case>();
        List<Quote> lQuotesToUpdate = new List<Quote>();
        List<ABA_Detalle_presupuesto__c> lPresupuestosToUpdate = new List<ABA_Detalle_presupuesto__c>();

        dataTree.opp.StageName = SegEmpUtil.OPP_STATUS_ORDENEMISION;
        lOppsToUpdate.add(dataTree.opp);

        dataTree.orden.Status = SegEmpUtil.CASE_STATUS_ORDENEMISION;
        lCasesToUpdate.add(dataTree.orden);
        dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_ORDENEMISION;
        lCasesToUpdate.add(dataTree.gestion);
        Case currentCase;
        ABA_Detalle_presupuesto__c currentPresupuesto;
        for (Case c : dataTree.lSolicitudes) {
            if (dataTree.mPresupuestosByCase?.get(c.Id) != null) {
                for (ABA_Detalle_presupuesto__c p : dataTree.mPresupuestosByCase.get(c.Id)) {
                    if (p.Id == acceptedPresupuestoId) {
                        c.Status = SegEmpUtil.CASE_STATUS_ORDENEMISION;
                        lCasesToUpdate.add(c);
                        currentCase = c;
                        currentPresupuesto = p;
                        p.Accepted__c = true;
                        lPresupuestosToUpdate.add(p);
                    } else {
                        if (!p.Outdated__c) {
                            p.Outdated__c = true;
                            lPresupuestosToUpdate.add(p);
                        }
                    }
                }
            }
            if (!lCasesToUpdate.contains(c)) {
                if (c.Status != SegEmpUtil.CASE_STATUS_CERRADO) {
                    c.Status = SegEmpUtil.CASE_STATUS_CERRADO;
                    //todo poner motivo de estado
                    lCasesToUpdate.add(c);
                }
            }
        }


        List<Product2> lProduct2s = [
                SELECT ID, ABA_Aseguradora__c, ABA_PIC_Ramo__c, Family, ABA_TX_CIA_ALIAS__c, ABA_TX_PRO_NOMBRE__c, ABA_TX_RAM_ALIAS__c, ABA_TX_PRO_ALIAS__c, Name
                FROM Product2
                WHERE Family = 'Seguros de empresa //ABANCA'
                AND ABA_PIC_Ramo__c = :dataTree.opp.ABA_LIS_Ramo__c
                AND ABA_Aseguradora__c = :currentPresupuesto.ABA_Aseguradora__c
        ];

        Map<String, Object> polizaData = (Map<String, Object>) JSON.deserializeUntyped(jsonPoliza);
        ABA_Poliza__c poliza = new ABA_Poliza__c();
        poliza.RecordTypeId = SegEmpUtil.POLIZA_SEGUROS_RT_ID;
        poliza.OpportunityId__c = dataTree.opp.Id;
        poliza.ABA_DT_Fecha_de_emisi_n__c = Date.valueOf((String) polizaData.get('ABA_DT_Fecha_de_emisi_n__c'));
        if (polizaData.get('ABA_Fecha_primer_efecto__c') != null) {
            poliza.ABA_Fecha_primer_efecto__c = Date.valueOf((String) polizaData.get('ABA_Fecha_primer_efecto__c'));
        }
        poliza.ABA_LIS_Periodicidad_cobro__c = (String) polizaData.get('ABA_LIS_Periodicidad_cobro__c');
        poliza.ABA_TXT_Descripci_n_riesgo__c = (String) polizaData.get('ABA_TXT_Descripci_n_riesgo__c');
        poliza.ABA_TXT_Entidad_Beneficiaria__c = (String) polizaData.get('ABA_TXT_Entidad_Beneficiaria__c');
        poliza.ABA_TXT_Oficina_asociada__c = (String) polizaData.get('ABA_TXT_Oficina_asociada__c');
        poliza.ABA_TXT_Prestamo__c = (String) polizaData.get('ABA_TXT_Prestamo__c');
        poliza.ABA_TXT_Tipo_riesgo__c = (String) polizaData.get('ABA_TXT_Tipo_riesgo__c');
        poliza.Forma_de_pago__c = (String) polizaData.get('Forma_de_pago__c');
        poliza.N_de_cuenta__c = (String) polizaData.get('N_de_cuenta__c');
        poliza.ABA_Aseguradora__c = currentCase.ABA_Aseguradora__c;
        poliza.ABA_Cliente__c = currentCase.AccountId;
        poliza.ABA_DIV_Prima_neta_anual__c = currentPresupuesto.ABA_DIV_Prima_Neta__c;
        poliza.ABA_DIV_Prima_total_anual__c = currentPresupuesto.ABA_DIV_Importe_Total_prima__c;
        poliza.ABA_Fecha_de_efecto__c = currentPresupuesto.ABA_DT_Fecha_de_efecto__c;
        poliza.ABA_Fecha_de_vencimiento__c = currentPresupuesto.ABA_DT_Fecha_de_vencimiento__c;
        poliza.ABA_LIS_Estado__c = 'En vigor';
        poliza.ABA_LIS_Estado_del_recibo__c = 'NO PAGADO';
        poliza.ABA_LIS_Ramo__c = dataTree.opp.ABA_LIS_Ramo__c;
        poliza.Name = '20809999SF' + currentCase.CaseNumber;


        if (!lProduct2s.isEmpty()) {
            Product2 p = lProduct2s[0];
            poliza.ABA_TX_CIA_ALIAS__c = p.ABA_TX_CIA_ALIAS__c;
            poliza.ABA_TX_PRO_NOMBRE__c = p.ABA_TX_PRO_NOMBRE__c;
            poliza.ABA_TX_PRO_ALIAS__c = p.ABA_TX_PRO_ALIAS__c;
            poliza.ABA_TX_RAM_ALIAS__c = p.ABA_TX_RAM_ALIAS__c;

        } else {
            response.isSuccess = false;
            response.message = 'Product not found';
            return response;
        }

        Case f = new Case();
        f.OwnerId = dataTree.gestion.OwnerId;
        f.RecordTypeId = SegEmpUtil.NUEVONEGOCIO_FORMALIZACION_RT_ID;
        f.ABA_Aseguradora__c = currentPresupuesto.ABA_Aseguradora__c;
        f.ABA_DATE_Fecha_de_efecto__c = currentPresupuesto.ABA_DT_Fecha_de_efecto__c;
        f.ABA_DATE_Fecha_de_vencimiento__c = currentPresupuesto.ABA_DT_Fecha_de_vencimiento__c;
        f.ABA_LIS_Ramo__c = dataTree.opp.ABA_LIS_Ramo__c;
        f.ABA_Opportunity__c = dataTree.opp.Id;
        f.ABA_TXT_Poliza__c = poliza.Id;
        f.AccountId = currentCase.AccountId;
        f.Description = poliza.ABA_TXT_Descripci_n_riesgo__c;
        f.Origin = 'ABANCA Seguros';
        f.Priority = 'Medium';
        f.Status = SegEmpUtil.CASE_STATUS_INICIOGESTION;
        f.Subject = 'Formalizacion ' + dataTree.opp.Name;
        f.ParentId = dataTree.gestion.Id;
        //TODO: is this needed?
        f.Deadline__c = dataTree.orden.Deadline__c;
        f.DeadlineReason__c = dataTree.orden.DeadlineReason__c;

        Savepoint sp = Database.setSavepoint();

        try {
            insert f;
            poliza.ABA_Caso_de_Formalizacion__c = f.Id;
            insert poliza;
        } catch (Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.message = e.getMessage() + ' - ' + e.getStackTraceString();
            return response;
        }

        dataTree.quote.Status = SegEmpUtil.QUOTE_STATUS_ACEPTADO;
        dataTree.quote.ABA_CUR_Prima_neta__c = currentPresupuesto.ABA_DIV_Prima_Neta__c;
        dataTree.quote.ExpirationDate = poliza.ABA_Fecha_de_efecto__c;
        lQuotesToUpdate.add(dataTree.quote);

        response = updateRecords(lOppsToUpdate, lCasesToUpdate, lQuotesToUpdate, lPresupuestosToUpdate);

        if (!response.isSuccess) {
            Database.rollback(sp);
        }

        return response;
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult quoteModification(String opportunityId, String caseId, String modificationType) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        List<Case> lCasesToUpdate = new List<Case>();
        List<Quote> lQuotesToUpdate = new List<Quote>();
        List<ABA_Detalle_presupuesto__c> lPresupuestosToUpdate = new List<ABA_Detalle_presupuesto__c>();

        Boolean areThereMoreValidProposals = false;
        Boolean gestionModified = false;
        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                if (c.Status != SegEmpUtil.CASE_STATUS_ENGESTIONCONASEGURADORA) {
                    c.Status = SegEmpUtil.CASE_STATUS_ENGESTIONCONASEGURADORA;
                }

                if (modificationType == 'recotizar') {
                    c.ProposalStatus__c = SegEmpUtil.CASE_PROPOSALSTATUS_PDT_RECOTIZACION;
                    SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_RECOTIZACION);
                    if (!SegEmpUtil.isPSContained(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_RECOTIZACION)) {
                        SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_RECOTIZACION);
                        gestionModified = true;
                    }
                } else if (modificationType == 'ajustar') {
                    c.ProposalStatus__c = SegEmpUtil.CASE_PROPOSALSTATUS_PDT_AJUSTE;
                }

                lCasesToUpdate.add(c);

            } else {
                if (!c.IsClosed && c.ProposalStatus__c == SegEmpUtil.CASE_PROPOSALSTATUS_VALIDA) {
                    areThereMoreValidProposals = true;
                }
            }

            for (ABA_Detalle_presupuesto__c p : dataTree.mPresupuestosByCase.get(c.Id)) {
                if (c.Id == caseId) {
                    p.Outdated__c = true;
                }
                lPresupuestosToUpdate.add(p);
            }
        }


        if (!areThereMoreValidProposals) {
            dataTree.gestion.ProposalStatus__c = SegEmpUtil.CASE_PROPOSALSTATUS_INVALIDA;
            gestionModified = true;
        }

        if (dataTree.opp.StageName != SegEmpUtil.OPP_STATUS_COTIZACION) {
            dataTree.opp.StageName = SegEmpUtil.OPP_STATUS_COTIZACION;
            lOppsToUpdate.add(dataTree.opp);
        }
        if (dataTree.orden.Status != SegEmpUtil.CASE_STATUS_COTIZACION) {
            dataTree.orden.Status = SegEmpUtil.CASE_STATUS_COTIZACION;
            lCasesToUpdate.add(dataTree.orden);
        }
        if (dataTree.gestion.Status != SegEmpUtil.CASE_STATUS_SOLICITUD_MERCADO) {
            dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_SOLICITUD_MERCADO;
            gestionModified = true;
        }
        if (gestionModified) {
            lCasesToUpdate.add(dataTree.gestion);
        }

        dataTree.quote.Status = SegEmpUtil.QUOTE_STATUS_ENGENERACION;
        lQuotesToUpdate.add(dataTree.quote);

        return updateRecords(lOppsToUpdate, lCasesToUpdate, lQuotesToUpdate, lPresupuestosToUpdate);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult reopenSolicitud(String opportunityId, String caseId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        for (Case c : dataTree.lSolicitudes) {
            if (c.Id == caseId) {
                c.Status = SegEmpUtil.CASE_STATUS_ENGESTIONCONASEGURADORA;
                c.ABA_LIS_Motivo_del_Estado__c = null;
                c.ABA_LIS_Situacion__c = null;
                c.ABA_TX_Comentarios_Estado__c = null;
                SegEmpUtil.addProcessStatus(c, SegEmpUtil.PROCESSSTATUS_PDT_GESTIONPLACEMENT);
                lCasesToUpdate.add(c);
            }
        }
        return updateRecords(null, lCasesToUpdate);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult coberturaFinished(String opportunityId, Boolean docReceived) {

        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();

        if (docReceived) {
            dataTree.formalizacion.Status = SegEmpUtil.CASE_STATUS_ENREVISIONDOC;
        } else {
            dataTree.formalizacion.Status = SegEmpUtil.CASE_STATUS_COBERTURAACEPTADA_PENDIENTEDOC;
        }
        lCasesToUpdate.add(dataTree.formalizacion);

        return updateRecords(null, lCasesToUpdate);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult coberturaReceivedDoc(String opportunityId) {

        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();

        dataTree.formalizacion.Status = SegEmpUtil.CASE_STATUS_ENREVISIONDOC;
        lCasesToUpdate.add(dataTree.formalizacion);

        return updateRecords(null, lCasesToUpdate);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setAsComputado(String opportunityId, Boolean isManual) {
        DMLResult response = new DMLResult();
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        //todo notificar en la oportunidad?
        //todo los computados son los que tienen la fecha rellena, hace falta poner un subestado o podríamos funcionar con eso?
        List<Case> lCasesToUpdate = new List<Case>();
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();

        Savepoint sp = Database.setSavepoint();
        if (dataTree.poliza.Fecha_de_env_o_a_Visual_SEG__c == null) {
            dataTree.poliza.Fecha_de_env_o_a_Visual_SEG__c = System.today();
            SegEmpUtil.addProcessStatus(dataTree.orden, SegEmpUtil.PROCESSSTATUS_COMPUTADO);
            SegEmpUtil.addProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_COMPUTADO);
            SegEmpUtil.addProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_COMPUTADO);
            if (isManual) {
                lCasesToUpdate.add(dataTree.orden);
                lCasesToUpdate.add(dataTree.gestion);
                lCasesToUpdate.add(dataTree.formalizacion);
            }
            try {
                update dataTree.poliza;
            } catch (Exception e) {
                Database.rollback(sp);
                response.isSuccess = false;
                response.message = e.getMessage() + ' - ' + e.getStackTraceString();
                return response;
            }
        }

        if (!isManual) {
            dataTree.opp.StageName = SegEmpUtil.OPP_STATUS_ENTREGADAPOLIZA;
            lOppsToUpdate.add(dataTree.opp);
            dataTree.orden.Status = SegEmpUtil.CASE_STATUS_ENTREGADAPOLIZA;
            lCasesToUpdate.add(dataTree.orden);
            dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_ENTREGADAPOLIZA;
            lCasesToUpdate.add(dataTree.gestion);
            dataTree.formalizacion.Status = SegEmpUtil.CASE_STATUS_ENTREGADAPOLIZA;
            lCasesToUpdate.add(dataTree.formalizacion);
        }
        response = updateRecords(lOppsToUpdate, lCasesToUpdate);

        if (!response.isSuccess) {
            Database.rollback(sp);
        }

        return response;
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setPolizaAsRevisedByGEE(String opportunityId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();

        dataTree.opp.StageName = SegEmpUtil.OPP_STATUS_POLIZAREVISADAGEE;
        lOppsToUpdate.add(dataTree.opp);

        dataTree.orden.Status = SegEmpUtil.CASE_STATUS_POLIZAREVISADAGEE;
        lCasesToUpdate.add(dataTree.orden);

        dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_POLIZAREVISADAGEE;
        lCasesToUpdate.add(dataTree.gestion);

        dataTree.formalizacion.Status = SegEmpUtil.CASE_STATUS_POLIZAREVISADAGEE;
        lCasesToUpdate.add(dataTree.formalizacion);

        //todo se indica algo más en la póliza?

        return updateRecords(lOppsToUpdate, lCasesToUpdate);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult setAsFormalizado(String opportunityId) {
        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Case> lCasesToUpdate = new List<Case>();
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();

        dataTree.opp.StageName = SegEmpUtil.OPP_STATUS_FORMALIZADA;
        lOppsToUpdate.add(dataTree.opp);

        dataTree.orden.Status = SegEmpUtil.CASE_STATUS_FORMALIZADA;
        lCasesToUpdate.add(dataTree.orden);

        dataTree.gestion.Status = SegEmpUtil.CASE_STATUS_FORMALIZADA;
        SegEmpUtil.removeProcessStatus(dataTree.gestion, SegEmpUtil.PROCESSSTATUS_ENCURSO);
        lCasesToUpdate.add(dataTree.gestion);

        dataTree.formalizacion.Status = SegEmpUtil.CASE_STATUS_FORMALIZADA;
        SegEmpUtil.removeProcessStatus(dataTree.formalizacion, SegEmpUtil.PROCESSSTATUS_ENCURSO);
        lCasesToUpdate.add(dataTree.formalizacion);

        for (Case c : dataTree.lSolicitudes) {
            if (dataTree.mPresupuestosByCase?.get(c.Id) != null) {
                for (ABA_Detalle_presupuesto__c p : dataTree.mPresupuestosByCase.get(c.Id)) {
                    if (p.Accepted__c) {
                        c.Status = SegEmpUtil.CASE_STATUS_FORMALIZADA;
                        SegEmpUtil.removeProcessStatus(c, SegEmpUtil.PROCESSSTATUS_ENCURSO);
                        lCasesToUpdate.add(c);
                    }
                }
            }
        }

        return updateRecords(lOppsToUpdate, lCasesToUpdate);
    }

    @AuraEnabled(Cacheable=false)
    public static DMLResult closeCases(String opportunityId, String caseId, String jsonData) {
        Map<String, Object> closingData = (Map<String, Object>) JSON.deserializeUntyped(jsonData);

        //todo qué pasa con quote?
        //todo qué pasa con campo estado propuesta?

        dataTree = SegEmpUtil.getDataTree(opportunityId);
        List<Opportunity> lOppsToUpdate = new List<Opportunity>();
        List<Case> lCasesToUpdate = new List<Case>();
        List<Quote> lQuotesToUpdate = new List<Quote>();
        List<ABA_Detalle_presupuesto__c> lPresupuestosToUpdate = new List<ABA_Detalle_presupuesto__c>();

        if (dataTree.gestion.Id == caseId || dataTree.orden.Id == caseId) {
            //qué pasa con la formalización? tiene otros cierres diferentes.
            //borrar alertas
            dataTree.opp.StageName = 'Cancelado';
            dataTree.opp.ABA_FLD_P_motivoCerradaPerdida__c = (String) closingData.get('ABA_LIS_Motivo_del_Estado__c');
            dataTree.opp.Situacion__c = (String) closingData.get('ABA_LIS_Situacion__c');
            clearProcessStatus(dataTree.opp);
            lOppsToUpdate.add(dataTree.opp);

            dataTree.gestion.Status = (String) closingData.get('Status');
            dataTree.gestion.ABA_LIS_Motivo_del_Estado__c = (String) closingData.get('ABA_LIS_Motivo_del_Estado__c');
            dataTree.gestion.ABA_LIS_Situacion__c = (String) closingData.get('ABA_LIS_Situacion__c');
            dataTree.gestion.ABA_TX_Comentarios_Estado__c = (String) closingData.get('ABA_TX_Comentarios_Estado__c');
            clearProcessStatus(dataTree.gestion);
            lCasesToUpdate.add(dataTree.gestion);
            dataTree.orden.Status = (String) closingData.get('Status');
            dataTree.orden.ABA_LIS_Motivo_del_Estado__c = (String) closingData.get('ABA_LIS_Motivo_del_Estado__c');
            dataTree.orden.ABA_LIS_Situacion__c = (String) closingData.get('ABA_LIS_Situacion__c');
            dataTree.orden.ABA_TX_Comentarios_Estado__c = (String) closingData.get('ABA_TX_Comentarios_Estado__c');
            clearProcessStatus(dataTree.orden);
            lCasesToUpdate.add(dataTree.orden);

            if (!dataTree.lSolicitudes.isEmpty()) {
                for (Case c : dataTree.lSolicitudes) {
                    if (!c.IsClosed) {
                        c.Status = (String) closingData.get('Status');
                        c.ABA_LIS_Motivo_del_Estado__c = (String) closingData.get('ABA_LIS_Motivo_del_Estado__c');
                        c.ABA_LIS_Situacion__c = (String) closingData.get('ABA_LIS_Situacion__c');
                        c.ABA_TX_Comentarios_Estado__c = (String) closingData.get('ABA_TX_Comentarios_Estado__c');
                        clearProcessStatus(c);
                        lCasesToUpdate.add(c);
                    }
                    if (dataTree.mPresupuestosByCase?.get(c.Id) != null) {
                        for (ABA_Detalle_presupuesto__c p : dataTree.mPresupuestosByCase.get(c.Id)) {
                            if (!p.Outdated__c) {
                                p.Outdated__c = true;
                                lPresupuestosToUpdate.add(p);
                            }
                        }
                    }
                }
            }

            if (dataTree.quote?.Id != null) {
                //todo modificar por label propia
                dataTree.quote.Status = SegEmpUtil.CASE_STATUS_CERRADO;
                lQuotesToUpdate.add(dataTree.quote);
            }

        }

        else if (dataTree.formalizacion?.Id == caseId) {
            dataTree.formalizacion.Status = (String) closingData.get('Status');
            dataTree.formalizacion.ABA_LIS_Motivo_del_Estado__c = (String) closingData.get('ABA_LIS_Motivo_del_Estado__c');
            dataTree.formalizacion.ABA_LIS_Situacion__c = (String) closingData.get('ABA_LIS_Situacion__c');
            dataTree.formalizacion.ABA_TX_Comentarios_Estado__c = (String) closingData.get('ABA_TX_Comentarios_Estado__c');
            clearProcessStatus(dataTree.formalizacion);
            lCasesToUpdate.add(dataTree.formalizacion);

        }

        else if (!dataTree.lSolicitudes.isEmpty()) {
            for (Case c : dataTree.lSolicitudes) {
                if (c.Id == caseId) {
                    c.Status = (String) closingData.get('Status');
                    c.ABA_LIS_Motivo_del_Estado__c = (String) closingData.get('ABA_LIS_Motivo_del_Estado__c');
                    c.ABA_LIS_Situacion__c = (String) closingData.get('ABA_LIS_Situacion__c');
                    c.ABA_TX_Comentarios_Estado__c = (String) closingData.get('ABA_TX_Comentarios_Estado__c');
                    clearProcessStatus(c);
                    lCasesToUpdate.add(c);
                    if (dataTree.mPresupuestosByCase?.get(c.Id) != null) {
                        for (ABA_Detalle_presupuesto__c p : dataTree.mPresupuestosByCase?.get(c.Id)) {
                            if (!p.Outdated__c) {
                                p.Outdated__c = true;
                                lPresupuestosToUpdate.add(p);
                            }
                        }
                    }
                }
            }
        }

        LwcSegEmpWorkPannelController.DMLResult result = LwcSegEmpWorkPannelController.updateRecords(lOppsToUpdate, lCasesToUpdate, lQuotesToUpdate, lPresupuestosToUpdate);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getNumeroAlertasActivas(Id caseId) {
        Integer countAlertas = [
                SELECT COUNT()
                FROM ABA_OBJ_Gestion__c
                WHERE ABA_LIS_Estado__c = 'Abierta'
                AND ABA_REL_Ticket__c = :caseId
        ];

        return countAlertas == null ? 0 : countAlertas;
    }

    public static DMLResult updateRecords(List<Opportunity> lOppsToUpdate, List<Case> lCasesToUpdate) {
        DMLResult response = new DMLResult();

        Savepoint sp = Database.setSavepoint();
        try {
            if (lOppsToUpdate != null && !lOppsToUpdate.isEmpty()) {
                update lOppsToUpdate;
            }
            if (lCasesToUpdate != null && !lCasesToUpdate.isEmpty()) {
                update lCasesToUpdate;
            }
            response.isSuccess = true;

        } catch (Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.message = e.getMessage() + ' - ' + e.getStackTraceString();
        }

        return response;
    }

    public static DMLResult updateRecords(List<Opportunity> lOppsToUpdate, List<Case> lCasesToUpdate, List<Quote> lQuotesToUpdate, List<ABA_Detalle_presupuesto__c> lPresupuestosToUpdate) {
        DMLResult response = new DMLResult();

        Savepoint sp = Database.setSavepoint();
        try {
            if (lOppsToUpdate != null && !lOppsToUpdate.isEmpty()) {
                update lOppsToUpdate;
            }
            if (lCasesToUpdate != null && !lCasesToUpdate.isEmpty()) {
                update lCasesToUpdate;
            }
            if (lQuotesToUpdate != null && !lQuotesToUpdate.isEmpty()) {
                update lQuotesToUpdate;
            }
            if (lPresupuestosToUpdate != null && !lPresupuestosToUpdate.isEmpty()) {
                update lPresupuestosToUpdate;
            }

            response.isSuccess = true;

        } catch (Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.message = e.getMessage() + ' - ' + e.getStackTraceString();
        }

        return response;
    }

    public static Boolean isPSContained(SObject obj, String subStatus) {
        return SegEmpUtil.isPSContained(obj, subStatus);
    }

    public static void clearProcessStatus(SObject obj) {
        Boolean isRecotizado = false;
        Boolean isComputado = false;
        if (isPSContained(obj, SegEmpUtil.PROCESSSTATUS_RECOTIZACION)) {
            isRecotizado = true;
        }
        if (isPSContained(obj, SegEmpUtil.PROCESSSTATUS_COMPUTADO)) {
            isComputado = true;
        }
        obj.put('ProcessStatus__c', null);
        if (isRecotizado) {
            SegEmpUtil.addProcessStatus(obj, SegEmpUtil.PROCESSSTATUS_RECOTIZACION);
        }
        if (isComputado) {
            SegEmpUtil.addProcessStatus(obj, SegEmpUtil.PROCESSSTATUS_COMPUTADO);
        }
    }

    public class DMLResult {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String message;
    }
}