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

  public static final String PORTAL_READER_PREFIX = 'portal.reader.';

  public static User newUser(String profileName, String usernamePrefix) {
    String unique = String.valueOf(Crypto.getRandomInteger()).remove('-');
    return new User(
      Alias = unique.left(8),
      Email = 'reader@inspection-tracker.test',
      Username = usernamePrefix + unique + '@inspection-tracker.test',
      LastName = 'Reader',
      ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1]
      .Id,
      TimeZoneSidKey = 'America/Chicago',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
  }

  /**
   * Creates a user with only the Inspection_Portal_Guest permission set, standing in for
   * the site guest user. Call from @TestSetup; runs in its own runAs block to avoid mixed DML.
   */
  public static void createPortalReader() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      User reader = newUser('Standard User', PORTAL_READER_PREFIX);
      insert reader;
      insert new PermissionSetAssignment(
        AssigneeId = reader.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'Inspection_Portal_Guest'
        ]
        .Id
      );
    }
  }

  public static User portalReader() {
    return [
      SELECT Id
      FROM User
      WHERE Username LIKE :PORTAL_READER_PREFIX + '%'
      LIMIT 1
    ];
  }
}
