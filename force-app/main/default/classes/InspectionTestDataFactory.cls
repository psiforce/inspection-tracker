@IsTest
public class InspectionTestDataFactory {
  public static Account facility(String name, String state) {
    return new Account(
      Name = name,
      RecordTypeId = InspectionConstants.facilityRecordTypeId(),
      Facility_Type__c = 'Hospital',
      Publicly_Listed__c = true,
      BillingStreet = '100 Main St',
      BillingCity = 'Springfield',
      BillingState = state,
      BillingPostalCode = '62701',
      BillingCountry = 'United States',
      BillingLatitude = 39.7817,
      BillingLongitude = -89.6501
    );
  }

  public static Account insertFacility(String name, String state) {
    Account record = facility(name, state);
    insert record;
    return record;
  }

  public static Inspection__c inspection(
    Id facilityId,
    String status,
    Date scheduled
  ) {
    return new Inspection__c(
      Facility__c = facilityId,
      Inspection_Type__c = InspectionConstants.TYPE_ANNUAL,
      Status__c = status,
      Scheduled_Date__c = scheduled
    );
  }

  public static List<Inspection__c> inspectionsFor(Id facilityId) {
    return [
      SELECT
        Id,
        Status__c,
        Inspection_Type__c,
        Scheduled_Date__c,
        Completed_Date__c,
        Inspector__c
      FROM Inspection__c
      WHERE Facility__c = :facilityId
      ORDER BY Scheduled_Date__c
    ];
  }
}
