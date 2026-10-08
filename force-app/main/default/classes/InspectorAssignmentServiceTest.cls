@IsTest
private class InspectorAssignmentServiceTest {
  @IsTest
  static void fallsBackToFacilityOwnerWhenStateHasNoInspector() {
    Account facility = InspectionTestDataFactory.insertFacility(
      'Owner Fallback Clinic',
      'Nevada'
    );

    insert InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today()
    );

    Inspection__c inspection = InspectionTestDataFactory.inspectionsFor(
      facility.Id
    )[0];
    Assert.areEqual(UserInfo.getUserId(), inspection.Inspector__c);
  }

  @IsTest
  static void keepsInspectorChosenByUser() {
    User other = createUser('chosen');
    Account facility = InspectionTestDataFactory.insertFacility(
      'Chosen Inspector Clinic',
      'Nevada'
    );
    Inspection__c inspection = InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today()
    );
    inspection.Inspector__c = other.Id;

    insert inspection;

    Assert.areEqual(
      other.Id,
      InspectionTestDataFactory.inspectionsFor(facility.Id)[0].Inspector__c
    );
  }

  @IsTest
  static void facilityWithoutStateFallsBackToOwner() {
    Account facility = InspectionTestDataFactory.facility(
      'No State Clinic',
      null
    );
    insert facility;

    insert InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today()
    );

    Assert.areEqual(
      UserInfo.getUserId(),
      InspectionTestDataFactory.inspectionsFor(facility.Id)[0].Inspector__c
    );
  }

  @IsTest
  static void stateLookupAcceptsCodeOrName() {
    Assert.areEqual('West', StateAssignments.forState('CA').Region__c);
    Assert.areEqual(
      'West',
      StateAssignments.forState(' california ').Region__c
    );
    Assert.isNull(StateAssignments.forState(''));
    Assert.areEqual(50, StateAssignments.all().size());
    Assert.areEqual('Alabama', StateAssignments.all()[0].State_Name__c);
  }

  private static User createUser(String alias) {
    Profile standard = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      LIMIT 1
    ];
    User u = new User(
      Alias = alias.left(8),
      Email = alias + '@inspection-tracker.test',
      Username = alias +
        '.' +
        System.currentTimeMillis() +
        '@inspection-tracker.test',
      LastName = 'Inspector',
      ProfileId = standard.Id,
      TimeZoneSidKey = 'America/Chicago',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert u;
    return u;
  }
}
