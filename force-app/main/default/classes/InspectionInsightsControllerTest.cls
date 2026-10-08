@IsTest
private class InspectionInsightsControllerTest {
  @TestSetup
  static void setup() {
    Account hospital = InspectionTestDataFactory.facility(
      'Insight Hospital',
      'Texas'
    );
    Account failingClinic = InspectionTestDataFactory.facility(
      'Insight Failing Clinic',
      'Texas'
    );
    failingClinic.Facility_Type__c = 'Clinic';
    Account overdueClinic = InspectionTestDataFactory.facility(
      'Insight Overdue Clinic',
      'Colorado'
    );
    overdueClinic.Facility_Type__c = 'Clinic';
    Account unlisted = InspectionTestDataFactory.facility(
      'Insight Unlisted Hospital',
      'Texas'
    );
    unlisted.Publicly_Listed__c = false;
    insert new List<Account>{
      hospital,
      failingClinic,
      overdueClinic,
      unlisted
    };

    // Open inspection first, so the completed history below doesn't schedule a follow-up.
    insert InspectionTestDataFactory.inspection(
      overdueClinic.Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today().addDays(-45)
    );

    insert new List<Inspection__c>{
      completed(hospital.Id, InspectionConstants.STATUS_PASSED, -30, 90, null),
      completed(
        failingClinic.Id,
        InspectionConstants.STATUS_FAILED,
        -10,
        50,
        'Infection Control;Medication Storage'
      ),
      completed(
        overdueClinic.Id,
        InspectionConstants.STATUS_PASSED_WITH_CONDITIONS,
        -400,
        80,
        'Infection Control'
      ),
      completed(
        unlisted.Id,
        InspectionConstants.STATUS_FAILED,
        -20,
        40,
        'Fire and Life Safety'
      )
    };

    InspectionTestDataFactory.createPortalReader();
  }

  private static Inspection__c completed(
    Id facilityId,
    String status,
    Integer daysAgo,
    Integer score,
    String areas
  ) {
    Inspection__c inspection = InspectionTestDataFactory.inspection(
      facilityId,
      status,
      Date.today().addDays(daysAgo)
    );
    inspection.Completed_Date__c = Date.today().addDays(daysAgo);
    inspection.Score__c = score;
    inspection.Deficiency_Areas__c = areas;
    inspection.Internal_Notes__c = 'Internal only';
    return inspection;
  }

  private static InspectionInsightsController.NationalInsights insightsAsGuest(
    String facilityType
  ) {
    InspectionInsightsController.NationalInsights result;
    System.runAs(InspectionTestDataFactory.portalReader()) {
      result = InspectionInsightsController.getNationalInsights(facilityType);
    }
    return result;
  }

  @IsTest
  static void kpisCountListedFacilitiesOnly() {
    InspectionInsightsController.Kpis k = insightsAsGuest(null).kpis;

    Assert.areEqual(3, k.facilities, 'Unlisted facility must be excluded');
    Assert.areEqual(33.3, k.compliantPct);
    Assert.areEqual(1, k.overdue);
    Assert.areEqual(1, k.failing);
    Assert.areEqual(2, k.inspectionsLast12Months);
    Assert.areEqual(50.0, k.failRateLast12Months);
    Assert.areEqual(70.0, k.avgScoreLast12Months);
  }

  @IsTest
  static void statesCoverAllFiftyWithCounts() {
    Map<String, InspectionInsightsController.StateStat> byCode = new Map<String, InspectionInsightsController.StateStat>();
    for (
      InspectionInsightsController.StateStat stat : insightsAsGuest(null).states
    ) {
      byCode.put(stat.code, stat);
    }

    Assert.areEqual(50, byCode.size());
    Assert.areEqual(2, byCode.get('TX').facilities);
    Assert.areEqual(1, byCode.get('TX').compliant);
    Assert.areEqual(1, byCode.get('TX').failing);
    Assert.areEqual(50.0, byCode.get('TX').compliantPct);
    Assert.areEqual(1, byCode.get('CO').overdue);
    Assert.areEqual(0, byCode.get('AL').facilities);
    Assert.isNull(
      byCode.get('AL').compliantPct,
      'States without facilities have no rate'
    );
  }

