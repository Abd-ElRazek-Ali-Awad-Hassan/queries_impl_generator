import 'package:failures/failures.dart';
import 'package:fpdart/fpdart.dart';

class GenerateForQueries {
  const GenerateForQueries();
}

typedef ExceptionToFailureMapper<ReturnType>
    = Future<Either<Failure, ReturnType>> Function({
  required Future<Either<Failure, ReturnType>> Function() callback,
});

class Query {
  const Query({
    this.mapExceptionToFailure,
  });

  final ExceptionToFailureMapper? mapExceptionToFailure;
}
