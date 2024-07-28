import 'dart:core';

import 'package:failures/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'package:queries_impl_annotation/queries_impl_annotation.dart';
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
  'mixin _\$QueriesImplMixin {\n'
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
  Future<Either<Failure, dynamic>> aFunctionNotAnnotated() async =>
      const Right(1);
}

@ShouldGenerate(
  '  Future<Either<Failure, dynamic>> _\$getSomethingWithoutCaching(\n'
  '    Future<Either<Failure, dynamic>> Function() callback,\n'
  '  ) async =>\n'
  '      _\$executeActionIfHasInternetAccess(\n'
  '        action: () => _\$mapExceptionToFailureOn(callback: callback),\n'
  '      );\n'
  '\n'
  '  Future<Either<Failure, ReturnType>> _\$getSomethingWithCaching<ReturnType>({\n'
  '    required Future<ReturnType> Function() getFromRemote,\n'
  '    required Future<ReturnType> Function() getFromCache,\n'
  '    required Future<void> Function(ReturnType) saveOnCache,\n'
  '  }) async {\n'
  '    return await _\$mapExceptionToFailureOn(callback: () async {\n'
  '      if (!await _checker.hasInternetAccess) {\n'
  '        return Right(await getFromCache());\n'
  '      }\n\n'
  '      final value = await getFromRemote();\n'
  '      await saveOnCache(value);\n'
  '      return Right(value);\n'
  '    });\n'
  '  }\n',
  contains: true,
)
@GenerateForQueries()
abstract class GenerateQueriesImpl {
  @Query()
  Future<Either<Failure, dynamic>> getSomethingWithoutCaching() async =>
      const Right(1);

  @Query(withCaching: true)
  Future<Either<Failure, int>> getSomethingWithCaching() async {
    return _$getSomethingWithCaching(
      getFromRemote: () async => Future.value(1),
      getFromCache: () async => Future.value(1),
      saveOnCache: (value) async {},
    );
  }

  Future<Either<Failure, ReturnType>> _$getSomethingWithCaching<ReturnType>({
    required Future<ReturnType> Function() getFromRemote,
    required Future<ReturnType> Function() getFromCache,
    required Future<void> Function(ReturnType) saveOnCache,
  });
}

@ShouldGenerate(
  '  Future<Either<Failure, int>> _\$getSomethingWithoutCaching(\n'
  '    Future<Either<Failure, int>> Function() callback,\n'
  '  ) async =>\n'
  '      _\$executeActionIfHasInternetAccess(\n'
  '        action: () => GenerateQueriesWithCustomExceptionMappingImpl\n'
  '            .mapExceptionToFailureOn(callback: callback),\n'
  '      );\n'
  '\n'
  '  Future<Either<Failure, ReturnType>> _\$getSomethingWithCaching<ReturnType>({\n'
  '    required Future<ReturnType> Function() getFromRemote,\n'
  '    required Future<ReturnType> Function() getFromCache,\n'
  '    required Future<void> Function(ReturnType) saveOnCache,\n'
  '  }) async {\n'
  '    return await GenerateQueriesWithCustomExceptionMappingImpl\n'
  '        .mapExceptionToFailureOn(callback: () async {\n'
  '      if (!await _checker.hasInternetAccess) {\n'
  '        return Right(await getFromCache());\n'
  '      }\n\n'
  '      final value = await getFromRemote();\n'
  '      await saveOnCache(value);\n'
  '      return Right(value);\n'
  '    });\n'
  '  }\n',
  contains: true,
)
@GenerateForQueries()
abstract class GenerateQueriesWithCustomExceptionMappingImpl {
  @Query<int>(mapExceptionToFailure: mapExceptionToFailureOn)
  Future<Either<Failure, int>> getSomethingWithoutCaching() async =>
      const Right(1);

  @Query<int>(withCaching: true, mapExceptionToFailure: mapExceptionToFailureOn)
  Future<Either<Failure, int>> getSomethingWithCaching() async {
    return _$getSomethingWithCaching(
      getFromRemote: () async => Future.value(1),
      getFromCache: () async => Future.value(1),
      saveOnCache: (value) async {},
    );
  }

  Future<Either<Failure, ReturnType>> _$getSomethingWithCaching<ReturnType>({
    required Future<ReturnType> Function() getFromRemote,
    required Future<ReturnType> Function() getFromCache,
    required Future<void> Function(ReturnType) saveOnCache,
  });

  static Future<Either<Failure, int>> mapExceptionToFailureOn({
    required Future<Either<Failure, int>> Function() callback,
  }) async {
    try {
      return await callback();
    } on FormatException {
      return Left(ServerFailure());
    }
  }
}