  @IsTest
  static void trendBucketsByQuarter() {
    List<InspectionInsightsController.QuarterStat> trend = insightsAsGuest(null)
      .trend;

    Assert.areEqual(12, trend.size());
    Assert.isTrue(trend[11].isPartial, 'Current quarter is marked partial');
    Integer passed = 0;
    Integer conditional = 0;
    Integer failed = 0;
    for (InspectionInsightsController.QuarterStat q : trend) {
      passed += q.passed;
      conditional += q.conditional;
      failed += q.failed;
      Assert.areEqual(q.passed + q.conditional + q.failed, q.total);
    }
    Assert.areEqual(1, passed);
    Assert.areEqual(1, conditional);
    Assert.areEqual(1, failed);
  }

  @IsTest
  static void deficienciesSplitMultiSelectValues() {
    List<InspectionInsightsController.CountStat> deficiencies = insightsAsGuest(
        null
      )
      .deficiencies;

    Assert.areEqual(
      8,
      deficiencies.size(),
      'Every area is listed, even with zero citations'
    );
    Assert.areEqual('Infection Control', deficiencies[0].label);
    Assert.areEqual(2, deficiencies[0].count);
    Assert.areEqual(66.7, deficiencies[0].pct);
    for (InspectionInsightsController.CountStat stat : deficiencies) {
      if (stat.label == 'Fire and Life Safety') {
        Assert.areEqual(
          0,
          stat.count,
          'Unlisted facility citations must be excluded'
        );
      }
    }
  }

  @IsTest
  static void breakdownsAndOverdueAging() {
    InspectionInsightsController.NationalInsights insights = insightsAsGuest(
      null
    );

    for (InspectionInsightsController.GroupStat stat : insights.byType) {
      if (stat.name == 'Clinic') {
        Assert.areEqual(2, stat.facilities);
        Assert.areEqual(50.0, stat.overdueRate);
        Assert.areEqual(100.0, stat.failRate);
        Assert.areEqual(50.0, stat.avgScore);
      }
      if (stat.name == 'Laboratory') {
        Assert.isNull(stat.overdueRate, 'No facilities, no rate');
        Assert.isNull(stat.failRate);
      }
    }
    for (InspectionInsightsController.GroupStat stat : insights.byRegion) {
      if (stat.name == 'Southwest') {
        Assert.areEqual(2, stat.facilities);
      }
      if (stat.name == 'West') {
        Assert.areEqual(1, stat.facilities);
      }
    }
    Assert.areEqual('31–90 days', insights.overdueAging[1].label);
    Assert.areEqual(1, insights.overdueAging[1].count);
    Assert.areEqual(0, insights.overdueAging[0].count);
  }

  @IsTest
  static void facilityTypeFilterAppliesToEverySection() {
    InspectionInsightsController.NationalInsights insights = insightsAsGuest(
      'Hospital'
    );

    Assert.areEqual('Hospital', insights.facilityType);
    Assert.areEqual(1, insights.kpis.facilities);
    Assert.areEqual(100.0, insights.kpis.compliantPct);
    Assert.areEqual(1, insights.byType.size());
    Assert.areEqual(0, insights.deficiencies[0].count);
  }

  @IsTest
  static void responseContainsNoRecordIdsOrInternalFields() {
    String json = JSON.serialize(insightsAsGuest(null));

    Assert.isFalse(json.contains('Internal only'));
    Assert.isFalse(json.containsIgnoreCase('inspector'));
    Assert.isFalse(json.contains('"001'), 'No Account ids');
  }

  @IsTest
  static void userWithoutFieldAccessGetsFriendlyError() {
    User noAccess = InspectionTestDataFactory.newUser(
      'Standard User',
      'insights.no.access.'
    );
    insert noAccess;
    System.runAs(noAccess) {
      try {
        InspectionInsightsController.getNationalInsights(null);
        Assert.fail('A user without access should get an error');
      } catch (AuraHandledException e) {
        Assert.isTrue(e.getMessage().contains('unavailable'));
      }
    }
  }

  @IsTest
  static void picklistValueCapitalizesAreas() {
    Assert.areEqual(
      'Fire and Life Safety',
      InspectionSampleData.picklistValue('fire and life safety')
    );
  }
}
