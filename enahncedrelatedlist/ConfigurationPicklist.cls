/**
 * @description       : 
 * @author            : grico
 * @group             : 
 * @last modified on  : 02-24-2022
 * @last modified by  : Clarcat
**/

public with sharing class ConfigurationPicklist extends VisualEditor.DynamicPickList{
    List<Related_List__mdt	> options = Related_List__mdt.getAll().values();

    public override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(options[0].label, options[0].DeveloperName);
        return defaultValue;
    }
    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
        for (Related_List__mdt config : options){
            myValues.addRow(new VisualEditor.DataRow( config.label, config.DeveloperName));
        }        
        return myValues;
    }
}