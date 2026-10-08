@IsTest
private class FacilityPortalControllerTest {
  @TestSetup
  static void setup() {
    List<Account> facilities = new List<Account>{
      InspectionTestDataFactory.facility(
        'Lakeview General Hospital of Austin',
        'Texas'
      ),
      InspectionTestDataFactory.facility(
        'Summit Urgent Care of Denver',
        'Colorado'
      ),
      InspectionTestDataFactory.facility('Hidden Clinic', 'Texas')
    };
    facilities[0].BillingPostalCode = '78701';
    facilities[1].Facility_Type__c = 'Urgent Care';
    facilities[2].Publicly_Listed__c = false;
    insert facilities;

    Inspection__c passed = InspectionTestDataFactory.inspection(
      facilities[0].Id,
      InspectionConstants.STATUS_PASSED,
      Date.today().addDays(-30)
    );
    passed.Completed_Date__c = Date.today().addDays(-30);
    passed.Score__c = 95;
    passed.Public_Summary__c = 'No deficiencies were cited.';
    passed.Internal_Notes__c = 'Internal only';
    insert passed;
    insert InspectionTestDataFactory.inspection(
      facilities[1].Id,
      InspectionConstants.STATUS_SCHEDULED,
      Date.today().addDays(-5)
    );

    InspectionTestDataFactory.createPortalReader();
  }

  @IsTest
  static void searchWithoutFiltersReturnsListedFacilitiesOnly() {
    System.runAs(InspectionTestDataFactory.portalReader()) {
      List<FacilityPortalController.FacilitySummary> results = FacilityPortalController.searchFacilities(
        null,
        null,
        null,
        null
      );
      Assert.areEqual(
        2,
        results.size(),
        'Unlisted facilities must not be returned'
      );
      Assert.areEqual('Lakeview General Hospital of Austin', results[0].name);
      Assert.isNotNull(results[0].latitude);
    }
  }

  @IsTest
  static void searchByTermMatchesNameCityOrZip() {
    System.runAs(InspectionTestDataFactory.portalReader()) {
      Assert.areEqual(
        1,
        FacilityPortalController.searchFacilities('lakeview', null, null, null)
          .size()
      );
      Assert.areEqual(
        1,
        FacilityPortalController.searchFacilities('78701', null, null, null)
          .size()
      );
      Assert.areEqual(
        2,
        FacilityPortalController.searchFacilities(
            'Springfield',
            null,
            null,
            null
          )
          .size()
      );
      Assert.areEqual(
        0,
        FacilityPortalController.searchFacilities('Spring%', null, null, null)
          .size(),
        '% is literal'
      );
    }
  }

  @IsTest
  static void searchByStateStatusAndType() {
    System.runAs(InspectionTestDataFactory.portalReader()) {
      Assert.areEqual(
        1,
        FacilityPortalController.searchFacilities(null, 'Texas', null, null)
          .size()
      );
      Assert.areEqual(
        1,
        FacilityPortalController.searchFacilities(null, 'CO', null, null).size()
      );
      List<FacilityPortalController.FacilitySummary> overdue = FacilityPortalController.searchFacilities(
        null,
        null,
        InspectionConstants.PORTAL_OVERDUE,
        null
      );
      Assert.areEqual(1, overdue.size());
      Assert.areEqual('Summit Urgent Care of Denver', overdue[0].name);
      Assert.areEqual(
        1,
        FacilityPortalController.searchFacilities(
            null,
            null,
            InspectionConstants.STATUS_PASSED,
            'Hospital'
          )
          .size()
      );
      Assert.areEqual(
        0,
        FacilityPortalController.searchFacilities(
            null,
            null,
            null,
            'Laboratory'
          )
          .size()
      );
    }
  }

  @IsTest
  static void detailReturnsHistoryWithoutInternalFields() {
    Account facility = [
      SELECT Id
      FROM Account
      WHERE Name = 'Lakeview General Hospital of Austin'
    ];
    System.runAs(InspectionTestDataFactory.portalReader()) {
      FacilityPortalController.FacilityDetail detail = FacilityPortalController.getFacilityDetail(
        facility.Id
      );

      Assert.areEqual(InspectionConstants.STATUS_PASSED, detail.portalStatus);
      Assert.areEqual(
        2,
        detail.inspections.size(),
        'Completed inspection plus the auto-scheduled follow-up'
      );
      String json = JSON.serialize(detail);
      Assert.isFalse(
        json.contains('Internal only'),
        'Internal notes must never be serialized'
      );
      Assert.isFalse(
        json.containsIgnoreCase('inspector'),
        'Inspector must not be exposed'
      );
    }
  }

  @IsTest
  static void detailRejectsUnlistedOrMissingFacility() {
    Account hidden = [SELECT Id FROM Account WHERE Name = 'Hidden Clinic'];
    System.runAs(InspectionTestDataFactory.portalReader()) {
      try {
        FacilityPortalController.getFacilityDetail(hidden.Id);
        Assert.fail('Unlisted facility should not be returned');
      } catch (AuraHandledException e) {
        Assert.areEqual(
          'This facility is not listed on the portal.',
          e.getMessage()
        );
      }
      try {
        FacilityPortalController.getFacilityDetail(null);
        Assert.fail('Null id should be rejected');
      } catch (AuraHandledException e) {
        Assert.isTrue(e.getMessage().contains('Choose a facility'));
      }
    }
  }

  @IsTest
  static void userWithoutFieldAccessGetsFriendlyError() {
    User noAccess = InspectionTestDataFactory.newUser(
      'Standard User',
      'no.access.'
    );
    insert noAccess;
    System.runAs(noAccess) {
      try {
        FacilityPortalController.searchFacilities(null, null, null, null);
        Assert.fail(
          'A user without access to the facility fields should get an error'
        );
      } catch (AuraHandledException e) {
        Assert.isTrue(e.getMessage().contains('unavailable'));
      }
    }
  }

  @IsTest
  static void filterOptionsListStatesTypesAndStatuses() {
    System.runAs(InspectionTestDataFactory.portalReader()) {
      FacilityPortalController.FilterOptions options = FacilityPortalController.getFilterOptions();
      Assert.areEqual(50, options.states.size());
      Assert.areEqual('Alabama', options.states[0].value);
      Assert.areEqual(6, options.facilityTypes.size());
      Assert.areEqual(
        FacilityPortalController.PORTAL_STATUSES.size(),
        options.statuses.size()
      );
    }
  }

  @IsTest
  static void escapeLikeEscapesWildcards() {
    Assert.areEqual(
      '50\\% off\\_now',
      FacilityPortalController.escapeLike('50% off_now')
    );
  }
}
