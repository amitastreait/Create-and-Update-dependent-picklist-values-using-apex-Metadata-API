public class UpdatePicklist{
    
    /* prepare the variables to parse the .csv file */
    public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public String[] csvFileLines{get;set;}
    public List<account> acclist{get;set;}
    
    public UpdatePicklist(){
        csvFileLines = new String[]{};
    }
    
    /* 
        Prepare the Org to call the Metadata API on the current user permissions 
    */
    public static MetadataService.MetadataPort createService(){
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }
    
    
    //Update Country and State Field-----
    public PageReference updatePicklistField_Product_Line() {
        /* query the data from the Custom Metdata and put into the Map */
        List<Country_State_Forecast__mdt> lstProduct_Line = new List<Country_State_Forecast__mdt>();
        lstProduct_Line = [Select Id,MasterLabel From Country_State_Forecast__mdt LIMIT 1];
        
        MetadataService.MetadataPort service = createService();
        /* 
            Create customfield Object to update the picklist 
        */
        MetadataService.CustomField customField = new MetadataService.CustomField(); 
        customField.fullName = 'Account.State__c';
        customField.label = 'State';
        customField.type_x = 'Picklist'; 
        
        /* Prepare the picklist with Controlling pickList field */
        MetadataService.Picklist pt = new metadataservice.Picklist();
        pt.sorted= true;
        pt.picklistValues = new list<metadataservice.PicklistValue>();
        /* API Name of controlling field if picklist has contrlloing field this must be asssigned
           else field dependency will be deleted!
        */
        pt.controllingField='Country__c'; 
        
        /* Prepare the Map with Dependent Value and Controlling picklist Values */
        
        Map<String, List<String>> mapDepValContVal = new Map<String, List<String>>();
        
        /* if using .csv file then remove commnent from the below line */
        /*
            mapDepValContVal = parseCSVFile();
        */
        //mapDepValContVal.put('Australia');
        
        /* if using .csv file then put commnent from the below line Starte from here to  */
        for(Country_State_Forecast__mdt prdLine : lstProduct_Line){
            List<String> lstControllingValues = mapDepValContVal.get(prdLine.MasterLabel);
            if(lstControllingValues == null)
                  lstControllingValues = new list<String>();
            lstControllingValues.add(prdLine.MasterLabel);
            mapDepValContVal.put('ACT', lstControllingValues);
            mapDepValContVal.put('SA', lstControllingValues);
        }
        mapDepValContVal.put('Burgenland', new List<String>{'Australia'});
        
        /* if using .csv file then put commnent from the below line End to the above line */
        
        for(String strDepVal : mapDepValContVal.keySet()){
            MetadataService.PicklistValue plValue = new MetadataService.PicklistValue();
            plValue.fullName=strDepVal; // Dependent picklist value
            plValue.default_x=false ; // Set default to false
            /* define which depedent picklist values will be available
               to which Controlling picklist values
            */
            plValue.controllingFieldValues = mapDepValContVal.get(strDepVal);
            pt.picklistValues.add(plValue);       
        } 
        customField.picklist = pt ;       
        
        MetadataService.SaveResult[] results = service.updateMetadata(new List<MetadataService.Metadata> {customField});
        
        return null;
    }
    
    /* method to parse the .csv file */
    public Map<String, List<String>> parseCSVFile(){
       
       Map<String, List<String>> DepValContValue_Map = new Map<String, List<String>>();
       try{
           csvAsString = csvFileBody.toString();
           csvFileLines = csvAsString.split('\n'); 
           /* iterate throught .csv file and prepare the MAP */
           for(Integer i=1;i<csvFileLines.size();i++){
              String[] csvRecordData = csvFileLines[i].split(',');
              String dependentValue = csvRecordData[1];
              String controllingValue = csvRecordData[0];
              if(!DepValContValue_Map.containsKey(dependentValue)){
                  DepValContValue_Map.put(dependentValue, new List<String> {controllingValue});
              }else{
                  List<String> controllingValueList = DepValContValue_Map.get(dependentValue);
                  controllingValueList.add(controllingValue);
                  DepValContValue_Map.put(dependentValue, controllingValueList);
              }
           }
        }catch (Exception e){
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importing data Please make sure input csv file is correct');
            ApexPages.addMessage(errorMessage);
        }
        
        return DepValContValue_Map;  
    }
    
}
