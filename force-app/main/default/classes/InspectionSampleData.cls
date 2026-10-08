/**
 * Generates demo data: 150 medical facilities (3 per state) with 1-3 years of
 * inspection history. Output is deterministic, so every run produces the same facilities.
 * Safe to rerun: facilities are upserted on License_Number__c and their demo
 * inspections are replaced.
 *
 * Run: sf apex run --file scripts/apex/seedData.apex
 */
public with sharing class InspectionSampleData {
  public static final String LICENSE_PREFIX = 'DEMO-';

  /** City|State|ZIP|Latitude|Longitude */
  private static final List<String> LOCATIONS = new List<String>{
    'Birmingham|Alabama|35203|33.5186|-86.8104',
    'Montgomery|Alabama|36104|32.3668|-86.3000',
    'Mobile|Alabama|36602|30.6954|-88.0399',
    'Anchorage|Alaska|99501|61.2181|-149.9003',
    'Fairbanks|Alaska|99701|64.8378|-147.7164',
    'Juneau|Alaska|99801|58.3019|-134.4197',
    'Phoenix|Arizona|85004|33.4484|-112.0740',
    'Tucson|Arizona|85701|32.2226|-110.9747',
    'Flagstaff|Arizona|86001|35.1983|-111.6513',
    'Little Rock|Arkansas|72201|34.7465|-92.2896',
    'Fayetteville|Arkansas|72701|36.0626|-94.1574',
    'Jonesboro|Arkansas|72401|35.8423|-90.7043',
    'Los Angeles|California|90012|34.0522|-118.2437',
    'San Francisco|California|94102|37.7749|-122.4194',
    'San Diego|California|92101|32.7157|-117.1611',
    'Denver|Colorado|80202|39.7392|-104.9903',
    'Colorado Springs|Colorado|80903|38.8339|-104.8214',
    'Grand Junction|Colorado|81501|39.0639|-108.5506',
    'Hartford|Connecticut|06103|41.7658|-72.6734',
    'New Haven|Connecticut|06510|41.3083|-72.9279',
    'Stamford|Connecticut|06901|41.0534|-73.5387',
    'Wilmington|Delaware|19801|39.7391|-75.5398',
    'Dover|Delaware|19901|39.1582|-75.5244',
    'Newark|Delaware|19711|39.6837|-75.7497',
    'Miami|Florida|33130|25.7617|-80.1918',
    'Orlando|Florida|32801|28.5384|-81.3789',
    'Tampa|Florida|33602|27.9506|-82.4572',
    'Atlanta|Georgia|30303|33.7490|-84.3880',
    'Savannah|Georgia|31401|32.0809|-81.0912',
    'Augusta|Georgia|30901|33.4735|-82.0105',
    'Honolulu|Hawaii|96813|21.3069|-157.8583',
    'Hilo|Hawaii|96720|19.7241|-155.0868',
    'Kahului|Hawaii|96732|20.8893|-156.4729',
    'Boise|Idaho|83702|43.6150|-116.2023',
    'Idaho Falls|Idaho|83402|43.4917|-112.0339',
    'Pocatello|Idaho|83201|42.8713|-112.4455',
    'Chicago|Illinois|60602|41.8781|-87.6298',
    'Springfield|Illinois|62701|39.7817|-89.6501',
    'Peoria|Illinois|61602|40.6936|-89.5890',
    'Indianapolis|Indiana|46204|39.7684|-86.1581',
    'Fort Wayne|Indiana|46802|41.0793|-85.1394',
    'Evansville|Indiana|47708|37.9716|-87.5711',
    'Des Moines|Iowa|50309|41.5868|-93.6250',
    'Cedar Rapids|Iowa|52401|41.9779|-91.6656',
    'Davenport|Iowa|52801|41.5236|-90.5776',
    'Wichita|Kansas|67202|37.6872|-97.3301',
    'Topeka|Kansas|66603|39.0473|-95.6752',
    'Kansas City|Kansas|66101|39.1141|-94.6275',
    'Louisville|Kentucky|40202|38.2527|-85.7585',
    'Lexington|Kentucky|40507|38.0406|-84.5037',
    'Bowling Green|Kentucky|42101|36.9685|-86.4808',
    'New Orleans|Louisiana|70112|29.9511|-90.0715',
    'Baton Rouge|Louisiana|70801|30.4515|-91.1871',
    'Shreveport|Louisiana|71101|32.5252|-93.7502',
    'Portland|Maine|04101|43.6591|-70.2568',
    'Bangor|Maine|04401|44.8016|-68.7712',
    'Augusta|Maine|04330|44.3106|-69.7795',
    'Baltimore|Maryland|21202|39.2904|-76.6122',
    'Annapolis|Maryland|21401|38.9784|-76.4922',
    'Frederick|Maryland|21701|39.4143|-77.4105',
    'Boston|Massachusetts|02108|42.3601|-71.0589',
    'Worcester|Massachusetts|01608|42.2626|-71.8023',
    'Springfield|Massachusetts|01103|42.1015|-72.5898',
    'Detroit|Michigan|48226|42.3314|-83.0458',
    'Grand Rapids|Michigan|49503|42.9634|-85.6681',
    'Lansing|Michigan|48933|42.7325|-84.5555',
    'Minneapolis|Minnesota|55401|44.9778|-93.2650',
    'Rochester|Minnesota|55902|44.0121|-92.4802',
    'Duluth|Minnesota|55802|46.7867|-92.1005',
    'Jackson|Mississippi|39201|32.2988|-90.1848',
    'Gulfport|Mississippi|39501|30.3674|-89.0928',
    'Tupelo|Mississippi|38804|34.2576|-88.7034',
    'Kansas City|Missouri|64106|39.0997|-94.5786',
    'St. Louis|Missouri|63101|38.6270|-90.1994',
    'Springfield|Missouri|65806|37.2090|-93.2923',
    'Billings|Montana|59101|45.7833|-108.5007',
    'Missoula|Montana|59802|46.8721|-113.9940',
    'Helena|Montana|59601|46.5891|-112.0391',
    'Omaha|Nebraska|68102|41.2565|-95.9345',
    'Lincoln|Nebraska|68508|40.8136|-96.7026',
    'Grand Island|Nebraska|68801|40.9264|-98.3420',
    'Las Vegas|Nevada|89101|36.1699|-115.1398',
    'Reno|Nevada|89501|39.5296|-119.8138',
    'Carson City|Nevada|89701|39.1638|-119.7674',
    'Manchester|New Hampshire|03101|42.9956|-71.4548',
    'Concord|New Hampshire|03301|43.2081|-71.5376',
    'Nashua|New Hampshire|03060|42.7654|-71.4676',
    'Newark|New Jersey|07102|40.7357|-74.1724',
    'Trenton|New Jersey|08608|40.2206|-74.7597',
    'Atlantic City|New Jersey|08401|39.3643|-74.4229',
    'Albuquerque|New Mexico|87102|35.0844|-106.6504',
    'Santa Fe|New Mexico|87501|35.6870|-105.9378',
    'Las Cruces|New Mexico|88001|32.3199|-106.7637',
    'New York|New York|10007|40.7128|-74.0060',
    'Buffalo|New York|14202|42.8864|-78.8784',
    'Albany|New York|12207|42.6526|-73.7562',
    'Charlotte|North Carolina|28202|35.2271|-80.8431',
    'Raleigh|North Carolina|27601|35.7796|-78.6382',
    'Asheville|North Carolina|28801|35.5951|-82.5515',
    'Fargo|North Dakota|58102|46.8772|-96.7898',
    'Bismarck|North Dakota|58501|46.8083|-100.7837',
    'Grand Forks|North Dakota|58201|47.9253|-97.0329',
    'Columbus|Ohio|43215|39.9612|-82.9988',
    'Cleveland|Ohio|44113|41.4993|-81.6944',
    'Cincinnati|Ohio|45202|39.1031|-84.5120',
    'Oklahoma City|Oklahoma|73102|35.4676|-97.5164',
    'Tulsa|Oklahoma|74103|36.1540|-95.9928',
    'Norman|Oklahoma|73069|35.2226|-97.4395',
    'Portland|Oregon|97204|45.5152|-122.6784',
    'Eugene|Oregon|97401|44.0521|-123.0868',
    'Bend|Oregon|97701|44.0582|-121.3153',
    'Philadelphia|Pennsylvania|19107|39.9526|-75.1652',
    'Pittsburgh|Pennsylvania|15222|40.4406|-79.9959',
    'Harrisburg|Pennsylvania|17101|40.2732|-76.8867',
    'Providence|Rhode Island|02903|41.8240|-71.4128',
    'Warwick|Rhode Island|02886|41.7001|-71.4162',
    'Newport|Rhode Island|02840|41.4901|-71.3128',
    'Charleston|South Carolina|29401|32.7765|-79.9311',
    'Columbia|South Carolina|29201|34.0007|-81.0348',
    'Greenville|South Carolina|29601|34.8526|-82.3940',
    'Sioux Falls|South Dakota|57104|43.5446|-96.7311',
    'Rapid City|South Dakota|57701|44.0805|-103.2310',
    'Pierre|South Dakota|57501|44.3683|-100.3510',
    'Nashville|Tennessee|37203|36.1627|-86.7816',
    'Memphis|Tennessee|38103|35.1495|-90.0490',
    'Knoxville|Tennessee|37902|35.9606|-83.9207',
    'Houston|Texas|77002|29.7604|-95.3698',
    'Dallas|Texas|75201|32.7767|-96.7970',
    'Austin|Texas|78701|30.2672|-97.7431',
    'Salt Lake City|Utah|84101|40.7608|-111.8910',
    'Provo|Utah|84601|40.2338|-111.6585',
    'St. George|Utah|84770|37.0965|-113.5684',
    'Burlington|Vermont|05401|44.4759|-73.2121',
    'Montpelier|Vermont|05602|44.2601|-72.5754',
    'Rutland|Vermont|05701|43.6106|-72.9726',
    'Richmond|Virginia|23219|37.5407|-77.4360',
    'Virginia Beach|Virginia|23451|36.8529|-75.9780',
    'Roanoke|Virginia|24011|37.2710|-79.9414',
    'Seattle|Washington|98104|47.6062|-122.3321',
    'Spokane|Washington|99201|47.6588|-117.4260',
    'Tacoma|Washington|98402|47.2529|-122.4443',
    'Charleston|West Virginia|25301|38.3498|-81.6326',
    'Morgantown|West Virginia|26505|39.6295|-79.9559',
    'Huntington|West Virginia|25701|38.4192|-82.4452',
    'Milwaukee|Wisconsin|53202|43.0389|-87.9065',
    'Madison|Wisconsin|53703|43.0731|-89.4012',
    'Green Bay|Wisconsin|54301|44.5133|-88.0133',
    'Cheyenne|Wyoming|82001|41.1400|-104.8202',
    'Casper|Wyoming|82601|42.8666|-106.3131',
    'Jackson|Wyoming|83001|43.4799|-110.7624'
  };

  private static final List<String> NAME_PREFIXES = new List<String>{
    'Riverside',
    'Summit',
    'Lakeview',
    'Pinecrest',
    'Valley',
    'Harbor',
    'Northside',
    'Unity',
    'Cedar',
    'Meridian',
    'Bayside',
    'Highland',
    'Prairie',
    'Westbrook',
    'Evergreen',
    'Crossroads',
    'Silver Creek',
    'Oak Ridge'
  };
  private static final List<String> STREETS = new List<String>{
    'Main St',
    'Medical Center Dr',
    'Health Pkwy',
    'Oak Ave',
    'Park Blvd',
    'Elm St',
    'Washington Ave',
    'Lincoln Way',
    'Hospital Dr',
    'Cedar Ln'
  };
  private static final Map<String, String> NAME_SUFFIX = new Map<String, String>{
    'Hospital' => 'General Hospital',
    'Urgent Care' => 'Urgent Care',
    'Clinic' => 'Family Clinic',
    'Nursing Home' => 'Care Center',
    'Laboratory' => 'Diagnostic Laboratory',
    'Surgery Center' => 'Surgery Center'
  };
  private static final List<String> FINDING_AREAS = new List<String>{
    'infection control',
    'medication storage',
    'fire and life safety',
    'staff credentialing records',
    'emergency preparedness',
    'sterilization logs',
    'patient records privacy',
    'equipment maintenance'
  };

  private Integer seed = 20261008;

  public static Integer generate() {
    return new InspectionSampleData().run(LOCATIONS.size());
  }

  @TestVisible
  private Integer run(Integer facilityCount) {
    Id recordTypeId = InspectionConstants.facilityRecordTypeId();
    Date today = Date.today();

    List<Account> facilities = new List<Account>();
    for (Integer i = 0; i < facilityCount; i++) {
      List<String> loc = LOCATIONS[Math.mod(i, LOCATIONS.size())].split('\\|');
      String facilityType = pickFacilityType();
      facilities.add(
        new Account(
          RecordTypeId = recordTypeId,
          License_Number__c = LICENSE_PREFIX + String.valueOf(10000 + i),
          Name = NAME_PREFIXES[nextInt(NAME_PREFIXES.size())] +
            ' ' +
            NAME_SUFFIX.get(facilityType) +
            ' of ' +
            loc[0],
          Facility_Type__c = facilityType,
          Publicly_Listed__c = true,
          BillingStreet = String.valueOf(100 + nextInt(9800)) +
            ' ' +
            STREETS[nextInt(STREETS.size())],
          BillingCity = loc[0],
          BillingState = loc[1],
          BillingPostalCode = loc[2],
          BillingCountry = 'United States',
          BillingLatitude = Decimal.valueOf(loc[3]),
          BillingLongitude = Decimal.valueOf(loc[4]),
          Region__c = StateAssignments.forState(loc[1])?.Region__c,
          Phone = '(555) ' +
            String.valueOf(200 + nextInt(700)) +
            '-' +
            String.valueOf(1000 + nextInt(9000))
        )
      );
    }
    upsert facilities License_Number__c;

    delete [SELECT Id FROM Inspection__c WHERE Facility__c IN :facilities];

    // Open inspections go in first, so the trigger sees every facility as already scheduled
    // and doesn't add follow-ups for the historical rows.
    List<Inspection__c> open = new List<Inspection__c>();
    List<Inspection__c> history = new List<Inspection__c>();
    for (Account facility : facilities) {
      Integer scenario = nextInt(100);
      if (scenario < 6) {
        // New facility: first inspection is upcoming.
        open.add(
          openInspection(
            facility,
            InspectionConstants.TYPE_ANNUAL,
            InspectionConstants.STATUS_SCHEDULED,
            today.addDays(10 + nextInt(110))
          )
        );
        continue;
      }

      Date latest;
      String latestStatus;
      if (scenario < 16) {
        // Overdue: last inspection was more than a year ago and the next one never happened.
        latest = today.addDays(
          -(InspectionConstants.ANNUAL_INTERVAL_DAYS + 15 + nextInt(105))
        );
        latestStatus = InspectionConstants.STATUS_PASSED;
      } else if (scenario < 24) {
        // Recently failed: re-inspection is coming up.
        latest = today.addDays(-(5 + nextInt(20)));
        latestStatus = InspectionConstants.STATUS_FAILED;
      } else if (scenario < 34) {
        latest = today.addDays(-(20 + nextInt(320)));
        latestStatus = InspectionConstants.STATUS_PASSED_WITH_CONDITIONS;
      } else {
        latest = today.addDays(-(20 + nextInt(320)));
        latestStatus = InspectionConstants.STATUS_PASSED;
      }

      history.add(
        completedInspection(
          facility,
          InspectionConstants.TYPE_ANNUAL,
          latestStatus,
          latest
        )
      );
      Integer priorYears = nextInt(3);
      for (Integer y = 1; y <= priorYears; y++) {
        Date prior = latest.addDays(
          -(InspectionConstants.ANNUAL_INTERVAL_DAYS * y) + nextInt(21) - 10
        );
        Boolean priorFailed = nextInt(8) == 0;
        history.add(
          completedInspection(
            facility,
            InspectionConstants.TYPE_ANNUAL,
            priorFailed
              ? InspectionConstants.STATUS_FAILED
              : pickPassingStatus(),
            prior
          )
        );
        if (priorFailed) {
          history.add(
            completedInspection(
              facility,
              InspectionConstants.TYPE_REINSPECTION,
              InspectionConstants.STATUS_PASSED,
              prior.addDays(InspectionConstants.REINSPECTION_INTERVAL_DAYS)
            )
          );
        }
      }

      if (latestStatus == InspectionConstants.STATUS_FAILED) {
        open.add(
          openInspection(
            facility,
            InspectionConstants.TYPE_REINSPECTION,
            InspectionConstants.STATUS_SCHEDULED,
            latest.addDays(InspectionConstants.REINSPECTION_INTERVAL_DAYS)
          )
        );
      } else {
        Date nextDate = latest.addDays(
          InspectionConstants.ANNUAL_INTERVAL_DAYS
        );
        String nextStatus = nextDate == today ||
          (nextDate > today &&
          nextDate < today.addDays(3) &&
          nextInt(2) == 0)
          ? InspectionConstants.STATUS_IN_PROGRESS
          : InspectionConstants.STATUS_SCHEDULED;
        open.add(
          openInspection(
            facility,
            InspectionConstants.TYPE_ANNUAL,
            nextStatus,
            nextDate
          )
        );
      }
    }
    insert open;
    insert history;
    return facilities.size();
  }

  private Inspection__c openInspection(
    Account facility,
    String inspectionType,
    String status,
    Date scheduled
  ) {
    return new Inspection__c(
      Facility__c = facility.Id,
      Inspection_Type__c = inspectionType,
      Status__c = status,
      Scheduled_Date__c = scheduled
    );
  }

  private Inspection__c completedInspection(
    Account facility,
    String inspectionType,
    String status,
    Date completed
  ) {
    String area = FINDING_AREAS[nextInt(FINDING_AREAS.size())];
    Integer score;
    String summary;
    String notes;
    if (status == InspectionConstants.STATUS_PASSED) {
      score = 88 + nextInt(13);
      summary = 'The facility met all state licensing standards. No deficiencies were cited.';
      notes = 'Walkthrough completed with the facility administrator. No follow-up required.';
    } else if (status == InspectionConstants.STATUS_PASSED_WITH_CONDITIONS) {
      score = 72 + nextInt(16);
      summary =
        'Minor deficiencies were cited in ' +
        area +
        '. The facility\'s plan of correction was accepted; documentation is due within 60 days.';
      notes =
        'Plan of correction received on site. Confirm ' +
        area +
        ' documentation at the next visit.';
    } else {
      score = 40 + nextInt(30);
      summary =
        'Significant deficiencies were cited in ' +
        area +
        '. A re-inspection is required within 30 days.';
      notes = 'Escalated to the regional manager. Facility contact acknowledged the findings.';
    }
    return new Inspection__c(
      Facility__c = facility.Id,
      Inspection_Type__c = inspectionType,
      Status__c = status,
      Scheduled_Date__c = completed.addDays(-nextInt(4)),
      Completed_Date__c = completed,
      Score__c = score,
      Public_Summary__c = summary,
      Internal_Notes__c = notes
    );
  }

  private String pickFacilityType() {
    Integer r = nextInt(100);
    if (r < 25) {
      return 'Hospital';
    } else if (r < 45) {
      return 'Urgent Care';
    } else if (r < 70) {
      return 'Clinic';
    } else if (r < 85) {
      return 'Nursing Home';
    } else if (r < 93) {
      return 'Laboratory';
    }
    return 'Surgery Center';
  }

  private String pickPassingStatus() {
    return nextInt(5) == 0
      ? InspectionConstants.STATUS_PASSED_WITH_CONDITIONS
      : InspectionConstants.STATUS_PASSED;
  }

  /** Linear congruential generator, so runs are repeatable. Returns 0..bound-1. */
  private Integer nextInt(Integer bound) {
    seed = Math.mod(seed * 1103515245L + 12345L, 2147483648L).intValue();
    return Math.mod(Math.abs(seed / 65536), bound);
  }
}
