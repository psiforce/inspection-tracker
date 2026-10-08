@IsTest
private class InspectionTriggerHandlerTest {
  @IsTest
  static void passingInspectionSchedulesNextAnnualAndRollsUp() {
    Account facility = InspectionTestDataFactory.insertFacility(
      'Test General Hospital',
      'Illinois'
    );
    Inspection__c inspection = InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today()
    );
    insert inspection;

    Date completed = Date.today().addDays(-1);
    Test.startTest();
    update new Inspection__c(
      Id = inspection.Id,
      Status__c = InspectionConstants.STATUS_PASSED,
      Completed_Date__c = completed
    );
    Test.stopTest();

    List<Inspection__c> all = InspectionTestDataFactory.inspectionsFor(
      facility.Id
    );
    Assert.areEqual(2, all.size(), 'A follow-up inspection should be created');
    Inspection__c followUp = all[1];
    Assert.areEqual(InspectionConstants.STATUS_SCHEDULED, followUp.Status__c);
    Assert.areEqual(
      InspectionConstants.TYPE_ANNUAL,
      followUp.Inspection_Type__c
    );
    Assert.areEqual(completed.addDays(365), followUp.Scheduled_Date__c);
    Assert.isNotNull(
      followUp.Inspector__c,
      'Follow-up should be assigned to an inspector'
    );

    Account rolled = [
      SELECT
        Inspection_Status__c,
        Last_Inspection_Date__c,
        Next_Inspection_Due__c,
        Region__c,
        Portal_Status__c
      FROM Account
      WHERE Id = :facility.Id
    ];
    Assert.areEqual(
      InspectionConstants.STATUS_PASSED,
      rolled.Inspection_Status__c
    );
    Assert.areEqual(completed, rolled.Last_Inspection_Date__c);
    Assert.areEqual(completed.addDays(365), rolled.Next_Inspection_Due__c);
    Assert.areEqual(
      'Midwest',
      rolled.Region__c,
      'Region should come from State_Assignment__mdt'
    );
    Assert.areEqual(InspectionConstants.STATUS_PASSED, rolled.Portal_Status__c);
  }

  @IsTest
  static void failedInspectionSchedulesReinspectionIn30Days() {
    Account facility = InspectionTestDataFactory.insertFacility(
      'Test Clinic',
      'Texas'
    );
    Inspection__c inspection = InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_IN_PROGRESS,
      Date.today()
    );
    insert inspection;

    Test.startTest();
    update new Inspection__c(
      Id = inspection.Id,
      Status__c = InspectionConstants.STATUS_FAILED
    );
    Test.stopTest();

    Inspection__c completed = [
      SELECT Completed_Date__c
      FROM Inspection__c
      WHERE Id = :inspection.Id
    ];
    Assert.areEqual(
      Date.today(),
      completed.Completed_Date__c,
      'Completed date should default to today'
    );

    Inspection__c followUp = [
      SELECT Inspection_Type__c, Scheduled_Date__c
      FROM Inspection__c
      WHERE
        Facility__c = :facility.Id
        AND Status__c = :InspectionConstants.STATUS_SCHEDULED
    ];
    Assert.areEqual(
      InspectionConstants.TYPE_REINSPECTION,
      followUp.Inspection_Type__c
    );
    Assert.areEqual(Date.today().addDays(30), followUp.Scheduled_Date__c);
  }

  @IsTest
  static void existingOpenInspectionPreventsDuplicateFollowUp() {
    Account facility = InspectionTestDataFactory.insertFacility(
      'Test Lab',
      'California'
    );
    insert InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today().addDays(200)
    );

    Test.startTest();
    Inspection__c historical = InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_PASSED,
      Date.today().addDays(-165)
    );
    historical.Completed_Date__c = Date.today().addDays(-165);
    insert historical;
    Test.stopTest();

    Assert.areEqual(
      2,
      InspectionTestDataFactory.inspectionsFor(facility.Id).size()
    );
  }

  @IsTest
  static void overdueWhenNextDueHasPassed() {
    Account facility = InspectionTestDataFactory.insertFacility(
      'Test Care Center',
      'Ohio'
    );
    insert InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today().addDays(-10)
    );

    Account rolled = [
      SELECT Portal_Status__c, Next_Inspection_Due__c
      FROM Account
      WHERE Id = :facility.Id
    ];
    Assert.areEqual(Date.today().addDays(-10), rolled.Next_Inspection_Due__c);
    Assert.areEqual(
      InspectionConstants.PORTAL_OVERDUE,
      rolled.Portal_Status__c
    );
  }

  @IsTest
  static void deletingInspectionRecalculatesFacility() {
    Account facility = InspectionTestDataFactory.insertFacility(
      'Test Surgery Center',
      'Ohio'
    );
    Inspection__c inspection = InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today().addDays(30)
    );
    insert inspection;

    Test.startTest();
    delete inspection;
    Test.stopTest();

    Account rolled = [
      SELECT Inspection_Status__c, Next_Inspection_Due__c, Portal_Status__c
      FROM Account
      WHERE Id = :facility.Id
    ];
    Assert.isNull(rolled.Inspection_Status__c);
    Assert.isNull(rolled.Next_Inspection_Due__c);
    Assert.areEqual(
      InspectionConstants.PORTAL_NOT_YET_INSPECTED,
      rolled.Portal_Status__c
    );

    undelete inspection;
    rolled = [SELECT Inspection_Status__c FROM Account WHERE Id = :facility.Id];
    Assert.areEqual(
      InspectionConstants.STATUS_SCHEDULED,
      rolled.Inspection_Status__c
    );
  }

  @IsTest
  static void bulkCompletionCreatesOneFollowUpPerFacility() {
    List<Account> facilities = new List<Account>();
    for (Integer i = 0; i < 50; i++) {
      facilities.add(
        InspectionTestDataFactory.facility('Bulk Facility ' + i, 'Florida')
      );
    }
    insert facilities;

    List<Inspection__c> inspections = new List<Inspection__c>();
    for (Account facility : facilities) {
      for (Integer year = 1; year <= 3; year++) {
        Inspection__c past = InspectionTestDataFactory.inspection(
          facility.Id,
          InspectionConstants.STATUS_PASSED,
          Date.today().addDays(-365 * year)
        );
        past.Completed_Date__c = Date.today().addDays(-365 * year + 30);
        inspections.add(past);
      }
    }

    Test.startTest();
    insert inspections;
    Test.stopTest();

    Assert.areEqual(
      50,
      [
        SELECT COUNT()
        FROM Inspection__c
        WHERE Status__c = :InspectionConstants.STATUS_SCHEDULED
      ],
      'Each facility should get exactly one follow-up, based on its latest result'
    );
  }

  @IsTest
  static void bypassSkipsAutomation() {
    Account facility = InspectionTestDataFactory.insertFacility(
      'Bypass Facility',
      'Ohio'
    );
    InspectionTriggerHandler.bypass = true;
    insert InspectionTestDataFactory.inspection(
      facility.Id,
      InspectionConstants.STATUS_PASSED,
      Date.today()
    );
    InspectionTriggerHandler.bypass = false;

    Assert.areEqual(
      1,
      InspectionTestDataFactory.inspectionsFor(facility.Id).size()
    );
    Assert.isNull(
      [SELECT Inspection_Status__c FROM Account WHERE Id = :facility.Id]
      .Inspection_Status__c
    );
  }
}
