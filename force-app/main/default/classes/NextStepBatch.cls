/*
 * NextStepBatch Class Description:
 * 
 * Implementing the 'Database.Batchable' interface allows you to define a job that can be broken into smaller batches.
 * Update the Next Step field on all accounts and opportunities in the org to 'Batching the next meetings together.' 
 * Send an email to all active users
 * 
 * Benefits of using Batch Apex:
 * 
 * 1. Large Data Volumes: Batch Apex is specifically tailored to handle large data volumes (LDV). It allows processing of records in batches, making it suitable for bulk processing, especially when dealing with millions of records.
 * 2. Avoid Governor Limits: By splitting the transaction into smaller batches, you can perform operations on a large number of records without hitting governor limits.
 * 3. Flexible Scheduling: Batch classes can be scheduled to run at specified intervals, providing flexibility in terms of when the processing occurs.
 * 4. Stateful Execution: Supports stateful execution, so you can maintain state across batch transactions by implementing the `Database.Stateful` interface.
 * 5. Built-in Retry Mechanism: If a batch fails, Salesforce provides built-in mechanisms to retry the batch.
 * 6. Asynchronous Processing: Operations are executed asynchronously, ensuring that the user is not blocked while the batch is processing.
 * 
 * For a more detailed understanding and best practices, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch.htm
 * 
 * Note: This class contains placeholders and commented sections that need to be updated with actual logic for querying and updating records.
 */
public with sharing class NextStepBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query for all accounts; Opportunities will be queried separately in execute
        return Database.getQueryLocator([
            SELECT Id, Next_Step__c FROM Account
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        final String BATCH_NEXT_STEP = 'Batching the next meetings together.';

       //List<Account> accountsToUpdate = new List<Account>();
        Set<Id> accountIds = new Set<Id>();

        for (Account acc : scope) {
            acc.Next_Step__c = BATCH_NEXT_STEP;
            System.debug('In For Loop'+acc.Next_Step__c);
            accountIds.add(acc.Id);
        }

        Database.update(scope);
        System.debug('After Update'+scope);

        // Query Opportunities related to these Accounts
        List<Opportunity> oppsToUpdate = [
            SELECT Id, AccountId, NextStep FROM Opportunity
            WHERE AccountId IN :accountIds
        ];

        for (Opportunity opp : oppsToUpdate) {
            opp.NextStep = BATCH_NEXT_STEP;
        }

        if (!oppsToUpdate.isEmpty()) {
            Database.update(oppsToUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        final List<User> USERS = [
            SELECT Id, Name, Email 
            FROM User 
            WHERE IsActive = true 
            AND (NOT Email LIKE 'autoproc%')
        ];

        Set<String> emailSet = new Set<String>();
        for (User u : USERS) {
            if (u.Email != null) {
                emailSet.add(u.Email);
            }
        }

        if (!emailSet.isEmpty()) {
            sendEmailToActiveUsers(emailSet);
        }
    }

    private void sendEmailToActiveUsers(Set<String> emails) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(emails));
            mail.setSubject('Next Step Batch Complete');
            mail.setPlainTextBody('The next step batch has completed.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
        }
    }
}