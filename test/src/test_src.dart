import 'package:failures/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'package:queries_impl_generator/annotations.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldThrow('The source annotation should be set!')
class AClassNotAnnotated {}

@ShouldThrow("'GenerateForQueries()' only support classes")
@GenerateForQueries()
void aFunctionNotAClass() {}

@ShouldThrow("'GenerateForQueries()' only support classes")
@GenerateForQueries()
const double aVariableNotAClass = 3.14;

@ShouldGenerate(
  'mixin _\$GenerateMixinMixin {\n'
  '  late final InternetConnectionChecker _checker;\n'
  '\n'
  '  void _\$setInternetConnectionChecker(InternetConnectionChecker checker) =>\n'
  '      _checker = checker;\n'
  '\n'
  '  Future<Either<Failure, ReturnType>>\n'
  '      _\$executeActionIfHasInternetAccess<ReturnType>({\n'
  '    required Future<Either<Failure, ReturnType>> Function() action,\n'
  '  }) async {\n'
  '    if (!await _checker.hasInternetAccess) {\n'
  '      return Left(NetworkFailure());\n'
  '    }\n'
  '    return action();\n'
  '  }\n'
  '\n'
  '  Future<Either<Failure, ReturnType>> _\$mapExceptionToFailureOn<ReturnType>({\n'
  '    required Future<Either<Failure, ReturnType>> Function() callback,\n'
  '  }) async {\n'
  '    try {\n'
  '      return await callback();\n'
  '    } on NetworkException {\n'
  '      return Left(NetworkFailure());\n'
  '    } on ServerException catch (exception) {\n'
  '      return Left(ServerFailure(message: exception.message));\n'
  '    } on CacheException catch (exception) {\n'
  '      return Left(CacheFailure(message: exception.message));\n'
  '    }\n'
  '  }\n'
  '}\n',
  contains: true,
)
@GenerateForQueries()
class GenerateMixin {
  Future<Either<Failure, dynamic>> getAnyThing2() async => const Right(1);
}

@ShouldGenerate(
  '  Future<Either<Failure, dynamic>> _\$getAnyThing(\n'
  '    Future<Either<Failure, dynamic>> Function() callback,\n'
  '  ) async =>\n'
  '      _\$executeActionIfHasInternetAccess(\n'
  '        action: () => _\$mapExceptionToFailureOn(callback: callback),\n'
  '      );\n',
  contains: true,
)
@GenerateForQueries()
class GenerateQueriesImpl {
  @Query()
  Future<Either<Failure, dynamic>> getAnyThing() async => const Right(1);
}
