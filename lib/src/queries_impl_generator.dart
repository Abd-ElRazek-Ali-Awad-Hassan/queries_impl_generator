import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:queries_impl_annotation/queries_impl_annotation.dart';
import 'package:queries_impl_generator/src/utils.dart';
import 'package:source_gen/source_gen.dart';

class QueriesImplGenerator extends GeneratorForAnnotation<GenerateForQueries> {
  const QueriesImplGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (annotation.isNull) {
      throw InvalidGenerationSource(
        'The source annotation should be set!',
        element: element,
      );
    }
    if (element is! ClassElement) {
      throw InvalidGenerationSource(
        "'$GenerateForQueries()' only support classes",
        element: element,
      );
    }

    return (StringBuffer()
          ..writeAll([
            _buildMixinDeclaration(element),
            _buildConnectionCheckerInstanceDeclaration(),
            _buildConnectionCheckerInstanceSetter(),
            ...Utils.methodsAnnotatedWith<Query>(element.methods).map(
              (e) => '${_buildMethod(e)}\n',
            ),
            _buildExecuteActionIfHasInternetAccess(),
            _buildMapExceptionToFailureOn(),
            '}\n',
          ]))
        .toString();
  }

  String _buildMixinDeclaration(ClassElement element) =>
      'mixin _\$${element.name}Mixin {\n'
      '\n';

  String _buildMethod(MethodElement element) {
    bool isQueryWithCaching = Utils.getFirstAnnotationOn<Query>(element)!
        .getField('withCaching')!
        .toBoolValue()!;

    if (isQueryWithCaching) {
      return _buildQueryWithCachingImplFor(element);
    }
    return _buildQueryWithoutCachingImplFor(element);
  }

  String _buildQueryWithCachingImplFor(MethodElement element) {
    return 'Future<Either<Failure, ReturnType>> _\$${element.name}<ReturnType>({\n'
        '  required Future<ReturnType> Function() getFromRemote,\n'
        '  required Future<ReturnType> Function() getFromCache,\n'
        '  required Future<void> Function(ReturnType) saveOnCache,\n'
        '}) async {\n'
        '  return await ${_getMapExceptionToFailureReferenceFor(element)}'
        '  (callback: () async {\n'
        '    if (!await _checker.hasInternetAccess) {\n'
        '      return Right(await getFromCache());\n'
        '    }\n\n'
        '    final value = await getFromRemote();\n'
        '    await saveOnCache(value);\n'
        '    return Right(value);\n'
        '  });\n'
        '}\n';
  }

  String _buildQueryWithoutCachingImplFor(MethodElement element) {
    return '${element.returnType} _\$${element.name}(\n'
        ' ${element.returnType} Function() callback,\n'
        ') async =>\n'
        '_\$executeActionIfHasInternetAccess(\n'
        'action: () => ${_getMapExceptionToFailureReferenceFor(element)}'
        '(callback: callback),\n'
        ');\n';
  }

  String _getMapExceptionToFailureReferenceFor(MethodElement element) {
    final mapExceptionToFailure = Utils.getPassedFunctionToAnnotation(
      Utils.getFirstAnnotationOn<Query>(element),
      'mapExceptionToFailure',
    );

    return switch (mapExceptionToFailure) {
      (null) => '_\$mapExceptionToFailureOn',
      (ExecutableElement e) => Utils.getFunctionReferenceAsStringFor(e),
    };
  }

  String _buildConnectionCheckerInstanceDeclaration() =>
      'late final InternetConnectionChecker _checker;\n\n';

  String _buildConnectionCheckerInstanceSetter() =>
      'void _\$setInternetConnectionChecker(InternetConnectionChecker checker) =>'
      ' _checker = checker;'
      '\n\n';

  String _buildExecuteActionIfHasInternetAccess() =>
      'Future<Either<Failure, ReturnType>>\n'
      '_\$executeActionIfHasInternetAccess<ReturnType>({\n'
      'required Future<Either<Failure, ReturnType>> Function() action,\n'
      '}) async {\n'
      'if (!await _checker.hasInternetAccess) {\n'
      'return Left(NetworkFailure());\n'
      '}\n'
      'return action();\n'
      '}\n';

  String _buildMapExceptionToFailureOn() =>
      'Future<Either<Failure, ReturnType>> _\$mapExceptionToFailureOn<ReturnType>({\n'
      'required Future<Either<Failure, ReturnType>> Function() callback,\n'
      '}) async {\n'
      'try {\n'
      'return await callback();\n'
      '} on NetworkException {\n'
      'return Left(NetworkFailure());\n'
      '} on ServerException catch (exception) {\n'
      'return Left(ServerFailure(message: exception.message));\n'
      '} on CacheException catch (exception) {\n'
      'return Left(CacheFailure(message: exception.message));\n'
      '}\n'
      '}\n';
}
