trigger InspectionTrigger on Inspection__c(
  before insert,
  before update,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new InspectionTriggerHandler().run();
}
