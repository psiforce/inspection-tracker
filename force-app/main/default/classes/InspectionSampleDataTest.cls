@IsTest
private class InspectionSampleDataTest {
  @IsTest
  static void generatesFacilitiesWithHistoryAndIsRerunnable() {
    Test.startTest();
    Integer created = new InspectionSampleData().run(30);
    Integer rerun = new InspectionSampleData().run(30);
    Test.stopTest();

    Assert.areEqual(30, created);
    Assert.areEqual(30, rerun);
    Assert.areEqual(
      30,
      [SELECT COUNT() FROM Account WHERE License_Number__c LIKE 'DEMO-%']
    );
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM Account
        WHERE License_Number__c LIKE 'DEMO-%' AND Next_Inspection_Due__c = NULL
      ],
      'Every facility should have a next due date'
    );
    Assert.areEqual(
      30,
      [
        SELECT COUNT()
        FROM Inspection__c
        WHERE Status__c IN :InspectionConstants.OPEN_STATUSES
      ],
      'Each facility has exactly one open inspection; history must not create duplicates'
    );
  }
}
