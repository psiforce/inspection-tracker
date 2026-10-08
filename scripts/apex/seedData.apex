// Creates or refreshes 150 demo medical facilities with inspection history.
// Run: sf apex run --file scripts/apex/seedData.apex
Integer count = InspectionSampleData.generate();
System.debug(LoggingLevel.INFO, count + ' facilities generated');
