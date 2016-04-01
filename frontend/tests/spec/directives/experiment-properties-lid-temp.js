describe("Specs for edit LID TEMP in the left menu", function() {

  beforeEach(module("ChaiBioTech"));
  var scope, compile, httpMock;

  beforeEach(inject(function($rootScope, $compile, $httpBackend) {
    scope = $rootScope.$new();
    compile = $compile;
    httpMock = $httpBackend;
    httpMock.expectGET("http://localhost:8000/status").respond("NOTHING");
    httpMock.expectGET("/experiments/").respond("NOTHING");

  }));

  it("Should check initial values of the dirctive", function() {

    var elem = angular.element('<edit-lid-temp></edit-lid-temp>');
    var compiled = compile(elem)(scope);
    scope.$digest();
    expect(scope.editLidTempMode).toBeFalsy();
  });


  it("Should check if the click on the name make editMode active and blur should call saveExperiment", function() {

    /*var elem = angular.element('<edit-lid-temp></edit-lid-temp>');
    var compiled = compile(elem)(scope);
    scope.$digest();
    //var compiledScope = compiled.isolateScope();
    spyOn(scope, "focusLidTemp");
    compiled.find(".truncate").click();
    scope.$digest();
    expect(scope.focusLidTemp).toHaveBeenCalled();

    /*spyOn(scope, "updateProtocol");
    compiled.find(":text").blur();
    scope.$digest();
    expect(scope.updateProtocol).toHaveBeenCalled();*/

  });

});