/*
 * NextStepFuture Class Description:
 * 
 * Question 1: Create a future method that updates all account and opportunities next step to 'Meeting in the future'
 * Question 2: Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
 * 
 * Benefits of using future methods:
 * 
 * 1. Asynchronous Processing: Allows long-running operations to be handled in the background, freeing up resources.
 * 2. Governor Limit Management: Asynchronous methods have a separate set of limits, providing more flexibility.
 * 3. User Experience Enhancement: Improves responsiveness in user interfaces by offloading processes to the background.
 * 4. Mixed DML Operations Handling: Helps overcome Mixed DML errors by allowing updates on setup and non-setup objects.
 * 5. Enhanced Integration Capabilities: Useful for making callouts to external systems without blocking the user interaction.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
 * 
 * Note: The class below contains placeholders for implementing a future method to update accounts and opportunities.
 *       The accompanying test class 'AsynchronousTest' should also be updated to test this method.
 */

 /*
1. Any Asynchronous method code runs it is registered in AsyncApexJob.  
2. Once it is registered, we will get JobId.
3. We can use this JobId to query the job.
4. If we want to query the job, we need to use System.enqueueJob(new QueueableClassName)

Future Method:
    1. If a transaction has any long running statements, and if these statements doesn't have any dependency on 
    rest of the statements then we can run those long running operations independently from the rest of the 
    transactions. By Using Future Method
    2. Long Running Operations [Ex: Webservices Calls, Bulk DML Operations]
    3. Rules to define future methods:
        1. All future methods should have @future annotation.
        2. All future methods should be static.
        3. All future methods should be void.
        4. Only primitive variables can be passed as parameters.
        5. When we invoke the future method they will be added to the queue and from the queue they will be executed.
        6. If you want to invoke webservices from the future method then define 
            @future(callout=true)
        7. Any Asynchronous Job that is running in Salesforce will be registered with AsyncApexJob object.
        8. How to track the status of the job:
            1. Write a SOQL Query on AsyncApexJob.
            2. Declarative way to check the status:
                1. Setup > Monitor > Jobs > Apex Jobs
        9. Future methods can be used to increase the governing limits.
    Drawbacks:
        1. Future method will not return jobId in the APEX code.
        2. Future method cannot be called from another future method.
        3. Future method will not support sObjects as parameters.

    Limits:
        1. Within in a trasaction we can call 50 Future methods.
    
    WorkAround:
        1. When we have requirement to pass object as parameter to future methos how will we do it:
            a. Pass RecordId instead of record.
            b. Serialize the sObject as String using JSON/XML and pass string as parameter to future method.
        */
public with sharing class NextStepFuture {

    /* 
     * Question 1
     * Update/Uncomment the template code to create a method
     * Create a future method that updates all account and opportunities next step to 'Meeting in the future'
     * Account Next Step field is a custom field
     * Opportunity Next Step field is a standard field
     * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testUpdateAllNextStep to cover test this method
     */
    //[public | private ] [static] data_type method_name (input parameters) {
    //  The body of the method
    //}

    @future
    public static void updateAllNextStep(){
        List<Account> accountList = [SELECT Id, Name, Next_Step__c FROM Account];
        for(Account acc : accountList){
            acc.Next_Step__c = 'Meeting in the future';
        }
        if(!accountList.isEmpty()){
            Database.update(accountList);
        }

        List<Opportunity>  opportunityList = [SELECT Id, Name, NextStep FROM Opportunity];
        for(Opportunity opp : opportunityList){
            opp.NextStep = 'Meeting in the future';
        }
        
        if(!opportunityList.isEmpty()){
            Database.update(opportunityList);
        }
    }

    /*
    * Question 2
    * Update/Uncomment the template code to create a method
    * Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
    * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testCreateDealAndUpdateRole to cover test this method
    */
    //Mix DML Error happens when you try to perform DML operations on setup and non-setup objects in a single transaction.
    public static void createDealAndUpdateRole() {
     Opportunity bigDeal = new Opportunity();
        insertBigDeal(bigDeal);

        UserRole[] roles = [SELECT Id, Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() OR Name = 'CRO' LIMIT 1];
        //we can only pass prmitive to Future Method so convert this to Primitive and passing value
        String roleId = roles.isEmpty()? null : roles[0].Id;
        updateUserRoleName(roleId);
    }

    // Helper method to insert big deal
    private static void insertBigDeal(Opportunity opp) {
        opp.Amount = 1000000;
        opp.Name = 'Big Deal';
        opp.StageName = 'Closed Won'; 
        opp.CloseDate = Date.today();
        
        insert opp;
    }


    // Helper method to update role name
    @future
    private static void updateUserRoleName(String roleId){
        UserRole role;
        if (roleId ==  null) {
            role = new UserRole();
            role.portalType = 'None'; 
            role.CaseAccessForAccountOwner = 'Edit'; 
            // role.OpportunityAccessForAccountOwner = 'Edit'; //This may need to be uncommented depending on your orgs Organization Wide Defaults(OWD) settings. If you are receiving FIELD_INTEGRITY_EXCEPTION, field integrity exception: unknown (Opportunity access level below organization default): [unknown], uncomment this line.
        } else {
            role = [SELECT Id, Name FROM UserRole WHERE Id = :roleId LIMIT 1];
        }

        role.Name = 'CRO';

        upsert role;
    }
}