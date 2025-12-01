public class DemoDataGenerator {

    public static void generateDemoData() {
        List<Data_Quality_Score__c> scores = new List<Data_Quality_Score__c>();

        // Define objects and metrics
        List<String> objects = new List<String>{'Account', 'Contact', 'Opportunity', 'Lead'};
        List<String> metrics = new List<String>{'MissingRequired','InvalidEmails','InvalidPhones','DuplicateEmails','DuplicatePhones'};

        Date today = Date.today();

        for(String obj : objects) {
            for(String metric : metrics) {
                Integer val = Math.mod(Math.abs(Crypto.getRandomInteger()), 10); // random 0–9
                scores.add(new Data_Quality_Score__c(
                    Object_Name__c = obj,
                    Field__c = metric,
                    Score__c = val,
                    Analysis_Date__c = today
                ));
            }
        }

        insert scores;
        System.debug('Inserted ' + scores.size() + ' demo Data_Quality_Score__c records');
    }
}