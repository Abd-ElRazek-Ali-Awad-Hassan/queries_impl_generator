# QueriesImplGenerator

## A package that generates impl for query methods.

### an example 

```
@GenerateForQueries()
class SomeRepo with _$SomeRepoMixin {
  SomeRepo(InternetConnectionChecker internetConnectionChecker) {
    _$setInternetConnectionChecker(internetConnectionChecker)
  }
  
  @Query()
  Future<Either<Failure, SomeData>> getSomeData() async {
    return await _$getSomeData(
      () async => Right(someData),
    );
  }
}
```